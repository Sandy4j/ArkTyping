extends CanvasLayer

@onready var progress_bar: ProgressBar = $Control/VBoxContainer/ProgressBar
@onready var loading_label: Label = $Control/VBoxContainer/LoadingLabel
@onready var progress_label: Label = $Control/VBoxContainer/ProgressLabel
@onready var color_rect: ColorRect = $Control/ColorRect
@onready var vbox_container: VBoxContainer = $Control/VBoxContainer

var target_scene: String = ""
var is_transitioning: bool = false
var show_time: float = 0.0
var min_display_time: float = 0.8  # Reduced from 1.5s to 0.8s
var is_ready_to_hide: bool = false
var last_progress: float = -1.0  # Track last progress to avoid redundant updates

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if is_transitioning and not is_ready_to_hide:
		show_time += delta

func show_loading(scene_path: String = "") -> void:
	target_scene = scene_path
	is_transitioning = true
	is_ready_to_hide = false
	show_time = 0.0
	last_progress = -1.0  # Reset tracking
	
	show()
	
	# Force initial values
	progress_bar.max_value = 100
	progress_bar.value = 0
	loading_label.text = "Loading..."
	progress_label.text = "0%"
	
	# Make sure VBoxContainer is visible and opaque
	vbox_container.visible = true
	vbox_container.modulate.a = 1.0
	
	# Fade in ColorRect only
	color_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	
func update_progress(progress: float) -> void:
	# Skip jika progress tidak berubah secara signifikan
	if abs(progress - last_progress) < 0.01:
		return
	
	last_progress = progress
	
	if not progress_bar or not progress_label or not loading_label:
		push_error("[LoadingScreen] Nodes null in update_progress!")
		return
	
	# Clamp progress between 0 and 1
	progress = clamp(progress, 0.0, 1.0)
	var percentage = int(progress * 100)
	progress_bar.max_value = 100
	progress_bar.value = percentage
	progress_label.text = str(percentage) + "%"
	
	# Force redraw
	progress_bar.queue_redraw()
	
	# Update loading text based on progress
	if progress < 0.3:
		loading_label.text = "Loading assets..."
	elif progress < 0.6:
		loading_label.text = "Mempersiapkan level..."
	elif progress < 0.9:
		loading_label.text = "Hampir Selesai..."
	else:
		loading_label.text = "Ready!"

func _fade_text(new_text: String) -> void:
	var tween = create_tween()
	tween.tween_property(loading_label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		loading_label.text = new_text
	)
	tween.tween_property(loading_label, "modulate:a", 1.0, 0.2)

func hide_loading() -> void:
	is_ready_to_hide = true
	
	# Wait for minimum display time
	var remaining_time = max(0.0, min_display_time - show_time)
	if remaining_time > 0:
		await get_tree().create_timer(remaining_time).timeout
	
	# Shorter delay
	await get_tree().create_timer(0.1).timeout
	
	# Faster fade out animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(vbox_container, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(0.1)
	
	await tween.finished
	
	hide()
	is_transitioning = false
	
	# Reset for next use
	color_rect.modulate.a = 1.0
	vbox_container.modulate.a = 1.0

func set_loading_message(message: String) -> void:
	_fade_text(message)
