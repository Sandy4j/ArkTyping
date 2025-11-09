extends Resource
class_name EnemySpawnEntry

## Definisi entri spawn untuk jenis musuh tertentu dalam wave

@export var enemy_scene: PackedScene
@export var enemy_data: EnemyData
@export var spawn_weight: float = 1.0
@export var min_wave: int = 1  # Wave minimum di mana musuh ini dapat muncul
