extends CanvasLayer

@onready var hp_label: Label = $HP/Health_Con/Cur
@onready var currency_label: Label = $TextureProgressBar/Label
@onready var wave_label: Label = $Wave/Wave_Con/Cur
@onready var wavesystem = $"../WaveManager"
@onready var message: Label = $Label

func _ready() -> void:
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	GameManager.game_over.connect(_on_game_over)
	LevelManager.victory.connect(_on_victory)
	wavesystem.wave_started.connect(_on_wave_started)
	message.visible = false

func _on_currency_changed(amount: int) -> void:
	currency_label.text = str(amount)

func _on_base_hp_changed(hp: int) -> void:
	hp_label.text = str(hp)

func _on_wave_started(wave: int) -> void:
	wave_label.text = str(wave)

func _on_game_over(stars: int) -> void:
	var winlose_scene = load("res://scenes/UI/WinLose.tscn")
	if winlose_scene:
		var winlose_instance = winlose_scene.instantiate()
		get_tree().current_scene.add_child(winlose_instance)
		winlose_instance.show_game_over()

func _on_victory() -> void:
	await get_tree().create_timer(1.0).timeout
	var winlose_scene = load("res://scenes/UI/WinLose.tscn")
	if winlose_scene:
		var winlose_instance = winlose_scene.instantiate()
		get_tree().current_scene.add_child(winlose_instance)
		winlose_instance.show_victory()

func show_message(v:String):
	message.text = v
	message.visible = true
	await get_tree().create_timer(2).timeout
	message.visible = false
