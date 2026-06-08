extends CanvasLayer
class_name GameHUD

## In-game HUD showing elapsed time, collected crystals, and current level.
## Includes pause button and entry/exit animations.

@onready var time_label: Label = %TimeLabel
@onready var crystals_label: Label = %CrystalsLabel
@onready var level_label: Label = %LevelLabel
@onready var pause_button: Button = %PauseButton
@onready var hud_panel: Control = %HUDPanel

var _elapsed_time: float = 0.0
var _crystal_count: int = 0
var _is_running: bool = false
var _hud_tween: Tween = null


func _ready() -> void:
	_connect_signals()
	_update_time_display()
	_update_crystals_display()


func _connect_signals() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	SignalBus.crystal_collected.connect(_on_crystal_collected)
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.game_over.connect(_on_game_ended)
	SignalBus.level_completed.connect(_on_game_ended)
	SignalBus.pause_toggled.connect(_on_pause_toggled)


func _process(delta: float) -> void:
	if not _is_running:
		return
	_elapsed_time += delta
	_update_time_display()


func start_hud(level_name: String) -> void:
	level_label.text = level_name
	_elapsed_time = 0.0
	_crystal_count = 0
	_is_running = false
	_update_time_display()
	_update_crystals_display()
	_play_enter_animation()


func stop_hud() -> void:
	_is_running = false


func _update_time_display() -> void:
	var minutes := int(_elapsed_time) / 60
	var seconds := int(_elapsed_time) % 60
	var millis := int(fmod(_elapsed_time, 1.0) * 100)
	time_label.text = "%02d:%02d:%02d" % [minutes, seconds, millis]


func _update_crystals_display() -> void:
	crystals_label.text = "💎 %d" % _crystal_count


func _play_enter_animation() -> void:
	if _hud_tween and _hud_tween.is_valid():
		_hud_tween.kill()
	
	_hud_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hud_tween.tween_property(hud_panel, "modulate:a", 1.0, 0.4).from(0.0)
	_hud_tween.parallel().tween_property(hud_panel, "position:y", 0.0, 0.4).from(-50.0)


func play_exit_animation() -> Signal:
	if _hud_tween and _hud_tween.is_valid():
		_hud_tween.kill()
	
	_hud_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_hud_tween.tween_property(hud_panel, "modulate:a", 0.0, 0.3)
	_hud_tween.parallel().tween_property(hud_panel, "position:y", -50.0, 0.3)
	return _hud_tween.finished


func _on_pause_pressed() -> void:
	SignalBus.pause_toggled.emit(true)


func _on_crystal_collected(crystal: Node, value: int) -> void:
	_crystal_count += value
	_update_crystals_display()


func _on_game_started() -> void:
	_is_running = true


func _on_game_ended(_arg = null) -> void:
	_is_running = false


func _on_pause_toggled(is_paused: bool) -> void:
	pause_button.disabled = is_paused


func _exit_tree() -> void:
	if _hud_tween and _hud_tween.is_valid():
		_hud_tween.kill()
