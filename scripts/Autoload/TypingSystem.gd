extends Node

signal text_submitted(full_text: String)
signal text_typed(character: String)

var debuff_text:Array[String] = ["cleansing", "cleanse", "purify",
"absolve", "refresh", "bless", "cure", "revive", "release", "rarefy"]
var _current_text: String = ""

var word_list: Array[String] = []
var active_words: Dictionary = {}  # {word: target_node}
var boss_typing_targets: Dictionary = {}  # {boss_node: word}
var backspace_held: bool = false
var backspace_hold_timer: float = 0.0
var backspace_hold_delay: float = 0.5
var backspace_repeat_rate: float = 0.05 

func _input(event) -> void:
	if get_tree().root.has_meta("time_stop_active") and get_tree().root.get_meta("time_stop_active"):
		return
	
	if event is InputEventKey:
		if event.keycode == KEY_BACKSPACE:
			if event.pressed and not event.echo:
				_delete_character()
				AudioManager.play_sfx("typing_delete")
				backspace_held = true
				backspace_hold_timer = 0.0
			elif not event.pressed:
				backspace_held = false
				backspace_hold_timer = 0.0
		
		elif event.pressed and not event.echo:
			if event.keycode >= KEY_A and event.keycode <= KEY_Z:
				var character = char(event.unicode).to_lower()
				_current_text += character
				text_typed.emit(_current_text)
				AudioManager.play_sfx("typing_random", randf_range(0.95, 1.05))
			elif event.keycode == KEY_SPACE:
				_current_text += " "
				text_typed.emit(_current_text)
				AudioManager.play_sfx("typing_random", randf_range(0.95, 1.05))
			elif event.keycode == KEY_ENTER:
				submit_text()

func _process(delta: float) -> void:
	if backspace_held:
		backspace_hold_timer += delta
		
		if backspace_hold_timer >= backspace_hold_delay:
			var repeat_time = backspace_hold_timer - backspace_hold_delay
			var delete_count = int(repeat_time / backspace_repeat_rate)
			
			if delete_count > 0:
				_delete_character()
				backspace_hold_timer = backspace_hold_delay + (repeat_time - delete_count * backspace_repeat_rate)

func _delete_character():
	if _current_text.length() > 0:
		_current_text = _current_text.substr(0, _current_text.length() - 1)
		text_typed.emit(_current_text)

func submit_text() -> String:
	var text = _current_text
	_current_text = ""
	text_submitted.emit(text)
	return text

func clear_text():	
	_current_text = ""
	text_typed.emit("")

## Register boss untuk typing system (Boss Herald)
func register_boss_typing(boss: Node, word: String):
	boss_typing_targets[boss] = word.to_upper()

func unregister_boss_typing(boss: Node):
	if boss in boss_typing_targets:
		boss_typing_targets.erase(boss)

func check_boss_typing(typed_word: String) -> bool:
	typed_word = typed_word.to_upper()
	for boss in boss_typing_targets.keys():
		if is_instance_valid(boss) and boss_typing_targets[boss] == typed_word:
			if boss.has_method("on_typing_success"):
				boss.on_typing_success()
				return true
	return false

func is_boss_typing_active() -> bool:
	return not boss_typing_targets.is_empty()

func notify_boss_typing_failed():
	for boss in boss_typing_targets.keys():
		if is_instance_valid(boss) and boss.has_method("on_typing_failed"):
			boss.on_typing_failed()
			print("[TypingSystem] Notified boss typing failed: ", boss.name)

## Clear all typing state - call when level exits
func clear_all() -> void:
	_current_text = ""
	active_words.clear()
	boss_typing_targets.clear()
	backspace_held = false
	backspace_hold_timer = 0.0

## Clean up invalid boss references
func cleanup_invalid_bosses() -> void:
	var invalid_bosses: Array = []
	for boss in boss_typing_targets.keys():
		if not is_instance_valid(boss):
			invalid_bosses.append(boss)
	
	for boss in invalid_bosses:
		boss_typing_targets.erase(boss)
