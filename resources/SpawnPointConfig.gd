extends Resource
class_name SpawnPointConfig

## Konfigurasi untuk satu titik spawn dalam wave
@export var spawn_path_node: NodePath  # Path Path3D node
@export var enemy_spawn_entries: Array[EnemySpawnEntry] = []  # Enemies yang dapat di-spawn dari titik ini
@export var enemies_to_spawn: int = 5  # Jumlah total musuh yang akan di-spawn dari titik ini
@export var spawn_interval: float = 1.0  # Interval waktu antara spawn musuh (dalam detik)

## Konfigurasi boss (opsional)
@export_group("boss")
@export var has_boss: bool = false
@export var boss_scene: PackedScene
@export var boss_data: EnemyData
@export var boss_spawn_timing: float = 0.5  # Waktu relatif (0.0 - 1.0) dalam durasi spawn point ketika boss akan di-spawn
