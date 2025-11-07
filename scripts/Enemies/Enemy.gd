extends CharacterBody3D

signal died(reward: int)
signal reached_end(damage: int)

@export var max_hp: float = 100.0
@export var move_speed: float = 3.0
@export var reward: int = 10
@export var base_damage: int = 1

var current_hp: float = 0.0
var path_to_follow: Path3D = null
var path_follow: PathFollow3D = null

func _ready() -> void:
	current_hp = max_hp
	
	if path_to_follow:
		path_follow = PathFollow3D.new()
		path_to_follow.add_child(path_follow)
		path_follow.loop = false

func _process(delta: float) -> void:
	if not path_follow:
		return
	
	path_follow.progress += move_speed * delta
	global_position = path_follow.global_position
	if path_follow.progress_ratio >= 1.0:
		reach_end()

func take_damage(damage: float) -> void:
	current_hp -= damage
	if current_hp <= 0:
		die()

func die() -> void:
	died.emit(reward)
	if path_follow:
		path_follow.queue_free()
	queue_free()

func reach_end() -> void:
	reached_end.emit(base_damage)
	if path_follow:
		path_follow.queue_free()
	queue_free()
