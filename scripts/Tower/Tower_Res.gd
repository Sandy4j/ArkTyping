extends Resource
class_name TowerData

@export var chara:String
@export var atk_sfx:AudioStreamWAV
@export var skl_sfx:AudioStreamWAV
@export var cost:int
@export var slot:CompressedTexture2D
@export var slot_glow:CompressedTexture2D
@export var damage:int
@export var speed:float
@export var range:float
@export var skill:String
@export var skill_duration:int
@export var skill_sprite:CompressedTexture2D
@export var cooldown:int
@export var max_hp:float = 100.0
@export var sprite:SpriteFrames
@export var projectile:PackedScene
@export var projectile_speed:int
var available:bool = true
