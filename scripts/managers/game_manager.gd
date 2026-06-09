extends Node

## Central coordinator for Orbit Survivor.
## Manages scene transitions, game flow, and connects all autoloads.

# Scene paths
const SCENES := {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"level_select": "res://scenes/ui/level_select.tscn",
	"game": "res://scenes/levels/level_scene.tscn",
	"settings": "res://scenes/ui/settings_screen.tscn",
	"shop": "res://scenes/ui/shop_screen.tscn",
	"credits": "res://scenes/ui/credits_screen.tscn"
}

var _current_level: String = "level_01"


func _ready() -> void:
	# Connect to SignalBus for scene changes
	SignalBus.scene_changed.connect(_on_scene_changed)
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.level_selected.connect(_on_level_selected)


## Handles scene transitions from any UI
func _on_scene_changed(from: String, to: String) -> void:
	var path = SCENES.get(to)
	if path and ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error("GameManager: Unknown scene '", to, "' or path not found")


## Starts a new game from level 1
func _on_game_started() -> void:
	_current_level = "level_01"
	_start_level()


## Handles level selection from level_select or victory screen
func _on_level_selected(level_id: String) -> void:
	_current_level = level_id
	_start_level()


## Changes to the game scene with the current level
func _start_level() -> void:
	var path = SCENES.get("game")
	if path and ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)


## Returns the current level ID (called by level_scene.gd)
func get_current_level() -> String:
	return _current_level


## Sets the current level ID (called before transitioning to game scene)
func set_current_level(level_id: String) -> void:
	_current_level = level_id
