extends CanvasLayer

@onready var progress_bar: ProgressBar = $Control/ProgressBar
@onready var loading_label: Label = $Control/LoadingLabel
@onready var tips_label: Label = $Control/TipsLabel
@onready var bg: TextureRect = $Control/BG

const bgloading: Array = [
	"res://asset/UI/loding bg/loading morriden.png",
	"res://asset/UI/loding bg/loading silvanna.png"
]

const TIPS: Array[String] = [
	"Tip: Ketik nama musuh dengan cepat untuk menyerang!",
	"Tip: Tower yang lebih kuat membutuhkan lebih banyak gold!",
	"Tip: Perhatikan gelombang musuh yang datang!",
	"Tip: Upgrade tower untuk meningkatkan damage!",
	"Tip: Jaga base kamu agar tidak hancur!",
	"Tip: Typing cepat adalah kunci kemenangan!",
	"Tip: Prioritaskan musuh yang paling dekat dengan base!",
	"Tip: Setiap tower memiliki kekuatan yang berbeda!",
	"Tip: Kumpulkan gold untuk membeli tower baru!",
	"Tip: Strategi yang baik lebih penting dari kecepatan!"
]

var target_scene: String = ""
var is_transitioning: bool = false
var show_time: float = 0.0
var min_display_time: float = 0.8
var is_ready_to_hide: bool = false
var last_progress: float = -1.0
var tips_timer: Timer
var current_tip_index: int = -1

func _ready() -> void:
	_setup_tips_timer()
	hide()

func _setup_tips_timer() -> void:
	tips_timer = Timer.new()
	tips_timer.wait_time = 3.0  # Change tip every 3 seconds
	tips_timer.one_shot = false
	tips_timer.timeout.connect(_on_tips_timer_timeout)
	add_child(tips_timer)

func _on_tips_timer_timeout() -> void:
	if is_transitioning and not is_ready_to_hide:
		_show_random_tip()

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
	
	# Set random background
	_set_random_background()
	
	progress_bar.max_value = 100
	progress_bar.value = 0
	loading_label.text = "Loading..."
	
	# Show first random tip
	_show_random_tip()
	
	# Start tips timer
	tips_timer.start()
	
	bg.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(bg, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	
func update_progress(progress: float) -> void:
	# Skip jika progress tidak berubah secara signifikan
	if abs(progress - last_progress) < 0.01:
		return
	
	last_progress = progress
	
	if not progress_bar or not loading_label:
		push_error("[LoadingScreen] Nodes null in update_progress!")
		return
	
	# Clamp progress between 0 and 1
	progress = clamp(progress, 0.0, 1.0)
	var percentage = int(progress * 100)
	progress_bar.max_value = 100
	progress_bar.value = percentage
	
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
	
	# Stop tips timer
	if tips_timer:
		tips_timer.stop()
	
	# Wait for minimum display time
	var remaining_time = max(0.0, min_display_time - show_time)
	if remaining_time > 0:
		await get_tree().create_timer(remaining_time).timeout
	
	# Shorter delay
	await get_tree().create_timer(0.1).timeout
	
	# Faster fade out animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(bg, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(0.1)
	
	await tween.finished
	
	hide()
	is_transitioning = false
	
	# Reset for next use
	bg.modulate.a = 1.0

func set_loading_message(message: String) -> void:
	_fade_text(message)

func _set_random_background() -> void:
	if bgloading.is_empty():
		push_warning("[LoadingScreen] No background images available!")
		return
	
	var random_index = randi() % bgloading.size()
	var bg_path = bgloading[random_index]
	
	var texture = load(bg_path)
	if texture:
		bg.texture = texture
	else:
		push_error("[LoadingScreen] Failed to load background: " + bg_path)

func _show_random_tip() -> void:
	if not tips_label:
		push_warning("[LoadingScreen] Tips label not found!")
		return
	
	if TIPS.is_empty():
		return
	
	# Get a different random tip than the current one
	var new_index = randi() % TIPS.size()
	if TIPS.size() > 1:
		while new_index == current_tip_index:
			new_index = randi() % TIPS.size()
	
	current_tip_index = new_index
	var new_tip = TIPS[current_tip_index]
	
	# Smooth transition animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade out
	tween.tween_property(tips_label, "modulate:a", 0.0, 0.3)
	
	# Change text
	tween.tween_callback(func():
		tips_label.text = new_tip
	)
	
	# Fade in
	tween.tween_property(tips_label, "modulate:a", 1.0, 0.3)
