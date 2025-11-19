extends Control

func _on_close_button_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
