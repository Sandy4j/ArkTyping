extends BaseEnemy
class_name RangedEnemy

var attack_timer: float = 0.0
var current_target: Node3D = null
var is_attacking: bool = false

@onready var attack_range_area: Area3D = $RadiusArea

func _on_ready() -> void:
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

func _move(delta: float) -> void:
	if is_attacking:
		# Still bob when attacking but don't move forward
		bob_timer += delta * bob_speed
		global_position.y += sin(bob_timer) * bob_height
		
		# Face the target when attacking
		if current_target and is_instance_valid(current_target):
			var direction_to_target = current_target.global_position - global_position
			if direction_to_target.x > 0.01:  # Target is to the right
				sprite.flip_h = true
			elif direction_to_target.x < -0.01:  # Target is to the left
				sprite.flip_h = false
		return
	
	path_follow.progress += enemy_data.move_speed * delta
	global_position = path_follow.global_position
	
	# Flip sprite based on movement direction (default facing left)
	var direction = global_position - previous_position
	if direction.x > 0.01:  # Moving right
		sprite.flip_h = true
	elif direction.x < -0.01:  # Moving left
		sprite.flip_h = false
	previous_position = global_position
	
	bob_timer += delta * bob_speed
	global_position.y += sin(bob_timer) * bob_height
	
	if path_follow.progress_ratio >= 1.0:
		reach_end()

func _update_logic(delta: float) -> void:
	if not enemy_data or not enemy_data.can_attack:
		return

	attack_timer += delta
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

	if current_target and attack_timer >= enemy_data.attack_cooldown:
		attack(current_target)
		attack_timer = 0.0

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

func attack(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		return

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
		AudioManager.play_sfx("enemy_hit")

		if projectile.has_method("initialize"):
			projectile.initialize(target, enemy_data.attack_damage, enemy_data.projectile_speed)
