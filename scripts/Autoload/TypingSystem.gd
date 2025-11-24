extends Node

signal text_submitted(full_text: String)
signal text_typed(character: String)

var _current_text: String = ""

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
