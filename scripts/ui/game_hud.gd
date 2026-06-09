extends CanvasLayer
class_name GameHUD

## HUD with lives, score, and level name.

@onready var lives_label: Label = %LivesLabel
@onready var score_label: Label = %ScoreLabel
@onready var level_label: Label = %LevelLabel
@onready var pause_button: Button = %PauseButton

func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)

func start_hud(level_name: String) -> void:
	level_label.text = level_name
	if score_label: score_label.text = "0"

func update_lives(lives: int) -> void:
	if not lives_label: return
	var txt = ""
	for i in range(3):
		if i < lives: txt += "❤️"
		else: txt += "🖤"
	lives_label.text = txt

func update_score(score: int) -> void:
	if score_label:
		score_label.text = str(score)

func _on_pause_pressed() -> void:
	SignalBus.pause_toggled.emit(not get_tree().paused)
