extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

@export var enemy_scene: PackedScene
@export var spawn_path_node: NodePath
@export var initial_enemies_per_wave: int = 5
@export var spawn_interval: float = 1.0
@export var time_between_waves: float = 5.0
@export var max_waves: int = 10

var current_wave: int = 0
var enemies_spawned: int = 0
var enemies_alive: int = 0
var is_spawning: bool = false
var spawn_timer: float = 0.0
var wave_timer: float = 0.0
var spawn_path: Path3D = null

func _ready() -> void:
	wave_timer = time_between_waves
	
	if spawn_path_node:
		spawn_path = get_node(spawn_path_node)

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
	
	if is_spawning:
		spawn_timer += delta
		if spawn_timer >= spawn_interval and enemies_spawned < get_enemies_in_wave():
			spawn_enemy()
			spawn_timer = 0.0
	elif current_wave < max_waves:
		wave_timer += delta
		if wave_timer >= time_between_waves:
			start_wave()

func start_wave() -> void:
	current_wave += 1
	enemies_spawned = 0
	is_spawning = true
	wave_timer = 0.0
	wave_started.emit(current_wave)
	print("Wave ", current_wave, " started!")

func get_enemies_in_wave() -> int:
	# Increase enemies per wave
	return initial_enemies_per_wave + (current_wave - 1) * 2

func spawn_enemy() -> void:
	if not enemy_scene or not spawn_path:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.path_to_follow = spawn_path
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	
	get_tree().current_scene.add_child(enemy)
	enemies_spawned += 1
	enemies_alive += 1
	
	if enemies_spawned >= get_enemies_in_wave():
		is_spawning = false

func _on_enemy_died(reward: int) -> void:
	enemies_alive -= 1
	GameManager.add_currency(reward)
	check_wave_complete()

func _on_enemy_reached_end(damage: int) -> void:
	enemies_alive -= 1
	GameManager.damage_base(damage)
	check_wave_complete()

func check_wave_complete() -> void:
	if not is_spawning and enemies_alive <= 0:
		wave_completed.emit(current_wave)
		print("Wave ", current_wave, " completed!")
		
		if current_wave >= max_waves:
			all_waves_completed.emit()
			print("All waves completed! Victory!")
		else:
			wave_timer = 0.0
