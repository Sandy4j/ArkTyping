extends CanvasLayer

@onready var hp_label: Label = $Panel/VBoxContainer/HPLabel
@onready var currency_label: Label = $Panel/VBoxContainer/CurrencyLabel
@onready var wave_label: Label = $Panel/VBoxContainer/WaveLabel
@onready var game_over_label: Label = $GameOverLabel

func _ready() -> void:
	game_over_label.visible = false
	
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	GameManager.game_over.connect(_on_game_over)
	
	WaveManager.wave_started.connect(_on_wave_started)

func _on_currency_changed(amount: int) -> void:
	currency_label.text = "Currency: " + str(amount)

func _on_base_hp_changed(hp: int) -> void:
	hp_label.text = "Base HP: " + str(hp)

func _on_wave_started(wave: int) -> void:
	wave_label.text = "Wave: " + str(wave)

func _on_game_over() -> void:
	game_over_label.visible = true
