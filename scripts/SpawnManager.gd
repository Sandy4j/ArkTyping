extends Node
class_name SpawnManager

## Manages enemy spawning

signal spawn_point_completed(spawn_point_index: int)
signal all_spawn_points_completed



# Sequential mode variables
var current_spawn_point_index: int = 0
var enemies_spawned_at_current_point: int = 0
var boss_spawned_at_current_point: bool = false
var spawn_timer: float = 0.0

# Simultaneous mode variables
var spawn_point_states: Array[Dictionary] = []  # Tracking state untkuk setiap spawn point
var spawn_timers: Array[float] = []  # Timer untuk setiap spawn point

# Variables umum
var base_node: NodePath
var spawn_point_configs: Array[SpawnPointConfig] = []
var is_spawning: bool = false
var base: Node = null
var active_enemies: int = 0
var spawn_mode: int = 0  # WaveConfig.SpawnMode

func _ready() -> void:
	call_deferred("_find_base")

func _process(delta: float) -> void:
	if not is_spawning or GameManager.is_game_over:
		return
	
	if spawn_mode == 0:  # SEQUENTIAL
		_process_sequential(delta)
	elif spawn_mode == 1:  # SIMULTANEOUS
		_process_simultaneous(delta)

func _find_base() -> void:
	if base_node:
		base = get_node(base_node)
	else:
		var root = get_tree().current_scene
		if root:
			base = root.get_node_or_null("Base")
			if not base:
				for child in root.get_children():
					if child.name == "Base" or (child is Node3D and child.has_method("take_damage")):
						base = child
						break

func _process_sequential(delta: float) -> void:
	var current_config = get_current_spawn_point_config()
	if not current_config:
		return
	spawn_timer += delta
	
	if current_config.has_boss and not boss_spawned_at_current_point:
		var boss_spawn_count = int(current_config.enemies_to_spawn * current_config.boss_spawn_timing)
		if enemies_spawned_at_current_point >= boss_spawn_count:
			spawn_boss(current_config, current_spawn_point_index)
			boss_spawned_at_current_point = true
	
	if spawn_timer >= current_config.spawn_interval and enemies_spawned_at_current_point < current_config.enemies_to_spawn:
		spawn_enemy(current_config, current_spawn_point_index)
		spawn_timer = 0.0
		enemies_spawned_at_current_point += 1
	
	if enemies_spawned_at_current_point >= current_config.enemies_to_spawn:
		complete_current_spawn_point()

func _process_simultaneous(delta: float) -> void:
	var all_complete = true
	
	for i in range(spawn_point_configs.size()):
		var config = spawn_point_configs[i]
		var state = spawn_point_states[i]
		
		if state.complete:
			continue
		
		all_complete = false
		spawn_timers[i] += delta
		
		if config.has_boss and not state.boss_spawned:
			var boss_spawn_count = int(config.enemies_to_spawn * config.boss_spawn_timing)
			if state.enemies_spawned >= boss_spawn_count:
				spawn_boss(config, i)
				state.boss_spawned = true
		
		if spawn_timers[i] >= config.spawn_interval and state.enemies_spawned < config.enemies_to_spawn:
			spawn_enemy(config, i)
			spawn_timers[i] = 0.0
			state.enemies_spawned += 1
		
		if state.enemies_spawned >= config.enemies_to_spawn:
			state.complete = true
			spawn_point_completed.emit(i)
			print("SpawnManager: Spawn point ", i, " completed (simultaneous mode)")
	
	if all_complete:
		is_spawning = false
		all_spawn_points_completed.emit()
		print("SpawnManager: All spawn points completed (simultaneous mode)")

func start_spawning(configs: Array[SpawnPointConfig], mode: int = 0) -> void:
	spawn_point_configs = configs
	spawn_mode = mode
	is_spawning = true
	
	if spawn_mode == 0:  # SEQUENTIAL
		current_spawn_point_index = 0
		enemies_spawned_at_current_point = 0
		spawn_timer = 0.0
		boss_spawned_at_current_point = false
		print("SpawnManager: Started SEQUENTIAL spawning with ", configs.size(), " spawn points")
	elif spawn_mode == 1:  # SIMULTANEOUS
		spawn_point_states.clear()
		spawn_timers.clear()
		for i in range(configs.size()):
			spawn_point_states.append({
				"enemies_spawned": 0,
				"boss_spawned": false,
				"complete": false
			})
			spawn_timers.append(0.0)
		print("SpawnManager: Started SIMULTANEOUS spawning with ", configs.size(), " spawn points")

func stop_spawning() -> void:
	is_spawning = false
	spawn_point_configs.clear()

func get_current_spawn_point_config() -> SpawnPointConfig:
	if current_spawn_point_index < spawn_point_configs.size():
		return spawn_point_configs[current_spawn_point_index]
	return null

func complete_current_spawn_point() -> void:
	spawn_point_completed.emit(current_spawn_point_index)
	print("SpawnManager: Spawn point ", current_spawn_point_index, " completed")
	
	current_spawn_point_index += 1
	enemies_spawned_at_current_point = 0
	spawn_timer = 0.0
	boss_spawned_at_current_point = false
	
	if current_spawn_point_index >= spawn_point_configs.size():
		is_spawning = false
		all_spawn_points_completed.emit()
		print("SpawnManager: All spawn points completed")

