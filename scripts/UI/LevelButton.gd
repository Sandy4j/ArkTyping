extends TextureRect

## LevelButton - Individual button untuk level selection

signal level_selected(level_path: String)

@onready var level_number_label = $MarginContainer/VBoxContainer/LevelNumberLabel
@onready var stars_container = $MarginContainer/VBoxContainer/StarsContainer
@onready var locked_overlay = $LockedOverlay
@onready var lock_icon = $LockedOverlay/CenterContainer/LockIcon
@onready var button = $Button

const Default ="res://asset/UI/main menu/Level.png"
const Hover = "res://asset/UI/main menu/level_hover.png"
const STAR_FILLED_TEXTURE = "res://asset/UI/star isi.png"
const STAR_EMPTY_TEXTURE = "res://asset/UI/star kosong.png"
const LOCK_TEXTURE = "res://asset/UI/lock.png"

var level_path: String = ""
var level_number: int = 0
var is_unlocked: bool = false
var stars: int = 0

func _ready() -> void:
	# Load lock texture
	if lock_icon and ResourceLoader.exists(LOCK_TEXTURE):
		lock_icon.texture = load(LOCK_TEXTURE)

func setup(p_level_number: int, p_level_path: String, p_is_unlocked: bool, p_stars: int, p_is_completed: bool) -> void:
	level_number = p_level_number
	level_path = p_level_path
	is_unlocked = p_is_unlocked
	stars = p_stars
	
	_update_ui()

func _update_ui() -> void:
	# Update level number
	if level_number_label:
		level_number_label.text = "Level %d" % level_number
	
	# Update stars display
	if stars_container:
		for i in range(stars_container.get_child_count()):
			var star = stars_container.get_child(i)
			if star is TextureRect:
				if i < stars:
					# Star filled
					if ResourceLoader.exists(STAR_FILLED_TEXTURE):
						star.texture = load(STAR_FILLED_TEXTURE)
					star.modulate = Color.WHITE
				else:
					# Star empty
					if ResourceLoader.exists(STAR_EMPTY_TEXTURE):
						star.texture = load(STAR_EMPTY_TEXTURE)
					star.modulate = Color(0.4, 0.4, 0.4, 0.6)
	
	# Update locked state
	if locked_overlay:
		locked_overlay.visible = not is_unlocked
	
	if button:
		button.disabled = not is_unlocked

func _on_button_pressed() -> void:
	if is_unlocked:
		level_selected.emit(level_path)


func _on_mouse_entered() -> void:
	if is_unlocked:
		if ResourceLoader.exists(Hover):
			self.texture = load(Hover)
			print("ganti texture")
		print("mouse masuk")

func _on_mouse_exited() -> void:
	if is_unlocked:
		if ResourceLoader.exists(Default):
			self.texture = load(Default)
