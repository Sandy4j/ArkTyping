extends CharacterBody3D
class_name BaseEnemy

## Base class untuk semua enemy

signal died(reward: int)
signal reached_end(damage: int)
signal hp_changed(current: float, maximum: float)

@export var enemy_data: EnemyData
@export var bob_height: float = 0.2
@export var bob_speed: float = 2.0

var bob_timer: float = 0.0
var current_hp: float = 0.0
var path_to_follow: Path3D = null
var path_follow: PathFollow3D = null
var pool_name: String = ""  # tracking asal pool

@onready var sprite: AnimatedSprite3D = $Anim


func _ready() -> void:
	sprite.play("default")
	if not enemy_data:
		push_error("Enemy has no data assigned!")
		queue_free()
		return
	
	current_hp = enemy_data.max_hp
	add_to_group("enemies")
	
	_setup_path()
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
	path_follow.progress += enemy_data.move_speed * delta
	global_position = path_follow.global_position
	
	bob_timer += delta * bob_speed
	global_position.y += sin(bob_timer) * bob_height
	
	if path_follow.progress_ratio >= 1.0:
		reach_end()

func _update_logic(delta: float) -> void:
	pass

func take_damage(damage: float) -> void:
	current_hp -= damage
	hp_changed.emit(current_hp, enemy_data.max_hp)
	
	if current_hp <= 0:
		die()

func die() -> void:
	died.emit(enemy_data.reward)
	AudioManager.play_sfx("enemy_die")
	_on_death()
	return_to_pool()

func _on_death() -> void:
	pass

func reach_end() -> void:
	reached_end.emit(enemy_data.base_damage)
	return_to_pool()

func return_to_pool() -> void:
	remove_from_group("enemies")
	bob_timer = 0.0
	
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

func get_hp_percentage() -> float:
	if enemy_data and enemy_data.max_hp > 0:
		return current_hp / enemy_data.max_hp
	return 0.0
