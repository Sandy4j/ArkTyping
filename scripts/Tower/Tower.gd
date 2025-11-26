extends Node3D

signal shot_fired
signal skill_activated(skill_name: String)
signal tower_destroyed
signal skill_done
@export var tower_data: TowerData

# Stats yang akan diambil dari TowerData
var detection_range: float = 0.0
var fire_rate: float = 0.0
var damage: float = 0.0
var projectile_speed: float = 0.0
var projectile: PackedScene = null
var skill_type: String = ""
var enemies_in_range: Array[CharacterBody3D] = []
var tower_in_range: Array[Node3D] = []
var overload_burst_active:bool
var scarlet_harvester_active:bool
var bullet_requiem_active:bool
var purify_wave_active:bool
var max_hp: float = 100.0
var current_hp: float = 100.0
var skill_duration:float
var vfx_node
var vfx_shoot
var vfx_aura
var orbit
var orbit2
var got_binded:bool
var is_healer:bool
var is_lilitia:bool
var is_kaelio:bool
var is_rosemary:bool
var fire_timer: float = 0.0
var current_target: CharacterBody3D = null
var healing_target: Node3D = null
var skill_active: bool = false
var skill_cooldown: float = 0.0
var current_skill_cooldown: float = 0.0
var is_shooting:bool
var is_animation_playing: bool = false
@onready var sprite: AnimatedSprite3D = $Sprite3D
@onready var range_area: Area3D = $RangeArea
@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer
@onready var shoot_point: Node3D = $ShootPoint
@onready var skill_sprite: Sprite3D = $SkillSprite
@onready var HPBar: ProgressBar = $SubViewport/TextureProgressBar
@onready var SBar: ProgressBar = $SubViewport2/TextureProgressBar
@onready var aoe: MeshInstance3D = $Aoe
@onready var debuff_text: Label3D = $Label3D
var debuff_aura
var altar
var stylefill:StyleBoxFlat
var mesh_aoe:CylinderMesh

func _ready() -> void:
	debuff_text.visible = false
	var temp_stylebox = SBar.get_theme_stylebox("fill")
	stylefill = temp_stylebox.duplicate()
	SBar.add_theme_stylebox_override("fill", stylefill)
	var temp_mesh = aoe.mesh
	mesh_aoe = temp_mesh.duplicate()  
	aoe.mesh = mesh_aoe
	var range_shape:CollisionShape3D = range_area.get_node("CollisionShape3D")
	var collision_shape:SphereShape3D = range_shape.shape.duplicate()
	sfx.stream = tower_data.atk_sfx
	shot_fired.connect(after_shoot)
	damage = tower_data.damage
	fire_rate = tower_data.speed 
	detection_range = tower_data.range
	projectile_speed = tower_data.projectile_speed 
	skill_type = tower_data.skill
	if tower_data.projectile:
		projectile = tower_data.projectile
		print("load projectile")
	max_hp = tower_data.max_hp
	HPBar.max_value = max_hp
	skill_cooldown = tower_data.cooldown
	SBar.max_value = skill_cooldown
	SBar.value = current_skill_cooldown
	stylefill.bg_color = Color("DAC41E")
	current_hp = max_hp
	HPBar.value = current_hp
	sprite.sprite_frames = tower_data.sprite
	skill_sprite.texture = tower_data.skill_sprite
	print("Tower initialized with data: ", tower_data.chara)
	print("Damage: ", damage, " Fire Rate: ", fire_rate, " Range: ", detection_range, " HP: ", max_hp)
	
	add_to_group("tower")
	match tower_data.chara:
			"lilitia":
				is_lilitia = true
				activate_holy_divine_basic()
			"kaelio":
				is_kaelio = true
				var vfx_scene = ResourceLoadManager.get_cached_resource("res://asset/Vfx/Effect/Shoot.tscn")
				if not vfx_scene:
					vfx_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/Shoot.tscn")
				if vfx_scene:
					var vfx_node = vfx_scene.instantiate()
					self.add_child(vfx_node)
					var light:OmniLight3D = vfx_node.get_child(3)
					light.light_energy = 0
					vfx_shoot = vfx_node.get_child(4)
			"rosemary":
				is_rosemary = true
				var vfx_scene = ResourceLoadManager.get_cached_resource("res://asset/Vfx/Effect/gun_Rosemary.tscn")
				if not vfx_scene:
					vfx_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/gun_Rosemary.tscn")
				if vfx_scene:
					var vfx_node = vfx_scene.instantiate()
					self.add_child(vfx_node)
					var light:OmniLight3D = vfx_node.get_child(3)
					light.light_energy = 0
					vfx_shoot = vfx_node.get_child(4)
			"cellene":
				is_healer = true
			"priestess":
				is_healer = true
	
	if range_area and is_healer:
		print("healer masuk")
		collision_shape.radius = detection_range
		mesh_aoe.top_radius = detection_range
		#range_shape.shape.radius = 0.1
		range_shape.shape = collision_shape
	elif range_area and tower_data.chara != "lilitia" :
		collision_shape.radius = detection_range
		mesh_aoe.top_radius = detection_range
		range_shape.shape = collision_shape
	else :
		collision_shape.radius = 0.1
		mesh_aoe.top_radius = 0.1
		range_shape.shape = collision_shape
	current_skill_cooldown = skill_cooldown
	sprite.play("default")
	hide_skill()

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	
	if current_skill_cooldown > 0 or skill_active and !bullet_requiem_active :
		execute_skill(delta)
	if got_binded:
		return
	fire_timer += delta
	
	update_animation()
	if is_lilitia:
		return
	if is_healer:
		update_healing_target()
		update_sprite_direction()
		if healing_target and is_instance_valid(healing_target) and fire_timer >= 1.0 / fire_rate:
			if purify_wave_active:
				purify_wave()
				fire_timer = 0.0
				return
			healing()
			fire_timer = 0.0
		return
	
	update_target()
	update_sprite_direction()
	# Shoot at target
	if current_target and is_instance_valid(current_target) and current_target.is_in_group("enemies") and fire_timer >= 1.0 / fire_rate:
		is_shooting = true
		sfx.play()
		if is_kaelio and overload_burst_active or is_rosemary:
			vfx_shoot.play("gun")
		elif is_kaelio:
			vfx_shoot.play("gun_slow")
		if overload_burst_active:
			overload_burst()
		elif scarlet_harvester_active:
			scarlet_harvester()
		elif tower_data.skill == "bloody opus":
			double_shoot(current_target)
		else:
			shoot(current_target)
		fire_timer = 0.0

