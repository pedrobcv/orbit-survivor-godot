extends Control
class_name MainMenuUI

## Main menu screen for Orbit Survivor.
## Shows title, buttons, and animated background particles.

@onready var title_label: Label = %TitleLabel
@onready var play_button: Button = %PlayButton
@onready var levels_button: Button = %LevelsButton
@onready var shop_button: Button = %ShopButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var star_particles: GPUParticles2D = %StarParticles

var _title_tween: Tween = null


func _ready() -> void:
	_connect_signals()
	_setup_title_animation()


func _connect_signals() -> void:
	play_button.pressed.connect(_on_play_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)


func _setup_title_animation() -> void:
	if _title_tween and _title_tween.is_valid():
		_title_tween.kill()
	
	_title_tween = create_tween().set_loops()
	_title_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_title_tween.tween_method(_animate_neon_pulse, 0.8, 1.0, 1.5)
	_title_tween.tween_method(_animate_neon_pulse, 1.0, 0.8, 1.5)


func _animate_neon_pulse(scale_value: float) -> void:
	title_label.scale = Vector2(scale_value, scale_value)
	# Modulate between base color and brighter neon
	var base_color := Color(0.663, 0.937, 0.059, 1.0)
	var bright_color := Color(0.176, 0.243, 0.055, 1.0)
	var t := (scale_value - 0.8) / 0.2
	title_label.modulate = base_color.lerp(bright_color, t)
	if title_label.has_theme_color_override(&"font_color"):
		title_label.remove_theme_color_override(&"font_color")
	title_label.add_theme_color_override(&"font_color", title_label.modulate)


func _on_play_pressed() -> void:
	SignalBus.game_started.emit()


func _on_levels_pressed() -> void:
	SignalBus.scene_changed.emit("main_menu", "level_select")


func _on_shop_pressed() -> void:
	SignalBus.scene_changed.emit("main_menu", "shop")


func _on_settings_pressed() -> void:
	SignalBus.scene_changed.emit("main_menu", "settings")


func _on_credits_pressed() -> void:
	SignalBus.scene_changed.emit("main_menu", "credits")


func _exit_tree() -> void:
	if _title_tween and _title_tween.is_valid():
		_title_tween.kill()
