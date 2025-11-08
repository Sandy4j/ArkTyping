extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

## Array of wave configurations - one for each wave
@export var wave_configs: Array[WaveConfig] = []

## Fallback enemy spawn entries if no wave configs are set
@export var default_enemy_entries: Array[EnemySpawnEntry] = []

@export var spawn_path_node: NodePath
@export var base_node: NodePath

## Fallback settings if no wave configs
@export var default_initial_enemies: int = 5
@export var default_spawn_interval: float = 1.0
@export var default_time_between_waves: float = 5.0

var current_wave: int = 0
var enemies_spawned: int = 0
var enemies_alive: int = 0
var is_spawning: bool = false
var spawn_timer: float = 0.0
var wave_timer: float = 0.0
var spawn_path: Path3D = null
var base: Node = null
var boss_spawned: bool = false
var current_wave_config: WaveConfig = null
var victory_triggered: bool = false

func _ready() -> void:
	var initial_wait = default_time_between_waves
	if wave_configs.size() > 0 and wave_configs[0]:
		initial_wait = wave_configs[0].time_until_next_wave
	wave_timer = initial_wait
	
	if spawn_path_node:
		spawn_path = get_node(spawn_path_node)
	if base_node:	
		base = get_node(base_node)
	
	# Initialize object pools
	_setup_object_pools()

func _setup_object_pools() -> void:
	# Register projectile pools
	var tower_projectile_scene = preload("res://scenes/Tower/Projectile.tscn")
	var enemy_projectile_scene = preload("res://scenes/Enemy/ProjectileE.tscn")
	
	ObjectPool.register_pool("tower_projectile", tower_projectile_scene, 20, 100)
	ObjectPool.register_pool("enemy_projectile", enemy_projectile_scene, 15, 80)
	
	# Register enemy pools based on wave configs
	var registered_enemies: Dictionary = {}
	
	for wave_config in wave_configs:
		if not wave_config:
			continue
		
		# Register regular enemies
		for entry in wave_config.enemy_spawn_entries:
			if entry and entry.enemy_scene:
				var scene_path = entry.enemy_scene.resource_path
				if not registered_enemies.has(scene_path):
					var pool_name = "enemy_" + scene_path.get_file().get_basename()
					ObjectPool.register_pool(pool_name, entry.enemy_scene, 10, 50)
					registered_enemies[scene_path] = pool_name
		
		# Register boss if exists
		if wave_config.has_boss and wave_config.boss_scene:
			var boss_path = wave_config.boss_scene.resource_path
			if not registered_enemies.has(boss_path):
				var pool_name = "enemy_" + boss_path.get_file().get_basename()
				ObjectPool.register_pool(pool_name, wave_config.boss_scene, 2, 5)
				registered_enemies[boss_path] = pool_name
	
	# Register default enemies if no wave configs
	if wave_configs.size() == 0:
		for entry in default_enemy_entries:
			if entry and entry.enemy_scene:
				var scene_path = entry.enemy_scene.resource_path
				if not registered_enemies.has(scene_path):
					var pool_name = "enemy_" + scene_path.get_file().get_basename()
					ObjectPool.register_pool(pool_name, entry.enemy_scene, 10, 50)
					registered_enemies[scene_path] = pool_name

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
	
	if is_spawning:
		spawn_timer += delta
		
		# Check if it's time to spawn boss
		if current_wave_config and current_wave_config.has_boss and not boss_spawned:
			var boss_spawn_count = int(get_enemies_in_wave() * current_wave_config.boss_spawn_timing)
			if enemies_spawned >= boss_spawn_count:
				spawn_boss()
				boss_spawned = true
		
		if spawn_timer >= get_spawn_interval() and enemies_spawned < get_enemies_in_wave():
			spawn_enemy()
			spawn_timer = 0.0
	elif current_wave < get_max_waves():
		wave_timer += delta
		if wave_timer >= get_time_between_waves():
			start_wave()

func start_wave() -> void:
	current_wave += 1
	enemies_spawned = 0
	boss_spawned = false
	is_spawning = true
	wave_timer = 0.0
	
	# Load wave config
	if current_wave <= wave_configs.size() and wave_configs[current_wave - 1]:
		current_wave_config = wave_configs[current_wave - 1]
	else:
		current_wave_config = null
	
	wave_started.emit(current_wave)

func get_enemies_in_wave() -> int:
	if current_wave_config:
		return current_wave_config.total_enemies
	else:
		return default_initial_enemies + (current_wave - 1) * 2

func get_spawn_interval() -> float:
	if current_wave_config:
		return current_wave_config.spawn_interval
	else:
		return default_spawn_interval

