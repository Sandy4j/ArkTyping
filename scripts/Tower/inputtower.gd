extends Node
class_name TowerInput

@onready var inputLbl: Label = $TxtPanel/Label

const TOWER_KEYWORD: String = "tower"
var selected_spot_index: int = -1

func _ready() -> void:
	TypingSystem.text_typed.connect(_on_text_typed)
	TypingSystem.text_submitted.connect(_on_text_submitted)

func _on_text_typed(current_text: String) -> void:
	inputLbl.text = current_text
	
	if current_text.to_lower() == TOWER_KEYWORD:
		inputLbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		inputLbl.add_theme_color_override("font_color", Color.WHITE)
	
func _on_text_submitted(full_text: String) -> void:	
	var typed_text = full_text.to_lower().strip_edges()
	
	if typed_text == TOWER_KEYWORD:
		if selected_spot_index >= 0:
			request_tower_placement()
			print("Spot yang kepilih: ", selected_spot_index + 1)
		else:
			print("Spot belum dipilih bro.")
	else:
		print("Input Salah Woi.")
	
	inputLbl.text = ""

func set_selected_spot(index: int) -> void:
	selected_spot_index = index

func request_tower_placement() -> void:
	var tower_controller = get_tree().get_first_node_in_group("towercon")
	if tower_controller and tower_controller.has_method("place_tower_at_selected"):
		tower_controller.place_tower_at_selected()
	else:
		print("TowerController not found!")
