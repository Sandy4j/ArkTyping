extends Node

signal loading_progress_changed(progress: float)
signal loading_completed(resource_path: String, resource: Resource)
signal loading_failed(resource_path: String, error: String)
signal all_resources_loaded

## Dictionary untuk menyimpan resource yang sudah di-load: {path: resource}
var loaded_resources: Dictionary = {}

## Dictionary untuk menyimpan status loading: {path: status}
var loading_status: Dictionary = {}

## Queue untuk resources yang akan di-load
var loading_queue: Array[Dictionary] = []

## Current loading progress (0.0 - 1.0)
var current_progress: float = 0.0

## Flag untuk mengetahui apakah sedang loading
var is_loading: bool = false

## Thread pool untuk loading resources
var loading_threads: Array[Thread] = []
var max_threads: int = 4

## Mutex untuk thread safety
var mutex: Mutex = Mutex.new()

## Cache untuk VFX scenes yang sering digunakan
const VFX_CACHE: Dictionary = {
	"magic_circle_1": "res://asset/Vfx/Effect/magic_circle_1.tscn",
	"magic_circle_2": "res://asset/Vfx/Effect/magic_circle_2(plague).tscn",
	"magic_circle_3": "res://asset/Vfx/Effect/magic_circle_3(Silvanna).tscn",
	"magic_circle_4": "res://asset/Vfx/Effect/magic_circle_4(Rosemary).tscn",
	"magic_circle_5": "res://asset/Vfx/Effect/magic_circle_5(vigilante).tscn",
	"magic_circle_6": "res://asset/Vfx/Effect/magic_circle_6(Leciana).tscn",
	"magic_circle_7": "res://asset/Vfx/Effect/magic_circle_7(Lilitia).tscn",
	"magic_circle_8": "res://asset/Vfx/Effect/magic_circle_8.tscn",
	"magic_circle_9": "res://asset/Vfx/Effect/magic_circle_9.tscn",
	"divine_ball": "res://asset/Vfx/Effect/Divine_Ball.tscn",
	"toxic_veil": "res://asset/Vfx/Effect/Toxicveil.tscn",
	"shoot": "res://asset/Vfx/Effect/Shoot.tscn",
	"gun_rosemary": "res://asset/Vfx/Effect/gun_Rosemary.tscn",
	"hit_tower": "res://asset/Vfx/Effect/hit_Tower.tscn",
	"heal_celen": "res://asset/Vfx/Effect/heal_aura_2.tscn",
	"heal_priest": "res://asset/Vfx/Effect/heal_aura.tscn"
}

## Resource types yang benefit dari threading
const SHOULD_THREAD_LOAD: Array[String] = [
	".tscn",   # Scenes
	".tres",   # Resources (TowerData, EnemyData, WaveConfig, etc)
	".png",    # Textures
	".jpg",    # Textures
	".wav",    # Audio
	".ogg",    # Audio
	".mp3",    # Audio
]

func _ready() -> void:
	print("ResourceLoadManager initialized")

## Load resource secara sinkron (blocking)
func load_resource_sync(path: String) -> Resource:
	# Cek apakah sudah ada di cache
	if loaded_resources.has(path):
		return loaded_resources[path]
	
	# Load resource
	if ResourceLoader.exists(path):
		var resource = ResourceLoader.load(path)
		if resource:
			loaded_resources[path] = resource
			return resource
		else:
			push_error("Failed to load resource: " + path)
			return null
	else:
		push_error("Resource does not exist: " + path)
		return null

## Load resource secara asinkron dengan threading
func load_resource_async(path: String, use_cache: bool = true) -> void:
	# Cek cache dulu
	if use_cache and loaded_resources.has(path):
		loading_completed.emit(path, loaded_resources[path])
		return
	
	# Cek apakah sedang loading
	if loading_status.has(path):
		return
	
	# Start loading menggunakan ResourceLoader threaded
	var status = ResourceLoader.load_threaded_request(path)
	if status == OK:
		loading_status[path] = "loading"
		_start_monitoring_async_load(path)
	else:
		push_error("Failed to start threaded load for: " + path)
		loading_failed.emit(path, "Failed to start loading")

## Monitor status loading threaded resource
func _start_monitoring_async_load(path: String) -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(func():
		_check_load_progress(path, timer)
	)
	timer.start(0.1)  # Check setiap 100ms

