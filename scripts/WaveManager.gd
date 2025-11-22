extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed
signal wave_transition_warning(next_wave_number: int, countdown: float)

## Array berisi konfigurasi WaveConfig untuk setiap gelombang
@export var wave_configs: Array[WaveConfig] = []

var current_wave: int = 0
var wave_timer: float = 0.0
var current_wave_config: WaveConfig = null
var victory_triggered: bool = false
var spawn_manager: SpawnManager = null
var wave_complete_checked: bool = false
var waiting_for_enemies_to_die: bool = false
var transition_warning_shown: bool = false

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
	
	# nunggu musuh mati
	if waiting_for_enemies_to_die:
		if spawn_manager.get_active_enemy_count() <= 0:
			waiting_for_enemies_to_die = false
			transition_warning_shown = false
			wave_timer = 0.0
	
	# Only start next wave if not spawning, not waiting for enemies, and timer is ready
	if not spawn_manager.is_currently_spawning() and not waiting_for_enemies_to_die and current_wave < get_max_waves():
		wave_timer += delta
		
		# Tampilkan peringatan transisi gelombang 3 detik sebelum gelombang berikutnya dimulai
		if not transition_warning_shown and wave_timer >= get_time_between_waves() - 3.0:
			if current_wave > 0:  # Hanya tampilkan pada transisi wave
				transition_warning_shown = true
				wave_transition_warning.emit(current_wave + 1, get_time_between_waves() - wave_timer)
		
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

## Get wave configs for resource preloading
func get_wave_configs() -> Array[WaveConfig]:
	return wave_configs

func _on_all_spawn_points_completed() -> void:
	waiting_for_enemies_to_die = true

func check_wave_complete() -> void:
	if wave_complete_checked:
		return
		
	var spawning_complete = not spawn_manager.is_currently_spawning()
	var all_enemies_defeated = spawn_manager.get_active_enemy_count() <= 0
	
	if spawning_complete and all_enemies_defeated and not GameManager.is_game_over:
		wave_complete_checked = true
		wave_completed.emit(current_wave)
		
		if current_wave >= get_max_waves() and not victory_triggered:
			victory_triggered = true
			all_waves_completed.emit()
			LevelManager.trigger_victory()
		else:
			wave_timer = 0.0
