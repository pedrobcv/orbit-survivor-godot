extends Node2D
class_name LevelScene

## Main gameplay scene for Orbit Survivor.
## Simplified and robust version.

# Preload UI scenes
const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over_screen.tscn")
const VICTORY_SCENE := preload("res://scenes/ui/victory_screen.tscn")

# Subsystems (set up in _ready)
var _orbit_system: OrbitSystem = null
var _player: PlayerOrbiter = null
var _hud = null
var _game_over_ui = null
var _victory_ui = null
var _pause_overlay: ColorRect = null

# Autoloads
@onready var _level_mgr = LevelManager
@onready var _save_mgr = SaveManager
@onready var _audio_mgr = AudioManager
@onready var _star_sys = StarSystem

# State
var _level_id: String = "level_01"
var _level_data: Dictionary = {}
var _is_game_over: bool = false
var _start_time: float = 0.0
var _elapsed_time: float = 0.0
var _deaths: int = 0
var _crystals_collected: int = 0
var _paused: bool = false

func _ready() -> void:
	# Get level ID from GameManager
	if GameManager.has_method("get_current_level"):
		_level_id = GameManager.get_current_level()
	
	# Load level data
	_load_current_level()
	
	# Create orbit system
	_orbit_system = OrbitSystem.new()
	add_child(_orbit_system)
	_orbit_system.build_from_level_data(_level_data)
	
	# Get player
	if _orbit_system.player:
		_player = _orbit_system.player
	
	# Create Camera
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(1.0, 1.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)
	camera.make_current()
	
	# Create HUD
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	if _hud.has_method("start_hud"):
		_hud.start_hud(_level_data.get("name", _level_id))
	
	# Connect signals
	SignalBus.player_hit.connect(_on_player_hit)
	SignalBus.portal_reached.connect(_on_portal_reached)
	SignalBus.crystal_collected.connect(_on_crystal_collected)
	SignalBus.pause_toggled.connect(_on_pause_toggled)
	
	# Start timer
	_start_time = Time.get_ticks_msec() / 1000.0
	
	# Pause overlay (hidden)
	_pause_overlay = ColorRect.new()
	_pause_overlay.color = Color(0, 0, 0, 0.5)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	_pause_overlay.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_pause_overlay)
	
	# Notify ready
	SignalBus.game_ready.emit()

func _load_current_level() -> void:
	_level_mgr.load_level(_level_id)
	_level_data = _level_mgr.get_current_level_data()
	if _level_data.is_empty():
		push_error("LevelScene: Failed to load ", _level_id)

func _process(delta: float) -> void:
	if _is_game_over or _paused:
		return
	_elapsed_time += delta
	
	# Camera follows player
	if _player:
		var camera = get_node_or_null(NodePath("Camera2D"))
		if camera:
			camera.global_position = _player.global_position

func _input(event: InputEvent) -> void:
	# Handle ESC for pause
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	
	# Handle tap/click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_tap()
			get_viewport().set_input_as_handled()
	
	if event is InputEventScreenTouch:
		if event.pressed and not event.is_canceled():
			_handle_tap()
			get_viewport().set_input_as_handled()

func _handle_tap() -> void:
	if _is_game_over or _paused or not _player:
		return
	if _player.has_method("handle_tap"):
		_player.handle_tap()

func _toggle_pause() -> void:
	if _is_game_over:
		return
	_paused = not _paused
	_pause_overlay.visible = _paused
	get_tree().paused = _paused
	SignalBus.pause_toggled.emit(_paused)

func _on_player_hit(damage: int, source: Node) -> void:
	if _is_game_over:
		return
	_is_game_over = true
	_deaths += 1
	
	if _hud and _hud.has_method("stop_hud"):
		_hud.stop_hud()
	if _audio_mgr:
		_audio_mgr.play_sfx("hit")
	
	_show_game_over()

func _on_portal_reached(portal: Node) -> void:
	if _is_game_over:
		return
	_is_game_over = true
	
	if _hud and _hud.has_method("stop_hud"):
		_hud.stop_hud()
	if _audio_mgr:
		_audio_mgr.play_sfx("victory")
	
	var time_target: float = _level_data.get("time_target", 30.0)
	var stars: int = 1
	if _star_sys:
		stars = _star_sys.calculate_stars(_level_id, _elapsed_time, _deaths, time_target)
	
	if _save_mgr:
		var current_stars := _save_mgr.get_level_stars(_level_id)
		if stars > current_stars:
			_save_mgr.set_level_stars(_level_id, stars)
		_save_mgr.add_crystals(max(_crystals_collected, 1))
		_save_mgr.save_game()
	
	_show_victory(stars)
	SignalBus.level_completed.emit(_level_id, stars, _crystals_collected)

func _on_crystal_collected(crystal: Node, value: int) -> void:
	_crystals_collected += value
	if _audio_mgr:
		_audio_mgr.play_sfx("crystal")

func _on_pause_toggled(is_paused: bool) -> void:
	_paused = is_paused
	_pause_overlay.visible = _paused
	get_tree().paused = _paused

func _show_game_over() -> void:
	if GAME_OVER_SCENE:
		_game_over_ui = GAME_OVER_SCENE.instantiate()
		add_child(_game_over_ui)
		if _game_over_ui.has_method("show_game_over"):
			_game_over_ui.show_game_over(_level_id)
	if _audio_mgr:
		_audio_mgr.play_sfx("game_over")

func _show_victory(stars: int) -> void:
	if VICTORY_SCENE:
		_victory_ui = VICTORY_SCENE.instantiate()
		add_child(_victory_ui)
		if _victory_ui.has_method("show_victory"):
			_victory_ui.show_victory(_level_id, _elapsed_time, _deaths, _crystals_collected, _level_data.get("time_target", 30.0))

## Used by Camera2D in the scene
func get_player() -> PlayerOrbiter:
	return _player

func _exit_tree() -> void:
	_clean_up()

func _clean_up() -> void:
	if SignalBus.player_hit.is_connected(_on_player_hit):
		SignalBus.player_hit.disconnect(_on_player_hit)
	if SignalBus.portal_reached.is_connected(_on_portal_reached):
		SignalBus.portal_reached.disconnect(_on_portal_reached)
	if SignalBus.crystal_collected.is_connected(_on_crystal_collected):
		SignalBus.crystal_collected.disconnect(_on_crystal_collected)
	if SignalBus.pause_toggled.is_connected(_on_pause_toggled):
		SignalBus.pause_toggled.disconnect(_on_pause_toggled)
	if get_tree().paused:
		get_tree().paused = false
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()