func _check_load_progress(path: String, timer: Timer) -> void:
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(path, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loading_failed.emit(path, "Invalid resource")
			loading_status.erase(path)
			timer.queue_free()
		
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				loading_progress_changed.emit(progress[0])
		
		ResourceLoader.THREAD_LOAD_FAILED:
			loading_failed.emit(path, "Loading failed")
			loading_status.erase(path)
			timer.queue_free()
		
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(path)
			if resource:
				loaded_resources[path] = resource
				loading_completed.emit(path, resource)
			else:
				loading_failed.emit(path, "Resource is null")
			loading_status.erase(path)
			timer.queue_free()

## Load multiple resources dengan progress tracking
func load_resources_batch(paths: Array[String], callback: Callable = Callable()) -> void:
	if paths.is_empty():
		if callback.is_valid():
			callback.call()
		return
	
	is_loading = true
	current_progress = 0.0
	var total = paths.size()
	var loaded = 0
	
	for path in paths:
		# Skip jika sudah di-load
		if loaded_resources.has(path):
			loaded += 1
			current_progress = float(loaded) / float(total)
			loading_progress_changed.emit(current_progress)
			continue
		
		# Start async load
		var status = ResourceLoader.load_threaded_request(path)
		if status != OK:
			push_error("Failed to start loading: " + path)
			loaded += 1
			continue
	
	# Monitor semua loading
	_monitor_batch_loading(paths, total, callback)

func _monitor_batch_loading(paths: Array[String], total: int, callback: Callable) -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_batch_check.bind(paths, total, callback, timer))
	timer.start(0.1)

func _on_batch_check(paths: Array[String], total: int, callback: Callable, timer: Timer) -> void:
	var all_done = true
	var loaded_count = 0
	
	for path in paths:
		# Skip jika sudah ada di cache
		if loaded_resources.has(path):
			loaded_count += 1
			continue
		
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(path, progress)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(path)
			if resource:
				loaded_resources[path] = resource
			loaded_count += 1
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			all_done = false
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loaded_count += 1
	
	# Update progress
	current_progress = float(loaded_count) / float(total)
	loading_progress_changed.emit(current_progress)
	
	# Cek apakah semua sudah selesai
	if all_done:
		is_loading = false
		all_resources_loaded.emit()
		timer.queue_free()
		if callback.is_valid():
			callback.call()

## Get loaded resource dari cache
func get_cached_resource(path: String) -> Resource:
	if loaded_resources.has(path):
		return loaded_resources[path]
	return null

## Get VFX resource by key
func get_vfx_resource(vfx_key: String) -> Resource:
	if VFX_CACHE.has(vfx_key):
		var path = VFX_CACHE[vfx_key]
		return get_cached_resource(path)
	return null

## Preload VFX resources yang umum digunakan
func preload_vfx_resources(callback: Callable = Callable()) -> void:
	var vfx_paths: Array[String] = []
	for path in VFX_CACHE.values():
		vfx_paths.append(path)
	load_resources_batch(vfx_paths, callback)

## Clear resource cache untuk menghemat memory
func clear_cache() -> void:
	loaded_resources.clear()
	loading_status.clear()
	current_progress = 0.0
	print("Resource cache cleared")

## Clear specific resource from cache
func unload_resource(path: String) -> void:
	if loaded_resources.has(path):
		loaded_resources.erase(path)
		print("Unloaded resource: ", path)

## Get loading progress
func get_progress() -> float:
	return current_progress

## Check if currently loading
func is_currently_loading() -> bool:
	return is_loading

## Check if resource type should use threaded loading
func should_use_threading(path: String) -> bool:
	var extension = path.get_extension()
	return ("." + extension) in SHOULD_THREAD_LOAD

## Preload tower data resources (TowerData .tres files)
func preload_tower_data(tower_data_paths: Array[String], callback: Callable = Callable()) -> void:
	load_resources_batch(tower_data_paths, callback)

## Preload enemy data resources (EnemyData .tres files)
func preload_enemy_data(enemy_data_paths: Array[String], callback: Callable = Callable()) -> void:
	load_resources_batch(enemy_data_paths, callback)

## Preload wave config resources (WaveConfig .tres files)
func preload_wave_configs(wave_config_paths: Array[String], callback: Callable = Callable()) -> void:
	load_resources_batch(wave_config_paths, callback)
