extends Node2D
class_name StarEffect

## Background visual effect: twinkling stars.
## Creates random points that pulse with varying brightness.

# State
var _stars: Array = []   # Each entry: { pos: Vector2, phase: float, speed: float, max_alpha: float }

# Configuration
@export var star_count: int = 80
@export var twinkle_speed_min: float = 0.5
@export var twinkle_speed_max: float = 2.5
@export var star_radius: float = 1.5
@export var star_color: Color = Color(1.0, 1.0, 1.0, 1.0)

# Screen dimensions from parent or viewport
var _screen_size: Vector2 = Vector2(720, 1280)


func _ready() -> void:
	_regenerate_stars()


## Regenerates all star positions and parameters.
func _regenerate_stars() -> void:
	_stars.clear()
	for i in range(star_count):
		var s = {
			"pos": Vector2(
				randf() * _screen_size.x,
				randf() * _screen_size.y
			),
			"phase": randf() * TAU,
			"speed": randf() * (twinkle_speed_max - twinkle_speed_min) + twinkle_speed_min,
			"max_alpha": randf() * 0.7 + 0.3  # 0.3 to 1.0
		}
		_stars.append(s)


func _process(delta: float) -> void:
	var updated = false
	for s in _stars:
		s["phase"] += s["speed"] * delta
		if s["phase"] > TAU:
			s["phase"] -= TAU
			updated = true

	if updated or _stars.size() > 0:
		queue_redraw()


func _draw() -> void:
	for s in _stars:
		# Sine wave twinkle: from ~0.2 to max_alpha
		var twinkle = (sin(s["phase"]) * 0.5 + 0.5)  # 0 to 1
		var alpha = twinkle * s["max_alpha"]
		var c = star_color
		c.a = max(alpha, 0.05)  # Always at least barely visible
		draw_circle(s["pos"], star_radius, c)
