extends Node2D
class_name OrbitNode

## Represents a orbital point with concentric orbit rings.
## Each orbit ring has a radius, speed, and direction.

# Signals
signal node_selected(node_id: String)

# Data
var node_id: String = ""
var orbits: Array = []  # Array of OrbitData dictionaries
var start_node: bool = false

# Visual
@export var center_color: Color = Color(0.2, 0.6, 1.0, 1.0)       # Bright blue
@export var orbit_color_outer: Color = Color(0.3, 0.3, 0.8, 0.6)   # Blue neon
@export var orbit_color_inner: Color = Color(0.6, 0.2, 0.8, 0.6)  # Purple neon
@export var center_radius: float = 8.0
@export var orbit_line_width: float = 1.5


## Configures this node from a level data dictionary entry.
func initialize(data_dict: Dictionary) -> void:
	node_id = data_dict.get("id", "")
	start_node = data_dict.get("start_node", false)
	
	var pos = data_dict.get("position", {"x": 360, "y": 640})
	position = Vector2(pos.get("x", 360), pos.get("y", 640))
	
	orbits = []
	var orbit_data = data_dict.get("orbits", [])
	for orbit in orbit_data:
		orbits.append({
			"radius": float(orbit.get("radius", 100)),
			"speed": float(orbit.get("speed", 1.0)),
			"direction": orbit.get("direction", "clockwise")
		})
	
	queue_redraw()


## Returns the number of orbit rings this node has.
func get_orbit_count() -> int:
	return orbits.size()


## Returns the radius of the orbit at the given index.
func get_orbit_radius(orbit_index: int) -> float:
	if orbit_index < 0 or orbit_index >= orbits.size():
		return 100.0
	return orbits[orbit_index]["radius"]


## Returns the orbital speed at the given index.
## Positive = clockwise, negative = counterclockwise (in radians per second).
func get_orbit_speed(orbit_index: int) -> float:
	if orbit_index < 0 or orbit_index >= orbits.size():
		return 1.0
	var speed = orbits[orbit_index]["speed"]
	var dir = orbits[orbit_index].get("direction", "clockwise")
	if dir == "counterclockwise":
		speed = -speed
	return speed


## Returns the direction string for an orbit ("clockwise" or "counterclockwise").
func get_orbit_direction(orbit_index: int) -> String:
	if orbit_index < 0 or orbit_index >= orbits.size():
		return "clockwise"
	return orbits[orbit_index].get("direction", "clockwise")


func _draw() -> void:
	# Draw orbit rings (concentric circles)
	for i in range(orbits.size()):
		var radius = orbits[i]["radius"]
		# Alternate colors between blue and purple neon
		var color = orbit_color_outer if i % 2 == 0 else orbit_color_inner
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, color, orbit_line_width)
		
		# Add a subtle glow ring behind
		var glow_color = color
		glow_color.a = 0.15
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, glow_color, orbit_line_width + 4)
	
	# Draw the central node (bright circle)
	# Outer glow
	var glow_center = center_color
	glow_center.a = 0.3
	draw_circle(Vector2.ZERO, center_radius + 4.0, glow_center)
	# Main body
	draw_circle(Vector2.ZERO, center_radius, center_color)
	
	# Inner bright core
	var core_color = Color.WHITE
	core_color.a = 0.7
	draw_circle(Vector2.ZERO, center_radius * 0.5, core_color)
