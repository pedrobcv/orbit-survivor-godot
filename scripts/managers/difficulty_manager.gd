extends Node
## DifficultyManager

## Scales game difficulty based on data from data/difficulty/scale.json.
## Provides per-level difficulty parameters (speeds, targets, enemy counts).

## Base path for difficulty configuration.
const DIFFICULTY_FILE: String = "res://data/difficulty/scale.json"

var _difficulty_data: Dictionary = {}


func _ready() -> void:
	_load_difficulty_data()


## Loads the difficulty scale data from JSON.
func _load_difficulty_data() -> void:
	if not ResourceLoader.exists(DIFFICULTY_FILE):
		push_error("DifficultyManager: scale.json not found at ", DIFFICULTY_FILE)
		return

	var file := FileAccess.open(DIFFICULTY_FILE, FileAccess.READ)
	if file == null:
		push_error("DifficultyManager: Could not open scale.json")
		return

	var raw := file.get_as_text()
	var json_parse := JSON.new()
	var parse_result := json_parse.parse(raw)
	if parse_result != OK:
		push_error("DifficultyManager: JSON parse error: ", json_parse.get_error_message())
		return

	_difficulty_data = json_parse.get_data()


## Returns the obstacle speed multiplier/absolute value for the given level.
## Falls back to a default if level data is missing.
func get_obstacle_speed(level_id: String) -> float:
	return _get_level_value(level_id, "obstacle_speed", 1.0)


## Returns the orbital rotation speed for the given level.
func get_orbital_speed(level_id: String) -> float:
	return _get_level_value(level_id, "orbital_speed", 1.0)


## Returns the target/par time in seconds for the given level.
func get_time_target(level_id: String) -> float:
	return _get_level_value(level_id, "time_target", 60.0)


## Returns the number of enemies for the given level.
func get_enemy_count(level_id: String) -> int:
	return int(_get_level_value(level_id, "enemy_count", 5))


## Internal: retrieves a float value from the difficulty data for a specific level.
## Returns the default value if the level or key doesn't exist.
func _get_level_value(level_id: String, key: String, default: float) -> float:
	var level_config = _difficulty_data.get("levels", {}).get(level_id, {})
	if level_config.has(key):
		return float(level_config[key])
	return default
