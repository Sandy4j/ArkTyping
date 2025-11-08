extends BaseEnemy
class_name RangedEnemy

var attack_timer: float = 0.0
var current_target: Node3D = null

@onready var attack_range_area: Area3D = $AttackRangeArea

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
			collision.shape.radius = enemy_data.attack_range

func _update_logic(delta: float) -> void:
	if not enemy_data or not enemy_data.can_attack:
		return
	
	attack_timer += delta
	if not current_target or not is_instance_valid(current_target):
		current_target = find_nearest_tower()
	
	if current_target:
		var distance = global_position.distance_to(current_target.global_position)
		if distance > enemy_data.attack_range:
			current_target = null
	
	if current_target and attack_timer >= enemy_data.attack_cooldown:
		attack(current_target)
		attack_timer = 0.0

func find_nearest_tower() -> Node3D:
	var towers = get_tree().get_nodes_in_group("tower")
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
	
	# Create projectile toward tower
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
			projectile.initialize(target, enemy_data.attack_damage, enemy_data.projectile_speed)