func update_sprite_direction():
	if not sprite:
		return
	
	# 🎯 JIKA ADA TARGET, FLIP BERDASARKAN POSISI TARGET
	if current_target and is_instance_valid(current_target):
		var target_position = current_target.global_position
		var tower_position = global_position
		
		# 🎯 CEK APAKAH TARGET DI KIRI ATAU KANAN
		if target_position.x < tower_position.x:
			sprite.flip_h = true
		else:
			sprite.flip_h = false

func update_animation():
	if is_shooting:
		if sprite.animation != "attack":
			sprite.play("attack")
	else:
		if sprite.animation != "default":
			sprite.play("default")

func binded():
	if got_binded:
		return
	sprite.stop()
	got_binded = true
	var aura_scene = ResourceLoadManager.get_vfx_resource("binded")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/debuff_bind.tscn")
	var aura_node = aura_scene.instantiate()
	altar.add_child(aura_node)
	debuff_aura = aura_node
	var anim = aura_node.get_node("AnimationPlayer")
	anim.play("bind")
	debuff_text.text = TypingSystem.debuff_text.pick_random()
	debuff_text.visible = true

func clear_bind():
	got_binded = false
	debuff_aura.queue_free()
	debuff_text.visible = false

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
	if not projectile:
		return
	
	var pool_key = PoolSetup.register_tower_projectile_pool(tower_data)
	if pool_key == "":
		pool_key = "tower_projectile_" + tower_data.chara
	
	var projectile = ObjectPool.get_pooled_object(pool_key)
	
	if not projectile:
		projectile = projectile.instantiate()
	else:
		projectile.pool_name = pool_key
	get_tree().current_scene.add_child(projectile)

	if shoot_point:
		projectile.global_position = shoot_point.global_position
	else:
		projectile.global_position = global_position + Vector3.UP
	projectile.initialize(target, damage, projectile_speed)
	shot_fired.emit()
	#print("shot")

