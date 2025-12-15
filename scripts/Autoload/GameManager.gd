extends Node

signal game_over(stars: int)
signal currency_changed(new_amount: int)
signal base_hp_changed(new_hp: int)

@export var starting_currency: int = 15
@export var currency_regen_amount: int = 1
@export var currency_regen_interval: float = 2.0

var cap_currency: int = 10
var currency: int = 0
var is_game_over: bool = false
var final_stars: int = 0
var base_reference: Node3D = null
var regen_timer: float = 0.0

func _ready() -> void:
	currency = starting_currency
	call_deferred("_emit_initial_currency")

func _process(delta: float) -> void:
	if is_game_over:
		return
	
	regen_timer += delta
	if regen_timer >= currency_regen_interval and currency < cap_currency:
		add_currency(currency_regen_amount)
		regen_timer = 0.0

func _emit_initial_currency() -> void:
	currency_changed.emit(currency)

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		currency_changed.emit(currency)
		return true
	return false

func set_base(base_node: Node3D) -> void:
	base_reference = base_node
	if base_reference and base_reference.has_signal("hp_changed"):
		base_reference.hp_changed.connect(_on_base_hp_changed)
		call_deferred("_emit_initial_base_hp")

func _on_base_hp_changed(current: int, _maximum: int) -> void:
	base_hp_changed.emit(current)

func _emit_initial_base_hp() -> void:
	if base_reference:
		base_hp_changed.emit(base_reference.current_hp)

func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	final_stars = calculate_stars()
	game_over.emit(final_stars)
	print("Game Over! Stars: ", final_stars)

func calculate_stars() -> int:
	if not base_reference:
		return 0

	var current_hp = base_reference.current_hp
	var max_hp = base_reference.max_hp
	var hp_percentage: float = float(current_hp) / float(max_hp)

	if hp_percentage >= 0.7:
		return 3
	elif hp_percentage >= 0.4:
		return 2
	elif hp_percentage > 0:
		return 1
	else:
		return 0

func reset_game_state() -> void:
	is_game_over = false
	final_stars = 0
	base_reference = null
	currency = starting_currency
	regen_timer = 0.0
	currency_changed.emit(currency)
	
	cleanup_timestop_effects()

func cleanup_timestop_effects() -> void:
	if not get_tree() or not get_tree().root:
		return
	
	# Force end timestop on all BossVoid instances
	var boss_voids = get_tree().get_nodes_in_group("enemies")
	for enemy in boss_voids:
		if is_instance_valid(enemy) and enemy.has_method("end_time_stop"):
			if enemy.get("is_time_stopped"):
				enemy.end_time_stop()
	
	# Clean up overlay
	var overlays = get_tree().root.get_children()
	for child in overlays:
		if is_instance_valid(child) and child is CanvasLayer and child.name == "TimeStopOverlay":
			child.queue_free()
	
	# Reset timestop meta flag
	get_tree().root.set_meta("time_stop_active", false)
	
	# unfreeze all entities
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			enemy.set_process(true)
			enemy.set_physics_process(true)
			enemy.set_process_input(true)
	
	var all_towers = get_tree().get_nodes_in_group("towers")
	for tower in all_towers:
		if is_instance_valid(tower):
			if tower.has_method("set"):
				tower.set("got_binded", false)
			tower.process_mode = Node.PROCESS_MODE_INHERIT
			tower.set_process(true)
			tower.set_physics_process(true)
			tower.set_process_input(true)
	
	var all_projectiles = get_tree().get_nodes_in_group("projectiles")
	for projectile in all_projectiles:
		if is_instance_valid(projectile):
			projectile.process_mode = Node.PROCESS_MODE_INHERIT
			projectile.set_process(true)
			projectile.set_physics_process(true)
	
	# Resume BGM if paused
	if AudioManager and AudioManager.bgm_player:
		AudioManager.bgm_player.stream_paused = false

func set_tower_state(data: TowerData, v: bool):
	data.available = v