func get_time_between_waves() -> float:
	if current_wave_config:
		return current_wave_config.time_until_next_wave
	else:
		return default_time_between_waves

func get_max_waves() -> int:
	if wave_configs.size() > 0:
		return wave_configs.size()
	else:
		return 1  # Default to 1 wave if no configs

func spawn_enemy() -> void:
	if not spawn_path:
		return
	
	var spawn_entry = select_enemy_to_spawn()
	if not spawn_entry or not spawn_entry.enemy_scene:
		return
	
	# Get pool name for this enemy type
	var scene_path = spawn_entry.enemy_scene.resource_path
	var pool_name = "enemy_" + scene_path.get_file().get_basename()
	
	# Get enemy from pool
	var enemy = ObjectPool.get_pooled_object(pool_name)
	
	# Fallback to instantiation if pool doesn't exist
	if not enemy:
		enemy = spawn_entry.enemy_scene.instantiate()
	else:
		enemy.pool_name = pool_name
	
	# Set enemy data if it's a BaseEnemy
	if enemy is BaseEnemy and spawn_entry.enemy_data:
		enemy.enemy_data = spawn_entry.enemy_data
	
	enemy.path_to_follow = spawn_path
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	
	get_tree().current_scene.add_child(enemy)
	
	if enemy is BaseEnemy:
		enemy._setup_path()
		enemy._setup_visual()
	
	enemies_spawned += 1
	enemies_alive += 1
	
	if enemies_spawned >= get_enemies_in_wave():
		is_spawning = false

func select_enemy_to_spawn() -> EnemySpawnEntry:
	var available_entries: Array[EnemySpawnEntry] = []
	
	# Get entries from current wave config or default
	if current_wave_config and current_wave_config.enemy_spawn_entries.size() > 0:
		available_entries = current_wave_config.enemy_spawn_entries
	elif default_enemy_entries.size() > 0:
		available_entries = default_enemy_entries
	else:
		return null
	
	# Filter by min_wave requirement
	var valid_entries: Array[EnemySpawnEntry] = []
	for entry in available_entries:
		if entry and entry.min_wave <= current_wave:
			valid_entries.append(entry)
	
	if valid_entries.size() == 0:
		return null
	
	# Calculate total weight
	var total_weight: float = 0.0
	for entry in valid_entries:
		total_weight += entry.spawn_weight
	
	# Weighted random selection
	var random_value = randf() * total_weight
	var cumulative_weight: float = 0.0
	
	for entry in valid_entries:
		cumulative_weight += entry.spawn_weight
		if random_value <= cumulative_weight:
			return entry
	
	# Fallback to first entry
	return valid_entries[0]

func spawn_boss() -> void:
	if not current_wave_config or not current_wave_config.boss_scene or not spawn_path:
		return
	
	# Get pool name for boss
	var boss_path = current_wave_config.boss_scene.resource_path
	var pool_name = "enemy_" + boss_path.get_file().get_basename()
	
	# Get boss from pool
	var boss = ObjectPool.get_pooled_object(pool_name)
	
	# Fallback to instantiation if pool doesn't exist
	if not boss:
		boss = current_wave_config.boss_scene.instantiate()
	else:
		boss.pool_name = pool_name
	
	# Set boss data if it's a BaseEnemy
	if boss is BaseEnemy and current_wave_config.boss_data:
		boss.enemy_data = current_wave_config.boss_data
		boss._setup_visual()
	
	boss.path_to_follow = spawn_path
	boss.died.connect(_on_enemy_died)
	boss.reached_end.connect(_on_enemy_reached_end)
	# Re-setup the boss path after adding to tree (for pooled bosses)
	get_tree().current_scene.add_child(boss)
	# Re-setup the boss path after adding to tree (for pooled bosses)
	if boss is BaseEnemy:
		boss._setup_path()
	
	enemies_alive += 1
	
	print("Boss spawned for wave ", current_wave)

func _on_enemy_died(reward: int) -> void:
	if enemies_alive > 0:
		enemies_alive -= 1
	GameManager.add_currency(reward)
	check_wave_complete()

func _on_enemy_reached_end(damage: int) -> void:
	if enemies_alive > 0:
		enemies_alive -= 1
	base.take_damage(damage)
	check_wave_complete()

func check_wave_complete() -> void:
	if not is_spawning and enemies_alive <= 0 and not GameManager.is_game_over:
		wave_completed.emit(current_wave)
		print("Wave ", current_wave, " completed!")
		
		if current_wave >= get_max_waves() and not victory_triggered:
			victory_triggered = true
			all_waves_completed.emit()
			LevelManager.trigger_victory()
		else:
			wave_timer = 0.0
