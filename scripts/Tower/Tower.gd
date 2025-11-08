extends Node3D

signal shot_fired

@export var projectile_scene: PackedScene
@export var detection_range: float = 10.0
@export var fire_rate: float = 1.0
@export var damage: float = 25.0
@export var projectile_speed: float = 15.0

# Upgrade stats
@export var upgrade_cost: int = 50
var upgrade_level: int = 0

var fire_timer: float = 0.0
var current_target: CharacterBody3D = null

@onready var range_area: Area3D = $RangeArea
@onready var shoot_point: Node3D = $ShootPoint

func _ready() -> void:
	if range_area:
		var collision_shape = range_area.get_node("CollisionShape3D")
		if collision_shape and collision_shape.shape is SphereShape3D:
			collision_shape.shape.radius = detection_range

func _process(delta: float) -> void:
	fire_timer += delta
	
	# Find target
	if not current_target or not is_instance_valid(current_target):
		current_target = find_nearest_enemy()
	
	# Check if target is still in range
	if current_target and global_position.distance_to(current_target.global_position) > detection_range:
		current_target = null
	
	# Shoot at target
	if current_target and fire_timer >= 1.0 / fire_rate:
		shoot(current_target)
		fire_timer = 0.0

func find_nearest_enemy() -> CharacterBody3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: CharacterBody3D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= detection_range and distance < nearest_distance:
				nearest = enemy
				nearest_distance = distance
	
	return nearest

func shoot(target: CharacterBody3D) -> void:
	if not projectile_scene:
		return
	
	var projectile = projectile_scene.instantiate()
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
