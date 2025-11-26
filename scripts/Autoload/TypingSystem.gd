extends Node

signal text_submitted(full_text: String)
signal text_typed(character: String)

var debuff_text:Array[String] = ["cleansing", "cleanse", "purify",
"absolve", "refresh", "bless", "cure", "revive", "release", "rarefy"]
var _current_text: String = ""

var word_list: Array[String] = []
var active_words: Dictionary = {}  # {word: target_node}
var boss_typing_targets: Dictionary = {}  # {boss_node: word}

func _input(event) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_A and event.keycode <= KEY_Z:
			var character = char(event.unicode).to_lower()
			_current_text += character
			text_typed.emit(_current_text)
			AudioManager.play_sfx("typing_random", randf_range(0.95, 1.05))
		elif event.keycode == KEY_BACKSPACE:
			if _current_text.length() > 0:
				_current_text = _current_text.substr(0, _current_text.length() - 1)
				text_typed.emit(_current_text)
		elif event.keycode == KEY_SPACE:
			_current_text += " "
			text_typed.emit(_current_text)
			AudioManager.play_sfx("typing_random", randf_range(0.95, 1.05))
		elif event.keycode == KEY_ENTER:
			submit_text()

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
	print("[TypingSystem] Registered boss typing: ", boss.name, " with word: ", word)

func unregister_boss_typing(boss: Node):
	if boss in boss_typing_targets:
		boss_typing_targets.erase(boss)
		print("[TypingSystem] Unregistered boss typing: ", boss.name)

func check_boss_typing(typed_word: String) -> bool:
	typed_word = typed_word.to_upper()
	for boss in boss_typing_targets.keys():
		if is_instance_valid(boss) and boss_typing_targets[boss] == typed_word:
			if boss.has_method("on_typing_success"):
				boss.on_typing_success()
				return true
	return false

func is_boss_typing_active() -> bool:
	"""Check apakah ada boss yang sedang aktif typing"""
	return not boss_typing_targets.is_empty()

func notify_boss_typing_failed():
	"""Notify semua boss yang active bahwa player typing failed"""
	for boss in boss_typing_targets.keys():
		if is_instance_valid(boss) and boss.has_method("on_typing_failed"):
			boss.on_typing_failed()
			print("[TypingSystem] Notified boss typing failed: ", boss.name)

