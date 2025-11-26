extends Control

@onready var resumebtn = $Panel/VBoxContainer/resumebtn
@onready var mainmenubtn = $Panel/VBoxContainer/mainmenubtn
@onready var restarbtn = $Panel/VBoxContainer/retrybtn


func _ready() -> void:
	hide()
	resumebtn.pressed.connect(_on_resume_pressed)
	mainmenubtn.pressed.connect(_on_main_menu_pressed)
	restarbtn.pressed.connect(_on_retry_pressed)

func show_pause_menu() -> void:
	if get_tree().root.has_meta("time_stop_active") and get_tree().root.get_meta("time_stop_active"):
		return
	
	show()
	get_tree().paused = true

func hide_pause_menu() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("button_click")
	hide_pause_menu()
	
func _on_retry_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().paused = false
	GameManager.reset_game_state()
	LevelManager.reload_current_level()

func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().paused = false
	GameManager.reset_game_state()
	LevelManager.load_level_async("res://scenes/UI/main_menu.tscn")
