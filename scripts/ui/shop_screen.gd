extends Control
class_name ShopScreenUI

## Shop screen for purchasing and selecting player skins.
## Shows total crystals, a grid of colored circle skins with purchase/select states.

const SKINS := [
	{"id": "blue",   "name": "Azul",    "color": Color("#4a9eff"), "price": 0},
	{"id": "purple", "name": "Morado",  "color": Color("#8b5cf6"), "price": 100},
	{"id": "red",    "name": "Rojo",    "color": Color("#ef4444"), "price": 200},
	{"id": "green",  "name": "Verde",   "color": Color("#22c55e"), "price": 300},
	{"id": "gold",   "name": "Dorado",  "color": Color("#eab308"), "price": 500},
	{"id": "rainbow","name": "Arcoíris","color": Color("#ec4899"), "price": 1000},
]

const SAVE_SECTION := "shop"
const KEY_UNLOCKED := "unlocked_skins"
const KEY_EQUIPPED := "equipped_skin"

@onready var crystals_label: Label = %CrystalsLabel
@onready var skin_grid: GridContainer = %SkinGrid
@onready var back_button: Button = %BackButton

var _unlocked_skins: Array[String] = ["blue"]
var _equipped_skin: String = "blue"
var _skin_buttons: Array[Button] = []


func _ready() -> void:
	_connect_signals()
	_load_shop_data()
	_build_skin_grid()
	_update_crystals_display()


func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)
	SignalBus.save_loaded.connect(_on_save_loaded)


func _load_shop_data() -> void:
	var config := ConfigFile.new()
	if config.load("user://shop_settings.cfg") == OK:
		var saved_unlocked := config.get_value(SAVE_SECTION, KEY_UNLOCKED, ["blue"])
		if typeof(saved_unlocked) == TYPE_ARRAY:
			_unlocked_skins = saved_unlocked
		_equipped_skin = config.get_value(SAVE_SECTION, KEY_EQUIPPED, "blue")


func _save_shop_data() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, KEY_UNLOCKED, _unlocked_skins)
	config.set_value(SAVE_SECTION, KEY_EQUIPPED, _equipped_skin)
	config.save("user://shop_settings.cfg")


func _build_skin_grid() -> void:
	skin_grid.columns = 3
	
	for child in skin_grid.get_children():
		child.queue_free()
	_skin_buttons.clear()
	
	for skin in SKINS:
		var skin_id: String = skin["id"]
		var skin_name: String = skin["name"]
		var skin_color: Color = skin["color"]
		var price: int = skin["price"]
		
		var is_unlocked := skin_id in _unlocked_skins
		var is_equipped := skin_id == _equipped_skin
		
		var container := VBoxContainer.new()
		container.custom_minimum_size = Vector2(180, 180)
		container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Color preview circle (simulated with a ColorRect + rounded corners)
		var preview := ColorRect.new()
		preview.custom_minimum_size = Vector2(60, 60)
		preview.color = skin_color
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		container.add_child(preview)
		
		# Skin name
		var name_label := Label.new()
		name_label.text = skin_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(name_label)
		
		# Action button
		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(140, 36)
		if is_equipped:
			action_btn.text = "✓ Seleccionado"
			action_btn.disabled = true
		elif is_unlocked:
			action_btn.text = "Usar"
			action_btn.pressed.connect(_on_equip_skin.bind(skin_id))
		else:
			action_btn.text = "💎 %d" % price
			action_btn.pressed.connect(_on_buy_skin.bind(skin_id, price))
		
		container.add_child(action_btn)
		_skin_buttons.append(action_btn)
		
		skin_grid.add_child(container)


func _update_crystals_display() -> void:
	var total := SaveManager.get_total_crystals()
	crystals_label.text = "💎 %d cristales" % total


func _on_buy_skin(skin_id: String, price: int) -> void:
	var total := SaveManager.get_total_crystals()
	if total < price:
		return
	
	SaveManager.add_crystals(-price)
	_unlocked_skins.append(skin_id)
	_save_shop_data()
	SaveManager.save_game()
	_build_skin_grid()
	_update_crystals_display()


func _on_equip_skin(skin_id: String) -> void:
	_equipped_skin = skin_id
	_save_shop_data()
	_build_skin_grid()
	SignalBus.settings_changed.emit("equipped_skin", skin_id)


func _on_back_pressed() -> void:
	SignalBus.scene_changed.emit("shop", "main_menu")


func _on_save_loaded(data: Dictionary) -> void:
	_update_crystals_display()
