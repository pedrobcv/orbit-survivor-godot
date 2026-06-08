extends Area2D
class_name Asteroid

## An asteroid enemy that moves between two orbit nodes or orbits a single node.
## Visual: rusty red/brown circle drawn with _draw().

# State
var speed: float = 0.4
var direction: int = 1               # 1 = forward, -1 = reverse along path
var start_node: OrbitNode = null
var end_node: OrbitNode = null
var current_progress: float = 0.0    # 0.0 = at start_node, 1.0 = at end_node
var orbit_index: int = 0
var orbit_angle: float = 0.0
var asteroid_size: float = 25.0

# Movement mode
enum MoveMode { LINEAR, ORBITAL }
var move_mode: MoveMode = MoveMode.LINEAR

# Visual
@export var base_color: Color = Color(0.667, 0.533, 0.267, 1.0)   # Rusty brown
@export var dark_color: Color = Color(0.4, 0.3, 0.15, 1.0)
@export var highlight_color: Color = Color(0.8, 0.7, 0.4, 1.0)
@export var glow_color: Color = Color(0.8, 0.4, 0.1, 0.3)

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	# Setup collision
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = asteroid_size * 0.8
	_collision_shape.shape = shape
	add_child(_collision_shape)

	collision_layer = 2  # enemies layer
	collision_mask = 1   # detect player

	area_entered.connect(_on_area_entered)


## Configures the asteroid from level/enemy data JSON.
func initialize(data: Dictionary) -> void:
	speed = float(data.get("speed", 0.4))
	orbit_index = data.get("orbit_index", 0)
	asteroid_size = float(data.get("size", 25.0))

	# Find nodes from the parent OrbitSystem
	var start_id = data.get("start_node_id", "")
	var end_id = data.get("end_node_id", "")
	var parent_system = _get_orbit_system()

	if start_id:
		start_node = parent_system.get_node_by_id(start_id)
	if end_id:
		end_node = parent_system.get_node_by_id(end_id)

	# Movement mode
	if start_node and end_node and start_node != end_node:
		move_mode = MoveMode.LINEAR
		current_progress = float(data.get("start_progress", 0.0))
	elif start_node:
		move_mode = MoveMode.ORBITAL
		orbit_angle = deg_to_rad(float(data.get("angle", 0.0)))
	else:
		# Fallback: use a single node from node_id
		var node_id = data.get("node_id", "")
		start_node = parent_system.get_node_by_id(node_id)
		move_mode = MoveMode.ORBITAL
		orbit_angle = deg_to_rad(float(data.get("angle", 0.0)))

	# Update collision shape
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape.radius = asteroid_size * 0.8

	_update_position()


## Finds the OrbitSystem ancestor.
func _get_orbit_system() -> OrbitSystem:
	var parent = get_parent()
	while parent:
		if parent is OrbitSystem:
			return parent
		parent = parent.get_parent()
	return null


## Updates position based on movement mode.
func _update_position() -> void:
	match move_mode:
		MoveMode.LINEAR:
			_update_linear_position()
		MoveMode.ORBITAL:
			_update_orbital_position()


## Linear interpolation between start_node and end_node.
func _update_linear_position() -> void:
	if not start_node or not end_node:
		return
	var start_pos = start_node.position
	var end_pos = end_node.position
	position = start_pos.lerp(end_pos, current_progress)


## Polar coordinate position around start_node.
func _update_orbital_position() -> void:
	if not start_node:
		return
	var radius = start_node.get_orbit_radius(orbit_index)
	position = start_node.position + Vector2(cos(orbit_angle), sin(orbit_angle)) * radius


func _process(delta: float) -> void:
	match move_mode:
		MoveMode.LINEAR:
			current_progress += speed * direction * delta
			if current_progress >= 1.0:
				current_progress = 1.0
				direction = -1
			elif current_progress <= 0.0:
				current_progress = 0.0
				direction = 1
			_update_linear_position()

		MoveMode.ORBITAL:
			if start_node:
				var orbit_speed = start_node.get_orbit_speed(orbit_index)
				orbit_angle += (orbit_speed + speed * 0.1) * delta
				_update_orbital_position()

	queue_redraw()


func _draw() -> void:
	# Outer glow
	var glow = glow_color
	draw_circle(Vector2.ZERO, asteroid_size + 4.0, glow)

	# Main body — irregular circle approximation (rusty asteroid)
	var points = PackedVector2Array()
	var num_points = 10
	for i in range(num_points):
		var a = (float(i) / num_points) * TAU
		# Irregular radius for rocky look
		var r = asteroid_size * (0.8 + randf() * 0.4 if i == 0 else 0.0)
		# Use deterministic variation based on index
		var variation = 1.0 + 0.2 * sin(i * 2.7) * cos(i * 1.3)
		var r_actual = asteroid_size * variation
		points.append(Vector2(cos(a), sin(a)) * r_actual)

	draw_colored_polygon(points, base_color)

	# Darker spots / craters
	var crater_color = dark_color
	crater_color.a = 0.5
	draw_circle(Vector2(asteroid_size * 0.3, -asteroid_size * 0.2), asteroid_size * 0.25, crater_color)
	draw_circle(Vector2(-asteroid_size * 0.25, asteroid_size * 0.35), asteroid_size * 0.2, crater_color)
	draw_circle(Vector2(-asteroid_size * 0.4, -asteroid_size * 0.1), asteroid_size * 0.15, crater_color)

	# Highlight edge
	var edge_color = highlight_color
	edge_color.a = 0.3
	draw_arc(Vector2.ZERO, asteroid_size * 0.85, -PI * 0.5, 0.0, 16, edge_color, 1.5)


func _on_area_entered(area: Area2D) -> void:
	if area is PlayerOrbiter:
		SignalBus.player_hit.emit(2, self)
