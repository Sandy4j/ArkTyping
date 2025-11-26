extends CanvasLayer

## Debug Menu untuk testing level selection system

@onready var panel = $Panel
@onready var unlock_all_btn = $Panel/VBoxContainer/UnlockAllBtn
@onready var reset_btn = $Panel/VBoxContainer/ResetBtn
@onready var give_3stars_btn = $Panel/VBoxContainer/Give3StarsBtn
@onready var info_label = $Panel/VBoxContainer/InfoLabel

var debug_visible: bool = false

func _ready() -> void:
	panel.visible = false
	
	unlock_all_btn.pressed.connect(_on_unlock_all_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	give_3stars_btn.pressed.connect(_on_give_3stars_pressed)
	
	_update_info()

func _input(event: InputEvent) -> void:
	# Toggle dengan F12
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			toggle_debug_menu()

func toggle_debug_menu() -> void:
	debug_visible = !debug_visible
	panel.visible = debug_visible
	
	if debug_visible:
		_update_info()

func _update_info() -> void:
	if not info_label:
		return
	
	var unlocked = SaveManager.get_unlocked_levels()
	var total_stars = SaveManager.get_total_stars()
	
	var text = "=== DEBUG INFO ===\n"
	text += "Unlocked Levels: " + str(unlocked) + "\n"
	text += "Total Stars: " + str(total_stars) + "\n\n"
	
	for i in range(1, 4):
		var stars = SaveManager.get_level_stars(i)
		var completed = SaveManager.is_level_completed(i)
		text += "Level %d: %d★ %s\n" % [i, stars, "(✓)" if completed else ""]
	
	info_label.text = text

func _on_unlock_all_pressed() -> void:
	for i in range(1, LevelManager.available_levels.size() + 1):
		SaveManager.unlock_level(i)
	_update_info()
	print("[Debug] All levels unlocked")

func _on_reset_pressed() -> void:
	SaveManager.reset_progress()
	_update_info()
	print("[Debug] Progress reset")

func _on_give_3stars_pressed() -> void:
	for i in range(1, LevelManager.available_levels.size() + 1):
		SaveManager.complete_level(i, 3)
	_update_info()
	print("[Debug] All levels completed with 3 stars")

