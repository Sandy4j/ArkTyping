extends Area3D
## TowerSpot - Marks valid locations for tower placement
signal tower_gone(v:TowerData)
@export var tower_scene: PackedScene
var tower_data:TowerData
var tower_node
@export var tower_cost: int = 50

var has_tower: bool = false
var hover_material: StandardMaterial3D
var default_material: StandardMaterial3D
var bind_vfx_node: Node3D = null

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

func place_tower(data:TowerData) -> bool:
	if has_tower or not tower_scene:
		return false
	
	if GameManager.spend_currency(data.cost):
		var tower = tower_scene.instantiate()
		tower_node = tower
		tower_data = data
		tower.tower_data = data
		tower.altar = mesh_instance
		tower.tower_destroyed.connect(remove_tower)
		self.add_child(tower)
		has_tower = true
		return true
	else:
		print("Kurang")
		return false

func remove_tower():
	tower_gone.emit(tower_data)
	tower_node.queue_free()
	tower_data = null
	has_tower = false
	print("tower di hapus")

## Apply bind VFX to this spot
func apply_bind_vfx():
	# Remove existing VFX if any
	if bind_vfx_node and is_instance_valid(bind_vfx_node):
		bind_vfx_node.queue_free()
	
	var aura_scene
	if ResourceLoadManager:
		aura_scene = ResourceLoadManager.load_resource_sync("res://asset/Vfx/Effect/debuff_bind.tscn")
	
	if aura_scene:
		bind_vfx_node = aura_scene.instantiate()
		add_child(bind_vfx_node)
		bind_vfx_node.position = Vector3.ZERO
		bind_vfx_node.rotation = Vector3.ZERO
		bind_vfx_node.scale = Vector3.ONE
		
		
		# Play animation
		var anim = bind_vfx_node.get_node_or_null("AnimationPlayer")
		if anim:
			anim.play("bind")

## Remove bind VFX from this spot
func remove_bind_vfx():
	if bind_vfx_node and is_instance_valid(bind_vfx_node):
		bind_vfx_node.queue_free()
		bind_vfx_node = null
