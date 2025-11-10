extends Area3D
## TowerSpot - Marks valid locations for tower placement

@export var tower_scene: PackedScene
var tower_data:TowerData
var tower_node
@export var tower_cost: int = 50

var has_tower: bool = false
var hover_material: StandardMaterial3D
var default_material: StandardMaterial3D

@onready var mesh_instance: MeshInstance3D = $Altar

func _ready() -> void:
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if not has_tower and mesh_instance:
		mesh_instance.material_override = hover_material

func _on_mouse_exited() -> void:
	if not has_tower and mesh_instance:
		mesh_instance.material_override = default_material

func place_tower(data:TowerData) -> void:
	if has_tower or not tower_scene:
		return
	
	if GameManager.spend_currency(tower_cost):
		var tower = tower_scene.instantiate()
		tower_node = tower
		tower_data = data
		tower.tower_data = data
		self.add_child(tower)
		tower.global_position = global_position + Vector3.UP * 0.5
		has_tower = true
		
		if mesh_instance:
			mesh_instance.visible = false
	else:
		print("Kurang")

func remove_tower():
	tower_node.queue_free()
	tower_data = null
	has_tower = false
	print("tower di hapus")
	mesh_instance.visible = true
