extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

## Array berisi konfigurasi WaveConfig untuk setiap gelombang
@export var wave_configs: Array[WaveConfig] = []

var current_wave: int = 0
var wave_timer: float = 0.0
var current_wave_config: WaveConfig = null
var victory_triggered: bool = false
var spawn_manager: SpawnManager = null
var wave_complete_checked: bool = false

func _ready() -> void:
	var initial_wait = 5.0
	if wave_configs.size() > 0 and wave_configs[0]:
		initial_wait = wave_configs[0].time_until_next_wave
	wave_timer = initial_wait
	
	spawn_manager = SpawnManager.new()
	add_child(spawn_manager)
	spawn_manager.all_spawn_points_completed.connect(_on_all_spawn_points_completed)
	
	# Get tower data dari TowerInput
	var tower_datas: Array[TowerData] = []
	var tower_input = get_tree().get_first_node_in_group("towerinput")
	if tower_input and "tower_list" in tower_input:
		tower_datas = tower_input.tower_list
	
	PoolSetup.setup_pools_for_waves(wave_configs, tower_datas)


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
	
	if current_wave > 0:
		check_wave_complete()
	
	if not spawn_manager.is_currently_spawning() and current_wave < get_max_waves():
		wave_timer += delta
		if wave_timer >= get_time_between_waves():
			start_wave()

func start_wave() -> void:
	current_wave += 1
	wave_timer = 0.0
	wave_complete_checked = false
	
	if current_wave <= wave_configs.size() and wave_configs[current_wave - 1]:
		current_wave_config = wave_configs[current_wave - 1]
	else:
		current_wave_config = null
	
	var spawn_configs = get_spawn_point_configs_for_wave()
	
	if spawn_configs.size() > 0:
		var mode = current_wave_config.spawn_mode
		
		spawn_manager.start_spawning(spawn_configs, mode)
		wave_started.emit(current_wave)
		
		var mode_name = "SEQUENTIAL" if mode == 0 else "SIMULTANEOUS"
		print("WaveManager: Wave ", current_wave, " mulai dengan", spawn_configs.size(), " spawn points (", mode_name, " mode)")
	else:
		push_error("WaveManager: tidak ada konfigurasi ", current_wave)

func get_spawn_point_configs_for_wave() -> Array[SpawnPointConfig]:
	var configs: Array[SpawnPointConfig] = []
	
	if current_wave_config:
		configs = current_wave_config.spawn_point_configs
	
	return configs

func get_time_between_waves() -> float:
	if current_wave_config:
		return current_wave_config.time_until_next_wave
	else:
		return 5.0  # Default fallback

func get_max_waves() -> int:
	return wave_configs.size()

func _on_all_spawn_points_completed() -> void:
	print("WaveManager: Semua spawn point sudah selesai", current_wave)

func check_wave_complete() -> void:
	if wave_complete_checked:
		return
		
	var spawning_complete = not spawn_manager.is_currently_spawning()
	var all_enemies_defeated = spawn_manager.get_active_enemy_count() <= 0
	
	if spawning_complete and all_enemies_defeated and not GameManager.is_game_over:
		wave_complete_checked = true
		wave_completed.emit(current_wave)
		print("WaveManager: Wave ", current_wave, " completed!")
		
		if current_wave >= get_max_waves() and not victory_triggered:
			victory_triggered = true
			all_waves_completed.emit()
			LevelManager.trigger_victory()
		else:
			wave_timer = 0.0
