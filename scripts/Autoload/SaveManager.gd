extends Node

## SaveManager - Handles saving and loading player progress

signal progress_loaded
signal progress_saved

const SAVE_FILE_PATH: String = "user://save_data.json"

var player_data: Dictionary = {
	"unlocked_levels": [1],  # Level pertama selalu unlocked
	"level_stars": {},  # Dictionary untuk menyimpan stars per level
	"level_completed": {}  # Dictionary untuk menyimpan completion status
}

func _ready() -> void:
	load_progress()

## Save player progress to file
func save_progress() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(player_data)
		file.store_string(json_string)
		file.close()
		progress_saved.emit()
		print("[SaveManager] Progress saved successfully")
	else:
		push_error("[SaveManager] Failed to save progress")

## Load player progress from file
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveManager] No save file found, using default progress")
		progress_loaded.emit()
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var loaded_data = json.get_data()
			if loaded_data is Dictionary:
				player_data = loaded_data
				# Pastikan level 1 selalu unlocked
				if not 1 in player_data.get("unlocked_levels", []):
					player_data["unlocked_levels"].append(1)
				print("[SaveManager] Progress loaded successfully")
				progress_loaded.emit()
			else:
				push_error("[SaveManager] Invalid save data format")
		else:
			push_error("[SaveManager] Failed to parse save file")
	else:
		push_error("[SaveManager] Failed to open save file")

## Check if a level is unlocked
func is_level_unlocked(level_number: int) -> bool:
	return level_number in player_data.get("unlocked_levels", [1])

## Unlock a level
func unlock_level(level_number: int) -> void:
	if not is_level_unlocked(level_number):
		player_data["unlocked_levels"].append(level_number)
		player_data["unlocked_levels"].sort()
		save_progress()
		print("[SaveManager] Level ", level_number, " unlocked")

## Complete a level with stars
func complete_level(level_number: int, stars: int) -> void:
	# Simpan stars (hanya jika lebih tinggi dari sebelumnya)
	var current_stars = player_data.get("level_stars", {}).get(str(level_number), 0)
	if stars > current_stars:
		player_data["level_stars"][str(level_number)] = stars
	
	# Mark level sebagai completed
	player_data["level_completed"][str(level_number)] = true
	
	# Unlock level berikutnya
	unlock_level(level_number + 1)
	
	save_progress()
	print("[SaveManager] Level ", level_number, " completed with ", stars, " stars")

## Get stars for a specific level
func get_level_stars(level_number: int) -> int:
	return player_data.get("level_stars", {}).get(str(level_number), 0)

## Get all unlocked levels
func get_unlocked_levels() -> Array:
	return player_data.get("unlocked_levels", [1])

## Check if level is completed
func is_level_completed(level_number: int) -> bool:
	return player_data.get("level_completed", {}).get(str(level_number), false)

## Reset all progress (for debugging or new game)
func reset_progress() -> void:
	player_data = {
		"unlocked_levels": [1],
		"level_stars": {},
		"level_completed": {}
	}
	save_progress()
	print("[SaveManager] Progress reset")

## Get total stars collected
func get_total_stars() -> int:
	var total = 0
	for stars in player_data.get("level_stars", {}).values():
		total += stars
	return total

