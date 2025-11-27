extends Node
class_name Towercon

var tower_spots: Array[Area3D] = []
var selected_spot_index: int = -1
var outline_material: ShaderMaterial
var tower_input: Node = null
@onready var ui: CanvasLayer = $"../UI"
var placed_tower:Array[String]
var last_index:int

func _ready() -> void:
	outline_material = ShaderMaterial.new()
	var outline_shader = load("res://asset/Shader/outline_highlight.gdshader")
	outline_material.shader = outline_shader
	outline_material.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0, 0.196))
	outline_material.set_shader_parameter("outline_width", 0.015)
	
	collect_tower_spots()
	
	update_spot_labels()
	tower_input = get_tree().get_first_node_in_group("towerinput")

func _input(event: InputEvent) -> void:
	# Block input saat time stop
	if get_tree().root.has_meta("time_stop_active") and get_tree().root.get_meta("time_stop_active"):
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		var key_code = event.keycode
		var index = -1
		
		if key_code >= KEY_1 and key_code <= KEY_9:
			index = key_code - KEY_1
		
		elif key_code >= KEY_KP_1 and key_code <= KEY_KP_9:
			index = key_code - KEY_KP_1
		
		if index >= 0 and index < tower_spots.size():
			select_spot(index)

func collect_tower_spots() -> void:
	tower_spots.clear()
	for child in get_children():
		if child is Area3D and child.has_method("place_tower"):
			tower_spots.append(child)
			child.tower_gone.connect(tower_gone)
	
	print("Found ", tower_spots.size(), " tower spots")

func add_outline_to_spot(spot: Area3D) -> void:
	var outline_node = spot.get_node_or_null("OutlineHighlight")
	if outline_node:
		return
	var mesh_instance = spot.get_node_or_null("Altar")
	if not mesh_instance:
		return
	
	# Create outline mesh that's slightly bigger
	var outline_mesh = MeshInstance3D.new()
	outline_mesh.name = "OutlineHighlight"
	outline_mesh.mesh = mesh_instance.mesh
	outline_mesh.material_override = outline_material
	outline_mesh.position = mesh_instance.position
	outline_mesh.rotation = mesh_instance.rotation
	outline_mesh.scale = mesh_instance.scale * 1.05
	outline_mesh.position.y -= 0.001
	spot.add_child(outline_mesh)
	spot.move_child(mesh_instance, -1)

func remove_outline_from_spot(spot: Area3D) -> void:
	var outline_node = spot.get_node_or_null("OutlineHighlight")
	if outline_node:
		outline_node.queue_free()

func select_spot(index: int) -> void:
	if index < 0 or index >= tower_spots.size():
		return
	
	var new_spot = tower_spots[index]
	var old_spot = null
	
	# 🎯 1. SAVE OLD SPOT IF EXISTS
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		old_spot = tower_spots[selected_spot_index]
	
	# 🎯 2. HIDE/REMOVE FROM OLD SPOT
	if old_spot:
		if not old_spot.has_tower:
			remove_outline_from_spot(old_spot)
		else:
			old_spot.tower_node.hide_skill()
	
	# 🎯 3. UPDATE SELECTED INDEX
	selected_spot_index = index
	
	# 🎯 4. SHOW/ADD TO NEW SPOT
	AudioManager.play_sfx("spot_select")
	
	if not new_spot.has_tower:
		add_outline_to_spot(new_spot)
	else:
		new_spot.tower_node.show_skill()
	
	# 🎯 5. UPDATE TOWER INPUT
	if tower_input and tower_input.has_method("set_selected_spot"):
		tower_input.set_selected_spot(index)
	
	print("🎯 Selected: ", index, " | Had tower: ", new_spot.has_tower)

func update_spot_labels() -> void:
	for i in range(tower_spots.size()):
		var spot = tower_spots[i]
		
		var label:Label3D = spot.get_node_or_null("NumberLabel")
		
		if not label:
			label = Label3D.new()
			label.name = "NumberLabel"
			spot.add_child(label)
			label.position = Vector3(-0.5, 0.1, 0.75)
			label.pixel_size = 0.01
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		
		label.text = str(i + 1)
		label.modulate = Color.YELLOW

