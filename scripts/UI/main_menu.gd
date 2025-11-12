extends Control

@onready var startbtn = $CanvasLayer/ButtonContainer/StartBtn
@onready var herobtn = $CanvasLayer/ButtonContainer/HeroBtn
@onready var tutorialbtn = $CanvasLayer/ButtonContainer/TutorialBtn
@onready var creditbtn = $CanvasLayer/ButtonContainer/CreditBtn
@onready var quitbtn = $CanvasLayer/ButtonContainer/QuitBtn

func _ready() -> void:
	AudioManager.play_bgm("mainmenu")

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_01.tscn")

func _on_hero_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/hero.tscn")

func _on_credit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/Credit.tscn")

func _on_tutorial_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/tutorial.tscn")

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
