extends Node3D

@export var speed: float = 15.0
@export var damage: float = 25.0

var target: CharacterBody3D = null
var velocity: Vector3 = Vector3.ZERO

func initialize(new_target: CharacterBody3D, new_damage: float, new_speed: float) -> void:
	target = new_target
	damage = new_damage
	speed = new_speed

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		queue_free()
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	global_position += velocity * delta
	
	look_at(target.global_position, Vector3.UP)
	
	if global_position.distance_to(target.global_position) < 0.5:
		hit_target()

func hit_target() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
