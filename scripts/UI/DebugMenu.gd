extends CanvasLayer

## Comprehensive Debug Menu for testing and cheats

@onready var panel = $Panel
@onready var scroll = $Panel/ScrollContainer
@onready var container = $Panel/ScrollContainer/VBoxContainer
@onready var info_label = $Panel/ScrollContainer/VBoxContainer/InfoLabel

# Debug flags
var debug_visible: bool = false
var godmode_enabled: bool = false
var instant_kill_enabled: bool = false

func _ready() -> void:
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_connect_buttons()
	_set_buttons_disabled(true)
	_update_info()

func _connect_buttons() -> void:
	# Level buttons
	var unlock_btn = $Panel/ScrollContainer/VBoxContainer/UnlockAllBtn
	var give3stars_btn = $Panel/ScrollContainer/VBoxContainer/Give3StarsBtn
	var reset_btn = $Panel/ScrollContainer/VBoxContainer/ResetBtn
	var add_currency_btn = $Panel/ScrollContainer/VBoxContainer/Add100CurrencyBtn
	var godmode_btn = $Panel/ScrollContainer/VBoxContainer/GodmodeBtn
	var heal_base_btn = $Panel/ScrollContainer/VBoxContainer/HealBaseBtn
	var kill_enemies_btn = $Panel/ScrollContainer/VBoxContainer/KillAllEnemiesBtn
	var instant_kill_btn = $Panel/ScrollContainer/VBoxContainer/InstantKillBtn
	var win_btn = $Panel/ScrollContainer/VBoxContainer/WinLevelBtn
	var skip_wave_btn = $Panel/ScrollContainer/VBoxContainer/SkipWaveBtn
	
	if unlock_btn.pressed.is_connected(_on_unlock_all_pressed):
		unlock_btn.pressed.disconnect(_on_unlock_all_pressed)
	if give3stars_btn.pressed.is_connected(_on_give_3stars_pressed):
		give3stars_btn.pressed.disconnect(_on_give_3stars_pressed)
	if reset_btn.pressed.is_connected(_on_reset_pressed):
		reset_btn.pressed.disconnect(_on_reset_pressed)
	if add_currency_btn.pressed.is_connected(_on_add_100_currency):
		add_currency_btn.pressed.disconnect(_on_add_100_currency)
	if godmode_btn.pressed.is_connected(_on_toggle_godmode):
		godmode_btn.pressed.disconnect(_on_toggle_godmode)
	if heal_base_btn.pressed.is_connected(_on_heal_base):
		heal_base_btn.pressed.disconnect(_on_heal_base)
	if kill_enemies_btn.pressed.is_connected(_on_kill_all_enemies):
		kill_enemies_btn.pressed.disconnect(_on_kill_all_enemies)
	if instant_kill_btn.pressed.is_connected(_on_toggle_instant_kill):
		instant_kill_btn.pressed.disconnect(_on_toggle_instant_kill)
	if win_btn.pressed.is_connected(_on_win_level):
		win_btn.pressed.disconnect(_on_win_level)
	if skip_wave_btn.pressed.is_connected(_on_skip_wave):
		skip_wave_btn.pressed.disconnect(_on_skip_wave)
	
	unlock_btn.pressed.connect(_on_unlock_all_pressed)
	give3stars_btn.pressed.connect(_on_give_3stars_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	add_currency_btn.pressed.connect(_on_add_100_currency)
	godmode_btn.pressed.connect(_on_toggle_godmode)
	heal_base_btn.pressed.connect(_on_heal_base)
	kill_enemies_btn.pressed.connect(_on_kill_all_enemies)
	instant_kill_btn.pressed.connect(_on_toggle_instant_kill)
	win_btn.pressed.connect(_on_win_level)
	skip_wave_btn.pressed.connect(_on_skip_wave)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			toggle_debug_menu()

func _process(_delta: float) -> void:	
	if godmode_enabled and GameManager.base_reference:
		GameManager.base_reference.current_hp = GameManager.base_reference.max_hp

func toggle_debug_menu() -> void:
	debug_visible = !debug_visible
	panel.visible = debug_visible
	if debug_visible:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_buttons_disabled(false)
		_update_info()
	else:
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_buttons_disabled(true)

func _set_buttons_disabled(disabled: bool) -> void:
	var buttons = [
		$Panel/ScrollContainer/VBoxContainer/UnlockAllBtn,
		$Panel/ScrollContainer/VBoxContainer/Give3StarsBtn,
		$Panel/ScrollContainer/VBoxContainer/ResetBtn,
		$Panel/ScrollContainer/VBoxContainer/Add100CurrencyBtn,
		$Panel/ScrollContainer/VBoxContainer/GodmodeBtn,
		$Panel/ScrollContainer/VBoxContainer/HealBaseBtn,
		$Panel/ScrollContainer/VBoxContainer/KillAllEnemiesBtn,
		$Panel/ScrollContainer/VBoxContainer/InstantKillBtn,
		$Panel/ScrollContainer/VBoxContainer/WinLevelBtn,
		$Panel/ScrollContainer/VBoxContainer/SkipWaveBtn
	]
	for btn in buttons:
		btn.disabled = disabled
		# Prevent buttons from capturing keyboard input (Enter/Space)
		btn.focus_mode = Control.FOCUS_NONE

func _update_info() -> void:
	if not info_label:
		return
	
	var text = "=== DEBUG INFO ===\n"
	text += "Currency: %d\n" % GameManager.currency
	
	if GameManager.base_reference:
		text += "Base HP: %d/%d\n" % [GameManager.base_reference.current_hp, GameManager.base_reference.max_hp]
	
	text += "\n=== CHEATS STATUS ===\n"
	text += "Godmode: %s\n" % ("ON" if godmode_enabled else "OFF")
	text += "Instant Kill: %s\n" % ("ON" if instant_kill_enabled else "OFF")
	
	var towers = get_tree().get_nodes_in_group("tower")
	text += "\nActive Towers: %d\n" % towers.size()
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	text += "Active Enemies: %d\n" % enemies.size()
	
	text += "\n=== LEVEL PROGRESS ===\n"
	if LevelManager:
		var unlocked = SaveManager.get_unlocked_levels()
		text += "Unlocked: " + str(unlocked) + "\n"
		text += "Total Stars: " + str(SaveManager.get_total_stars()) + "\n"
	
	info_label.text = text

# === LEVEL FUNCTIONS ===
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

# === CURRENCY FUNCTIONS ===
func _on_add_100_currency() -> void:
	if not debug_visible:
		return
	GameManager.add_currency(100)
	_update_info()
	print("[Debug] Added 100 currency")
	# Release focus to prevent keyboard triggering this button
	$Panel/ScrollContainer/VBoxContainer/Add100CurrencyBtn.release_focus()

# === BASE/HP FUNCTIONS ===
func _on_toggle_godmode() -> void:
	godmode_enabled = !godmode_enabled
	var btn = $Panel/ScrollContainer/VBoxContainer/GodmodeBtn
	btn.text = "Godmode: " + ("ON" if godmode_enabled else "OFF")
	_update_info()
	print("[Debug] Godmode: ", godmode_enabled)

func _on_heal_base() -> void:
	if GameManager.base_reference:
		GameManager.base_reference.current_hp = GameManager.base_reference.max_hp
		GameManager.base_reference.hp_changed.emit(
			GameManager.base_reference.current_hp, 
			GameManager.base_reference.max_hp
		)
	_update_info()
	print("[Debug] Base healed to full")

# === ENEMY FUNCTIONS ===
func _on_kill_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				enemy.take_damage(99999)
			elif enemy.has_method("die"):
				enemy.die()
			else:
				enemy.queue_free()
			count += 1
	_update_info()
	print("[Debug] Killed %d enemies" % count)

func _on_toggle_instant_kill() -> void:
	instant_kill_enabled = !instant_kill_enabled
	var btn = $Panel/ScrollContainer/VBoxContainer/InstantKillBtn
	btn.text = "Instant Kill: " + ("ON" if instant_kill_enabled else "OFF")
	
	# Apply damage boost to all towers
	var towers = get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if is_instance_valid(tower):
			if instant_kill_enabled:
				tower.damage = 99999
			else:
				tower.damage = tower.tower_data.damage
	_update_info()
	print("[Debug] Instant kill: ", instant_kill_enabled)

# === GAME FUNCTIONS ===
func _on_win_level() -> void:
	if GameManager.base_reference:
		GameManager.base_reference.current_hp = GameManager.base_reference.max_hp
	
	# Kill all remaining enemies
	_on_kill_all_enemies()
	
	# Trigger win
	GameManager.is_game_over = true
	GameManager.final_stars = 3
	GameManager.game_over.emit(3)
	print("[Debug] Forced win with 3 stars")

func _on_skip_wave() -> void:
	# Kill all current enemies to trigger next wave
	_on_kill_all_enemies()
	print("[Debug] Skipped wave (killed all enemies)")
