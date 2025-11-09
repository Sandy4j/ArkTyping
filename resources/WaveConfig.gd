extends Resource
class_name WaveConfig

## Konfigurasi untuk satu wave

enum SpawnMode {
	SEQUENTIAL,    ## Spawn secara bergantian (A → B → C)
	SIMULTANEOUS,  ## Spawn secara bersamaan (A + B + C)
	MIXED          ## Kombinasi antara sequential dan simultaneous
}

@export var wave_number: int = 1
@export var time_until_next_wave: float = 5.0
## Mode spawn untuk wave ini
@export var spawn_mode: SpawnMode = SpawnMode.SEQUENTIAL
## Konfigurasi spawn points dalam wave
@export var spawn_point_configs: Array[SpawnPointConfig] = []
