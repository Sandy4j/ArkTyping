extends Node3D

signal shot_fired
signal skill_activated(skill_name: String)

@export var tower_data: TowerData
@export var projectile_scene: PackedScene

# Stats yang akan diambil dari TowerData
var detection_range: float = 0.0
var fire_rate: float = 0.0
var damage: float = 0.0
var projectile_speed: float = 0.0
var skill_type: String = ""
var enemies_in_range: Array[CharacterBody3D] = []
var overload_burst_active:bool
var scarlet_harvester_active:bool

# Upgrade stats
@export var upgrade_cost: int = 50
var upgrade_level: int = 0

var orbit
var is_lilitia:bool
var fire_timer: float = 0.0
var current_target: CharacterBody3D = null
var skill_active: bool = false
var skill_cooldown: float = 0.0
var current_skill_cooldown: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var range_area: Area3D = $RangeArea
@onready var shoot_point: Node3D = $ShootPoint

func _ready() -> void:
	damage = tower_data.damage
	fire_rate = tower_data.speed 
	detection_range = tower_data.range
	projectile_speed = tower_data.projectile_speed 
	skill_type = tower_data.skill
	sprite.texture = tower_data.sprite
	print("Tower initialized with data: ", tower_data.chara)
	print("Damage: ", damage, " Fire Rate: ", fire_rate, " Range: ", detection_range)
	if tower_data.chara == "lilitia":
		is_lilitia = true
		activate_holy_divine_basic()
		return
	
	if range_area:
		var collision_shape = range_area.get_node("CollisionShape3D")
		if collision_shape and collision_shape.shape is SphereShape3D:
			collision_shape.shape.radius = detection_range

func _process(delta: float) -> void:
	
	fire_timer += delta
	
	# Update skill cooldown
	if current_skill_cooldown > 0:
		current_skill_cooldown -= delta
	if is_lilitia:
		return
	
	 
	
	# Find target
	#if not current_target or not is_instance_valid(current_target):
		#current_target = find_nearest_enemy()
	update_target()
	# Check if target is still in range
	#if current_target and global_position.distance_to(current_target.global_position) > detection_range:
		#current_target = null
	
	
	if current_target and fire_timer >= 1.0 / fire_rate:
		if overload_burst_active:
			overload_burst()
		elif tower_data.skill == "bloody opus" or scarlet_harvester_active:
			shoot(current_target)
			fire_timer = 0.0
			await get_tree().create_timer(0.25).timeout
			shoot(current_target)
		else:
			shoot(current_target)
		fire_timer = 0.0

func shoot(target: CharacterBody3D) -> void:
	if not projectile_scene:
		return
	
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	if shoot_point:
		projectile.global_position = shoot_point.global_position
	else:
		projectile.global_position = global_position + Vector3.UP
	
	projectile.initialize(target, damage, projectile_speed)
	shot_fired.emit()
	print("shot")

func double_shoot(target: CharacterBody3D) -> void:
	if not projectile_scene:
		return
	
	var projectile1 = projectile_scene.instantiate()
	var projectile2 = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile1)
	get_tree().current_scene.add_child(projectile2)
	if shoot_point:
		projectile1.global_position = shoot_point.global_position
		projectile2.global_position = shoot_point.global_position
	else:
		projectile1.global_position = global_position + Vector3.UP
		projectile2.global_position = global_position + Vector3.UP
	
	projectile1.initialize(target, damage, projectile_speed)
	await get_tree().create_timer(0.25).timeout
	projectile2.initialize(target, damage, projectile_speed)
	shot_fired.emit()
	print("shot")

func overload_burst() -> void:
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
	
	for i in range(targets.size()):
		var target = targets[i]
		if is_instance_valid(target):
			
			var projectile = projectile_scene.instantiate()
			get_tree().current_scene.add_child(projectile)
			
			if shoot_point:
				projectile.global_position = shoot_point.global_position
			else:
				projectile.global_position = global_position + Vector3.UP
			
			projectile.initialize(target, damage, projectile_speed)
			
	
	shot_fired.emit()
	print("Triple Shot! Hit ", targets.size(), " enemies")

