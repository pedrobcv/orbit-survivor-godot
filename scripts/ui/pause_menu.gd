extends CanvasLayer
class_name PauseMenuUI

## Pause menu overlay shown when the player pauses the game.
## Semi-transparent panel with resume, retry, and main menu options.

@onready var resume_button: Button = %ResumeButton
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var pause_panel: Panel = %PausePanel
@onready var overlay: ColorRect = %Overlay

var _pause_tween: Tween = null


func _ready() -> void:
	_connect_signals()
	visible = false


func _connect_signals() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func show_pause() -> void:
	visible = true
	SignalBus.pause_toggled.emit(true)
	
	# Pause music
	if AudioManager:
		AudioManager.play_music("pause")
	
	if _pause_tween and _pause_tween.is_valid():
		_pause_tween.kill()
	
	_pause_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pause_tween.tween_property(overlay, "modulate:a", 0.6, 0.2).from(0.0)
	_pause_tween.parallel().tween_property(pause_panel, "modulate:a", 1.0, 0.2).from(0.0)
	_pause_tween.parallel().tween_property(pause_panel, "scale", Vector2.ONE, 0.2).from(Vector2(0.8, 0.8))
	
	get_tree().paused = true


func hide_pause() -> void:
	SignalBus.pause_toggled.emit(false)
	
	if _pause_tween and _pause_tween.is_valid():
		_pause_tween.kill()
	
	_pause_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_pause_tween.tween_property(pause_panel, "modulate:a", 0.0, 0.15)
	_pause_tween.parallel().tween_property(pause_panel, "scale", Vector2(0.8, 0.8), 0.15)
	_pause_tween.parallel().tween_property(overlay, "modulate:a", 0.0, 0.15)
	_pause_tween.finished.connect(_finish_hide, CONNECT_ONE_SHOT)


func _finish_hide() -> void:
	visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	hide_pause()


func _on_retry_pressed() -> void:
	get_tree().paused = false
	var current_level := LevelManager.get_current_level_data()
	if current_level and current_level.has("id"):
		SignalBus.level_selected.emit(current_level["id"])
	else:
		SignalBus.scene_changed.emit("pause", "game")


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SignalBus.scene_changed.emit("pause", "main_menu")


func _exit_tree() -> void:
	if _pause_tween and _pause_tween.is_valid():
		_pause_tween.kill()
