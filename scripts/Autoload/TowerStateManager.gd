extends Node
## TowerStateManager - Manages tower availability states

# Dictionary to track tower availability by character name
var tower_availability: Dictionary = {}

func _ready() -> void:
	pass

## Check if a tower is available for deployment
func is_tower_available(tower_name: String) -> bool:
	if not tower_availability.has(tower_name):
		return true
	return tower_availability[tower_name]

## Set tower availability state
func set_tower_available(tower_name: String, available: bool) -> void:
	tower_availability[tower_name] = available
	print("[TowerStateManager] Tower '", tower_name, "' availability set to: ", available)

## Reset all tower availability to true
func reset_all_towers() -> void:
	tower_availability.clear()

## Get cooldown status for debugging
func get_status_string() -> String:
	var status = "Tower Status:\n"
	for tower_name in tower_availability.keys():
		status += "  " + tower_name + ": " + ("Available" if tower_availability[tower_name] else "On Cooldown") + "\n"
	return status

