extends Node3D

var target: Node3D = null
var damage: float = 10.0
var speed: float = 10.0
var pool_name: String = ""  # tracking asal pool

func initialize(target_node: Node3D, proj_damage: float, proj_speed: float) -> void:
	target = target_node
	damage = proj_damage
	speed = proj_speed

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
		
	if not target or not is_instance_valid(target):
		return_to_pool()
		return
	
	# Check if target is in the "enemies" group (not pooled)
	if not target.is_in_group("enemies"):
		return_to_pool()
		return
	
	var direction = (target.global_position - global_position).normalized()
	var angle = atan2(direction.z, direction.x)
	self.rotation.y = angle + deg_to_rad(180)
	global_position += direction * speed * delta
	
	if global_position.distance_to(target.global_position) < 0.5:
		hit_target()

func hit_target() -> void:
	if target and is_instance_valid(target) and target.is_in_group("enemies") and target.has_method("take_damage"):
		target.take_damage(damage)
	return_to_pool()

func return_to_pool() -> void:
	# Reset properties first
	target = null
	damage = 10.0
	speed = 10.0
	
	# Remove from tree before returning to pool
	if is_inside_tree():
		get_parent().remove_child(self)
	
	if pool_name != "" and ObjectPool.pools.has(pool_name):
		ObjectPool.return_pooled_object(pool_name, self)
	else:
		queue_free()
