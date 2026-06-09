extends Control
class_name LevelSelectUI

## Level selection screen.
## Displays a 2-column grid of 10 level buttons with star ratings and lock state.

const COLS := 2
const ROWS := 5
const TOTAL_LEVELS := 10

@onready var level_grid: GridContainer = %LevelGrid
@onready var back_button: Button = %BackButton

var _level_data: Array[Dictionary] = []
var _level_buttons: Array[Node] = []


func _ready() -> void:
	_connect_signals()
	_load_all_levels()
	_build_level_grid()
	_refresh_buttons()


func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)
	SignalBus.save_loaded.connect(_on_save_loaded)


func _load_all_levels() -> void:
	_level_data.clear()
	for i in range(1, TOTAL_LEVELS + 1):
		var level_id := "level_%02d" % i
		var path := "res://data/levels/%s.json" % level_id
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var raw := file.get_as_text()
		var json_parse := JSON.new()
		if json_parse.parse(raw) != OK:
			continue
		var data = json_parse.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			_level_data.append(data)


func _build_level_grid() -> void:
	level_grid.columns = COLS
	
	# Clear existing children
	for child in level_grid.get_children():
		child.queue_free()
	_level_buttons.clear()
	
	for level in _level_data:
		var level_id: String = level.get("id", "")
		var level_name: String = level.get("name", "")
		var order: int = level.get("order", 1)
		var stars: int = SaveManager.get_level_stars(level_id)
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(300, 100)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		# Build button text
		var star_str := ""
		for s in range(3):
			if s < stars:
				star_str += "★"
			else:
				star_str += "☆"
		btn.text = "Nivel %d\n%s\n%s" % [order, level_name, star_str]
		btn.add_theme_font_size_override("font_size", 14)
		
		var is_locked := _is_level_locked(level)
		btn.disabled = is_locked
		if is_locked:
			btn.text = "Nivel %d\n🔒 Bloqueado" % order
			btn.modulate = Color("#555555")
		
		btn.pressed.connect(_on_level_button_pressed.bind(level_id))
		
		level_grid.add_child(btn)
		_level_buttons.append(btn)


func _is_level_locked(level_data: Dictionary) -> bool:
	var require: String = level_data.get("unlock_requirement", "none")
	if require == "none":
		return false
	
	var order: int = level_data.get("order", 1)
	if order <= 1:
		return false
	
	# Check previous level
	var prev_id := "level_%02d" % (order - 1)
	var prev_stars := SaveManager.get_level_stars(prev_id)
	return prev_stars < 1


func _refresh_buttons() -> void:
	# Rebuild the grid when save data changes
	if not is_node_ready():
		return
	_build_level_grid()


func _on_level_button_pressed(level_id: String) -> void:
	SignalBus.level_selected.emit(level_id)


func _on_save_loaded(data: Dictionary) -> void:
	_refresh_buttons()


func _on_back_pressed() -> void:
	SignalBus.scene_changed.emit("level_select", "main_menu")
