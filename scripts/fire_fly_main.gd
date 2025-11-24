extends Node2D
class_name FireflyManager

@export var firefly_scene: PackedScene
@export var path_node: Path2D
@export var firefly_count: int = 12
@export var move_speed: float = 50.0
@export var speed_variation: float = 15.0

var fireflies: Array = []
var firefly_data: Array = []

func _ready():
	spawn_fireflies_even_distributed()

func spawn_fireflies_even_distributed():
	# 🎯 BAGI PATH MENJADI SECTIONS YANG JAUH
	var section_size = 1.0 / firefly_count
	
	for i in range(firefly_count):
		# 🎯 POSISI DASAR DI TENGAH SETIAP SECTION
		var base_position = (i + 0.5) * section_size  # +0.5 biar di tengah section
		
		# 🎯 RANDOM OFFSET YANG TIDAK BESAR (max 25% dari section)
		var max_offset = section_size * 0.25
		var random_offset = randf_range(-max_offset, max_offset)
		var final_position = base_position + random_offset
		
		# 🎯 PASTIKAN MASIH DALAM RANGE 0-1
		final_position = wrapf(final_position, 0.0, 1.0)
		
		create_firefly_at_position(final_position, i)
		print("📐 Firefly ", i, " at position: ", final_position)

func create_firefly_at_position(position_ratio: float, index: int):
	var firefly = firefly_scene.instantiate()
	var path_follow = PathFollow2D.new()

	path_node.add_child(path_follow)
	# 🎯 SET POSISI DENGAN RATIO YANG SUDAH DICARI
	path_follow.progress_ratio = position_ratio
	path_follow.rotates = false
	path_follow.loop = true
	
	path_follow.add_child(firefly)
	
	# 🎯 SETUP DATA INDIVIDUAL
	var data = {
		"speed": move_speed + randf() * speed_variation,
		"pause_timer": 0.0,
		"is_paused": false,
		"light_energy": randf_range(0.4, 1.0),
		"flicker_speed": randf_range(0.5, 2.0)
	}
	
	fireflies.append(path_follow)
	firefly_data.append(data)
	
	setup_firefly_visual(firefly, data)
	print("✅ Firefly ", index, " spawned at position: ", position_ratio)

func setup_firefly_visual(firefly: Node2D, data: Dictionary):
	if firefly.has_node("Light2D"):
		var light = firefly.get_node("Light2D")
		light.energy = data["light_energy"]
		light.color = Color(1.0, 1.0, 0.7)  # 🎯 WARNA KUNING SOFT
	
	if firefly.has_node("Sprite2D"):
		var sprite = firefly.get_node("Sprite2D")
		sprite.modulate = Color(1.0, 1.0, 0.8, randf_range(0.7, 0.9))
		sprite.scale = Vector2(0.8, 0.8) * randf_range(0.8, 1.2)  # 🎯 SIZE VARIATION

func _process(delta):
	update_fireflies(delta)
	update_light_flicker(delta)

func update_fireflies(delta):
	for i in range(fireflies.size()):
		var firefly = fireflies[i]
		var data = firefly_data[i]
		
		if data["is_paused"]:
			data["pause_timer"] -= delta
			if data["pause_timer"] <= 0:
				data["is_paused"] = false
				data["speed"] = move_speed + randf() * speed_variation
		else:
			# 🎯 GERAK DENGAN SPEED YANG BERBEDA-BEDA
			firefly.progress += data["speed"] * delta
			
			# 🎯 RANDOM PAUSE (lebih jarang biar smooth)
			if randf() < 0.003:  # 0.3% chance per frame
				data["is_paused"] = true
				data["pause_timer"] = randf_range(1.0, 3.0)
			
			# 🎯 RANDOM SPEED CHANGE
			if randf() < 0.008:
				data["speed"] = move_speed + randf() * speed_variation
			
			# 🎯 LOOP KALAU SUDAH SAMPAI AKHIR
			if firefly.progress_ratio >= 1.0:
				firefly.progress_ratio = 0.0

func update_light_flicker(delta):
	for i in range(fireflies.size()):
		var firefly = fireflies[i]
		var data = firefly_data[i]
		
		if firefly.has_node("Light2D"):
			var light = firefly.get_node("Light2D")
			# 🎯 FLICKER EFFECT YANG NATURAL
			var flicker = sin(Time.get_ticks_msec() * 0.001 * data["flicker_speed"]) * 0.3 + 0.7
			light.energy = data["light_energy"] * flicker
