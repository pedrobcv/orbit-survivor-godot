extends Control
class_name CreditsScreenUI

## Credits screen with slow-scrolling text and a back button.

const SCROLL_DURATION := 30.0  # seconds for full scroll
const SCROLL_START_Y := 900.0
const SCROLL_END_Y := -1800.0

@onready var credits_text: RichTextLabel = %CreditsText
@onready var back_button: Button = %BackButton
@onready var credits_container: ScrollContainer = %CreditsContainer

var _scroll_tween: Tween = null


func _ready() -> void:
	_connect_signals()
	_populate_credits()
	_start_scroll_animation()


func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)


func _populate_credits() -> void:
	var credit_lines := PackedStringArray()
	credit_lines.append("[center][b][color=#4a9eff][font_size=36]ORBIT SURVIVOR[/font_size][/color][/b][/center]")
	credit_lines.append("")
	credit_lines.append("[center][color=#22d3ee]━━━━━━━━━━━━━━━━━━━━[/color][/center]")
	credit_lines.append("")
	credit_lines.append("[center][b]Desarrollado por[/b][/center]")
	credit_lines.append("[center]Nous Research Team[/center]")
	credit_lines.append("")
	credit_lines.append("[center][b]Programación[/b][/center]")
	credit_lines.append("[center]Equipo de Desarrollo[/center]")
	credit_lines.append("")
	credit_lines.append("[center][b]Diseño de Juego[/b][/center]")
	credit_lines.append("[center]Game Design Team[/center]")
	credit_lines.append("")
	credit_lines.append("[center][b]Arte y Animación[/b][/center]")
	credit_lines.append("[center]Art Department[/center]")
	credit_lines.append("")
	credit_lines.append("[center][b]Música y Sonido[/b][/center]")
	credit_lines.append("[center]Audio Team[/center]")
	credit_lines.append("")
	credit_lines.append("[center][color=#22d3ee]━━━━━━━━━━━━━━━━━━━━[/color][/center]")
	credit_lines.append("")
	credit_lines.append("[center][b][color=#8b5cf6]Powered by[/color][/b][/center]")
	credit_lines.append("[center][color=#ffffff]Godot Engine[/color][/center]")
	credit_lines.append("")
	credit_lines.append("[center][color=#22d3ee]━━━━━━━━━━━━━━━━━━━━[/color][/center]")
	credit_lines.append("")
	credit_lines.append("[center][i]Gracias por jugar[/i][/center]")
	credit_lines.append("")
	credit_lines.append("[center][color=#4a9eff]© 2026 Orbit Survivor[/color][/center]")
	
	credits_text.text = "\n".join(credit_lines)
	credits_text.anchor_right = 1.0
	credits_text.anchor_left = 0.0


func _start_scroll_animation() -> void:
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	
	# Position the scroll container's content at start
	var v_scroll := credits_container.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value = 0
	
	# Use a tween on the scroll container's scroll offset
	_scroll_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_scroll_tween.tween_method(_update_scroll, 0.0, 1.0, SCROLL_DURATION)
	
	# Make the animation loop
	_scroll_tween.finished.connect(_restart_scroll, CONNECT_ONE_SHOT)


func _update_scroll(progress: float) -> void:
	var v_scroll := credits_container.get_v_scroll_bar()
	if v_scroll:
		var max_value := v_scroll.max_value
		v_scroll.value = lerp(0.0, max_value, progress)


func _restart_scroll() -> void:
	_start_scroll_animation()


func _on_back_pressed() -> void:
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	SignalBus.scene_changed.emit("credits", "main_menu")


func _exit_tree() -> void:
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
