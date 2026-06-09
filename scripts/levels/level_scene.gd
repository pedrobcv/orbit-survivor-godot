extends Node2D
class_name LevelScene

## Orbit Survivor — simple, fun combat gameplay.

const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over_screen.tscn")
const VICTORY_SCENE := preload("res://scenes/ui/victory_screen.tscn")

var _orbit_system: OrbitSystem = null
var _player: PlayerOrbiter = null
var _hud = null
var _game_over_ui = null
var _victory_ui = null
var _pause_overlay: ColorRect = null
var _lives: int = 3

@onready var _level_mgr = LevelManager
@onready var _audio_mgr = AudioManager
@onready var _star_sys = StarSystem
@onready var _save_mgr = SaveManager

var _level_id: String = "level_01"
var _level_data: Dictionary = {}
var _is_game_over: bool = false
var _elapsed_time: float = 0.0
var _score: int = 0

func _ready() -> void:
	if GameManager.has_method("get_current_level"):
		_level_id = GameManager.get_current_level()
	
	_load_level()
	
	# Create orbit system
	_orbit_system = OrbitSystem.new()
	add_child(_orbit_system)
	_orbit_system.build_from_level_data(_level_data)
	
	if _orbit_system.player:
		_player = _orbit_system.player
		_player.lives_changed.connect(_on_lives_changed)
	
	# Camera
	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(1.0, 1.0)
	add_child(cam)
	cam.make_current()
	
	# HUD
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	if _hud.has_method("start_hud"):
		_hud.start_hud(_level_data.get("name", _level_id))
	if _hud.has_method("update_lives"):
		_hud.update_lives(_lives)
	
	# Signals
	SignalBus.player_hit.connect(_on_player_hit)
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.portal_reached.connect(_on_portal_reached)
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.pause_toggled.connect(_on_pause_toggled)
	
	# Pause overlay
	_pause_overlay = ColorRect.new()
	_pause_overlay.color = Color(0, 0, 0, 0.5)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	_pause_overlay.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_pause_overlay)
	
	SignalBus.game_ready.emit()

func _load_level() -> void:
	_level_mgr.load_level(_level_id)
	_level_data = _level_mgr.get_current_level_data()

func _process(delta: float) -> void:
	if _is_game_over: return
	_elapsed_time += delta
	if _player:
		var cam = get_node_or_null(NodePath("Camera2D"))
		if cam: cam.global_position = _player.global_position

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_tap()
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed and not event.is_canceled():
			_handle_tap()
			get_viewport().set_input_as_handled()

func _handle_tap() -> void:
	if _is_game_over or not _player: return
	if _player.has_method("handle_tap"):
		_player.handle_tap()

func _toggle_pause() -> void:
	if _is_game_over: return
	get_tree().paused = not get_tree().paused
	_pause_overlay.visible = get_tree().paused
	SignalBus.pause_toggled.emit(get_tree().paused)

func _on_player_hit(damage: int, source: Node) -> void:
	if _is_game_over: return
	# Player loses a life automatically via player.gd
	# Just play sound
	if _audio_mgr: _audio_mgr.play_sfx("hit")

func _on_lives_changed(lives: int) -> void:
	_lives = lives
	if _hud and _hud.has_method("update_lives"):
		_hud.update_lives(lives)

func _on_player_died() -> void:
	if _is_game_over: return
	_is_game_over = true
	if _audio_mgr: _audio_mgr.play_sfx("game_over")
	_show_game_over()

func _on_enemy_killed(enemy: Node) -> void:
	_score += 100
	if _hud and _hud.has_method("update_score"):
		_hud.update_score(_score)

func _on_portal_reached(portal: Node) -> void:
	if _is_game_over: return
	_is_game_over = true
	
	if _audio_mgr: _audio_mgr.play_sfx("victory")
	
	var time_target = _level_data.get("time_target", 30.0)
	var stars = 1
	if _star_sys:
		stars = _star_sys.calculate_stars(_level_id, _elapsed_time, 0, time_target)
	
	if _save_mgr:
		var cur = _save_mgr.get_level_stars(_level_id)
		if stars > cur: _save_mgr.set_level_stars(_level_id, stars)
		_save_mgr.add_crystals(max(_score / 100, 1))
		_save_mgr.save_game()
	
	_show_victory(stars)
	SignalBus.level_completed.emit(_level_id, stars, _score)

func _on_pause_toggled(is_paused: bool) -> void:
	_pause_overlay.visible = is_paused

func _show_game_over() -> void:
	if GAME_OVER_SCENE:
		_game_over_ui = GAME_OVER_SCENE.instantiate()
		add_child(_game_over_ui)
		if _game_over_ui.has_method("show_game_over"):
			_game_over_ui.show_game_over(_level_id)

func _show_victory(stars: int) -> void:
	if VICTORY_SCENE:
		_victory_ui = VICTORY_SCENE.instantiate()
		add_child(_victory_ui)
		if _victory_ui.has_method("show_victory"):
			_victory_ui.show_victory(_level_id, _elapsed_time, 0, _score, _level_data.get("time_target", 30.0))

func get_player() -> PlayerOrbiter: return _player

func _exit_tree() -> void:
	_clean_up()

func _clean_up() -> void:
	for s in ["player_hit", "player_died", "portal_reached", "enemy_killed", "pause_toggled"]:
		var sig = SignalBus.get(s)
		if sig and sig.is_connected(_on_player_hit): sig.disconnect(_on_player_hit)
	if get_tree().paused: get_tree().paused = false
	for child in get_children():
		if is_instance_valid(child): child.queue_free()
