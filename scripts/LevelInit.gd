extends Node
class_name LevelInit

@onready var pause = $UI/Pause
@onready var wave_manager = $WaveManager

var is_level_ready: bool = false

func _ready() -> void:
	var scene_path = get_tree().current_scene.scene_file_path
	if scene_path != "":
		LevelManager.set_current_level(scene_path)
	await _preload_level_resources()
	
	AudioManager.play_bgm("gameplay")
	_setup_danger_vignette()
	
	is_level_ready = true


## Preload semua resources yang dibutuhkan level sebelum memulai gameplay
func _preload_level_resources() -> void:
	await ResourceLoadManager.preload_vfx_resources(Callable())
	
	if wave_manager and wave_manager.has_method("get_wave_configs"):
		var wave_configs = wave_manager.get_wave_configs()
		
		# Get tower datas dari UI/Input TowerInput node
		var tower_datas: Array[TowerData] = []
		var ui_node = get_node_or_null("UI")
		if ui_node:
			var tower_input = ui_node.get_node_or_null("Input")
			if tower_input and "tower_list" in tower_input:
				tower_datas = tower_input.tower_list
		
		if not wave_configs.is_empty():
			await PoolSetup.preload_level_resources_async(wave_configs, tower_datas, Callable())
	
	var vignette_path = "res://scenes/UI/Vignette.tscn"
	if ResourceLoader.exists(vignette_path):
		ResourceLoadManager.load_resource_sync(vignette_path)

func _setup_danger_vignette() -> void:
	var vignette_scene = ResourceLoadManager.get_cached_resource("res://scenes/UI/Vignette.tscn")
	if not vignette_scene:
		vignette_scene = ResourceLoadManager.load_resource_sync("res://scenes/UI/Vignette.tscn")
	if vignette_scene:
		var vignette = vignette_scene.instantiate()
		add_child(vignette)
	

func toggle_pause() -> void:
	if pause.visible:
		pause.hide_pause_menu()
	else:
		pause.show_pause_menu()
		
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == Key.KEY_ESCAPE:
			toggle_pause()

				
