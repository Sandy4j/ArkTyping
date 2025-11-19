extends Node
class_name LevelInit

@onready var pause = $UI/Pause

func _ready() -> void:
	var scene_path = get_tree().current_scene.scene_file_path
	if scene_path != "":
		LevelManager.set_current_level(scene_path)
	
	AudioManager.play_bgm("gameplay")
	_setup_danger_vignette()

func _setup_danger_vignette() -> void:
	var vignette_scene = load("res://scenes/UI/Vignette.tscn")
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
				
