extends Node
class_name GameManager

## Central coordinator for all game managers.
## Orchestrates game flow without knowing internal details of other managers.

# Signals
signal game_started
signal game_over
signal level_completed
signal level_failed
signal pause_toggled(is_paused: bool)

# References to other managers (assigned externally or via autoload)
var level_manager: LevelManager
var save_manager: SaveManager
var audio_manager: AudioManager
var star_system: StarSystem
var difficulty_manager: DifficultyManager

var _is_paused: bool = false


## Starts a new game session.
func start_game() -> void:
	game_started.emit()


## Ends the current game session (win or loss).
## result: String describing the result (e.g. "victory", "defeat").
func end_game(result: String = "") -> void:
	game_over.emit()
	if result == "victory":
		level_completed.emit()
	elif result == "defeat":
		level_failed.emit()


## Toggles pause state.
func pause_game() -> void:
	_is_paused = true
	pause_toggled.emit(true)


## Resumes from pause.
func resume_game() -> void:
	_is_paused = false
	pause_toggled.emit(false)


## Reloads the current level.
func reload_level() -> void:
	if level_manager:
		var current_data = level_manager.get_current_level_data()
		if current_data:
			level_manager.load_level(current_data.get("id", ""))


## Loads the next level in sequence.
func load_next_level() -> void:
	if level_manager:
		var current_data = level_manager.get_current_level_data()
		if current_data and current_data.has("next_level_id"):
			level_manager.load_level(current_data["next_level_id"])


## Returns to the main menu (placeholder — override or connect externally).
func go_to_menu() -> void:
	pass
