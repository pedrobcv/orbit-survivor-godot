extends Node
## LevelManager

## Loads levels from JSON files stored in data/levels/.
## Emits signals with parsed level data for other systems to consume.

signal level_loaded(level_data: Dictionary)
signal level_unloaded

## Base path for level data files.
const LEVELS_DIR: String = "res://data/levels/"

var _current_level_data: Dictionary = {}
var _current_level_id: String = ""


## Loads a level by its identifier.
## level_id: Unique string ID for the level (maps to a .json file).
func load_level(level_id: String) -> void:
	_level_unload_current()
	var path := LEVELS_DIR + level_id + ".json"
	if not ResourceLoader.exists(path):
		push_error("LevelManager: Level file not found at ", path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LevelManager: Could not open file at ", path)
		return

	var raw := file.get_as_text()
	var json_parse := JSON.new()
	var parse_result := json_parse.parse(raw)
	if parse_result != OK:
		push_error("LevelManager: JSON parse error in ", path, ": ", json_parse.get_error_message())
		return

	var data = json_parse.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("LevelManager: Expected JSON object (Dictionary), got ", typeof(data))
		return

	_current_level_id = level_id
	_current_level_data = data
	level_loaded.emit(_current_level_data)


## Returns the currently loaded level data dictionary.
func get_current_level_data() -> Dictionary:
	return _current_level_data.duplicate()


## Returns a specific config value from the current level data by key.
## Returns null if the key doesn't exist.
func get_level_config(key: String):
	return _current_level_data.get(key, null)


## Internal: unloads the current level before loading a new one.
func _level_unload_current() -> void:
	if _current_level_id != "":
		level_unloaded.emit()
	_current_level_id = ""
	_current_level_data = {}
