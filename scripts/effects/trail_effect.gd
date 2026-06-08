extends Node2D
class_name TrailEffect

## Player trail effect while orbiting.
## Draws curved lines behind the player with fading opacity.

# Configuration
@export var max_points: int = 30
@export var color: Color = Color(0.0, 0.8, 1.0, 0.6)       # Cyan, matches player color
@export var line_width: float = 2.0
@export var fade_start: float = 0.6  # Fraction of trail where fade begins

# State
var _points: Array = []          # Array of Vector2 positions
var _point_times: Array = []     # Array of float timestamps


## Adds a new position to the trail.
func add_point(pos: Vector2) -> void:
	_points.append(pos)
	_point_times.append(Time.get_ticks_msec() / 1000.0)

	# Trim excess points
	while _points.size() > max_points:
		_points.pop_front()
		_point_times.pop_front()

	queue_redraw()


## Clears all trail points.
func clear_trail() -> void:
	_points.clear()
	_point_times.clear()
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return

	var now = Time.get_ticks_msec() / 1000.0
	var oldest_time = _point_times[0]
	var newest_time = _point_times[_point_times.size() - 1]
	var total_span = newest_time - oldest_time
	if total_span <= 0:
		total_span = 0.001

	# Draw segments from oldest to newest
	for i in range(_points.size() - 1):
		var p0: Vector2 = _points[i]
		var p1: Vector2 = _points[i + 1]

		# Normalized age: 0 = oldest, 1 = newest
		var age = (_point_times[i] - oldest_time) / total_span
		var alpha = 1.0

		# Fade oldest portion
		if age < fade_start:
			alpha = age / fade_start

		var c = color
		c.a = alpha
		draw_line(p0, p1, c, line_width)
