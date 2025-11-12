extends Control

@onready var resumebtn = $Panel/VBoxContainer/resumebtn
@onready var mainmenubtn = $Panel/VBoxContainer/mainmenubtn

func _ready() -> void:
	# Hide the pause menu initially
	hide()
	# Connect button signals
	resumebtn.pressed.connect(_on_resume_pressed)
	mainmenubtn.pressed.connect(_on_main_menu_pressed)

func show_pause_menu() -> void:
	show()
	get_tree().paused = true

func hide_pause_menu() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	hide_pause_menu()

func _on_main_menu_pressed() -> void:
	# Unpause before changing scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
