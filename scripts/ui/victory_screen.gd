extends Control
class_name VictoryScreenUI

## Victory screen displayed when a level is completed.
## Shows stars, crystals collected, time, and navigation buttons.

@onready var title_label: Label = %TitleLabel
@onready var stars_container: HBoxContainer = %StarsContainer
@onready var crystals_label: Label = %CrystalsLabel
@onready var time_label: Label = %TimeLabel
@onready var next_level_button: Button = %NextLevelButton
@onready var retry_button: Button = %RetryButton
@onready var levels_button: Button = %LevelsButton
@onready var victory_panel: Panel = %VictoryPanel
@onready var overlay: ColorRect = %Overlay

var _level_id: String = ""
var _earned_stars: int = 0
var _total_score: int = 0
var _victory_tween: Tween = null


func _ready() -> void:
	_connect_signals()
	visible = false


func _connect_signals() -> void:
	next_level_button.pressed.connect(_on_next_level_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	levels_button.pressed.connect(_on_levels_pressed)


func show_victory(level_id: String, completion_time: float, deaths: int, crystals: int, time_target: float) -> void:
	visible = true
	_level_id = level_id
	
	# Calculate stars
	_earned_stars = StarSystem.calculate_stars(level_id, completion_time, deaths, time_target)
	_total_score = crystals * GameConstants.CRYSTAL_SCORE_VALUE
	
	# Update display
	title_label.text = "¡Victoria!"
	crystals_label.text = "💎 %d" % crystals
	
	var minutes := int(completion_time) / 60
	var seconds := int(completion_time) % 60
	time_label.text = "⏱ %02d:%02d" % [minutes, seconds]
	
	# Save progress
	var current_stars := SaveManager.get_level_stars(level_id)
	if _earned_stars > current_stars:
		SaveManager.set_level_stars(level_id, _earned_stars)
	SaveManager.add_crystals(crystals)
	SaveManager.save_game()
	
	# Check if next level exists
	var has_next := _check_next_level()
	next_level_button.visible = has_next
	
	# Animate in
	_animate_in()


func _check_next_level() -> bool:
	var level_data := LevelManager.get_current_level_data()
	if level_data.is_empty():
		return false
	return level_data.has("next_level_id") and level_data["next_level_id"] != null


func _animate_in() -> void:
	if _victory_tween and _victory_tween.is_valid():
		_victory_tween.kill()
	
	# Fade in overlay
	overlay.modulate = Color(0, 0, 0, 0)
	
	_victory_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_victory_tween.tween_property(overlay, "modulate:a", 0.7, 0.3)
	_victory_tween.parallel().tween_property(victory_panel, "modulate:a", 1.0, 0.3).from(0.0)
	_victory_tween.parallel().tween_property(victory_panel, "scale", Vector2.ONE, 0.3).from(Vector2(1.2, 1.2))
	
	# Animate stars appearing one by one
	_animate_stars_appearing()


func _animate_stars_appearing() -> void:
	# Wait for panel to appear first
	await get_tree().create_timer(0.3).timeout
	
	for i in range(_earned_stars):
		if i >= stars_container.get_child_count():
			break
		var star := stars_container.get_child(i) as TextureRect
		if star == null:
			star := stars_container.get_child(i) as Label
		if star == null:
			continue
		
		star.modulate = Color(1, 1, 0, 0)  # Gold color hidden
		star.scale = Vector2.ZERO
		
		var star_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		star_tween.tween_property(star, "modulate:a", 1.0, 0.25)
		star_tween.parallel().tween_property(star, "scale", Vector2.ONE, 0.25)
		
		await get_tree().create_timer(0.2).timeout


func _on_next_level_pressed() -> void:
	var level_data := LevelManager.get_current_level_data()
	if level_data.has("next_level_id"):
		SignalBus.level_selected.emit(level_data["next_level_id"])
	else:
		SignalBus.scene_changed.emit("victory", "level_select")


func _on_retry_pressed() -> void:
	SignalBus.level_selected.emit(_level_id)


func _on_levels_pressed() -> void:
	SignalBus.scene_changed.emit("victory", "level_select")


func _exit_tree() -> void:
	if _victory_tween and _victory_tween.is_valid():
		_victory_tween.kill()
