extends Node3D

signal shot_fired
signal skill_activated(skill_name: String)
signal tower_destroyed

@export var tower_data: TowerData

# Stats yang akan diambil dari TowerData
var detection_range: float = 0.0
var fire_rate: float = 0.0
var damage: float = 0.0
var projectile_speed: float = 0.0
var projectile_scene: PackedScene = null
var skill_type: String = ""
var enemies_in_range: Array[CharacterBody3D] = []
var overload_burst_active:bool
var scarlet_harvester_active:bool
var bullet_requiem_active:bool
var max_hp: float = 100.0
var current_hp: float = 100.0

var vfx_node
var vfx_aura
var orbit
var orbit2
var is_lilitia:bool
var fire_timer: float = 0.0
var current_target: CharacterBody3D = null
var skill_active: bool = false
var skill_cooldown: float = 0.0
var current_skill_cooldown: float = 0.0
var is_shooting:bool
var is_animation_playing: bool = false
@onready var sprite: AnimatedSprite3D = $Sprite3D
@onready var range_area: Area3D = $RangeArea
@onready var shoot_point: Node3D = $ShootPoint
@onready var skill_sprite: Sprite3D = $SkillSprite
var altar

func _ready() -> void:
	shot_fired.connect(after_shoot)
	damage = tower_data.damage
	fire_rate = tower_data.speed 
	detection_range = tower_data.range
	projectile_speed = tower_data.projectile_speed 
	skill_type = tower_data.skill
	if tower_data.projectile:
		projectile_scene = tower_data.projectile
		print("load projectile")
	max_hp = tower_data.max_hp
	skill_cooldown = tower_data.cooldown
	current_hp = max_hp
	sprite.sprite_frames = tower_data.sprite
	skill_sprite.texture = tower_data.skill_sprite
	print("Tower initialized with data: ", tower_data.chara)
	print("Damage: ", damage, " Fire Rate: ", fire_rate, " Range: ", detection_range, " HP: ", max_hp)
	if tower_data.chara == "lilitia":
		is_lilitia = true
		activate_holy_divine_basic()
		return
	
	add_to_group("tower")
	
	if range_area:
		var collision_shape = range_area.get_node("CollisionShape3D")
		if collision_shape and collision_shape.shape is SphereShape3D:
			collision_shape.shape.radius = detection_range
	current_skill_cooldown = skill_cooldown
	sprite.play("default")


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	
	fire_timer += delta
	
	# Update skill cooldown
	if current_skill_cooldown > 0:
		skill_sprite.modulate = Color(0.5,0.5,0.5,1.0)
		current_skill_cooldown -= delta
	else:
		skill_sprite.modulate = Color(1.0,1.0,1.0,1.0)
	
	update_animation()
	if is_lilitia:
		return
	
	update_target()
	
	# Find target if none
	if not current_target or not is_instance_valid(current_target) or not current_target.is_in_group("enemies"):
		current_target = find_nearest_enemy()
	
	# Check if target is still in range
	if current_target and global_position.distance_to(current_target.global_position) > detection_range:
		current_target = null
	
	# Shoot at target
	if current_target and is_instance_valid(current_target) and current_target.is_in_group("enemies") and fire_timer >= 1.0 / fire_rate:
		is_shooting = true
		if overload_burst_active:
			overload_burst()
		elif scarlet_harvester_active:
			scarlet_harvester()
		elif tower_data.skill == "bloody opus":
			double_shoot(current_target)
			print("vigilante nembak")
		else:
			shoot(current_target)
		fire_timer = 0.0

func update_animation():
	if is_shooting:
		if sprite.animation != "attack":
			sprite.play("attack")
			print("iki attack")
	else:
		if sprite.animation != "default":
			sprite.play("default")
			print("default")

func after_shoot():
	#is_shooting = false
	pass

