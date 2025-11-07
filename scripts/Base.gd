extends Node3D

signal hp_changed(new_hp: int)

@export var max_hp: int = 20

var current_hp: int = 0

func _ready() -> void:
	current_hp = max_hp
	GameManager.set_base(self)
	hp_changed.emit(current_hp)

func take_damage(damage: int) -> void:
	current_hp -= damage
	hp_changed.emit(current_hp)
	
	if current_hp <= 0:
		current_hp = 0
		hp_changed.emit(current_hp)
		GameManager.trigger_game_over()
