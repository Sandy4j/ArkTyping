extends CanvasLayer
class_name DangerVignette

@export var danger_threshold: float = 0.8
@export var max_intensity: float = 0.4
@export var fade_speed: float = 2.0

@onready var color_rect: ColorRect = $ColorRect
var shader_material: ShaderMaterial
var current_intensity: float = 0.0
var target_intensity: float = 0.0
var is_boss_warning_active: bool = false
var boss_warning_tween: Tween = null

func _ready() -> void:
	layer = 100
	
	if color_rect and color_rect.material is ShaderMaterial:
		shader_material = color_rect.material

func _process(delta: float) -> void:
	# Don't process normal vignette during boss warning
	if is_boss_warning_active:
		return
	
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

func trigger_boss_warning(duration: float = 3.0) -> void:
	if boss_warning_tween and boss_warning_tween.is_running():
		boss_warning_tween.kill()
	
	if not shader_material:
		push_error("Vignette: Shader material is null!")
		return
	
	is_boss_warning_active = true
	
	boss_warning_tween = create_tween()
	boss_warning_tween.set_loops(int(duration * 2))
	boss_warning_tween.tween_method(func(value): 
		if shader_material:
			shader_material.set_shader_parameter("vignette_intensity", value)
	, 0.6, 0.3, 0.25)
	boss_warning_tween.tween_method(func(value): 
		if shader_material:
			shader_material.set_shader_parameter("vignette_intensity", value)
	, 0.3, 0.6, 0.25)
	
	await get_tree().create_timer(duration).timeout
	
	# Kill the pulsing tween if it's still running
	if boss_warning_tween and boss_warning_tween.is_running():
		boss_warning_tween.kill()
	
	# Create smooth fade-out tween
	var fade_out_tween = create_tween()
	fade_out_tween.set_ease(Tween.EASE_OUT)
	fade_out_tween.set_trans(Tween.TRANS_CUBIC)
	
	
	var current_shader_intensity = shader_material.get_shader_parameter("vignette_intensity")
	if current_shader_intensity == null:
		current_shader_intensity = 0.6
	
	fade_out_tween.tween_method(func(value):
		if shader_material:
			shader_material.set_shader_parameter("vignette_intensity", value)
			current_intensity = value
	, float(current_shader_intensity), 0.0, 0.5)
	
	# Wait for fade out to complete
	await fade_out_tween.finished
	
	is_boss_warning_active = false
	target_intensity = 0.0
	current_intensity = 0.0

