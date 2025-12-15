extends CharacterBody3D
class_name BaseEnemy

## Base class untuk semua enemy

signal died(reward: int)
signal reached_end(damage: int)
signal hp_changed(current: float, maximum: float)

@export var enemy_data: EnemyData
@export var bob_height: float = 0.1
@export var bob_speed: float = 2.0

var bob_timer: float = 0.0
var current_hp: float = 0.0
var path_to_follow: Path3D = null
var path_follow: PathFollow3D = null
var pool_name: String = ""  # tracking asal pool
var move_speed
var previous_position: Vector3 = Vector3.ZERO
var speed_buffs: Dictionary = {}
var original_move_speed: float = 0.0
var is_alive: bool = true

@onready var sprite: AnimatedSprite3D = $Anim


func _ready() -> void:
	move_speed = enemy_data.move_speed
	original_move_speed = enemy_data.move_speed
	is_alive = true
	sprite.play("default")
	if not enemy_data:
		push_error("Enemy has no data assigned!")
		queue_free()
		return
	
	current_hp = enemy_data.max_hp
	add_to_group("enemies")
	
	_setup_path()
	previous_position = global_position
	_on_ready()

func _on_ready() -> void:
	pass

func _setup_visual() -> void:
	if enemy_data:
		current_hp = enemy_data.max_hp
	add_to_group("enemies")

func _setup_path() -> void:
	if path_to_follow:
		path_follow = PathFollow3D.new()
		path_to_follow.add_child(path_follow)
		path_follow.loop = false

func _process(delta: float) -> void:
	if not path_follow or not enemy_data:
		return
	
	_move(delta)
	_update_logic(delta)

func _move(delta: float) -> void:
	path_follow.progress += move_speed * delta
	var base_y = path_follow.global_position.y
	bob_timer += delta * bob_speed
	
	# Apply position with bobbing
	global_position.x = path_follow.global_position.x
	global_position.y = base_y + sin(bob_timer) * bob_height
	global_position.z = path_follow.global_position.z
	
	# Flip sprite based on movement direction (default facing left)
	var direction = global_position - previous_position
	if direction.x > 0.01:  # Moving right
		sprite.flip_h = true
	elif direction.x < -0.01:  # Moving left
		sprite.flip_h = false
	previous_position = global_position
	
	if path_follow.progress_ratio >= 1.0:
		reach_end()

func _update_logic(delta: float) -> void:
	pass

## Cached hit VFX scene - loaded once
static var _hit_vfx_scene: PackedScene = null

func take_damage(damage: float) -> void:
	if not is_alive:
		return
	
	current_hp -= damage
	hp_changed.emit(current_hp, enemy_data.max_hp)
	
	# Flash effect without await to prevent issues when pooled
	_flash_damage()
	
	# Spawn hit VFX using cached scene
	_spawn_hit_vfx()
	
	if current_hp <= 0:
		die()

func _flash_damage() -> void:
	sprite.modulate = Color(1, 0, 0)
	# Use tween instead of await to avoid issues if enemy is pooled
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

func _spawn_hit_vfx() -> void:
	# Cache the scene on first use
	if _hit_vfx_scene == null:
		_hit_vfx_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/hit.tscn")
	
	if _hit_vfx_scene:
		var vfx_nd = _hit_vfx_scene.instantiate()
		var gpu: GPUParticles3D = vfx_nd.get_child(0)
		gpu.finished.connect(_on_hit_vfx_finished.bind(vfx_nd))
		self.add_child(vfx_nd)

func _on_hit_vfx_finished(vfx_node: Node) -> void:
	if is_instance_valid(vfx_node):
		vfx_node.queue_free()

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	died.emit(enemy_data.reward)
	AudioManager.play_sfx("enemy_die")
	sprite.play("die")
	
	# Use tween instead of await to prevent pool issues
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(_complete_death)

func _on_death() -> void:
	pass

func _complete_death() -> void:
	_on_death()
	return_to_pool()

func reach_end() -> void:
	reached_end.emit(enemy_data.base_damage)
	return_to_pool()

func return_to_pool() -> void:
	# Kill any active tweens to prevent callbacks after pooling
	var tweens = get_tree().get_processed_tweens()
	for tween in tweens:
		if tween.is_valid() and tween.get_meta("owner", null) == self:
			tween.kill()
	
	remove_from_group("enemies")
	bob_timer = 0.0
	is_alive = false
	speed_buffs.clear()
	move_speed = original_move_speed

	# Reset sprite animation and modulate
	sprite.play("default")
	sprite.modulate = Color(1, 1, 1)
	
	# Clean up any VFX children before returning to pool
	for child in get_children():
		if child.name.contains("hit") or child.name.contains("vfx") or child is GPUParticles3D:
			child.queue_free()
	
	# Disconnect all signals before returning to pool
	for connection in died.get_connections():
		died.disconnect(connection.callable)
	
	for connection in reached_end.get_connections():
		reached_end.disconnect(connection.callable)
	
	for connection in hp_changed.get_connections():
		hp_changed.disconnect(connection.callable)
	
	current_hp = enemy_data.max_hp if enemy_data else 0.0
	
	if path_follow:
		path_follow.queue_free()
		path_follow = null
	
	path_to_follow = null
	if pool_name != "" and ObjectPool.pools.has(pool_name):
		ObjectPool.return_pooled_object(pool_name, self)
	else:
		queue_free()

## Speed buff system untuk boss Herald
func apply_speed_buff(multiplier: float, source: Node):
	speed_buffs[source] = multiplier
	_recalculate_move_speed()
	print("[Enemy] Speed buff applied: ", multiplier, "x from ", source.name)

func remove_speed_buff(source: Node):
	if source in speed_buffs:
		speed_buffs.erase(source)
		_recalculate_move_speed()
		print("[Enemy] Speed buff removed from ", source.name)

func _recalculate_move_speed():
	if speed_buffs.is_empty():
		move_speed = original_move_speed
	else:
		var max_multiplier = 1.0
		for multiplier in speed_buffs.values():
			max_multiplier = max(max_multiplier, multiplier)
		move_speed = original_move_speed * max_multiplier

func get_hp_percentage() -> float:
	if enemy_data and enemy_data.max_hp > 0:
		return current_hp / enemy_data.max_hp
	return 0.0
