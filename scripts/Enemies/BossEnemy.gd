extends BaseEnemy
class_name BossEnemy

## Base class untuk semua Boss dengan sistem buff/debuff dan abilities

signal ability_activated(ability_name: String)
signal ability_cleansed(ability_name: String)

@export var ability_cooldown: float = 15.0
@export var ability_duration: float = -1.0  # -1 = permanent until cleansed

var ability_timer: Timer
var ability_active: bool = false
var typing_words: Array[String] = []
var current_typing_progress: int = 0

func _ready():
	super._ready()
	setup_ability_timer()
	
func setup_ability_timer():
	ability_timer = Timer.new()
	add_child(ability_timer)
	ability_timer.timeout.connect(_on_ability_timer_timeout)
	ability_timer.one_shot = false
	ability_timer.start(randf_range(ability_cooldown * 0.5, ability_cooldown))

func _on_ability_timer_timeout():
	if is_alive and is_instance_valid(self):
		activate_ability()

## Override di child class untuk implement ability-specific logic
func activate_ability():
	ability_active = true
	ability_activated.emit("generic_ability")
	print("[BossEnemy] Ability activated")

## Dipanggil ketika typing berhasil untuk cleanse ability
func on_typing_success():
	current_typing_progress += 1
	if should_cleanse_ability():
		cleanse_ability()

func should_cleanse_ability() -> bool:
	# Override di child class jika butuh multiple typing
	return current_typing_progress >= 1

func cleanse_ability():
	ability_active = false
	current_typing_progress = 0
	ability_cleansed.emit("generic_ability")
	print("[BossEnemy] Ability cleansed")

func take_damage(amount: float):
	super.take_damage(amount)
	# Boss bisa punya special reaction saat kena damage
