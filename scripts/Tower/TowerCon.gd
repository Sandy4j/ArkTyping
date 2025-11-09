extends Node
class_name Towercon

var tower_spots: Array[Area3D] = []
var selected_spot_index: int = -1
var highlight_material: StandardMaterial3D
var tower_input: Node = null
@onready var ui: CanvasLayer = $"../UI"

func _ready() -> void:
	
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1.0, 1.0, 0.0, 0.8)
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(1.0, 1.0, 0.0)
	highlight_material.emission_energy = 0.5
	
	collect_tower_spots()
	
	update_spot_labels()
	tower_input = get_tree().get_first_node_in_group("towerinput")

func _input(event: InputEvent) -> void:
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
	
	print("Found ", tower_spots.size(), " tower spots")

func select_spot(index: int) -> void:
	if index < 0 or index >= tower_spots.size():
		return
	
	var spot = tower_spots[index]
	

	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var prev_spot = tower_spots[selected_spot_index]
		if prev_spot.mesh_instance and not prev_spot.has_tower:
			prev_spot.mesh_instance.material_override = prev_spot.default_material

	selected_spot_index = index
	if spot.mesh_instance and not spot.has_tower:
		spot.mesh_instance.material_override = highlight_material
	
	print("Selected spot ", index + 1, " - Type 'tower' to place")
	if tower_input and tower_input.has_method("set_selected_spot"):
		tower_input.set_selected_spot(index)

func update_spot_labels() -> void:
	for i in range(tower_spots.size()):
		var spot = tower_spots[i]
		
		var label = spot.get_node_or_null("NumberLabel")
		
		if not label:
			label = Label3D.new()
			label.name = "NumberLabel"
			spot.add_child(label)
			label.position = Vector3(0, 1.5, 0)
			label.pixel_size = 0.01
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		
		label.text = str(i + 1)
		label.modulate = Color.YELLOW
		if spot.has_tower:
			label.visible = false

func place_tower_at_selected(data:TowerData) -> void:
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var spot = tower_spots[selected_spot_index]
		if spot.has_tower:
			var msg:String = str("Spot ", selected_spot_index + 1, " sudah ada tower!")
			ui.show_message(msg)
			return
		spot.place_tower(data)
		var msg =str("memasang tower ", data.chara)
		ui.show_message(msg)
		update_spot_labels()
		selected_spot_index = -1
		TypingSystem.clear_text()
	else:
		ui.show_message("No spot selected!")

func active_tower_at_selected(v:String) -> void:
	print("mengaktifkan skill dengan ", v)
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var spot = tower_spots[selected_spot_index]
		if !spot.has_tower:
			var msg = str("Spot ", selected_spot_index + 1, " belum ada tower!")
			ui.show_message(msg)
		if spot.tower_data.skill == v:
			spot.tower_node.Skill(v)
			var msg =str("mengaktifkan skill ", v)
			ui.show_message(msg)
		else:
			ui.show_message("salah skill woi")
		#selected_spot_index = -1
		TypingSystem.clear_text()
	else:
		ui.show_message("No spot selected!")

func delete_tower_at_selected() -> void:
	if selected_spot_index >= 0 and selected_spot_index < tower_spots.size():
		var spot = tower_spots[selected_spot_index]
		if !spot.has_tower:
			ui.show_message("Spot ini belum ada tower")
			return
		var msg =str("menghapus tower ", spot.tower_data.chara)
		spot.remove_tower()
		update_spot_labels()
		ui.show_message(msg)
		TypingSystem.clear_text()

func _process(_delta: float) -> void:
	pass
