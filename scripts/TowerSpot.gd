extends Area3D
## TowerSpot - Marks valid locations for tower placement

@export var tower_scene: PackedScene
@export var tower_cost: int = 50

var has_tower: bool = false
var hover_material: StandardMaterial3D
var default_material: StandardMaterial3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	# Create materials for visual feedback
	default_material = StandardMaterial3D.new()
	default_material.albedo_color = Color(0.3, 0.3, 0.8, 0.5)
	default_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	hover_material = StandardMaterial3D.new()
	hover_material.albedo_color = Color(0.3, 0.8, 0.3, 0.7)
	hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if mesh_instance:
		mesh_instance.material_override = default_material
	
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		place_tower()

func _on_mouse_entered() -> void:
	if not has_tower and mesh_instance:
		mesh_instance.material_override = hover_material

func _on_mouse_exited() -> void:
	if not has_tower and mesh_instance:
		mesh_instance.material_override = default_material

func place_tower() -> void:
	if has_tower or not tower_scene:
		return
	
	if GameManager.spend_currency(tower_cost):
		var tower = tower_scene.instantiate()
		add_child(tower)
		tower.global_position = global_position + Vector3.UP * 0.5
		has_tower = true
		
		if mesh_instance:
			mesh_instance.visible = false
		
		print("Tower placed!")
	else:
		print("Not enough currency!")
