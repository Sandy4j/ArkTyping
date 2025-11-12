extends Node3D
@onready var area1: Area3D = $Ball/Area3D
@onready var area2: Area3D = $Ball2/Area3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer

var damage:int 
var timer:float 
var dot_timer:float 
var speed:float 
var near_enemy:Array
var disabled:bool

func _ready() -> void:
	if disabled:
		anim.play("orbit2")
	else:
		anim.play("orbit")

func _physics_process(delta: float) -> void:
	timer += delta
	cleanup_near_enemy_array()
	if timer >= dot_timer:
		if near_enemy.size() != 0 and !disabled:
			_enemy_take_damage()
		timer = 0

func cleanup_near_enemy_array():
	var invalid_enemies = []
	
	for enemy in near_enemy:
		if not is_instance_valid(enemy):
			invalid_enemies.append(enemy)
		elif not enemy.is_inside_tree() or not enemy.is_in_group("enemies"):
			invalid_enemies.append(enemy)
	for invalid_enemy in invalid_enemies:
		near_enemy.erase(invalid_enemy)

func _enemy_near(body:Node3D)-> void:
	if is_instance_valid(body) and body.is_in_group("enemies") and body is CharacterBody3D and body.has_method("take_damage") and !disabled:
		near_enemy.append(body)
		body.take_damage(damage)
		sfx.play()
		print("body masuk")

func _enemy_take_damage()-> void:
	var valid_enemies = []
	for body in near_enemy:
		if is_instance_valid(body) and body.is_in_group("enemies"):
			valid_enemies.append(body)
	near_enemy = valid_enemies
	
	for body in near_enemy:
		body.take_damage(damage)
		print("body damage")
		sfx.play()

func _enemy_out(body:Node3D)-> void:
	if body.is_in_group("enemies") and body is CharacterBody3D and body.has_method("take_damage") and !disabled:
		near_enemy.erase(body)

func modify_skill(new_dmg:int,new_speed:float,new_dot:float):
	damage = new_dmg
	dot_timer = new_dot
	anim.stop()
	anim.play("spin", -1, new_speed)

func normalize_attack():
	damage = 10
	dot_timer = 0.8
	anim.stop()
	anim.play("spin")

func _exit_tree() -> void:
	# Clean up all enemy references when this node is removed
	near_enemy.clear()