func shoot(target: Node3D) -> void:
	if is_animation_playing:
		return  # 🚫 JANGAN SHOOT JIKA MASIH ANIMASI ATTACK
	
	is_shooting = true
	is_animation_playing = true
	
	# 🎯 STOP ANIMASI IDLE DULU
	sprite.stop()
	
	# 🎯 PLAY ANIMASI ATTACK
	sprite.play("attack")
	if not projectile_scene:
		return
	
	var pool_key = "tower_projectile_" + tower_data.chara
	var projectile = ObjectPool.get_pooled_object(pool_key)
	
	if not projectile:
		projectile = projectile_scene.instantiate()
		print("shoot dengan custom")
	else:
		projectile.pool_name = pool_key
	
	get_tree().current_scene.add_child(projectile)
	
	if shoot_point:
		projectile.global_position = shoot_point.global_position
	else:
		projectile.global_position = global_position + Vector3.UP
	print("Bulet ", projectile.name)
	projectile.initialize(target, damage, projectile_speed)
	shot_fired.emit()
	print("shot")

func double_shoot(target: CharacterBody3D) -> void:
	if is_animation_playing:
		return
	
	is_shooting = true
	is_animation_playing = true
	
	sprite.stop()
	sprite.play("attack")
	
	if not projectile_scene:
		return
	
	var pool_key = "tower_projectile_" + tower_data.chara
	
	# First projectile
	var projectile1 = ObjectPool.get_pooled_object(pool_key)
	if not projectile1:
		projectile1 = projectile_scene.instantiate()
	else:
		projectile1.pool_name = pool_key
	
	get_tree().current_scene.add_child(projectile1)
	
	if shoot_point:
		projectile1.global_position = shoot_point.global_position
	else:
		projectile1.global_position = global_position + Vector3.UP
	
	projectile1.initialize(target, damage, projectile_speed)
	
	# Second projectile
	await get_tree().create_timer(0.15).timeout
	
	var projectile2 = ObjectPool.get_pooled_object(pool_key)
	if not projectile2:
		projectile2 = projectile_scene.instantiate()
	else:
		projectile2.pool_name = pool_key
	
	get_tree().current_scene.add_child(projectile2)
	
	if shoot_point:
		projectile2.global_position = shoot_point.global_position
	else:
		projectile2.global_position = global_position + Vector3.UP
	
	projectile2.initialize(target, damage, projectile_speed)
	shot_fired.emit()
	print("shot")

func overload_burst() -> void:
	if is_animation_playing:
		return
	
	is_shooting = true
	is_animation_playing = true
	
	sprite.stop()
	
	sprite.play("attack")
	
	if not projectile_scene:
		return
	
	var targets:Array
	
	if enemies_in_range.size() == 0:
		return
	elif enemies_in_range.size() < 2:
		targets.append(enemies_in_range.get(0))
	else:
		targets.append(enemies_in_range.get(0))
		targets.append(enemies_in_range.get(1))
	
	if targets.size() == 0:
		return
	
	var pool_key = "tower_projectile_" + tower_data.chara
	
	for i in range(targets.size()):
		var target = targets[i]
		if is_instance_valid(target):
			var projectile = ObjectPool.get_pooled_object(pool_key)
			
			if not projectile:
				projectile = projectile_scene.instantiate()
			else:
				projectile.pool_name = pool_key
			
			get_tree().current_scene.add_child(projectile)
			
			if shoot_point:
				projectile.global_position = shoot_point.global_position
			else:
				projectile.global_position = global_position + Vector3.UP
			
			projectile.initialize(target, damage, projectile_speed)
	
	shot_fired.emit()
	print("Triple Shot! Hit ", targets.size(), " enemies")

