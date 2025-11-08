extends Control

enum EndState { GAME_OVER, VICTORY }

@onready var game_over_panel: Panel = $GameOverPanel
@onready var victory_panel: Panel = $VictoryPanel

@onready var go_restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton
@onready var go_menu_button: Button = $GameOverPanel/VBoxContainer/MenuButton

@onready var vstar1: TextureRect = $VictoryPanel/VBoxContainer/StarsContainer/Star1
@onready var vstar2: TextureRect = $VictoryPanel/VBoxContainer/StarsContainer/Star2
@onready var vstar3: TextureRect = $VictoryPanel/VBoxContainer/StarsContainer/Star3
@onready var vhp_label: Label = $VictoryPanel/VBoxContainer/HPLabel
@onready var vwave_label: Label = $VictoryPanel/VBoxContainer/WaveLabel
@onready var next_button: Button = $VictoryPanel/VBoxContainer/NextButton
@onready var replay_button: Button = $VictoryPanel/VBoxContainer/ReplayButton
@onready var menu_button: Button = $VictoryPanel/VBoxContainer/MenuButton

var stars_earned: int = 0
var current_state: EndState = EndState.GAME_OVER

func _ready() -> void:
	go_restart_button.pressed.connect(_on_restart_pressed)
	go_menu_button.pressed.connect(_on_menu_pressed)
	
	next_button.pressed.connect(_on_next_level_pressed)
	replay_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func show_game_over() -> void:
	current_state = EndState.GAME_OVER
	game_over_panel.visible = true
	victory_panel.visible = false

func show_victory() -> void:
	current_state = EndState.VICTORY
	game_over_panel.visible = false
	victory_panel.visible = true
	
	if GameManager.final_stars == 0:
		stars_earned = GameManager.calculate_stars()
	else:
		stars_earned = GameManager.final_stars
	
	update_stats(vhp_label, vwave_label)
	update_stars(vstar1, vstar2, vstar3)
	
	if not LevelManager.has_next_level():
		next_button.visible = false

func update_stats(hp_label: Label, wave_label: Label) -> void:
	var final_hp = 0
	var max_hp = 20
	if GameManager.base_reference:
		final_hp = GameManager.base_reference.current_hp
		max_hp = GameManager.base_reference.max_hp
	
	hp_label.text = "Base HP: " + str(final_hp) + " / " + str(max_hp)
	
	var final_wave = get_node_or_null("/root/Main/WaveManager")
	if not final_wave:
		var root = get_tree().current_scene
		if root:
			for child in root.get_children():
				if child is WaveManager:
					final_wave = child
					break
	
	if final_wave:
		wave_label.text = "Waves Completed: " + str(final_wave.current_wave)

func update_stars(star1: TextureRect, star2: TextureRect, star3: TextureRect) -> void:
	star1.modulate = Color(0.3, 0.3, 0.3, 1.0)
	star2.modulate = Color(0.3, 0.3, 0.3, 1.0)
	star3.modulate = Color(0.3, 0.3, 0.3, 1.0)
	
	star1.scale = Vector2(1.0, 1.0)
	star2.scale = Vector2(1.0, 1.0)
	star3.scale = Vector2(1.0, 1.0)
	
	if stars_earned >= 1:
		_animate_star_async(star1, 0.2)
	if stars_earned >= 2:
		_animate_star_async(star2, 0.4)
	if stars_earned >= 3:
		_animate_star_async(star3, 0.6)

func _animate_star_async(star: TextureRect, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(star, "modulate", Color(1.0, 1.0, 0.0, 1.0), 0.3)
	tween.tween_property(star, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_property(star, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)

func _on_restart_pressed() -> void:
	GameManager.reset_game_state()
	LevelManager.reload_current_level()

func _on_next_level_pressed() -> void:
	GameManager.reset_game_state()
	LevelManager.load_next_level()

func _on_menu_pressed() -> void:
	GameManager.reset_game_state()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
