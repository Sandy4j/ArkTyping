extends Resource
class_name WaveConfig

## Konfigurasi untuk satu wave

@export var wave_number: int = 1
@export var total_enemies: int = 5
@export var spawn_interval: float = 1.0
@export var time_until_next_wave: float = 5.0

@export var enemy_spawn_entries: Array[EnemySpawnEntry] = []

@export var has_boss: bool = false
@export var boss_scene: PackedScene
@export var boss_data: EnemyData
@export var boss_spawn_timing: float = 0.5  # range dari 0.0 (awal) ke 1.0 (akhir)

