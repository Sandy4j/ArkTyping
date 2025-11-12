extends CanvasLayer

@onready var hp_label: Label = $HP/Health_Con/Cur
@onready var hp_max_label: Label = $HP/Health_Con/Max
@onready var currency_label: Label = $TextureProgressBar/Label
@onready var wave_label: Label = $Wave/Wave_Con/Cur
@onready var wave_max_label: Label = $Wave/Wave_Con/Max
@onready var enemy_label: Label = $Enemy/Wave_Con/Cur
@onready var enemy_max_label: Label = $Enemy/Wave_Con/Max
@onready var wavesystem = $"../WaveManager"
@onready var message: Label = $Label
@onready var NPR: NinePatchRect = $NinePatchRect
@onready var input: TowerInput = $Input
@onready var icon_con: HBoxContainer = $NinePatchRect/MarginContainer/HBoxContainer
@onready var winlose = $WinLose

func _ready() -> void:
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	GameManager.game_over.connect(_on_game_over)
	LevelManager.victory.connect(_on_victory)
	wavesystem.wave_started.connect(_on_wave_started)
	message.visible = false
	NPR.size = Vector2((145 * input.tower_list.size()),169)
	for tower in input.tower_list:
		var icon_rect = TextureRect.new()
		icon_rect.texture = tower.slot
		icon_con.add_child(icon_rect)
	
	if wavesystem:
		wave_max_label.text = str(wavesystem.get_max_waves())
	
	call_deferred("_set_max_hp")

func _set_max_hp() -> void:
	var base = get_tree().current_scene.get_node_or_null("Base")
	if base and "max_hp" in base:
		hp_max_label.text = str(base.max_hp)

func _process(_delta: float) -> void:
	if wavesystem and wavesystem.spawn_manager:
		var enemy_count = wavesystem.spawn_manager.get_active_enemy_count()
		enemy_label.text = str(enemy_count)

func _on_currency_changed(amount: int) -> void:
	currency_label.text = str(amount)

func _on_base_hp_changed(hp: int) -> void:
	hp_label.text = str(hp)

func _on_wave_started(wave: int) -> void:
	wave_label.text = str(wave)
	
	if wavesystem and wavesystem.current_wave_config:
		var max_enemies = 0
		for spawn_config in wavesystem.current_wave_config.spawn_point_configs:
			if spawn_config:
				max_enemies += spawn_config.enemies_to_spawn
				if spawn_config.has_boss:
					max_enemies += 1
		enemy_max_label.text = str(max_enemies)

func _on_game_over(stars: int) -> void:
	if winlose:
		winlose.show_game_over()

func _on_victory() -> void:
	await get_tree().create_timer(1.0).timeout
	if winlose:
		winlose.show_victory()


func _on_tower_gone(data:TowerData) -> void:
	var v = 0
	var tmp = -1
	for tower in input.tower_list:
		tmp += 1
		if data == tower:
			v = tmp
	var target:TextureRect = icon_con.get_child(v)
	target.self_modulate = Color(0.5,0.5,0.5)
	var CD = Label.new()
	target.add_child(CD)
	CD.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CD.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var cus_fnt = load("res://asset/UI_Gameplay/effortless.ttf")
	CD.anchor_bottom = 1
	CD.anchor_right = 1
	CD.add_theme_font_override("font", cus_fnt)
	CD.add_theme_color_override("font_color", Color.WHITE)
	CD.add_theme_font_size_override("font_size", 35)
	
	start_countdown(data, target, CD)

func start_countdown(data:TowerData, target: TextureRect, countdown_label: Label):
	var countdown_time: int = 10  # 10 detik
	var current_time: int = countdown_time
	
	while current_time > 0:
		countdown_label.text = str(ceil(current_time))  
		await get_tree().create_timer(1.0).timeout 
		current_time -= 1.0
	
	countdown_finished(data, target, countdown_label)

func countdown_finished(data:TowerData, target: TextureRect, countdown_label: Label):
	target.self_modulate = Color(1.0, 1.0, 1.0)
	GameManager.set_tower_state(data,true)
	countdown_label.queue_free()
	
	print("Countdown finished for tower ", data.chara)

func show_message(v:String):
	message.text = v
	message.visible = true
	await get_tree().create_timer(2).timeout
	message.visible = false
