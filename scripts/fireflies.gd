extends Node3D

@onready var light: OmniLight3D = $OmniLight3D
@export var float_strength = 0.2
@export var float_speed = 1.5
@export var flicker_speed = 2.0
@export var intensity_range = 0.5
@export var base_intensity = 0.5
var start_y = 0.0

func _ready():
	start_y = global_position.y

func _process(delta):
	var offset = sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_strength
	global_position.y = start_y + offset
	var pulse = (sin(Time.get_ticks_msec() / 1000.0 * flicker_speed) + 1) / 2.0
	light.light_energy = base_intensity + pulse * intensity_range