func place_tower_at_selected(data:TowerData) -> void:
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var spot = tower_spots[selected_spot_index]
		if !data.available:
			var msg:String = str(data.chara, " is currently on cooldown!")
			ui.show_message(msg)
			return
		for name in placed_tower:
			if name == data.chara:
				var msg:String = str(data.chara, " is already deployed!")
				ui.show_message(msg)
				return
		if spot.has_tower:
			var msg:String = str("Spot ", selected_spot_index + 1, " already has a tower!")
			ui.show_message(msg)
			return
		
		var success = spot.place_tower(data)
		if !success:
			var msg:String = str("Failed to place tower! Not enough cost or other error.")
			ui.show_message(msg)
			return
		
		# Tower placed successfully, update game state
		AudioManager.play_sfx("tower_deploy")
		placed_tower.append(data.chara)
		var msg =str("Placed ", data.chara, " tower")
		ui.show_message(msg)
		ui._on_tower_placed(data.chara)
		update_spot_labels()
		remove_outline_from_spot(spot)
		selected_spot_index = -1
		TypingSystem.clear_text()
	else:
		ui.show_message("No spot selected!")

func debuff_clear(v:String) -> void:
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var spot = tower_spots[selected_spot_index]
		if !spot.has_tower:
			var msg = str("Spot ", selected_spot_index + 1, " has no tower!")
			ui.show_message(msg)
			return
		if !spot.tower_node.got_binded:
			var msg =str(spot.tower_node.tower_data.chara," doesn't have a debuff")
			ui.show_message(msg)
		elif spot.tower_node.got_binded:
			# Check if typed word matches the debuff word
			var debuff_word = spot.tower_node.debuff_text.text.to_lower()
			if v.to_lower() == debuff_word:
				# Check if this is from BossDevil (custom bind) or regular debuff
				if spot.tower_node.has_method("remove_bind_debuff"):
					spot.tower_node.remove_bind_debuff()
					
					# Notify BossDevil that tower is cleansed
					var boss_devil = get_tree().get_first_node_in_group("boss_devil")
					if boss_devil and boss_devil.has_method("_on_tower_cleansed"):
						boss_devil._on_tower_cleansed(spot.tower_node)
				else:
					spot.tower_node.clear_bind()
				
				var msg =str(spot.tower_node.tower_data.chara, " debuff is gone")
				ui.show_message(msg)
			else:
				var msg = str("Wrong word! Type '", debuff_word.to_upper(), "'")
				ui.show_message(msg)
		#selected_spot_index = -1
		TypingSystem.clear_text()
	else:
		ui.show_message("No spot selected!")

func active_tower_at_selected(v:String) -> void:
	print("Activating skill: ", v)
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var spot = tower_spots[selected_spot_index]
		if !spot.has_tower:
			var msg = str("Spot ", selected_spot_index + 1, " has no tower!")
			ui.show_message(msg)
			return
		if spot.tower_node.current_skill_cooldown > 0 and spot.tower_data.skill == v:
			var msg =str("Skill ", v," is on cooldown")
			ui.show_message(msg)
		elif spot.tower_node.skill_active:
			var msg =str("Tower skill is already active")
			ui.show_message(msg)
		elif spot.tower_node.got_binded:
			var msg =str(spot.tower_node.tower_data.chara, " cant activate the skill because of debuff")
			ui.show_message(msg)
		elif spot.tower_data.skill == v:
			spot.tower_node.Skill(v)
			var msg =str("Activated ", v, " skill")
			ui.show_message(msg)
		else:
			ui.show_message("Wrong skill for this tower!")
		#selected_spot_index = -1
		TypingSystem.clear_text()
	else:
		ui.show_message("No spot selected!")

func delete_tower_at_selected() -> void:
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var spot = tower_spots[selected_spot_index]
		if !spot.has_tower:
			ui.show_message("This spot has no tower")
			return
		var msg =str("Removed ", spot.tower_data.chara, " tower")
		GameManager.set_tower_state(spot.tower_data,false)
		spot.remove_tower()
		AudioManager.play_sfx("tower_retreat")
		update_spot_labels()
		ui.show_message(msg)
		TypingSystem.clear_text()

func tower_gone(v:TowerData):
	ui._on_tower_gone(v)
	for name in placed_tower:
			if name == v.chara:
				placed_tower.erase(name)

func _process(_delta: float) -> void:
	pass
