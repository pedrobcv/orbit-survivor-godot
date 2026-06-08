extends Control
class_name SettingsScreenUI

## Settings screen with SFX volume, music volume, vibration toggle, and progress reset.

@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var vibration_check: CheckBox = %VibrationCheck
@onready var reset_button: Button = %ResetButton
@onready var back_button: Button = %BackButton
@onready var confirm_dialog: AcceptDialog = %ConfirmDialog
@onready var settings_panel: Panel = %SettingsPanel


func _ready() -> void:
	_connect_signals()
	_load_settings()


func _connect_signals() -> void:
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	vibration_check.toggled.connect(_on_vibration_toggled)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	confirm_dialog.confirmed.connect(_on_reset_confirmed)


func _load_settings() -> void:
	# Try to load from AudioManager
	if AudioManager:
		sfx_slider.value = AudioManager.get_sfx_volume() * 100.0
		music_slider.value = AudioManager.get_music_volume() * 100.0
	
	# Load vibration setting from project settings or save
	var settings_file := "user://settings.cfg"
	var config := ConfigFile.new()
	if config.load(settings_file) == OK:
		vibration_check.button_pressed = config.get_value("settings", "vibration", true)
	else:
		vibration_check.button_pressed = true


func _on_sfx_volume_changed(value: float) -> void:
	var volume := value / 100.0
	if AudioManager:
		AudioManager.set_sfx_volume(volume)
	SignalBus.settings_changed.emit("sfx_volume", volume)


func _on_music_volume_changed(value: float) -> void:
	var volume := value / 100.0
	if AudioManager:
		AudioManager.set_music_volume(volume)
	SignalBus.settings_changed.emit("music_volume", volume)


func _on_vibration_toggled(enabled: bool) -> void:
	SignalBus.settings_changed.emit("vibration", enabled)
	
	# Save to config
	var config := ConfigFile.new()
	config.set_value("settings", "vibration", enabled)
	config.save("user://settings.cfg")


func _on_reset_pressed() -> void:
	confirm_dialog.dialog_text = "¿Estás seguro de que quieres restablecer todo tu progreso?\n¡Esta acción no se puede deshacer!"
	confirm_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	SaveManager.reset_progress()
	SignalBus.settings_changed.emit("progress_reset", true)
	# Show brief feedback
	confirm_dialog.dialog_text = "Progreso restablecido."
	confirm_dialog.popup_centered()


func _on_back_pressed() -> void:
	SignalBus.scene_changed.emit("settings", "main_menu")
