extends Node

func _ready() -> void:
	var scene_path = get_tree().current_scene.scene_file_path
	if scene_path != "":
		LevelManager.set_current_level(scene_path)
