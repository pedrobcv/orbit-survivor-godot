extends CanvasLayer
class_name ProgressSummaryUI

## Global progress summary showing total stars, total crystals, and level completion.

@onready var total_stars_label: Label = %TotalStarsLabel
@onready var total_crystals_label: Label = %TotalCrystalsLabel
@onready var levels_completed_label: Label = %LevelsCompletedLabel
@onready var close_button: Button = %CloseButton
@onready var summary_panel: Panel = %SummaryPanel
@onready var overlay: ColorRect = %Overlay

var _summary_tween: Tween = null


func _ready() -> void:
	_connect_signals()
	visible = false


func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)


func show_summary() -> void:
	visible = true
	_calculate_and_display()
	_animate_in()


func _calculate_and_display() -> void:
	var total_stars := 0
	var completed_count := 0
	var total_crystals := SaveManager.get_total_crystals()
	
	var stars_data := _get_stars_data()
	for level_id in stars_data:
		var s := stars_data[level_id] as int
		total_stars += s
		if s >= 1:
			completed_count += 1
	
	total_stars_label.text = "⭐ %d" % total_stars
	total_crystals_label.text = "💎 %d" % total_crystals
	levels_completed_label.text = "📊 %d / 10 niveles completados" % completed_count


## Safely access the stars dictionary from SaveManager internals.
func _get_stars_data() -> Dictionary:
	# SaveManager._save_data is private. We read it via save/load.
	# Since SaveManager has get_level_stars() per-level, we iterate known levels.
	var result := {}
	for i in range(1, 11):
		var level_id := "level_%02d" % i
		var stars := SaveManager.get_level_stars(level_id)
		if stars > 0:
			result[level_id] = stars
		else:
			result[level_id] = 0
	return result


func _animate_in() -> void:
	if _summary_tween and _summary_tween.is_valid():
		_summary_tween.kill()
	
	overlay.modulate = Color(0, 0, 0, 0)
	summary_panel.modulate = Color(1, 1, 1, 0)
	
	_summary_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_summary_tween.tween_property(overlay, "modulate:a", 0.6, 0.3)
	_summary_tween.parallel().tween_property(summary_panel, "modulate:a", 1.0, 0.3)
	_summary_tween.parallel().tween_property(summary_panel, "scale", Vector2.ONE, 0.3).from(Vector2(0.85, 0.85))


func _on_close_pressed() -> void:
	visible = false


func _exit_tree() -> void:
	if _summary_tween and _summary_tween.is_valid():
		_summary_tween.kill()