func double_shoot(target: CharacterBody3D) -> void:
	if is_animation_playing:
		return
	
	is_shooting = true
	is_animation_playing = true
	
	sprite.stop()
	sprite.play("attack")
	
	if not projectile:
		return
	
	var pool_key = "tower_projectile_" + tower_data.chara
	
	for i in 2:
		if is_instance_valid(target):
			var projectile = ObjectPool.get_pooled_object(pool_key)
			if not projectile:
				projectile = projectile.instantiate()
			else:
				projectile.pool_name = pool_key
			
			get_tree().current_scene.add_child(projectile)
			
			if shoot_point:
				projectile.global_position = shoot_point.global_position
			else:
				projectile.global_position = global_position + Vector3.UP
			
			projectile.initialize(target, damage, projectile_speed)
			if i == 0:
				await get_tree().create_timer(0.25).timeout
			
	shot_fired.emit()
	print("shot")

func overload_burst() -> void:
	if is_animation_playing:
		return
	
	is_shooting = true
	is_animation_playing = true
	
	sprite.stop()
	
	sprite.play("attack")
	
	if not projectile:
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
				projectile = projectile.instantiate()
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
	if not projectile:
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
	
	var pool_key = "tower_projectile_" + tower_data.chara
	
	for i in range(targets.size()):
		var target = targets[i]
		if is_instance_valid(target):
			var proj = ObjectPool.get_pooled_object(pool_key)
			
			if not proj:
				proj = projectile.instantiate()
			else:
				proj.pool_name = pool_key
			
			get_tree().current_scene.add_child(proj)
			
			if shoot_point:
				proj.global_position = shoot_point.global_position
			else:
				proj.global_position = global_position + Vector3.UP
			
			proj.initialize(target, damage, projectile_speed)
	
	shot_fired.emit()

func healing()-> void:
	is_shooting = true
	is_animation_playing = true
	
	# 🎯 STOP ANIMASI IDLE DULU
	sprite.stop()
	sfx.play()
	# 🎯 PLAY ANIMASI ATTACK
	sprite.play("attack")
	if healing_target.current_hp == healing_target.max_hp:
		return
	else :
		var aura = projectile.instantiate()
		healing_target.healed(damage, aura)
		print(tower_data.chara, " melakukan heal pada ", healing_target.tower_data.chara)


func purify_wave()-> void:
	is_shooting = true
	is_animation_playing = true
	
	# 🎯 STOP ANIMASI IDLE DULU
	sprite.stop()
	
	# 🎯 PLAY ANIMASI ATTACK
	sprite.play("attack")
	sfx.play()
	for tower in tower_in_range:
		healing_target = tower
		if healing_target.current_hp == healing_target.max_hp:
			return
		else :
			var aura = ResourceLoadManager.get_vfx_resource("heal_priest")
			healing_target.healed(damage, aura)
			print(tower_data.chara, " melakukan heal pada ", healing_target.tower_data.chara)
	shot_fired.emit()

func show_skill():
	skill_sprite.visible = true

func hide_skill():
	skill_sprite.visible = false

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
		
		if not enemy in enemies_in_range:
			enemies_in_range.append(enemy)
			#print(tower_data.chara, "Enemy entered range. Total enemies: ", enemies_in_range.size())
			
			if not current_target:
				current_target = enemy
				#print(tower_data.chara, " New target set: ", enemy.name)

func _on_enemy_exited_range(body: Node3D) -> void:
	# Cek jika body adalah musuh
	if body.is_in_group("enemies") and body is CharacterBody3D:
		var enemy = body as CharacterBody3D
		
		# Hapus musuh dari array
		if enemy in enemies_in_range:
			enemies_in_range.erase(enemy)
			#print(tower_data.chara, " Enemy exited range. Total enemies: ", enemies_in_range.size())
		
		if enemy == current_target:
			current_target = null
			update_target()

func update_target() -> void:
	cleanup_enemies_array()
	
	if not current_target and enemies_in_range.size() > 0:
		# Pilih musuh pertama dalam array (yang pertama masuk)
		current_target = enemies_in_range[0]
		#print(tower_data.chara, " Target updated to first enemy in range: ", current_target.name)
	
	elif current_target and (not is_instance_valid(current_target) or not current_target in enemies_in_range):
		current_target = null
		if enemies_in_range.size() > 0:
			current_target = enemies_in_range[0]
			print(tower_data.chara, " Target reacquired: ", current_target.name)

