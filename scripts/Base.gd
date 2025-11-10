extends Node3D

signal hp_changed(current: int, maximum: int)

@export var max_hp: int = 20
var current_hp: int = 20

func _ready() -> void:
	current_hp = max_hp
	GameManager.set_base(self)
	call_deferred("_emit_initial_hp")

func _emit_initial_hp() -> void:
	hp_changed.emit(current_hp, max_hp)

func take_damage(damage: int) -> void:
	current_hp -= damage
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		current_hp = 0
		GameManager.trigger_game_over()