func spawn_enemy(config: SpawnPointConfig, spawn_point_index: int) -> void:
	var spawn_path = get_spawn_path(config)
	if not spawn_path:
		push_error("SpawnManager: Invalid spawn path for spawn point ", spawn_point_index)
		return
	
	var spawn_entry = select_enemy_to_spawn(config)
	if not spawn_entry or not spawn_entry.enemy_scene:
		push_error("SpawnManager: No valid enemy entry to spawn")
		return
	
	var scene_path = spawn_entry.enemy_scene.resource_path
	var pool_name = "enemy_" + scene_path.get_file().get_basename()
	
	var enemy = ObjectPool.get_pooled_object(pool_name)
	
	if not enemy:
		enemy = spawn_entry.enemy_scene.instantiate()
	else:
		enemy.pool_name = pool_name
	
	if enemy is BaseEnemy and spawn_entry.enemy_data:
		enemy.enemy_data = spawn_entry.enemy_data
	
	enemy.path_to_follow = spawn_path
	
	# Connect signals only if not already connected
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	if not enemy.reached_end.is_connected(_on_enemy_reached_end):
		enemy.reached_end.connect(_on_enemy_reached_end, CONNECT_ONE_SHOT)
	
	get_tree().current_scene.add_child(enemy)
	
	if enemy is BaseEnemy:
		enemy._setup_path()
		enemy._setup_visual()
	
	# Play spawn sound
	AudioManager.play_sfx("enemy_spawn")
	
	active_enemies += 1
	
	if spawn_mode == 0:  # SEQUENTIAL
		print("SpawnManager: Spawned enemy from spawn point ", spawn_point_index, " (", enemies_spawned_at_current_point, "/", config.enemies_to_spawn, ")")
	else:  # SIMULTANEOUS
		var state = spawn_point_states[spawn_point_index]
		print("SpawnManager: Spawned enemy from spawn point ", spawn_point_index, " (", state.enemies_spawned, "/", config.enemies_to_spawn, ")")

func spawn_boss(config: SpawnPointConfig, spawn_point_index: int) -> void:
	if not config.boss_scene:
		return
		
	var spawn_path = get_spawn_path(config)
	if not spawn_path:
		push_error("SpawnManager: Invalid spawn path for boss at spawn point ", spawn_point_index)
		return
	
	var boss_path = config.boss_scene.resource_path
	var pool_name = "enemy_" + boss_path.get_file().get_basename()
	
	var boss = ObjectPool.get_pooled_object(pool_name)
	
	if not boss:
		boss = config.boss_scene.instantiate()
	else:
		boss.pool_name = pool_name
	
	if boss is BaseEnemy and config.boss_data:
		boss.enemy_data = config.boss_data
		boss._setup_visual()
	
	boss.path_to_follow = spawn_path
	
	# Connect signals only if not already connected
	if not boss.died.is_connected(_on_enemy_died):
		boss.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	if not boss.reached_end.is_connected(_on_enemy_reached_end):
		boss.reached_end.connect(_on_enemy_reached_end, CONNECT_ONE_SHOT)
	
	get_tree().current_scene.add_child(boss)
	
	if boss is BaseEnemy:
		boss._setup_path()
	
	active_enemies += 1
	
	print("SpawnManager: Boss spawned at spawn point ", spawn_point_index)

func select_enemy_to_spawn(config: SpawnPointConfig) -> EnemySpawnEntry:
	var available_entries = config.enemy_spawn_entries
	
	if available_entries.size() == 0:
		return null
	
	var total_weight: float = 0.0
	for entry in available_entries:
		if entry:
			total_weight += entry.spawn_weight
	
	if total_weight <= 0:
		return available_entries[0]
	
	var random_value = randf() * total_weight
	var cumulative_weight: float = 0.0
	
	for entry in available_entries:
		if entry:
			cumulative_weight += entry.spawn_weight
			if random_value <= cumulative_weight:
				return entry
	
	return available_entries[0]

func get_spawn_path(config: SpawnPointConfig) -> Path3D:
	if config.spawn_path_node:
		# Try to get the node from the current scene root first
		var scene_root = get_tree().current_scene
		var path = scene_root.get_node_or_null(config.spawn_path_node)
		if path and path is Path3D:
			return path
		
		# Fallback: try from SpawnManager's parent (WaveManager)
		if get_parent():
			path = get_parent().get_node_or_null(config.spawn_path_node)
			if path and path is Path3D:
				return path
		
		# Last resort: try from SpawnManager itself
		path = get_node_or_null(config.spawn_path_node)
		if path and path is Path3D:
			return path
	return null

func _on_enemy_died(reward: int) -> void:
	if active_enemies > 0:
		active_enemies -= 1
	GameManager.add_currency(reward)

func _on_enemy_reached_end(damage: int) -> void:
	if active_enemies > 0:
		active_enemies -= 1
	if base:
		base.take_damage(damage)

func get_active_enemy_count() -> int:
	return active_enemies

func is_currently_spawning() -> bool:
	return is_spawning