func find_nearest_enemy() -> CharacterBody3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: CharacterBody3D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
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
		
		# Hapus dari array
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
	# Hapus musuh yang sudah tidak valid dari array
	var invalid_enemies: Array[CharacterBody3D] = []
	
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			invalid_enemies.append(enemy)
	
	for invalid_enemy in invalid_enemies:
		enemies_in_range.erase(invalid_enemy)
	
	# Jika ada musuh yang dihapus, update target
	if invalid_enemies.size() > 0:
		print("Cleaned up ", invalid_enemies.size(), " invalid enemies")
		if current_target and not is_instance_valid(current_target):
			current_target = null
			update_target()

func upgrade() -> bool:
	if GameManager.spend_currency(upgrade_cost):
		upgrade_level += 1
		
		damage *= 1.2
		fire_rate *= 1.1
		detection_range *= 1.1
		
		if range_area:
			var collision_shape = range_area.get_node("CollisionShape3D")
			if collision_shape and collision_shape.shape is SphereShape3D:
				collision_shape.shape.radius = detection_range
		
		print("Tower upgraded to level ", upgrade_level)
		return true
	return false

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
	var original_fire_rate = fire_rate
	fire_rate = original_fire_rate * 3.0  # 3x lebih cepat
	overload_burst_active = true
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		overload_burst_active = false
		fire_rate = original_fire_rate
		print("Overload burst berakhir")
	)

func activate_lunar_blessing() -> void:
	print("lunar blessing aktif")
	var normal_damage = damage
	var damage = normal_damage * 2
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		damage = normal_damage
		print("lunar blessing berakhir")
	)

func activate_holy_divine_basic() -> void:
	print("lilitia aktif!")
	is_lilitia = true
	var orbit_scene = load("res://scenes/orbit.tscn")
	var orbit_node = orbit_scene.instantiate()
	orbit_node.damage = tower_data.damage
	orbit_node.dot_timer = tower_data.speed
	orbit_node.speed = 1
	orbit = orbit_node
	self.add_child(orbit_node)

func activate_holy_divine() -> void:
	print("holy divine aktif!")
	orbit.modify_skill(15, 3, 0.3)
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		orbit.normalize_attack
		print("holy divine berakhir")
	)

func activate_toxic_veil() -> void:
	print("toxic veil aktif!")
	var veil_scene = load("res://scenes/slow_scene.tscn")
	var veil_node:MeshInstance3D = veil_scene.instantiate()
	var area:Area3D = veil_node.get_child(0)
	area.collision_mask = 2
	print(area.name)
	area.body_entered.connect(Callable(self, "_on_body_entered_veil"))
	area.body_exited.connect(Callable(self, "_on_body_exited_veil"))
	self.add_child(veil_node)
	veil_node.add_child(area)
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		veil_node.queue_free()
		print("holy divine berakhir")
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
	var normal_speed = fire_rate
	fire_rate = normal_speed * 2
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		fire_rate = normal_speed
		print("bloody opus berakhir")
	)

func activate_scarlet_harvester()-> void:
	scarlet_harvester_active = true
	var skill_duration = tower_data.skill_duration
	var timer = get_tree().create_timer(skill_duration)
	timer.timeout.connect(func(): 
		scarlet_harvester_active = false
	)

var requiem_shot: int 
var shot_count: int 
func activate_bullet_requiem()-> void:
	damage = 99999
	fire_rate = 1
	requiem_shot = tower_data.skill_duration
	shot_fired.connect(bullet_requiem_counter)

func bullet_requiem_counter():
	shot_count += 1
	if shot_count >= requiem_shot:
		damage = tower_data.damage
		fire_rate = tower_data.speed
		shot_fired.disconnect(bullet_requiem_counter)
