extends Control

@onready var startbtn = $CanvasLayer/ButtonContainer/StartBtn
@onready var herobtn = $CanvasLayer/ButtonContainer/HeroBtn
@onready var tutorialbtn = $CanvasLayer/ButtonContainer/TutorialBtn
@onready var creditbtn = $CanvasLayer/ButtonContainer/CreditBtn
@onready var quitbtn = $CanvasLayer/ButtonContainer/QuitBtn

func _ready() -> void:
	AudioManager.play_bgm("mainmenu")

func _on_start_btn_pressed() -> void:
	AudioManager.play_sfx("button_click")
	LevelManager.load_level_async("res://levels/level_01.tscn")

func _on_hero_btn_pressed() -> void:
	AudioManager.play_sfx("button_click")
	LevelManager.load_level_async("res://scenes/UI/hero.tscn")

func _on_credit_btn_pressed() -> void:
	AudioManager.play_sfx("button_click")
	LevelManager.load_level_async("res://scenes/UI/Credit.tscn")

func _on_tutorial_btn_pressed() -> void:
	AudioManager.play_sfx("button_click")
	LevelManager.load_level_async("res://scenes/UI/tutorial.tscn")

func _on_quit_btn_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().quit()
