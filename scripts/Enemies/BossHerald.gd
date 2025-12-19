extends BossEnemy
class_name BossHerald

## Boss Herald - Buff movement speed semua enemy, cleansed setelah 3x typing

@export var speed_buff_multiplier: float = 1.5
@export var required_typing_count: int = 3
@export var typing_word_pool: Array[String] = [
	"Banish",
	"Purge",
	"Dispel",
	"Nullify",
	"Consecrate",
	"Suppress",
	"Repell",
	"Smite",
	"Sunder",
	"Enlighten"
]

var buffed_enemies: Array[Node] = []
var buffed_enemies_vfx: Dictionary = {}
var current_buff_word: String = ""
var typing_label: Label3D
var attack_timer: float = 0.0
var current_targets: Array[Node3D] = []  # Multiple targets
@export var max_attack_targets: int = 4  # Maximum targets to attack
var is_attacking: bool = false
var boss_rage_vfx: Node3D = null

func _ready():
	super._ready()
	ability_cooldown = 30.0
	setup_ability_timer()
	_setup_attack_range()
	setup_typing_label()

func _setup_attack_range():
	if not enemy_data or not enemy_data.can_attack:
		return

func setup_typing_label():
	typing_label = get_node_or_null("TypingLabel")
	if typing_label:
		typing_label.visible = false
		typing_label.modulate = Color(1, 1, 0, 1)

func _update_logic(delta: float):
	if not enemy_data or not enemy_data.can_attack or not is_alive:
		return
	
	_update_tower_targets()
	
	# Clean up invalid targets
	current_targets = current_targets.filter(func(t): return is_instance_valid(t))
	
	if current_targets.size() > 0:
		is_attacking = true
		attack_timer -= delta
		if attack_timer <= 0:
			_perform_attack()
			attack_timer = enemy_data.attack_cooldown
	else:
		is_attacking = false

func _update_tower_targets():
	if not get_tree():
		return
	
	var towers = get_tree().get_nodes_in_group("tower")
	current_targets.clear()
	
	for tower in towers:
		if is_instance_valid(tower):
			var distance = global_position.distance_to(tower.global_position)
			if distance <= enemy_data.attack_range:
				current_targets.append(tower)
				if current_targets.size() >= max_attack_targets:
					break

func find_nearest_tower() -> Node3D:
	if not get_tree():
		return null
	
	var towers = get_tree().get_nodes_in_group("tower")
	if towers.is_empty():
		return null
	
	var nearest: Node3D = null
	var nearest_distance: float = INF
	
	for tower in towers:
		if is_instance_valid(tower):
			var distance = global_position.distance_to(tower.global_position)
			if distance <= enemy_data.attack_range and distance < nearest_distance:
				nearest = tower
				nearest_distance = distance
	return nearest

func _perform_attack():
	if current_targets.is_empty():
		return
	
	var projectile_scene = preload("res://scenes/Enemy/ProjectileE.tscn")
	var pool_key = "enemy_projectile"
	
	if ability_active:
		# Rage Mode: Focus all shots on nearest target
		var nearest = find_nearest_tower()
		if nearest and is_instance_valid(nearest):
			for i in range(max_attack_targets):
				_spawn_projectile(projectile_scene, pool_key, nearest)
	else:
		# Normal Mode: 1 shot per unique target
		for target in current_targets:
			if target and is_instance_valid(target):
				_spawn_projectile(projectile_scene, pool_key, target)

func _spawn_projectile(projectile_scene: PackedScene, pool_key: String, target: Node3D):
	var projectile = ObjectPool.get_pooled_object(pool_key)
	
	if not projectile:
		projectile = projectile_scene.instantiate()
	else:
		projectile.pool_name = pool_key
	
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 0.5
	
	if projectile.has_method("initialize"):
		projectile.initialize(target, enemy_data.attack_damage, enemy_data.projectile_speed)

