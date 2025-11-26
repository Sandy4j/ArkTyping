extends BossEnemy
class_name BossVoid

## Boss Void - The World Time Stop Ability

@export var time_stop_duration: float = 5.0
@export var time_stop_cooldown_min: float = 15.0
@export var time_stop_cooldown_max: float = 30.0

var is_time_stopped: bool = false
var time_stop_timer: float = 0.0
var tick_timer: float = 0.0
var tick_interval: float = 1.0
var timestop_vfx: Node3D = null
var time_stop_overlay: ColorRect = null
var original_pause_mode: Dictionary = {}

func _ready():
	super._ready()
	ability_cooldown = randf_range(time_stop_cooldown_min, time_stop_cooldown_max)
	setup_ability_timer()
	ability_timer.start(ability_cooldown)

func _process(delta: float) -> void:
	if not is_time_stopped:
		super._process(delta)
	else:
		if not path_follow or not enemy_data:
			return
		
		_move(delta)
		_update_time_stop(delta)

func _update_time_stop(delta: float):
	time_stop_timer -= delta
	tick_timer -= delta
	
	if tick_timer <= 0:
		AudioManager.play_sfx("zawarudo_tick")
		tick_timer = tick_interval
	
	if time_stop_timer <= 0:
		end_time_stop()

func activate_ability():
	if not is_alive or ability_active or is_time_stopped or not is_instance_valid(self):
		return
	
	is_time_stopped = true
	ability_active = true
	time_stop_timer = time_stop_duration
	tick_timer = tick_interval
	
	# Play "ZA WARUDO!" sound
	AudioManager.play_sfx("zawarudo_start")
	
	create_time_stop_overlay()
	spawn_timestop_vfx()
	freeze_all_entities()
	disable_pause()
	
	ability_activated.emit("time_stop")

func end_time_stop():
	if not is_time_stopped:
		return
	
	is_time_stopped = false
	ability_active = false
	
	# Play "Time resumes" sound
	AudioManager.play_sfx("zawarudo_end")
	
	remove_time_stop_overlay()
	
	if timestop_vfx and is_instance_valid(timestop_vfx):
		timestop_vfx.queue_free()
		timestop_vfx = null
	
	unfreeze_all_entities()
	
	enable_pause()
	ability_cooldown = randf_range(time_stop_cooldown_min, time_stop_cooldown_max)
	ability_timer.start(ability_cooldown)
	
	ability_cleansed.emit("time_stop")

func spawn_timestop_vfx():
	if ResourceLoadManager:
		var vfx_scene = ResourceLoadManager.load_resource_sync("res://timestopu.tscn")
		if vfx_scene:
			timestop_vfx = vfx_scene.instantiate()
			add_child(timestop_vfx)
			timestop_vfx.position = Vector3.ZERO
			timestop_vfx.rotation = Vector3.ZERO
			timestop_vfx.scale = Vector3.ONE
			
			var anim_player = timestop_vfx.get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.play("Za warudo")

func create_time_stop_overlay():
	var canvas_layer = _find_canvas_layer()
	
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "TimeStopOverlay"
		canvas_layer.layer = 100
		get_tree().root.add_child(canvas_layer)
	
	time_stop_overlay = ColorRect.new()
	time_stop_overlay.name = "TimeStopShader"
	time_stop_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_stop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	time_stop_overlay.offset_left = 0
	time_stop_overlay.offset_top = 0
	time_stop_overlay.offset_right = 0
	time_stop_overlay.offset_bottom = 0
	
	# Load shader material dengan efek The World
	if ResourceLoadManager:
		var shader_material = ResourceLoadManager.load_resource_sync("res://asset/Shader/time_stop_material.tres")
		if shader_material:
			time_stop_overlay.material = shader_material
		else:
			# Fallback: create material with shader directly
			var shader = ResourceLoadManager.load_resource_sync("res://asset/Shader/time_stop_overlay.gdshader")
			if shader:
				var material = ShaderMaterial.new()
				material.shader = shader
				material.set_shader_parameter("desaturation", 0.85)
				material.set_shader_parameter("brightness", 0.9)
				time_stop_overlay.material = material
	
	canvas_layer.add_child(time_stop_overlay)
	
	# Fade in animation untuk dramatic effect
	time_stop_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(time_stop_overlay, "modulate:a", 1.0, 0.5)

func remove_time_stop_overlay():
	if time_stop_overlay and is_instance_valid(time_stop_overlay):
		# Fade out animation
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(time_stop_overlay, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			if is_instance_valid(time_stop_overlay):
				var parent = time_stop_overlay.get_parent()
				time_stop_overlay.queue_free()
				time_stop_overlay = null
				# Cleanup canvas layer jika kosong
				if parent and parent.name == "TimeStopOverlay" and parent.get_child_count() == 0:
					parent.queue_free()
		)

