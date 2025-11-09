extends Node

## Object Pooling System

class Pool:
	var scene: PackedScene
	var pool: Array[Node] = []
	var active: Array[Node] = []
	var initial_size: int = 10
	var max_size: int = 50
	
	func _init(p_scene: PackedScene, p_initial_size: int = 10, p_max_size: int = 50) -> void:
		scene = p_scene
		initial_size = p_initial_size
		max_size = p_max_size
	
	func prewarm() -> void:
		for i in range(initial_size):
			var obj = scene.instantiate()
			obj.process_mode = Node.PROCESS_MODE_DISABLED
			pool.append(obj)
	
	func get_object() -> Node:
		var obj: Node = null

		if pool.size() > 0:
			obj = pool.pop_back()
		elif active.size() < max_size:
			obj = scene.instantiate()
		else:
			push_warning("Object pool at maximum capacity")
			return null
		
		obj.process_mode = Node.PROCESS_MODE_INHERIT
		active.append(obj)
		return obj
	
	func return_object(obj: Node) -> void:
		if not obj or not is_instance_valid(obj):
			return
		
		var idx = active.find(obj)
		if idx != -1:
			active.remove_at(idx)
		
		obj.process_mode = Node.PROCESS_MODE_DISABLED
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		
		if pool.size() < max_size:
			pool.append(obj)
		else:
			obj.queue_free()
	
	func clear() -> void:
		for obj in active:
			if is_instance_valid(obj):
				obj.process_mode = Node.PROCESS_MODE_DISABLED
				if obj.get_parent():
					obj.get_parent().remove_child(obj)
				pool.append(obj)
		active.clear()
	
	func cleanup() -> void:
		for obj in pool:
			if is_instance_valid(obj):
				obj.queue_free()
		pool.clear()
		
		for obj in active:
			if is_instance_valid(obj):
				obj.queue_free()
		active.clear()

# Dictionary untuk menyimpan semua pool
var pools: Dictionary = {}

func _ready() -> void:
	pass

## register pool baru
func register_pool(pool_name: String, scene: PackedScene, initial_size: int = 10, max_size: int = 50) -> void:
	if pools.has(pool_name):
		push_warning("Pool '%s' already exists" % pool_name)
		return
	
	var pool = Pool.new(scene, initial_size, max_size)
	pools[pool_name] = pool
	add_child(pool.scene.instantiate())
	get_child(get_child_count() - 1).queue_free()
	pool.prewarm()

## Get objek dari pool
func get_pooled_object(pool_name: String) -> Node:
	if not pools.has(pool_name):
		push_error("Pool '%s' does not exist" % pool_name)
		return null
	
	var pool: Pool = pools[pool_name]
	return pool.get_object()

## Return objek ke pool
func return_pooled_object(pool_name: String, obj: Node) -> void:
	if not pools.has(pool_name):
		push_error("Pool '%s' does not exist" % pool_name)
		if is_instance_valid(obj):
			obj.queue_free()
		return
	
	var pool: Pool = pools[pool_name]
	pool.return_object(obj)

## Clear objek dari pool tertentu
func clear_pool(pool_name: String) -> void:
	if pools.has(pool_name):
		var pool: Pool = pools[pool_name]
		pool.clear()

## Clear semua pool
func clear_all_pools() -> void:
	for pool_name in pools.keys():
		clear_pool(pool_name)

## Cleanup semua pool
func cleanup_all_pools() -> void:
	for pool in pools.values():
		pool.cleanup()
	pools.clear()

func _exit_tree() -> void:
	cleanup_all_pools()
