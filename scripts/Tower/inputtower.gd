extends Node
class_name TowerInput

signal Pop(v:String)
signal PopBack
var popped:bool
@export var tower_list:Array[TowerData]
@onready var inputLbl: Label = $"../TypeBox/Label"
@onready var history_box: TextureRect = $"../HistoryBox"
var HistoryLbl:Array[Node]
var count:int = 0
var TOWER_KEYWORD:Array[String]
var SKILL_KEYWORD:Array[String]
var DEBUFF_WORD:Array[String]
var selected_spot_index: int = -1

func _ready() -> void:
	HistoryLbl = history_box.get_children()
	for data in tower_list:
		TOWER_KEYWORD.append(data.chara)
		SKILL_KEYWORD.append(data.skill)
	for word in TypingSystem.debuff_text:
		DEBUFF_WORD.append(word)
	TypingSystem.text_typed.connect(_on_text_typed)
	TypingSystem.text_submitted.connect(_on_text_submitted)

func _on_text_typed(current_text: String) -> void:
	inputLbl.text = current_text
	for word in TOWER_KEYWORD:
		if current_text.to_lower() == word:
			inputLbl.add_theme_color_override("font_color", Color.GREEN)
			emit_signal("Pop",current_text)
			popped = true
			return
	for word in SKILL_KEYWORD:
		if current_text.to_lower() == word:
			inputLbl.add_theme_color_override("font_color", Color.YELLOW)
			return
	for word in TypingSystem.debuff_text:
		if current_text.to_lower() == word:
			inputLbl.add_theme_color_override("font_color", Color.GREEN)
			emit_signal("Pop",current_text)
			popped = true
			return
	if current_text == "Retreat" or current_text == "retreat":
		inputLbl.add_theme_color_override("font_color", Color.RED)
		return
	else:
		inputLbl.add_theme_color_override("font_color", Color.WHITE)
		if popped:
			emit_signal("PopBack")
			popped = false
	

func _on_text_submitted(full_text: String) -> void:	
	var typed_text = full_text.to_lower().strip_edges()
	for word in TOWER_KEYWORD:
		if typed_text == word:
			if selected_spot_index >= 0:
				request_tower_placement(typed_text)
				print("Spot yang kepilih: ", selected_spot_index + 1)
				HIstory_add(typed_text,Color.GREEN)
				AudioManager.play_sfx("type_correct")
				inputLbl.text = ""
				return
			else:
				print("Spot belum dipilih bro.")
				show_message("Pilih spot dulu! Tekan 1-9")
				AudioManager.play_sfx("type_wrong")
				return
	for word in DEBUFF_WORD:
		if typed_text == word:
			if selected_spot_index >= 0:
				request_tower_debuff_clear(typed_text)
				HIstory_add(typed_text,Color.GREEN)
				AudioManager.play_sfx("type_correct")
				inputLbl.text = ""
				return
			else:
				print("Spot belum dipilih bro.")
				show_message("Pilih spot dulu! Tekan 1-9")
				AudioManager.play_sfx("type_wrong")
				return
	for word in SKILL_KEYWORD:
		if typed_text == word:
			if selected_spot_index >= 0:
				request_tower_skill(typed_text)
				print("Mengaktifkan skill di slot: ", selected_spot_index + 1)
				HIstory_add(typed_text,Color.GREEN)
				AudioManager.play_sfx("type_correct")
				inputLbl.text = ""
				return
			else:
				print("Spot belum dipilih bro.")
				show_message("Pilih spot dulu! Tekan 1-9")
				AudioManager.play_sfx("type_wrong")
				return
	if typed_text == "retreat":
		if selected_spot_index >= 0:
			request_delete_tower()
			print("Hapus Tower di slot: ", selected_spot_index + 1)
			HIstory_add(typed_text,Color.GREEN)
			AudioManager.play_sfx("type_correct")
			inputLbl.text = ""
			return
		else:
			print("Spot belum dipilih bro.")
			show_message("Pilih spot dulu! Tekan 1-9")
			AudioManager.play_sfx("type_wrong")
			return
			
	else:
		HIstory_add(typed_text,Color.RED)
		AudioManager.play_sfx("type_wrong")
		print("Input Salah Woi.")
	inputLbl.text = ""

func set_selected_spot(index: int) -> void:
	selected_spot_index = index

func request_tower_debuff_clear(v:String) -> void:
	var tower_controller = get_tree().get_first_node_in_group("towercon")
	if tower_controller and tower_controller.has_method("debuff_clear"):
		tower_controller.debuff_clear(v)
	else:
		print("TowerController not found!")

func request_tower_placement(v:String) -> void:
	var data:TowerData
	for datas in tower_list:
		if datas.chara == v:
			data = datas
	
	var tower_controller = get_tree().get_first_node_in_group("towercon")
	if tower_controller and tower_controller.has_method("place_tower_at_selected"):
		tower_controller.place_tower_at_selected(data)
	else:
		print("TowerController not found!")

func request_tower_skill(v:String) -> void:
	var tower_controller = get_tree().get_first_node_in_group("towercon")
	if tower_controller and tower_controller.has_method("active_tower_at_selected"):
		tower_controller.active_tower_at_selected(v)
	else:
		print("TowerController not found!")

func request_delete_tower() ->void:
	
	var tower_controller = get_tree().get_first_node_in_group("towercon")
	if tower_controller and tower_controller.has_method("delete_tower_at_selected"):
		tower_controller.delete_tower_at_selected()
	else:
		print("TowerController not found!")

func HIstory_add(v:String, cl:Color):
	if count < 3:
		count += 1
	
	match count:
		1:
			HistoryLbl[0].text = v
			HistoryLbl[0].modulate = cl
			
		2:
			HistoryLbl[1].text = HistoryLbl[0].text
			HistoryLbl[1].modulate = HistoryLbl[0].modulate
			HistoryLbl[0].text = v
			HistoryLbl[0].modulate = cl
			
		3:
			HistoryLbl[2].text = HistoryLbl[1].text
			HistoryLbl[2].modulate = HistoryLbl[1].modulate
			HistoryLbl[1].text = HistoryLbl[0].text
			HistoryLbl[1].modulate = HistoryLbl[0].modulate
			HistoryLbl[0].text = v
			HistoryLbl[0].modulate = cl

func show_message(msg: String) -> void:
	var ui = get_node_or_null("../")
	if ui and ui.has_method("show_message"):
		ui.show_message(msg)
	else:
		print("UI node not found, message: ", msg)
