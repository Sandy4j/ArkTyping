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
	
	if not attack_range_area:
		attack_range_area = Area3D.new()
		add_child(attack_range_area)

		var collision = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = enemy_data.attack_range
		collision.shape = shape
		attack_range_area.add_child(collision)
	else:
		var collision = attack_range_area.get_node_or_null("CollisionShape3D")
		if collision and collision.shape is SphereShape3D:
			var sphere_shape = collision.shape as SphereShape3D
			sphere_shape.radius = enemy_data.attack_range

func _on_body_entered_range(body: Node3D):
	if body.is_in_group("tower") and not is_attacking:
		current_target = body
		is_attacking = true

func _on_body_exited_range(body: Node3D):
	if body == current_target:
		current_target = null
		is_attacking = false

func _update_logic(delta: float):
	if not enemy_data or not enemy_data.can_attack:
		return
	
	if is_attacking and current_target and is_instance_valid(current_target):
		attack_timer -= delta
		if attack_timer <= 0:
			_perform_attack()
			attack_timer = enemy_data.attack_cooldown
	else:
		is_attacking = false
		current_target = null

func _perform_attack():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Spawn projectile
	var projectile_scene = load("res://scenes/Enemy/ProjectileE.tscn")
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = global_position
	projectile.initialize(current_target, enemy_data.attack_damage, enemy_data.projectile_speed)

func _move(delta: float):
	if is_attacking:
		# Bob when attacking but don't move forward
		bob_timer += delta * bob_speed
		global_position.y += sin(bob_timer) * bob_height
		
		# Face target
		if current_target and is_instance_valid(current_target):
			var direction_to_target = current_target.global_position - global_position
			if direction_to_target.x > 0.01:
				sprite.flip_h = true
			elif direction_to_target.x < -0.01:
				sprite.flip_h = false
		return
	
	super._move(delta)

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
	super.die()