func scarlet_harvester() -> void:
	if not projectile_scene:
		return
	
	var targets:Array
	
	if enemies_in_range.size() == 0:
		return
	elif enemies_in_range.size() < 2:
		targets.append(enemies_in_range.get(0))
	elif enemies_in_range.size() < 3:
		targets.append(enemies_in_range.get(0))
		targets.append(enemies_in_range.get(1))
	elif enemies_in_range.size() < 4:
		targets.append(enemies_in_range.get(0))
		targets.append(enemies_in_range.get(1))
		targets.append(enemies_in_range.get(2))
	elif enemies_in_range.size() < 5:
		targets.append(enemies_in_range.get(0))
		targets.append(enemies_in_range.get(1))
		targets.append(enemies_in_range.get(2))
		targets.append(enemies_in_range.get(3))
	else:
		targets.append(enemies_in_range.get(0))
		targets.append(enemies_in_range.get(1))
		targets.append(enemies_in_range.get(2))
		targets.append(enemies_in_range.get(3))
		targets.append(enemies_in_range.get(4))
	
	if targets.size() == 0:
		return
	
	var pool_key = "tower_projectile"
	
	for i in range(targets.size()):
		var target = targets[i]
		if is_instance_valid(target):
			var projectile = ObjectPool.get_pooled_object(pool_key)
			
			if not projectile:
				projectile = projectile_scene.instantiate()
			else:
				projectile.pool_name = pool_key
			
			get_tree().current_scene.add_child(projectile)
			
			if shoot_point:
				projectile.global_position = shoot_point.global_position
			else:
				projectile.global_position = global_position + Vector3.UP
			
			projectile.initialize(target, damage, projectile_speed)
	
	shot_fired.emit()

func find_nearest_enemy() -> CharacterBody3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: CharacterBody3D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_in_group("enemies"):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= detection_range and distance < nearest_distance:
				nearest = enemy
				nearest_distance = distance
	
	return nearest

func _on_enemy_entered_range(body: Node3D) -> void:
	# Cek jika body adalah musuh
	if body.is_in_group("enemies") and body is CharacterBody3D:
		var enemy = body as CharacterBody3D
		
		# Tambahkan ke array jika belum ada
		if not enemy in enemies_in_range:
			enemies_in_range.append(enemy)
			print("Enemy entered range. Total enemies: ", enemies_in_range.size())
			
			# Jika belum ada target, set target ke musuh ini
			if not current_target:
				current_target = enemy
				print("New target set: ", enemy.name)

func _on_enemy_exited_range(body: Node3D) -> void:
	# Cek jika body adalah musuh
	if body.is_in_group("enemies") and body is CharacterBody3D:
		var enemy = body as CharacterBody3D
		
		# Hapus musuh dari array
		if enemy in enemies_in_range:
			enemies_in_range.erase(enemy)
			print("Enemy exited range. Total enemies: ", enemies_in_range.size())
		
		# Jika musuh yang keluar adalah target saat ini, cari target baru
		if enemy == current_target:
			current_target = null
			update_target()

func update_target() -> void:
	# Bersihkan array dari musuh yang sudah tidak valid
	cleanup_enemies_array()
	
	# Jika tidak ada target saat ini dan ada musuh dalam range
	if not current_target and enemies_in_range.size() > 0:
		# Pilih musuh pertama dalam array (yang pertama masuk)
		current_target = enemies_in_range[0]
		print("Target updated to first enemy in range: ", current_target.name)
	
	# Jika target saat ini sudah tidak valid atau tidak dalam array, cari yang baru
	elif current_target and (not is_instance_valid(current_target) or not current_target in enemies_in_range):
		current_target = null
		if enemies_in_range.size() > 0:
			current_target = enemies_in_range[0]
			print("Target reacquired: ", current_target.name)

func cleanup_enemies_array() -> void:
	# Hapus musuh yang sudah tidak valid atau tidak dalam group "enemies" (pooled)
	var invalid_enemies: Array[CharacterBody3D] = []
	
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy) or not enemy.is_in_group("enemies"):
			invalid_enemies.append(enemy)
	
	for invalid_enemy in invalid_enemies:
		enemies_in_range.erase(invalid_enemy)
	
	# Jika ada musuh yang dihapus, update target
	if invalid_enemies.size() > 0:
		print("Cleaned up ", invalid_enemies.size(), " invalid enemies")
		if current_target and (not is_instance_valid(current_target) or not current_target.is_in_group("enemies")):
			current_target = null
			update_target()


