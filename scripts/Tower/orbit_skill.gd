extends Node3D
@onready var area1: Area3D = $Sphere1/Area3D
@onready var area2: Area3D = $Sphere2/Area3D
@onready var anim: AnimationPlayer = $AnimationPlayer

var damage:int 
var timer:float 
var dot_timer:float 
var speed:float 
var near_enemy:Array

func _ready() -> void:
	area1.body_entered.connect(_enemy_near)
	area2.body_entered.connect(_enemy_near)
	area1.body_exited.connect(_enemy_out)
	area2.body_exited.connect(_enemy_out)
	anim.play("spin")

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= dot_timer:
		if near_enemy.size() != 0:
			_enemy_take_damage()
		timer = 0

func _enemy_near(body:Node3D)-> void:
	if body.is_in_group("enemies") and body is CharacterBody3D and body.has_method("take_damage"):
		near_enemy.append(body)
		body.take_damage(damage)
		print("body masuk")

func _enemy_take_damage()-> void:
	for body in near_enemy:
		body.take_damage(damage)
		print("body damage")

func _enemy_out(body:Node3D)-> void:
	if body.is_in_group("enemies") and body is CharacterBody3D and body.has_method("take_damage"):
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
