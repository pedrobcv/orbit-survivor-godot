extends Node2D
class_name LevelScene

## Main gameplay scene for "Orbit Survivor".
## Coordinates level loading, orbit system building, player control,
## HUD display, and handles game flow (victory / game over / pause).

# Scene paths for UI that must be loaded from .tscn files
const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over_screen.tscn")
const VICTORY_SCENE := preload("res://scenes/ui/victory_screen.tscn")

# References to major subsystems
var _orbit_system: OrbitSystem = null
var _player: PlayerOrbiter = null
var _hud = null
var _camera: CameraController = null
var _game_over_ui = null
var _victory_ui = null

# Autoload references (resolved at runtime via @onready)
@onready var _level_mgr = LevelManager
@onready var _save_mgr = SaveManager
@onready var _audio_mgr = AudioManager
@onready var _star_sys = StarSystem

# State
var _level_id: String = ""
var _level_data: Dictionary = {}
var _is_game_over: bool = false
var _start_time: float = 0.0
var _elapsed_time: float = 0.0
var _deaths: int = 0
var _crystals_collected: int = 0
var _paused: bool = false

# Pause overlay (simple ColorRect to dim the scene)
var _pause_overlay: ColorRect = null


func _ready() -> void:
	# --- 1. Get level ID ---
	if GameManager.has_method("get_current_level"):
		_level_id = GameManager.get_current_level()
	else:
		_level_id = ProjectSettings.get_setting("application/current_level", "level_01")

	# --- 2. Load level data ---
	if _level_mgr:
		_level_mgr.load_level(_level_id)
		_level_data = _level_mgr.get_current_level_data()
		if _level_data.is_empty():
			push_error("LevelScene: Failed to load level data for ", _level_id)
			return
	else:
		push_error("LevelScene: LevelManager not available")
		return

	# --- 3. Get Camera (pre-placed in scene or create one) ---
	_camera = get_node_or_null(NodePath("CameraController")) as CameraController
	if not _camera:
		_camera = CameraController.new()
		add_child(_camera)
	_camera.make_current()

	# --- 4. Create OrbitSystem and build from level data ---
	_orbit_system = OrbitSystem.new()
	add_child(_orbit_system)
	_orbit_system.build_from_level_data(_level_data)

	# --- 5. Get reference to PlayerOrbiter (created by OrbitSystem) ---
	if _orbit_system.player:
		_player = _orbit_system.player
		_camera.focus_on_player()
	else:
		push_error("LevelScene: No PlayerOrbiter created by OrbitSystem")

	# --- 6. Create GameHUD from .tscn ---
	if HUD_SCENE:
		_hud = HUD_SCENE.instantiate()
		add_child(_hud)
		if _hud.has_method("start_hud"):
			_hud.start_hud(_level_data.get("name", _level_id))
		else:
			push_error("LevelScene: HUD missing start_hud method")
	else:
		push_error("LevelScene: HUD_SCENE not found")

	# --- 7. Connect SignalBus signals ---
	SignalBus.player_hit.connect(_on_player_hit)
	SignalBus.portal_reached.connect(_on_portal_reached)
	SignalBus.crystal_collected.connect(_on_crystal_collected)
	SignalBus.pause_toggled.connect(_on_pause_toggled)
	SignalBus.level_selected.connect(_on_level_selected)

	# --- 8. Record start time ---
	_start_time = Time.get_ticks_msec() / 1000.0

	# Emit game ready (notify that scene is fully loaded)
	SignalBus.game_ready.emit()

	# --- 9. Create pause overlay (hidden) ---
	_pause_overlay = ColorRect.new()
	_pause_overlay.color = Color(0, 0, 0, 0.5)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	_pause_overlay.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_pause_overlay)


func _process(delta: float) -> void:
	if _is_game_over or _paused:
		return
	_elapsed_time += delta

	# Update camera to follow player
	if _camera and _player:
		_camera.focus_on_player()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
	elif event is InputEventScreenTouch and event.pressed and not event.is_canceled():
		# Forward tap to player
		if _player and _player.has_method("handle_tap") and not _is_game_over and not _paused:
			_player.handle_tap()


## Handles pause toggle
func _toggle_pause() -> void:
	if _is_game_over:
		return

	_paused = not _paused
	if _paused:
		_pause_overlay.visible = true
		get_tree().paused = true
		SignalBus.pause_toggled.emit(true)
	else:
		_pause_overlay.visible = false
		get_tree().paused = false
		SignalBus.pause_toggled.emit(false)


