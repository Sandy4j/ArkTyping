extends Node
## GameManager - Controls game state, currency, and base HP

signal game_over
signal currency_changed(new_amount: int)
signal base_hp_changed(new_hp: int)

@export var starting_currency: int = 100
@export var starting_base_hp: int = 20

var currency: int = 0
var base_hp: int = 0
var is_game_over: bool = false

func _ready() -> void:
	currency = starting_currency
	base_hp = starting_base_hp
	currency_changed.emit(currency)
	base_hp_changed.emit(base_hp)

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		currency_changed.emit(currency)
		return true
	return false

func damage_base(damage: int) -> void:
	if is_game_over:
		return
	
	base_hp -= damage
	base_hp_changed.emit(base_hp)
	
	if base_hp <= 0:
		base_hp = 0
		trigger_game_over()

func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit()
	print("Game Over!")