func cleanup_enemies_array() -> void:
	# Hapus musuh yang sudah tidak valid atau tidak dalam group "enemies" (pooled)
	var invalid_enemies: Array[CharacterBody3D] = []
	
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy) or not enemy.is_in_group("enemies"):
			invalid_enemies.append(enemy)
	
	for invalid_enemy in invalid_enemies:
		enemies_in_range.erase(invalid_enemy)
	
	if invalid_enemies.size() > 0:
		print("Cleaned up ", invalid_enemies.size(), " invalid enemies")
		if current_target and (not is_instance_valid(current_target) or not current_target.is_in_group("enemies")):
			current_target = null
			update_target()

func update_healing_target():
	cleanup_tower_array()
	var near_tower = range_area.get_overlapping_areas()
	
	for area in near_tower:
		if area.has_method("place_tower"):
			if area.has_tower:
				tower_in_range.append(area.tower_node)
		#if area.get_parent().is_in_group("tower"):
			#tower_in_range.append(area.get_parent())
			#print("terdeteksi ", area.get_parent().tower_data.chara)
		#print(area.get_parent().name, " masuk ke range healer")
	
	if tower_in_range.size() <= 0:
		return
	var lowest_hp = INF
	
	for tower in tower_in_range:
		if not is_instance_valid(tower) or tower.current_hp == tower.max_hp:
			continue
			
		if tower.current_hp < lowest_hp:
			lowest_hp = tower.current_hp
			healing_target = tower

func cleanup_tower_array() -> void:
	var invalid_towers: Array[Node3D] = []
	
	for tower in tower_in_range:
		if not is_instance_valid(tower) or not tower.is_in_group("tower"):
			invalid_towers.append(tower)
	
	for invalid_tower in invalid_towers:
		tower_in_range.erase(invalid_tower)
	
	if invalid_towers.size() > 0:
		print("Cleaned up ", invalid_towers.size(), " invalid enemies")
		if healing_target and (not is_instance_valid(healing_target) or not healing_target.is_in_group("tower")):
			healing_target = null
			update_healing_target()

func take_damage(dmg: float) -> void:
	if !got_binded:
		binded()
	current_hp -= dmg
	HPBar.value = current_hp
	var vfx_sc = ResourceLoadManager.get_vfx_resource("hit_tower")
	if not vfx_sc:
		vfx_sc = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/hit_Tower.tscn")
	if vfx_sc:
		var vfx_nd = vfx_sc.instantiate()
		self.add_child(vfx_nd)
	if current_hp <= 0:
		if is_instance_valid(debuff_aura):
			debuff_aura.queue_free()
		destroy()


func destroy() -> void:
	AudioManager.play_sfx("tower_dead")
	tower_destroyed.emit()
	print("Tower destroyed!")

func healed(heal: float, aura:Node3D) -> void:
	print(tower_data.chara, " kena heal ", str(heal))
	current_hp += heal
	if current_hp > max_hp:
		current_hp = max_hp
	HPBar.value = current_hp
	altar.add_child(aura)
	var anim = aura.get_node("AnimationPlayer")
	anim.play("healaura")
	await anim.animation_finished
	aura.queue_free()

func get_hp_percentage() -> float:
	return current_hp / max_hp if max_hp > 0 else 0.0

func Skill(skill_name: String) -> void:
	if current_skill_cooldown > 0 or skill_active:
		print("Skill on cooldown: ", current_skill_cooldown, "s remaining")
		return
	AudioManager.play_sfx("tower_skill")
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
		"unholy bless":
			active_unholy_bless()
		"purify wave":
			activate_purify_wave()
		_:
			print("Unknown skill: ", skill_name)
			return
	if tower_data.skl_sfx:
		sfx.stream = tower_data.skl_sfx
	SBar.max_value = tower_data.skill_duration
	skill_duration = tower_data.skill_duration
	SBar.value = skill_duration
	skill_active = true
	skill_activated.emit(skill_name)
	#current_skill_cooldown = skill_cooldown

func execute_skill(delta: float) -> void:
	if skill_active and !is_rosemary:
		skill_duration -= delta
		SBar.value = skill_duration
		if skill_duration < 0:
			skill_active = false
			SBar.max_value = skill_cooldown
			current_skill_cooldown = skill_cooldown
			stylefill.bg_color = Color("DAC41E")
			skill_sprite.modulate = Color(0.5,0.5,0.5,1.0)
			skill_done.emit()
		#DAC41E warna cooldown
		#1E9CDA warna full
	else:
		current_skill_cooldown -= delta
		var val = skill_cooldown - current_skill_cooldown
		SBar.value = val
		if current_skill_cooldown < 0:
			stylefill.bg_color = Color("1E9CDA")
			skill_sprite.modulate = Color(1.0,1.0,1.0,1.0)

