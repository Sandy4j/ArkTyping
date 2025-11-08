extends Node

signal victory
signal level_completed

var current_level_path: String = ""
var available_levels: Array[String] = []
var current_level_index: int = -1

func _ready() -> void:
	scan_levels()

func scan_levels() -> void:
	available_levels.clear()
	var dir = DirAccess.open("res://levels/")
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				available_levels.append("res://levels/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		available_levels.sort()
	else:
		print("Fail")

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
		get_tree().change_scene_to_file(next_level)
	else:
		print("Level entek")

func reload_current_level() -> void:
	if current_level_path != "":
		get_tree().change_scene_to_file(current_level_path)
	else:
		get_tree().reload_current_scene()

func trigger_victory() -> void:
	victory.emit()
	print("Menang cuy")
