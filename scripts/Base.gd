extends Node3D

## Base/Home structure that enemies try to reach

signal hp_changed(current: int, maximum: int)

@export var max_hp: int = 20
var current_hp: int = 20

func _ready() -> void:
	current_hp = max_hp
	GameManager.set_base(self)

func take_damage(damage: int) -> void:
	current_hp -= damage
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		current_hp = 0
		GameManager.trigger_game_over()
