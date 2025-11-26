extends Control

## LevelSelection - UI untuk memilih level yang akan dimainkan

@onready var level_container = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LevelContainer
@onready var back_button = $CanvasLayer/BackButton

const LEVEL_BUTTON_SCENE = preload("res://scenes/UI/LevelButton.tscn")

var level_buttons: Array = []

func _ready() -> void:
	AudioManager.play_bgm("mainmenu")
	_setup_level_buttons()
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

## Setup semua tombol level berdasarkan available levels
func _setup_level_buttons() -> void:
	if not level_container:
		push_error("[LevelSelection] Level container not found!")
		return
	
	# Clear existing buttons
	for child in level_container.get_children():
		child.queue_free()
	level_buttons.clear()
	
	# Create button untuk setiap level
	var available_levels = LevelManager.available_levels
	for i in range(available_levels.size()):
		var level_number = i + 1
		var level_path = available_levels[i]
		
		var button = LEVEL_BUTTON_SCENE.instantiate()
		level_container.add_child(button)
		level_buttons.append(button)
		
		# Setup button
		if button.has_method("setup"):
			var is_unlocked = SaveManager.is_level_unlocked(level_number)
			var stars = SaveManager.get_level_stars(level_number)
			var is_completed = SaveManager.is_level_completed(level_number)
			
			button.setup(level_number, level_path, is_unlocked, stars, is_completed)
			button.level_selected.connect(_on_level_selected)

## Handle level selection
func _on_level_selected(level_path: String) -> void:
	AudioManager.play_sfx("button_click")
	LevelManager.load_level_async(level_path)

## Handle back button
func _on_back_button_pressed() -> void:
	AudioManager.play_sfx("button_click")
	LevelManager.load_level_async("res://scenes/UI/main_menu.tscn")