func _find_canvas_layer() -> CanvasLayer:
	for child in get_tree().root.get_children():
		if child is CanvasLayer and child.name == "TimeStopOverlay":
			return child
	return null

func freeze_all_entities():
	# Freeze enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			enemy.set_process(false)
			enemy.set_physics_process(false)
			enemy.set_process_input(false)
			_freeze_timers(enemy)
	
	# Freeze all towers with bind mechanism
	var towers = get_tree().get_nodes_in_group("towers")
	for tower in towers:
		if is_instance_valid(tower):
			# Store original state
			if not tower in original_pause_mode:
				original_pause_mode[tower] = {
					"process_mode": tower.process_mode,
					"got_binded": tower.get("got_binded") if tower.has_method("get") else false,
					"fire_timer": tower.get("fire_timer") if tower.has_method("get") and tower.get("fire_timer") != null else 0.0
				}
			
			# Use bind mechanism to freeze (proven to work!)
			if tower.has_method("set"):
				tower.set("got_binded", true)
	
			# Additional safety measures
			tower.process_mode = Node.PROCESS_MODE_DISABLED
			tower.set_process(false)
			tower.set_physics_process(false)
			tower.set_process_input(false)
			
			# Freeze all timers
			_freeze_timers(tower)
			
	# Freeze all projectiles
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.process_mode = Node.PROCESS_MODE_DISABLED
			projectile.set_process(false)
			projectile.set_physics_process(false)
	
	# Pause BGM untuk efek dramatic
	if AudioManager and AudioManager.bgm_player:
		AudioManager.bgm_player.stream_paused = true

func _freeze_timers(node: Node):
	for child in node.get_children():
		if child is Timer:
			child.paused = true
		_freeze_timers(child)  # Recursive untuk nested children

func unfreeze_all_entities():
	# Unfreeze enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			enemy.set_process(true)
			enemy.set_physics_process(true)
			enemy.set_process_input(true)
			_unfreeze_timers(enemy)
	
	# Unfreeze towers - restore bind state
	var towers = get_tree().get_nodes_in_group("towers")
	for tower in towers:
		if is_instance_valid(tower):
			# Restore original got_binded state
			if tower in original_pause_mode:
				if original_pause_mode[tower].has("got_binded"):
					if tower.has_method("set"):
						tower.set("got_binded", original_pause_mode[tower]["got_binded"])
				
				# Restore original process mode
				if original_pause_mode[tower].has("process_mode"):
					tower.process_mode = original_pause_mode[tower]["process_mode"]
				else:
					tower.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				# Default: not binded, inherit process mode
				if tower.has_method("set"):
					tower.set("got_binded", false)
				tower.process_mode = Node.PROCESS_MODE_INHERIT
			
			tower.set_process(true)
			tower.set_physics_process(true)
			tower.set_process_input(true)
			
			# Unpause all timers
			_unfreeze_timers(tower)
			print("[BossVoid] Tower unfrozen: ", tower.name)
	
	# Unfreeze projectiles
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.process_mode = Node.PROCESS_MODE_INHERIT
			projectile.set_process(true)
			projectile.set_physics_process(true)
	
	# Clear stored state
	original_pause_mode.clear()
	
	# Resume BGM
	if AudioManager and AudioManager.bgm_player:
		AudioManager.bgm_player.stream_paused = false

func _unfreeze_timers(node: Node):
	for child in node.get_children():
		if child is Timer:
			child.paused = false
		_unfreeze_timers(child)  # Recursive untuk nested children

func disable_pause():
	get_tree().root.set_meta("time_stop_active", true)
	
	get_tree().paused = false
	var ui_nodes = get_tree().get_nodes_in_group("ui")
	for ui_node in ui_nodes:
		if is_instance_valid(ui_node) and ui_node.has_method("disable_pause"):
			ui_node.disable_pause()

func enable_pause():
	get_tree().root.set_meta("time_stop_active", false)
	
	var ui_nodes = get_tree().get_nodes_in_group("ui")
	for ui_node in ui_nodes:
		if is_instance_valid(ui_node) and ui_node.has_method("enable_pause"):
			ui_node.enable_pause()

func _on_death():
	if is_time_stopped:
		end_time_stop()

func return_to_pool():
	if is_time_stopped:
		end_time_stop()
	
	if time_stop_overlay and is_instance_valid(time_stop_overlay):
		time_stop_overlay.queue_free()
		time_stop_overlay = null
	
	if timestop_vfx and is_instance_valid(timestop_vfx):
		timestop_vfx.queue_free()
		timestop_vfx = null
	
	super.return_to_pool()
