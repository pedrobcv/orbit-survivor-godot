extends Control
class_name GameOverScreenUI

## Game over screen displayed when the player dies.
## Shows "Game Over" in red neon with retry and level menu options.

@onready var title_label: Label = %TitleLabel
@onready var retry_button: Button = %RetryButton
@onready var levels_button: Button = %LevelsButton
@onready var game_over_panel: Panel = %GameOverPanel
@onready var overlay: ColorRect = %Overlay

var _level_id: String = ""
var _fade_tween: Tween = null


func _ready() -> void:
	_connect_signals()
	visible = false


func _connect_signals() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	levels_button.pressed.connect(_on_levels_pressed)


func show_game_over(level_id: String) -> void:
	visible = true
	_level_id = level_id
	
	# Red neon title
	title_label.text = "GAME OVER"
	title_label.add_theme_color_override("font_color", Color(0.957, 0.267, 0.016, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(0.957, 0.267, 0.016, 1.0))
	title_label.add_theme_constant_override("outline_size", 8)
	
	_animate_fade_in()


func _animate_fade_in() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	
	overlay.modulate = Color(0, 0, 0, 0)
	game_over_panel.modulate = Color(1, 1, 1, 0)
	
	_fade_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(overlay, "modulate:a", 0.7, 0.4)
	_fade_tween.parallel().tween_property(game_over_panel, "modulate:a", 1.0, 0.4)
	_fade_tween.parallel().tween_property(game_over_panel, "scale", Vector2.ONE, 0.4).from(Vector2(0.8, 0.8))


func _on_retry_pressed() -> void:
	SignalBus.level_selected.emit(_level_id)


func _on_levels_pressed() -> void:
	SignalBus.scene_changed.emit("game_over", "level_select")


func _exit_tree() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
