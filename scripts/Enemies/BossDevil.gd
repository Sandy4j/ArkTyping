extends BossEnemy
class_name BossDevil

## Boss Devil - Bind random towers (1-3)

@export var min_targets: int = 1
@export var max_targets: int = 3
@export var bind_word_pool: Array[String] = ["CURSE", "BIND", "CHAIN", "SEAL", "LOCK"]
@onready var attack_range_area: Area3D = $RadiusArea

var bound_towers: Array[Node] = []
var attack_timer: float = 0.0
var current_target: Node3D = null
var is_attacking: bool = false


func _ready():
	super._ready()
	add_to_group("boss_devil")
	ability_cooldown = randf_range(1, 3)
	setup_ability_timer()
	_setup_attack_range()

func _setup_attack_range():
	if not enemy_data or not enemy_data.can_attack:
		return

func _update_logic(delta: float):
	if not enemy_data or not enemy_data.can_attack or not is_alive:
		return

	if not current_target or not is_instance_valid(current_target):
		current_target = find_nearest_tower()
		is_attacking = false
	
	if current_target:
		var distance = global_position.distance_to(current_target.global_position)
		if distance > enemy_data.attack_range:
			current_target = null
			is_attacking = false
		else:
			is_attacking = true
	
	if is_attacking and current_target and is_instance_valid(current_target):
		attack_timer -= delta
		if attack_timer <= 0:
			_perform_attack()
			attack_timer = enemy_data.attack_cooldown

func find_nearest_tower() -> Node3D:
	if not get_tree():
		return null
	
	var towers = get_tree().get_nodes_in_group("tower")
	if towers.is_empty():
		return null
	
	var nearest: Node3D = null
	var nearest_distance: float = INF
	
	for tower in towers:
		if is_instance_valid(tower):
			var distance = global_position.distance_to(tower.global_position)
			if distance <= enemy_data.attack_range and distance < nearest_distance:
				nearest = tower
				nearest_distance = distance
	return nearest

func _perform_attack():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Use ObjectPool for projectile
	var projectile_scene = preload("res://scenes/Enemy/ProjectileE.tscn")
	if projectile_scene:
		var pool_key = "enemy_projectile"
		var projectile = ObjectPool.get_pooled_object(pool_key)

		if not projectile:
			projectile = projectile_scene.instantiate()
		else:
			projectile.pool_name = pool_key

		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + Vector3.UP * 0.5

		if projectile.has_method("initialize"):
			projectile.initialize(current_target, enemy_data.attack_damage, enemy_data.projectile_speed)

func activate_ability():
	if not is_alive or not is_instance_valid(self):
		return
		
	# Get all towers in the scene
	var towers = get_tree().get_nodes_in_group("tower")
	if towers.is_empty():
		return
	
	# Select random number of targets
	var target_count = randi_range(min_targets, max_targets)
	target_count = min(target_count, towers.size())
	
	towers.shuffle()
	bound_towers.clear()
	
	for i in range(target_count):
		var tower = towers[i]
		if tower.has_method("apply_bind_debuff"):
			var bind_word = bind_word_pool[randi() % bind_word_pool.size()]
			tower.apply_bind_debuff(bind_word)
			bound_towers.append(tower)
			AudioManager.play_sfx("boss_silence")
			print("[BossDevil] Bound tower: ", tower.name, " with word: ", bind_word)
	
	ability_active = true
	ability_activated.emit("bind")
	
	ability_timer.start(randf_range(15.0, 30.0))

## Cleanse dilakukan per tower yang terkena bind
func should_cleanse_ability() -> bool:
	return false

func cleanse_ability():
	pass

func _on_tower_cleansed(tower: Node):
	if tower in bound_towers:
		bound_towers.erase(tower)
		
		if bound_towers.is_empty():
			ability_active = false
			ability_cleansed.emit("bind")

func die():
	for tower in bound_towers:
		if is_instance_valid(tower) and tower.has_method("remove_bind_debuff"):
			tower.remove_bind_debuff()
	bound_towers.clear()
	
	current_target = null
	is_attacking = false
	
	super.die()

