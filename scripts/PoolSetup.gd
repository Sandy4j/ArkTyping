extends Node
class_name PoolSetup

static func setup_pools_for_waves(wave_configs: Array[WaveConfig], tower_datas: Array[TowerData] = []) -> void:
	var enemy_projectile_path = "res://scenes/Enemy/ProjectileE.tscn"
	var enemy_projectile_scene = ResourceLoadManager.load_resource_sync(enemy_projectile_path)
	
	# Register tower projectile pools dari tower resources
	var registered_tower_projectiles: Dictionary = {}
	for tower_data in tower_datas:
		if tower_data and tower_data.projectile:
			var scene_path = tower_data.projectile.resource_path
			if not registered_tower_projectiles.has(scene_path):
				var pool_name = "tower_projectile_" + tower_data.chara
				if not ObjectPool.pools.has(pool_name):
					ObjectPool.register_pool(pool_name, tower_data.projectile, 20, 100)
					print("Registered tower projectile pool: ", pool_name)
				registered_tower_projectiles[scene_path] = pool_name
	
	# Fallback: register default tower projectile jika tidak ada tower data
	if tower_datas.is_empty():
		var tower_projectile_path = "res://scenes/Tower/Projectile.tscn"
		var tower_projectile_scene = ResourceLoadManager.load_resource_sync(tower_projectile_path)
		if tower_projectile_scene and not ObjectPool.pools.has("tower_projectile"):
			ObjectPool.register_pool("tower_projectile", tower_projectile_scene, 20, 100)
	
	if enemy_projectile_scene and not ObjectPool.pools.has("enemy_projectile"):
		ObjectPool.register_pool("enemy_projectile", enemy_projectile_scene, 15, 80)
	
	var registered_enemies: Dictionary = {}
	
	for wave_config in wave_configs:
		if not wave_config:
			continue
		
		for spawn_point_config in wave_config.spawn_point_configs:
			if not spawn_point_config:
				continue
			
			for entry in spawn_point_config.enemy_spawn_entries:
				if entry and entry.enemy_scene:
					var scene_path = entry.enemy_scene.resource_path
					if not registered_enemies.has(scene_path):
						var pool_name = "enemy_" + scene_path.get_file().get_basename()
						ObjectPool.register_pool(pool_name, entry.enemy_scene, 10, 50)
						registered_enemies[scene_path] = pool_name
			
			if spawn_point_config.has_boss and spawn_point_config.boss_scene:
				var boss_path = spawn_point_config.boss_scene.resource_path
				if not registered_enemies.has(boss_path):
					var pool_name = "enemy_" + boss_path.get_file().get_basename()
					ObjectPool.register_pool(pool_name, spawn_point_config.boss_scene, 2, 5)
					registered_enemies[boss_path] = pool_name

## Helper function to register a tower projectile pool on-demand
static func register_tower_projectile_pool(tower_data: TowerData) -> String:
	if not tower_data or not tower_data.projectile:
		return ""
	
	var pool_name = "tower_projectile_" + tower_data.chara
	
	# Check if pool already exists
	if not ObjectPool.pools.has(pool_name):
		ObjectPool.register_pool(pool_name, tower_data.projectile, 20, 100)
		print("Registered tower projectile pool on-demand: ", pool_name)
	
	return pool_name

## Preload all resources for a level asynchronously
static func preload_level_resources_async(wave_configs: Array[WaveConfig], tower_datas: Array[TowerData] = [], callback: Callable = Callable()) -> void:
	var resources_to_load: Array[String] = []
	
	# Add enemy projectile
	resources_to_load.append("res://scenes/Enemy/ProjectileE.tscn")
	
	# Add tower projectiles and tower data dependencies
	if tower_datas.is_empty():
		resources_to_load.append("res://scenes/Tower/Projectile.tscn")
	else:
		for tower_data in tower_datas:
			if tower_data:
				# Add tower projectile scene
				if tower_data.projectile:
					var path = tower_data.projectile.resource_path
					if not resources_to_load.has(path):
						resources_to_load.append(path)
				
				# Add tower audio streams
				if tower_data.atk_sfx and tower_data.atk_sfx.resource_path != "":
					var audio_path = tower_data.atk_sfx.resource_path
					if not resources_to_load.has(audio_path):
						resources_to_load.append(audio_path)
				
				if tower_data.skl_sfx and tower_data.skl_sfx.resource_path != "":
					var audio_path = tower_data.skl_sfx.resource_path
					if not resources_to_load.has(audio_path):
						resources_to_load.append(audio_path)
	
	# Add enemy scenes and their dependencies
	for wave_config in wave_configs:
		if not wave_config:
			continue
		
		for spawn_point_config in wave_config.spawn_point_configs:
			if not spawn_point_config:
				continue
			
			for entry in spawn_point_config.enemy_spawn_entries:
				if entry and entry.enemy_scene:
					var path = entry.enemy_scene.resource_path
					if not resources_to_load.has(path):
						resources_to_load.append(path)
					
					# Add enemy data if available
					if entry.enemy_data:
						var data_path = entry.enemy_data.resource_path
						if not resources_to_load.has(data_path) and data_path != "":
							resources_to_load.append(data_path)
			
			# Add boss scene
			if spawn_point_config.has_boss and spawn_point_config.boss_scene:
				var path = spawn_point_config.boss_scene.resource_path
				if not resources_to_load.has(path):
					resources_to_load.append(path)
	
	# Preload VFX resources juga
	await ResourceLoadManager.preload_vfx_resources(Callable())
	
	# Load all resources
	ResourceLoadManager.load_resources_batch(resources_to_load, callback)
