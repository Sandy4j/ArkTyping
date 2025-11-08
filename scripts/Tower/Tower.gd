extends Node3D

signal shot_fired
signal tower_destroyed

@export var projectile_scene: PackedScene
@export var detection_range: float = 10.0
@export var fire_rate: float = 1.0
@export var damage: float = 25.0
@export var projectile_speed: float = 15.0

# Health system for tower
@export var max_hp: float = 100.0
var current_hp: float = 100.0
# Upgrade stats

@export var upgrade_cost: int = 50
var upgrade_level: int = 0

var fire_timer: float = 0.0
var current_target: Node3D = null

@onready var range_area: Area3D = $RangeArea
@onready var shoot_point: Node3D = $ShootPoint

func _ready() -> void:
	add_to_group("tower")
	current_hp = max_hp
	
	if range_area:
		var collision_shape = range_area.get_node("CollisionShape3D")
		if collision_shape and collision_shape.shape is SphereShape3D:
			collision_shape.shape.radius = detection_range

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
		
	fire_timer += delta
	
	if not current_target or not is_instance_valid(current_target):
		current_target = find_nearest_enemy()
	
	if current_target and global_position.distance_to(current_target.global_position) > detection_range:
		current_target = null
	
	if current_target and fire_timer >= 1.0 / fire_rate:
		shoot(current_target)
		fire_timer = 0.0

func find_nearest_enemy() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= detection_range and distance < nearest_distance:
				nearest = enemy
				nearest_distance = distance
	
	return nearest

func shoot(target: Node3D) -> void:
	if not projectile_scene:
		return
	
	var pool_key = "tower_projectile"
	var projectile = ObjectPool.get_pooled_object(pool_key)
	
	if not projectile:
		projectile = projectile_scene.instantiate()
	else:
		projectile.pool_name = pool_key
	
	get_tree().current_scene.add_child(projectile)
	
	if shoot_point:
		projectile.global_position = shoot_point.global_position
	else:
		projectile.global_position = global_position + Vector3.UP
	
	projectile.initialize(target, damage, projectile_speed)
	shot_fired.emit()

func upgrade() -> bool:
	if GameManager.spend_currency(upgrade_cost):
		upgrade_level += 1
		
		damage *= 1.2
		fire_rate *= 1.1
		detection_range *= 1.1
		
		if range_area:
			var collision_shape = range_area.get_node("CollisionShape3D")
			if collision_shape and collision_shape.shape is SphereShape3D:
				collision_shape.shape.radius = detection_range
		
		print("Tower upgraded to level ", upgrade_level)
		return true
	return false

func take_damage(dmg: float) -> void:
	current_hp -= dmg
	
	if current_hp <= 0:
		destroy()

func destroy() -> void:
	tower_destroyed.emit()
	print("Tower destroyed!")
	queue_free()

func get_hp_percentage() -> float:
	return current_hp / max_hp if max_hp > 0 else 0.0