## Called when player collides with an obstacle
func _on_player_hit(damage: int, source: Node) -> void:
	if _is_game_over:
		return

	_is_game_over = true
	_deaths += 1

	# Stop game time
	if _hud and _hud.has_method("stop_hud"):
		_hud.stop_hud()

	# Play hit sound
	if _audio_mgr:
		_audio_mgr.play_sfx("hit")

	# Show Game Over screen
	_show_game_over()


## Called when player reaches the portal
func _on_portal_reached(portal: Node) -> void:
	if _is_game_over:
		return

	_is_game_over = true

	# Stop game time
	if _hud and _hud.has_method("stop_hud"):
		_hud.stop_hud()

	# Play victory sound
	if _audio_mgr:
		_audio_mgr.play_sfx("victory")

	# Calculate stars
	var time_target: float = _level_data.get("time_target", 30.0)
	var stars: int = 1
	if _star_sys:
		stars = _star_sys.calculate_stars(_level_id, _elapsed_time, _deaths, time_target)

	# Save progress via SaveManager
	if _save_mgr:
		var current_stars := _save_mgr.get_level_stars(_level_id)
		if stars > current_stars:
			_save_mgr.set_level_stars(_level_id, stars)
		_save_mgr.add_crystals(_crystals_collected)
		_save_mgr.save_game()

	# Show Victory screen
	_show_victory(stars)

	# Emit level completed signal
	SignalBus.level_completed.emit(_level_id, stars, _crystals_collected * Globals.CRYSTAL_SCORE_VALUE)


## Called when a crystal is collected
func _on_crystal_collected(crystal: Node, value: int) -> void:
	_crystals_collected += value
	if _audio_mgr:
		_audio_mgr.play_sfx("crystal")


## Handles pause toggled from HUD's pause button
func _on_pause_toggled(is_paused: bool) -> void:
	if _is_game_over:
		return
	_paused = is_paused
	if _paused:
		_pause_overlay.visible = true
		get_tree().paused = true
	else:
		_pause_overlay.visible = false
		get_tree().paused = false


## Handles level_selected signal (from victory screen "next level" or "retry")
func _on_level_selected(level_id: String) -> void:
	_clean_up()
	_level_id = level_id
	var game_scene_path: String = Globals.GAME_SCENE
	if ResourceLoader.exists(game_scene_path):
		get_tree().change_scene_to_file(game_scene_path)
		if GameManager.has_method("set_current_level"):
			GameManager.set_current_level(level_id)
	else:
		ProjectSettings.set_setting("application/current_level", level_id)
		get_tree().reload_current_scene()


## Shows the Game Over screen
func _show_game_over() -> void:
	if GAME_OVER_SCENE:
		_game_over_ui = GAME_OVER_SCENE.instantiate()
		add_child(_game_over_ui)
		if _game_over_ui.has_method("show_game_over"):
			_game_over_ui.show_game_over(_level_id)
	else:
		push_error("LevelScene: GAME_OVER_SCENE not found")

	if _audio_mgr:
		_audio_mgr.play_sfx("game_over")


## Shows the Victory screen
func _show_victory(stars: int) -> void:
	if VICTORY_SCENE:
		_victory_ui = VICTORY_SCENE.instantiate()
		add_child(_victory_ui)
		if _victory_ui.has_method("show_victory"):
			_victory_ui.show_victory(_level_id, _elapsed_time, _deaths, _crystals_collected, _level_data.get("time_target", 30.0))
	else:
		push_error("LevelScene: VICTORY_SCENE not found")


## Returns the player reference (used by CameraController)
func get_player() -> PlayerOrbiter:
	return _player

## Cleans up all children before transitioning
func _clean_up() -> void:
	# Disconnect signals
	if SignalBus.player_hit.is_connected(_on_player_hit):
		SignalBus.player_hit.disconnect(_on_player_hit)
	if SignalBus.portal_reached.is_connected(_on_portal_reached):
		SignalBus.portal_reached.disconnect(_on_portal_reached)
	if SignalBus.crystal_collected.is_connected(_on_crystal_collected):
		SignalBus.crystal_collected.disconnect(_on_crystal_collected)
	if SignalBus.pause_toggled.is_connected(_on_pause_toggled):
		SignalBus.pause_toggled.disconnect(_on_pause_toggled)
	if SignalBus.level_selected.is_connected(_on_level_selected):
		SignalBus.level_selected.disconnect(_on_level_selected)

	# Unpause if paused
	if get_tree().paused:
		get_tree().paused = false

	# Queue free all children
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

	_orbit_system = null
	_player = null
	_hud = null
	_camera = null
	_game_over_ui = null
	_victory_ui = null
	_pause_overlay = null


func _exit_tree() -> void:
	_clean_up()