func take_damage(dmg: float) -> void:
	current_hp -= dmg
	
	if current_hp <= 0:
		destroy()

func destroy() -> void:
	tower_destroyed.emit()
	print("Tower destroyed!")
	queue_free()

func get_hp_percentage() -> float:
	return current_hp / max_hp if max_hp > 0 else 0.0

func Skill(skill_name: String) -> void:
	if current_skill_cooldown > 0:
		print("Skill on cooldown: ", current_skill_cooldown, "s remaining")
		return
	
	match skill_name:
		"overload burst":
			activate_overload_burst()
		"holy divine":
			activate_holy_divine()
		"toxic veil":
			activate_toxic_veil()
		"bloody opus":
			activeate_bloody_opus()
		"scarlet harvester":
			activate_scarlet_harvester()
		"bullet requiem":
			activate_bullet_requiem()
			print("bul req")
		"lunar blessing":
			activate_lunar_blessing()
		_:
			print("Unknown skill: ", skill_name)
			return
	
	skill_activated.emit(skill_name)
	current_skill_cooldown = skill_cooldown

func execute_skill(delta: float) -> void:
	# Base implementation - override di subclass jika skill butuh update per frame
	pass

func activate_overload_burst() -> void:
	print("Overload burst aktif!")
	var aura_scene = load("res://asset/Vfx/Effect/magic_circle_1.tscn")
	var aura_node = aura_scene.instantiate()
	altar.add_child(aura_node)
	aura_node.get_child(5).play("Kaileo_FX")
	var original_fire_rate = fire_rate
	fire_rate = original_fire_rate * 3.0  # 3x lebih cepat
	overload_burst_active = true
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		aura_node.queue_free()
		overload_burst_active = false
		fire_rate = original_fire_rate
		print("Overload burst berakhir")
	)

func activate_lunar_blessing() -> void:
	print("lunar blessing aktif")
	var aura_scene = load("res://asset/Vfx/Effect/magic_circle_3(Silvanna).tscn")
	var aura_node = aura_scene.instantiate()
	altar.add_child(aura_node)
	print(aura_node.get_child(5).name)
	aura_node.get_child(5).play("Kaileo_FX")
	var normal_damage = damage
	var damage = normal_damage * 2
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		aura_node.queue_free()
		damage = normal_damage
		print("lunar blessing berakhir")
	)

func activate_holy_divine_basic() -> void:
	print("lilitia aktif!")
	is_lilitia = true
	var orbit_scene = load("res://asset/Vfx/Effect/Divine_Ball.tscn")
	var orbit_node = orbit_scene.instantiate()
	orbit_node.damage = tower_data.damage
	orbit_node.dot_timer = tower_data.speed
	orbit_node.speed = 1
	orbit = orbit_node
	var orbit_scene2 = load("res://asset/Vfx/Effect/Divine_Ball.tscn")
	var orbit_node2 = orbit_scene2.instantiate()
	orbit_node2.damage = tower_data.damage
	orbit_node2.dot_timer = tower_data.speed
	orbit_node2.speed = 1
	orbit_node2.disabled = true
	orbit2 = orbit_node2
	orbit2.visible = false
	self.add_child(orbit_node)
	self.add_child(orbit_node2)

func activate_holy_divine() -> void:
	print("holy divine aktif!")
	var aura_scene = load("res://asset/Vfx/Effect/magic_circle_7(Lilitia).tscn")
	var aura_node = aura_scene.instantiate()
	altar.add_child(aura_node)
	print(aura_node.get_child(5).name)
	aura_node.get_child(5).play("Kaileo_FX")
	orbit2.visible = true
	orbit2.disabled = false
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		aura_node.queue_free()
		orbit2.visible = false
		orbit2.disabled = true
		print("holy divine berakhir")
	)

