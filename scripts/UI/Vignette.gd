extends CanvasLayer
class_name DangerVignette

@export var danger_threshold: float = 0.8
@export var max_intensity: float = 0.4
@export var fade_speed: float = 2.0

@onready var color_rect: ColorRect = $ColorRect
var shader_material: ShaderMaterial
var current_intensity: float = 0.0
var target_intensity: float = 0.0

func _ready() -> void:
	layer = 100
	
	if color_rect and color_rect.material is ShaderMaterial:
		shader_material = color_rect.material

func _process(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var has_danger = false
	
	for enemy in enemies:
		if enemy is BaseEnemy and enemy.path_follow:
			if enemy.path_follow.progress_ratio >= danger_threshold:
				has_danger = true
				break
	
	target_intensity = max_intensity if has_danger else 0.0
	
	current_intensity = lerp(current_intensity, target_intensity, fade_speed * delta)
	
	if shader_material:
		shader_material.set_shader_parameter("vignette_intensity", current_intensity)

func set_danger_threshold(threshold: float) -> void:
	danger_threshold = clamp(threshold, 0.0, 1.0)

func set_max_intensity(intensity: float) -> void:
	max_intensity = clamp(intensity, 0.0, 1.0)
