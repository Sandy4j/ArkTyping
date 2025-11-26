extends Control

enum EndState { GAME_OVER, VICTORY }

@onready var game_over_panel: Panel = $GameOverPanel
@onready var victory_panel: Panel = $VictoryPanel

@onready var go_title: Label = $GameOverPanel/VBoxContainer/TitleLabel
@onready var go_restart_button: TextureButton = $GameOverPanel/VBoxContainer/BtnContainer/RetryBtn
@onready var go_menu_button: TextureButton = $GameOverPanel/VBoxContainer/BtnContainer/MenuBtn

@onready var vtitle: Label = $VictoryPanel/VBoxContainer/TitleLabel
@onready var vstar1: TextureRect = $VictoryPanel/VBoxContainer/StarsContainer/Star1
@onready var vstar2: TextureRect = $VictoryPanel/VBoxContainer/StarsContainer/Star2
@onready var vstar3: TextureRect = $VictoryPanel/VBoxContainer/StarsContainer/Star3
@onready var vhp_label: Label = $VictoryPanel/VBoxContainer/HPLabel
@onready var vwave_label: Label = $VictoryPanel/VBoxContainer/WaveLabel
@onready var next_button: TextureButton = $VictoryPanel/VBoxContainer/HBoxContainer/Next
@onready var replay_button: TextureButton = $VictoryPanel/VBoxContainer/HBoxContainer/ReplayBtn
@onready var menu_button: TextureButton = $VictoryPanel/VBoxContainer/HBoxContainer/MenuBtn

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
	get_tree().paused = true
	
	_animate_game_over()

func show_victory() -> void:
	current_state = EndState.VICTORY
	game_over_panel.visible = false
	victory_panel.visible = true
	get_tree().paused = true
	
	if GameManager.final_stars == 0:
		stars_earned = GameManager.calculate_stars()
	else:
		stars_earned = GameManager.final_stars
	
	update_stats(vhp_label, vwave_label)
	
	# Save progress setelah menang
	_save_level_completion()
	
	if LevelManager.has_next_level():
		next_button.visible = true
	else:
		next_button.visible = false
	
	_animate_victory()

func _save_level_completion() -> void:
	# Dapatkan level number dari current level path
	var level_number = _get_level_number_from_path(LevelManager.current_level_path)
	if level_number > 0:
		SaveManager.complete_level(level_number, stars_earned)
		print("[WinLose] Level ", level_number, " completed with ", stars_earned, " stars")

func _get_level_number_from_path(path: String) -> int:
	# Extract level number dari path seperti "res://levels/level_01.tscn"
	if path.contains("level_"):
		var parts = path.split("level_")
		if parts.size() > 1:
			var num_str = parts[1].replace(".tscn", "")
			return int(num_str)
	return 0

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
	# Reset stars to dark
	star1.modulate = Color(0.3, 0.3, 0.3, 0.0)
	star2.modulate = Color(0.3, 0.3, 0.3, 0.0)
	star3.modulate = Color(0.3, 0.3, 0.3, 0.0)
	
	star1.scale = Vector2(1.0, 1.0)
	star2.scale = Vector2(1.0, 1.0)
	star3.scale = Vector2(1.0, 1.0)
	
	# Animate stars based on earned stars
	if stars_earned >= 1:
		_animate_star_appear(star1, 0.0)
	if stars_earned >= 2:
		_animate_star_appear(star2, 0.2)
	if stars_earned >= 3:
		_animate_star_appear(star3, 0.4)

func _animate_star_appear(star: TextureRect, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	
	var original_pos = star.position
	
	# Fade in and move from bottom
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(star, "modulate", Color(1.0, 1.0, 0.0, 1.0), 0.3)
	tween.tween_property(star, "position:y", original_pos.y, 0.3).from(original_pos.y + 50).set_trans(Tween.TRANS_BACK)
	tween.tween_property(star, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_property(star, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().paused = false
	GameManager.reset_game_state()
	LevelManager.load_level_async(LevelManager.current_level_path)

func _on_next_level_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().paused = false
	GameManager.reset_game_state()
	LevelManager.load_next_level()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().paused = false
	GameManager.reset_game_state()
	LevelManager.load_level_async("res://scenes/UI/main_menu.tscn")

func _animate_victory() -> void:
	vtitle.modulate.a = 0
	vtitle.scale = Vector2(0.5, 0.5)
	
	vstar1.modulate.a = 0
	vstar1.position.y = 50
	vstar2.modulate.a = 0
	vstar2.position.y = 50
	vstar3.modulate.a = 0
	vstar3.position.y = 50
	
	vhp_label.modulate.a = 0
	vhp_label.position.y = 30
	vwave_label.modulate.a = 0
	vwave_label.position.y = 30
	
	next_button.modulate.a = 0
	next_button.position.y = 50
	replay_button.modulate.a = 0
	replay_button.position.y = 50
	menu_button.modulate.a = 0
	menu_button.position.y = 50
	
	# Start animation sequence
	_animate_victory_sequence()

func _animate_victory_sequence() -> void:
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(vtitle, "modulate:a", 1.0, 0.3)
	title_tween.tween_property(vtitle, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_tween.chain().tween_property(vtitle, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	await title_tween.finished
	
	await _animate_element_from_bottom(vhp_label, 0.0)
	await _animate_element_from_bottom(vwave_label, 0.1)
	
	update_stars(vstar1, vstar2, vstar3)
	
	await get_tree().create_timer(1.0).timeout
	
	await _animate_element_from_bottom(next_button, 0.0)
	await _animate_element_from_bottom(replay_button, 0.1)
	await _animate_element_from_bottom(menu_button, 0.2)

func _animate_game_over() -> void:
	go_title.modulate.a = 0
	go_title.scale = Vector2(0.5, 0.5)
	
	go_restart_button.modulate.a = 0
	go_restart_button.position.y = 50
	go_menu_button.modulate.a = 0
	go_menu_button.position.y = 50
	
	_animate_game_over_sequence()

func _animate_game_over_sequence() -> void:
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(go_title, "modulate:a", 1.0, 0.3)
	title_tween.tween_property(go_title, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_tween.chain().tween_property(go_title, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	await title_tween.finished
	
	await get_tree().create_timer(0.3).timeout
	await _animate_element_from_bottom(go_restart_button, 0.0)
	await _animate_element_from_bottom(go_menu_button, 0.1)

func _animate_element_from_bottom(element: Control, delay: float) -> void:
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	var original_pos = element.position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(element, "modulate:a", 1.0, 0.3)
	tween.tween_property(element, "position:y", original_pos.y, 0.4).from(original_pos.y + 50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