func activate_toxic_veil() -> void:
	print("toxic veil aktif!")
	var aura_scene = load("res://asset/Vfx/Effect/magic_circle_2(plague).tscn")
	var aura_node = aura_scene.instantiate()
	altar.add_child(aura_node)
	aura_node.get_child(5).play("Kaileo_FX")
	var veil_scene = load("res://asset/Vfx/Effect/Toxicveil.tscn")
	var veil_node:Node3D = veil_scene.instantiate()
	var area = veil_node.get_child(0).get_child(0)
	area.collision_mask = 2
	print(area.name)
	area.body_entered.connect(Callable(self, "_on_body_entered_veil"))
	area.body_exited.connect(Callable(self, "_on_body_exited_veil"))
	veil_node.position.y = -3
	self.add_child(veil_node)
	veil_node.add_child(area)
	veil_node.get_child(1).play("Toxicvwil")
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		aura_node.queue_free()
		veil_node.queue_free()
		print("Toxic Veil berakhir")
	)

func enemy_enter_veil(body:Node3D)-> void:
	print("veil trigger enemy")
	if body.is_in_group("enemies") and body is CharacterBody3D:
		var original_speed = body.move_speed
		body.move_speed = original_speed * 0.5
		print(body.name, "telah ter slow", str(body.move_speed))

func enemy_exit_veil(body:Node3D)-> void:
	if body.is_in_group("enemies") and body is CharacterBody3D:
		var original_speed = body.move_speed
		body.move_speed = original_speed * 2
		print(body.name, "telah normal", str(body.move_speed))

func activeate_bloody_opus()-> void:
	print("bloody opus aktif")
	var aura_scene = load("res://asset/Vfx/Effect/magic_circle_5(vigilante).tscn")
	var aura_node = aura_scene.instantiate()
	altar.add_child(aura_node)
	aura_node.get_child(5).play("Kaileo_FX")
	var normal_speed = fire_rate
	fire_rate = normal_speed * 2
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		aura_node.queue_free()
		fire_rate = normal_speed
		print("bloody opus berakhir")
	)

func activate_scarlet_harvester()-> void:
	var aura_scene = load("res://asset/Vfx/Effect/magic_circle_6(Leciana).tscn")
	var aura_node = aura_scene.instantiate()
	altar.add_child(aura_node)
	aura_node.get_child(5).play("Kaileo_FX")
	scarlet_harvester_active = true
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		aura_node.queue_free()
		scarlet_harvester_active = false
	)

var requiem_shot: int 
var shot_count: int 
func activate_bullet_requiem()-> void:
	var aura_scene = load("res://asset/Vfx/Effect/magic_circle_4(Rosemary).tscn")
	var aura_node = aura_scene.instantiate()
	vfx_aura = aura_node
	altar.add_child(aura_node)
	aura_node.get_child(5).play("Kaileo_FX")
	var normal_dmg = damage
	damage = normal_dmg * 2
	var normal_speed = fire_rate
	fire_rate = 1
	requiem_shot = tower_data.skill_duration
	shot_fired.connect(bullet_requiem_counter)
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		if bullet_requiem_active:
			shot_fired.disconnect(bullet_requiem_counter)
			aura_node.queue_free()
			damage = tower_data.damage
			fire_rate = tower_data.speed
			bullet_requiem_active = false
	)

func bullet_requiem_counter():
	shot_count += 1
	if shot_count >= requiem_shot and bullet_requiem_active:
		damage = tower_data.damage
		fire_rate = tower_data.speed
		shot_fired.disconnect(bullet_requiem_counter)
		vfx_aura.queue_free()



func _on_sprite_3d_animation_finished() -> void:
	print("Animation finished: ", sprite.animation)
	
	# 🎯 JIKA ANIMASI ATTACK SELESAI, KEMBALI KE IDLE
	if sprite.animation == "attack":
		is_shooting = false
		is_animation_playing = false
		sprite.play("idle")  # 🎯 KEMBALI KE IDLE YANG MUTER-MUTER
