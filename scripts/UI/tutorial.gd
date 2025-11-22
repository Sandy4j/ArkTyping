extends Control

@onready var tutorial_image = $TutorialImage
@onready var prev_button = $PrevButton
@onready var next_button = $NextButton
@onready var page_indicator = $PageIndicator

var current_page = 0
var total_pages = 6
var tutorial_pages = []

func _ready():
	tutorial_pages = [
		preload("res://asset/UI/Tutorial/tutorial 1.png"),
		preload("res://asset/UI/Tutorial/tutorial 2.png"),
		preload("res://asset/UI/Tutorial/tutorial 3.png"),
		preload("res://asset/UI/Tutorial/tutorial 4.png"),
		preload("res://asset/UI/Tutorial/tutorial 5.png"),
		preload("res://asset/UI/Tutorial/tutorial 6.png")
	]
	
	update_page()

func update_page():
	tutorial_image.texture = tutorial_pages[current_page]
	
	page_indicator.text = str(current_page + 1) + " / " + str(total_pages)
	
	prev_button.disabled = (current_page == 0)
	prev_button.visible = (current_page > 0)
	next_button.disabled = false

func _on_prev_button_pressed():
	if current_page > 0:
		AudioManager.play_sfx("button_click")
		current_page -= 1
		update_page()

func _on_next_button_pressed():
	AudioManager.play_sfx("button_click")
	if current_page < total_pages - 1:
		current_page += 1
		update_page()
	else:
		LevelManager.load_level_async("res://scenes/UI/main_menu.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_on_prev_button_pressed()
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_on_next_button_pressed()
		elif event.keycode == KEY_ESCAPE:
			LevelManager.load_level_async("res://scenes/UI/main_menu.tscn")
