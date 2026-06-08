extends Node
class_name SaveManager
## SaveManager

## Manages game progress persistence using FileAccess + JSON.
## Data is stored at user://orbit_survivor_save.json.

signal save_loaded(save_data: Dictionary)
signal save_saved

## Path to the save file in the user data directory.
const SAVE_FILE: String = "user://orbit_survivor_save.json"

var _save_data: Dictionary = {
	"stars": {},          # { level_id: int }
	"crystals": 0,        # int
	"keys": []            # Array of key_id strings
}


## Saves the current progress to disk.
func save_game() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Could not open save file for writing.")
		return
	var json_string := JSON.stringify(_save_data, "\t")
	file.store_string(json_string)
	save_saved.emit()


## Loads progress from disk. Falls back to defaults if the file doesn't exist.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		save_loaded.emit(_save_data)
		return

	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Could not open save file for reading.")
		save_loaded.emit(_save_data)
		return

	var raw := file.get_as_text()
	var json_parse := JSON.new()
	var parse_result := json_parse.parse(raw)
	if parse_result != OK:
		push_error("SaveManager: JSON parse error: ", json_parse.get_error_message())
		save_loaded.emit(_save_data)
		return

	var data = json_parse.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		# Merge loaded data with defaults to ensure all keys exist
		_save_data = data
		# Ensure default keys exist
		if not _save_data.has("stars"):
			_save_data["stars"] = {}
		if not _save_data.has("crystals"):
			_save_data["crystals"] = 0
		if not _save_data.has("keys"):
			_save_data["keys"] = []
	save_loaded.emit(_save_data)


## Returns the star rating for a given level (0 if not set).
func get_level_stars(level_id: String) -> int:
	return _save_data.get("stars", {}).get(level_id, 0)


## Sets the star rating for a given level.
func set_level_stars(level_id: String, stars: int) -> void:
	if not _save_data.has("stars"):
		_save_data["stars"] = {}
	_save_data["stars"][level_id] = stars


## Returns the total number of crystals collected.
func get_total_crystals() -> int:
	return _save_data.get("crystals", 0)


## Adds the given amount of crystals to the total.
func add_crystals(amount: int) -> void:
	if not _save_data.has("crystals"):
		_save_data["crystals"] = 0
	_save_data["crystals"] += amount


## Returns true if the given key has been collected.
func has_key(key_id: String) -> bool:
	return key_id in _save_data.get("keys", [])


## Adds a key to the collected keys list (no duplicates).
func add_key(key_id: String) -> void:
	if not _save_data.has("keys"):
		_save_data["keys"] = []
	if not has_key(key_id):
		_save_data["keys"].append(key_id)


## Resets all progress to default values.
func reset_progress() -> void:
	_save_data = {
		"stars": {},
		"crystals": 0,
		"keys": []
	}
	save_game()
