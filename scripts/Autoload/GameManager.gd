extends Node

signal game_over(stars: int)
signal currency_changed(new_amount: int)
signal base_hp_changed(new_hp: int)

@export var starting_currency: int = 100

var currency: int = 0
var is_game_over: bool = false
var final_stars: int = 0
var base_reference: Node3D = null

func _ready() -> void:
	currency = starting_currency
	call_deferred("_emit_initial_currency")

func _emit_initial_currency() -> void:
	currency_changed.emit(currency)

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		currency_changed.emit(currency)
		return true
	return false

func set_base(base_node: Node3D) -> void:
	base_reference = base_node
	if base_reference and base_reference.has_signal("hp_changed"):
		base_reference.hp_changed.connect(_on_base_hp_changed)
		call_deferred("_emit_initial_base_hp")

func _on_base_hp_changed(current: int, _maximum: int) -> void:
	base_hp_changed.emit(current)

func _emit_initial_base_hp() -> void:
	if base_reference:
		base_hp_changed.emit(base_reference.current_hp)

func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	final_stars = calculate_stars()
	game_over.emit(final_stars)
	print("Game Over! Stars: ", final_stars)

func calculate_stars() -> int:
	if not base_reference:
		return 0
	
	var current_hp = base_reference.current_hp
	var max_hp = base_reference.max_hp
	var hp_percentage: float = float(current_hp) / float(max_hp)
	
	if hp_percentage >= 0.7:  
		return 3
	elif hp_percentage >= 0.4:
		return 2
	elif hp_percentage > 0: 
		return 1
	else:
		return 0

func reset_game_state() -> void:
	is_game_over = false
	final_stars = 0
	base_reference = null
	currency = starting_currency
	currency_changed.emit(currency)

func set_tower_state(data:TowerData,v:bool):
	data.available = v
