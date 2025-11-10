extends Node
class_name PoolSetup

static func setup_pools_for_waves(wave_configs: Array[WaveConfig]) -> void:
	var tower_projectile_scene = preload("res://scenes/Tower/Projectile.tscn")
	var enemy_projectile_scene = preload("res://scenes/Enemy/ProjectileE.tscn")
	
	ObjectPool.register_pool("tower_projectile", tower_projectile_scene, 20, 100)
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