func activate_overload_burst() -> void:
	print("Overload burst aktif!")
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_1")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_1.tscn")
	if aura_scene:
		var aura_node = aura_scene.instantiate()
		altar.add_child(aura_node)
		aura_node.get_child(5).play("Kaileo_FX")
		var original_fire_rate = fire_rate
		fire_rate = 1.0
		overload_burst_active = true
		await skill_done 
		aura_node.queue_free()
		sfx.stream = tower_data.atk_sfx
		overload_burst_active = false
		fire_rate = original_fire_rate
		print("Overload burst berakhir")
		

func activate_lunar_blessing() -> void:
	print("lunar blessing aktif")
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_3")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_3(Silvanna).tscn")
	if aura_scene:
		var aura_node = aura_scene.instantiate()
		altar.add_child(aura_node)
		print(aura_node.get_child(5).name)
		aura_node.get_child(5).play("Kaileo_FX")
		var normal_damage = damage
		damage = normal_damage * 2
		await skill_done  
		sfx.stream = tower_data.atk_sfx
		aura_node.queue_free()
		damage = normal_damage
		print("lunar blessing berakhir")

func activate_holy_divine_basic() -> void:
	print("lilitia aktif!")
	is_lilitia = true
	var orbit_scene = ResourceLoadManager.get_vfx_resource("divine_ball")
	if not orbit_scene:
		orbit_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/Divine_Ball.tscn")
	if orbit_scene:
		var orbit_node = orbit_scene.instantiate()
		orbit_node.damage = tower_data.damage
		orbit_node.dot_timer = tower_data.speed
		orbit_node.speed = 1
		orbit = orbit_node
		var orbit_scene2 = orbit_scene  # Reuse same scene
		var orbit_node2 = orbit_scene2.instantiate()
		orbit_node2.damage = tower_data.damage
		orbit_node2.dot_timer = tower_data.speed
		orbit_node2.speed = 1
		orbit_node2.disabled = true
		orbit2 = orbit_node2
		orbit2.visible = false
		self.add_child(orbit_node)
		orbit_node.sfx.stream = tower_data.atk_sfx
		self.add_child(orbit_node2)
		orbit_node2.sfx.stream = tower_data.atk_sfx

func activate_holy_divine() -> void:
	print("holy divine aktif!")
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_7")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_7(Lilitia).tscn")
	if aura_scene:
		var aura_node = aura_scene.instantiate()
		altar.add_child(aura_node)
		print(aura_node.get_child(5).name)
		aura_node.get_child(5).play("Kaileo_FX")
		orbit2.visible = true
		orbit2.disabled = false
		await skill_done 
		aura_node.queue_free()
		orbit2.visible = false
		orbit2.disabled = true
		print("holy divine berakhir")
		

func activate_toxic_veil() -> void:
	print("toxic veil aktif!")
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_2")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_2(plague).tscn")
	var veil_scene = ResourceLoadManager.get_vfx_resource("toxic_veil")
	if not veil_scene:
		veil_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/Toxicveil.tscn")
	
	if aura_scene and veil_scene:
		var aura_node = aura_scene.instantiate()
		altar.add_child(aura_node)
		aura_node.get_child(5).play("Kaileo_FX")
		var veil_node:Node3D = veil_scene.instantiate()
		var area = veil_node.get_child(0).get_child(0)
		print(area.name)
		area.body_entered.connect(Callable(self, "enemy_enter_veil"))
		area.body_exited.connect(Callable(self, "enemy_exit_veil"))
		veil_node.position.y = -3
		self.add_child(veil_node)
		veil_node.get_child(1).play("Toxicvwil")
		await skill_done  
		sfx.stream = tower_data.atk_sfx
		aura_node.queue_free()
		veil_node.queue_free()
		print("Toxic Veil berakhir")
		

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
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_5")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_5(vigilante).tscn")
	if aura_scene:
		var aura_node = aura_scene.instantiate()
		altar.add_child(aura_node)
		aura_node.get_child(5).play("Kaileo_FX")
		var normal_speed = fire_rate
		fire_rate = normal_speed * 2
		await skill_done 
		aura_node.queue_free()
		fire_rate = normal_speed
		print("bloody opus berakhir")
		

