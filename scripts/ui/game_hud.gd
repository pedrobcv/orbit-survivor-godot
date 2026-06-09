extends CanvasLayer
class_name GameHUD

## HUD mejorado con barra de energía y contador de cristales.

@onready var time_label: Label = %TimeLabel
@onready var crystals_label: Label = %CrystalsLabel
@onready var level_label: Label = %LevelLabel
@onready var pause_button: Button = %PauseButton
@onready var energy_bar: ColorRect = %EnergyBar
@onready var energy_bg: ColorRect = %EnergyBG
@onready var energy_container: Control = %EnergyContainer
@onready var all_crystals_label: Label = %AllCrystalsLabel

var _elapsed_time: float = 0.0
var _is_running: bool = false

func _ready() -> void:
	_connect_signals()
	_update_time_display()

func _connect_signals() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	SignalBus.crystal_collected.connect(_on_crystal_collected)
	SignalBus.pause_toggled.connect(_on_pause_toggled)

func _process(delta: float) -> void:
	if not _is_running:
		return
	_elapsed_time += delta
	_update_time_display()

func start_hud(level_name: String, total_crystals: int = 0) -> void:
	level_label.text = level_name
	_elapsed_time = 0.0
	_is_running = false
	_update_time_display()
	# Configurar label de todos los cristales
	if all_crystals_label:
		all_crystals_label.text = "💎 0/%d" % total_crystals
		all_crystals_label.visible = total_crystals > 0
	# Reset barra de energía
	update_energy(1.0)
	_play_enter_animation()

# NUEVO: método separado para empezar el timer después de la animación
func start_timer() -> void:
	_is_running = true

func stop_hud() -> void:
	_is_running = false

func update_energy(percent: float) -> void:
	if not energy_bar:
		return
	energy_bar.size.x = percent * (energy_bg.size.x if energy_bg else 200.0)
	# Color: verde > amarillo > rojo
	if percent > 0.5:
		energy_bar.color = Color(0.2, 0.9, 0.3, 1.0)
	elif percent > 0.25:
		energy_bar.color = Color(0.9, 0.8, 0.2, 1.0)
	else:
		energy_bar.color = Color(0.9, 0.2, 0.2, 1.0)
		# Parpadeo cuando está crítico
		if percent < 0.15:
			energy_bar.modulate = Color.WHITE if int(_elapsed_time * 8) % 2 == 0 else Color(1, 1, 1, 0.3)
		else:
			energy_bar.modulate = Color.WHITE

func update_crystals(collected: int, total: int) -> void:
	if all_crystals_label:
		all_crystals_label.text = "💎 %d/%d" % [collected, total]
		# Efecto visual cuando se completa
		if collected >= total and total > 0:
			all_crystals_label.modulate = Color(1.0, 0.9, 0.1, 1.0)  # Dorado

func _update_time_display() -> void:
	var minutes := int(_elapsed_time) / 60
	var seconds := int(_elapsed_time) % 60
	var millis := int(fmod(_elapsed_time, 1.0) * 100)
	time_label.text = "%02d:%02d:%02d" % [minutes, seconds, millis]

func _play_enter_animation() -> void:
	# Animación simple de entrada
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_animate_hud_entry, 0.0, 1.0, 0.4)
	# Iniciar timer después de la animación
	await tween.finished
	_is_running = true

func _animate_hud_entry(t: float) -> void:
	if energy_container:
		energy_container.modulate.a = t
	if level_label:
		level_label.modulate.a = t
	if time_label:
		time_label.modulate.a = t

func _on_pause_pressed() -> void:
	SignalBus.pause_toggled.emit(not get_tree().paused)

func _on_crystal_collected(crystal: Node, value: int) -> void:
	if crystals_label:
		var current = int(crystals_label.text.trim_prefix("💎 "))
		crystals_label.text = "💎 " + str(current + value)

func _on_pause_toggled(is_paused: bool) -> void:
	pause_button.text = "▶" if is_paused else "⏸"
