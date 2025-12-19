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
	_connect_buttons()
	_update_info()

func _connect_buttons() -> void:
	# Level buttons
	$Panel/ScrollContainer/VBoxContainer/UnlockAllBtn.pressed.connect(_on_unlock_all_pressed)
	$Panel/ScrollContainer/VBoxContainer/Give3StarsBtn.pressed.connect(_on_give_3stars_pressed)
	$Panel/ScrollContainer/VBoxContainer/ResetBtn.pressed.connect(_on_reset_pressed)
	
	# Currency buttons
	$Panel/ScrollContainer/VBoxContainer/Add100CurrencyBtn.pressed.connect(_on_add_100_currency)
	# Base/HP buttons
	$Panel/ScrollContainer/VBoxContainer/GodmodeBtn.pressed.connect(_on_toggle_godmode)
	$Panel/ScrollContainer/VBoxContainer/HealBaseBtn.pressed.connect(_on_heal_base)
	
	# Enemy buttons
	$Panel/ScrollContainer/VBoxContainer/KillAllEnemiesBtn.pressed.connect(_on_kill_all_enemies)
	$Panel/ScrollContainer/VBoxContainer/InstantKillBtn.pressed.connect(_on_toggle_instant_kill)
	
	# Game buttons
	$Panel/ScrollContainer/VBoxContainer/WinLevelBtn.pressed.connect(_on_win_level)
	$Panel/ScrollContainer/VBoxContainer/SkipWaveBtn.pressed.connect(_on_skip_wave)

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
		_update_info()

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
	GameManager.add_currency(100)
	_update_info()
	print("[Debug] Added 100 currency")

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