func activate_scarlet_harvester()-> void:
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_6")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_6(Leciana).tscn")
	if aura_scene:
		var aura_node = aura_scene.instantiate()
		altar.add_child(aura_node)
		aura_node.get_child(5).play("Kaileo_FX")
		scarlet_harvester_active = true
		await skill_done 
		sfx.stream = tower_data.atk_sfx
		aura_node.queue_free()
		scarlet_harvester_active = false
		

var requiem_shot: int  
func activate_bullet_requiem()-> void:
	requiem_shot = tower_data.skill_duration
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_4")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_4(Rosemary).tscn")
	if aura_scene:
		bullet_requiem_active = true
		var aura_node = aura_scene.instantiate()
		vfx_aura = aura_node
		altar.add_child(aura_node)
		aura_node.get_child(5).play("Kaileo_FX")
		var normal_dmg = damage
		damage = normal_dmg * 2
		var normal_speed = fire_rate
		fire_rate = 1
		SBar.max_value = tower_data.skill_duration
		SBar.value = tower_data.skill_duration
		shot_fired.connect(bullet_requiem_counter)

func bullet_requiem_counter():
	requiem_shot -= 1
	print("req ", str(requiem_shot))
	SBar.value = requiem_shot
	if requiem_shot <= 0 and bullet_requiem_active:
		skill_active = false
		SBar.max_value = skill_cooldown
		current_skill_cooldown = skill_cooldown
		stylefill.bg_color = Color("DAC41E")
		skill_sprite.modulate = Color(0.5,0.5,0.5,1.0)
		skill_done.emit()
		sfx.stream = tower_data.atk_sfx
		damage = tower_data.damage
		fire_rate = tower_data.speed
		shot_fired.disconnect(bullet_requiem_counter)
		vfx_aura.queue_free()

func active_unholy_bless()-> void:
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_9")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_9.tscn")
	if aura_scene:
		var aura_node = aura_scene.instantiate()
		altar.add_child(aura_node)
		print(aura_node.get_child(5).name)
		aura_node.get_child(5).play("Kaileo_FX")
		var normal_damage = damage
		damage = normal_damage * 2
		await skill_done  
		sfx.stream = tower_data.atk_sfx
		aura_node.queue_free()
		damage = normal_damage
		print("lunar blessing berakhir")

var purify: int  
func activate_purify_wave()-> void:
	purify = tower_data.skill_duration
	var aura_scene = ResourceLoadManager.get_vfx_resource("magic_circle_8")
	if not aura_scene:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/magic_circle_8.tscn")
	if aura_scene:
		purify_wave_active = true
		var aura_node = aura_scene.instantiate()
		vfx_aura = aura_node
		altar.add_child(aura_node)
		aura_node.get_child(5).play("Kaileo_FX")
		var normal_dmg = damage
		damage = normal_dmg * 2
		var normal_speed = fire_rate
		fire_rate = 1
		SBar.max_value = tower_data.skill_duration
		SBar.value = tower_data.skill_duration
		shot_fired.connect(purify_wave_counter)

func purify_wave_counter():
	purify -= 1
	print("req ", str(purify))
	SBar.value = purify
	if purify <= 0 and purify_wave_active:
		skill_active = false
		SBar.max_value = skill_cooldown
		current_skill_cooldown = skill_cooldown
		stylefill.bg_color = Color("DAC41E")
		skill_sprite.modulate = Color(0.5,0.5,0.5,1.0)
		skill_done.emit()
		sfx.stream = tower_data.atk_sfx
		damage = tower_data.damage
		fire_rate = tower_data.speed
		shot_fired.disconnect(purify_wave_counter)
		vfx_aura.queue_free()

func _on_sprite_3d_animation_finished() -> void:
	#print("Animation finished: ", sprite.animation)
	
	# 🎯 JIKA ANIMASI ATTACK SELESAI, KEMBALI KE IDLE
	if sprite.animation == "attack":
		is_shooting = false
		is_animation_playing = false
		sprite.play("idle")  # 🎯 KEMBALI KE IDLE YANG MUTER-MUTER
