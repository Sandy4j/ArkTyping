extends Node3D

@export var max_hp: int = 20

var current_hp: int = 0

func _ready() -> void:
	current_hp = max_hp

func take_damage(damage: int) -> void:
	current_hp -= damage
	if current_hp <= 0:
		current_hp = 0
