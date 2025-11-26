extends Resource
class_name EnemyData

## Konfigurasi statistik dan atribut Enemy

@export_group("Basic Stats")
@export var enemy_name: String = "Enemy"
@export var max_hp: float = 100.0
@export var move_speed: float = 3.0
@export var reward: int = 10
@export var base_damage: int = 1

@export_group("Combat")
@export var can_attack: bool = false
@export var attack_range: float = 5.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 2.0
@export var projectile_speed: float = 8.0

@export_group("Special")
@export var is_boss: bool = false
@export var boss_scale_multiplier: float = 1.0
