extends Node

signal victory
signal level_completed
signal level_loading_started(level_path: String)
signal level_loading_progress(progress: float)
signal level_loading_completed(level_path: String)

var current_level_path: String = ""
var available_levels: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn"
]
var current_level_index: int = -1
var loading_screen: CanvasLayer = null
var is_loading: bool = false
var fake_progress: float = 0.0
var real_progress: float = 0.0
var is_scene_loaded: bool = false

func _ready() -> void:
	# Load loading screen scene
	var loading_scene = load("res://scenes/UI/LoadingScreen.tscn")
	if loading_scene:
		loading_screen = loading_scene.instantiate()
		add_child(loading_screen)
	else:
		push_error("Failed to load LoadingScreen.tscn")

func _process(_delta: float) -> void:
	# Update loading screen dengan progress
	if is_loading and loading_screen and loading_screen.has_method("update_progress"):
		var display_progress = max(fake_progress, real_progress)
		loading_screen.update_progress(display_progress)

func set_current_level(level_path: String) -> void:
	current_level_path = level_path
	current_level_index = available_levels.find(level_path)

func get_next_level() -> String:
	if current_level_index >= 0 and current_level_index < available_levels.size() - 1:
		return available_levels[current_level_index + 1]
	return ""

func has_next_level() -> bool:
	return get_next_level() != ""

func load_next_level() -> void:
	var next_level = get_next_level()
	if next_level != "":
		load_level_async(next_level)
	else:
		load_level_async("res://scenes/UI/main_menu.tscn")

func reload_current_level() -> void:
	if current_level_path != "":
		load_level_async(current_level_path)
	else:
		get_tree().reload_current_scene()

func trigger_victory() -> void:
	if GameManager.is_game_over:
		return
	victory.emit()
	print("Menang cuy")

## Check if scene is a gameplay level (needs full loading screen)
func is_gameplay_level(scene_path: String) -> bool:
	return scene_path.contains("/levels/level_")

## Load level dengan threaded loading dan loading screen
func load_level_async(level_path: String) -> void:
	if is_loading:
		return
	
	var is_level = is_gameplay_level(level_path)
	
	if is_level:
		is_loading = true
		fake_progress = 0.0
		real_progress = 0.0
		is_scene_loaded = false
		level_loading_started.emit(level_path)
		
		if loading_screen and loading_screen.has_method("show_loading"):
			loading_screen.show_loading(level_path)
		else:
			push_error("[LevelManager] Loading screen not available!")
		
		_animate_fake_progress()
		
		var status = ResourceLoader.load_threaded_request(level_path)
		if status == OK:
			_monitor_level_loading(level_path)
		else:
			push_error("[LevelManager] Failed to start loading level: " + level_path)
			is_loading = false
			if loading_screen and loading_screen.has_method("hide_loading"):
				loading_screen.hide_loading()
	else:
		#jika bukan level gameplay, gunakan simple fade transition
		_simple_fade_transition(level_path)

func _animate_fake_progress() -> void:
	var tween = create_tween()
	tween.tween_property(self, "fake_progress", 0.9, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if is_scene_loaded:
			_complete_progress()
	)

func _monitor_level_loading(level_path: String) -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_level_load_check.bind(level_path, timer))
	timer.start(0.05)  # cek setiap 0.05 detik

func _on_level_load_check(level_path: String, timer: Timer) -> void:
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(level_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# Update progress dari ResourceLoader
		if progress.size() > 0:
			real_progress = progress[0]
			var display_progress = max(fake_progress, real_progress)
			
			level_loading_progress.emit(display_progress)
	
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene_resource = ResourceLoader.load_threaded_get(level_path)
		timer.queue_free()
		
		if scene_resource:
			is_scene_loaded = true
			real_progress = 1.0
			
			# tunggu sampai fake progress mencapai 90%
			if fake_progress < 0.9:
				await get_tree().create_timer(0.5).timeout
			
			await _complete_progress()
			
			# tunggu sebentar sebelum ganti scene
			await get_tree().create_timer(0.1).timeout
			
			level_loading_completed.emit(level_path)
			is_loading = false
			get_tree().change_scene_to_packed(scene_resource)
			
			await get_tree().process_frame
			await get_tree().process_frame
			
			# Sembunyikan loading screen
			if loading_screen and loading_screen.has_method("hide_loading"):
				loading_screen.hide_loading()
		else:
			push_error("[LevelManager] Failed to get loaded scene resource")
			is_loading = false
			if loading_screen and loading_screen.has_method("hide_loading"):
				loading_screen.hide_loading()
	
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_error("[LevelManager] Failed to load level: " + level_path + " (status: " + str(status) + ")")
		is_loading = false
		if loading_screen and loading_screen.has_method("hide_loading"):
			loading_screen.hide_loading()
		timer.queue_free()

func _complete_progress() -> void:
	var tween = create_tween()
	tween.tween_property(self, "fake_progress", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func preload_level(level_path: String) -> void:
	if not ResourceLoader.has_cached(level_path):
		ResourceLoader.load_threaded_request(level_path)

## Simple fade transition untuk non-gameplay scenes
func _simple_fade_transition(scene_path: String) -> void:
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(fade)
	
	# Fade out (to black)
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	get_tree().change_scene_to_file(scene_path)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade in (from black)
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	# Cleanup
	canvas.queue_free()