func activate_ability():
	if not is_alive or ability_active or not is_instance_valid(self):
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	
	buffed_enemies.clear()
	buffed_enemies_vfx.clear()
	AudioManager.play_sfx("boss_speed")
	
	# Apply buff ke semua enemy
	for enemy in enemies:
		if enemy != self:
			if enemy.has_method("apply_speed_buff"):
				enemy.apply_speed_buff(speed_buff_multiplier, self)
				buffed_enemies.append(enemy)
			elif enemy.has_method("set") and enemy.get("move_speed"):
				# Fallback: langsung modify move_speed
				var original_speed = enemy.move_speed
				enemy.set("original_move_speed", original_speed)
				enemy.move_speed = original_speed * speed_buff_multiplier
				buffed_enemies.append(enemy)
			
			if ResourceLoadManager:
				var enemy_vfx_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/enemy_rage.tscn")
				if enemy_vfx_scene:
					var enemy_vfx = enemy_vfx_scene.instantiate()
					enemy.add_child(enemy_vfx)
					# Reset transform untuk memastikan VFX centered dan follow parent
					enemy_vfx.position = Vector3.ZERO
					enemy_vfx.rotation = Vector3.ZERO
					enemy_vfx.scale = Vector3.ONE
					# Set owner untuk proper scene tree
					enemy_vfx.owner = enemy
					buffed_enemies_vfx[enemy] = enemy_vfx
				
	if ResourceLoadManager:
		var boss_vfx_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/rage_boss.tscn")
		if boss_vfx_scene:
			boss_rage_vfx = boss_vfx_scene.instantiate()
			add_child(boss_rage_vfx)
			# Reset transform untuk memastikan VFX centered dan follow parent
			boss_rage_vfx.position = Vector3.ZERO
			boss_rage_vfx.rotation = Vector3.ZERO
			boss_rage_vfx.scale = Vector3.ONE
			# Set owner untuk proper scene tree
			boss_rage_vfx.owner = self
			
	ability_active = true
	current_typing_progress = 0
	
	_generate_new_word()
	
	ability_activated.emit("speed_buff")
	# Register ke TypingSystem
	if TypingSystem:
		TypingSystem.register_boss_typing(self, current_buff_word)
	
	ability_timer.start(30.0)

func _generate_new_word():
	var old_word = current_buff_word
	# Pilih kata yang berbeda dari sebelumnya
	var new_word = typing_word_pool[randi() % typing_word_pool.size()]
	while new_word == old_word and typing_word_pool.size() > 1:
		new_word = typing_word_pool[randi() % typing_word_pool.size()]
	
	current_buff_word = new_word
	
	if typing_label:
		typing_label.text = current_buff_word + " (" + str(current_typing_progress) + "/" + str(required_typing_count) + ")"
		typing_label.visible = true
	
	# Update TypingSystem dengan kata baru
	if TypingSystem:
		TypingSystem.register_boss_typing(self, current_buff_word)
	
func on_typing_success():
	if not ability_active:
		return
		
	current_typing_progress += 1

	if should_cleanse_ability():
		cleanse_ability()
	else:
		_generate_new_word()

func on_typing_failed():
	if not ability_active:
		return
	_generate_new_word()

func should_cleanse_ability() -> bool:
	return current_typing_progress >= required_typing_count

func cleanse_ability():
	# Remove buff dari semua enemy
	for enemy in buffed_enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("remove_speed_buff"):
				enemy.remove_speed_buff(self)
			elif enemy.has_method("get") and enemy.get("original_move_speed"):
				# Fallback: balik original speed
				enemy.move_speed = enemy.get("original_move_speed")
	
	for vfx in buffed_enemies_vfx.values():
		if is_instance_valid(vfx):
			vfx.call_deferred("queue_free")
	
	if boss_rage_vfx and is_instance_valid(boss_rage_vfx):
		boss_rage_vfx.call_deferred("queue_free")
		boss_rage_vfx = null
	
	buffed_enemies.clear()
	buffed_enemies_vfx.clear()
	ability_active = false
	current_typing_progress = 0
	
	if typing_label:
		typing_label.visible = false
	
	if TypingSystem:
		TypingSystem.unregister_boss_typing(self)
	
	ability_cleansed.emit("speed_buff")
	
func die():
	cleanse_ability()
	super.die()

func get_typing_word() -> String:
	return current_buff_word

func _on_death() -> void:
	# Clean up all references and VFX
	_cleanup_ability_resources()
	
	# Unregister from TypingSystem
	if TypingSystem:
		TypingSystem.unregister_boss_typing(self)
	
	super._on_death()

func _cleanup_ability_resources() -> void:
	# Clean up all buffed enemy VFX
	for vfx in buffed_enemies_vfx.values():
		if is_instance_valid(vfx):
			vfx.call_deferred("queue_free")
	buffed_enemies_vfx.clear()
	
	# Clean up boss rage VFX
	if boss_rage_vfx and is_instance_valid(boss_rage_vfx):
		boss_rage_vfx.call_deferred("queue_free")
		boss_rage_vfx = null
	
	# Clear enemy references
	buffed_enemies.clear()
	current_targets.clear()
	
	# Hide typing label
	if typing_label:
		typing_label.visible = false


