extends Control

func _on_close_button_pressed() -> void:
	AudioManager.play_sfx("button_click")
	LevelManager.load_level_async("res://scenes/UI/main_menu.tscn")
