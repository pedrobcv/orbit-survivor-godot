extends Area2D
class_name MovingEnemy

## An enemy that follows a path of orbit nodes, moving from one to another.
## Visual: purple/red diamond/rhombus shape.

# State
var path_nodes: Array = []         # Array of OrbitNode references
var current_path_index: int = 0
var speed: float = 0.5
var patrol: bool = false
var orbit_index: int = 0
var angle: float = 0.0

# Movement mode
enum MoveMode { TRANSIT, ORBITAL }
var move_mode: MoveMode = MoveMode.TRANSIT
var _transit_progress: float = 0.0
var _transit_direction: int = 1

# Visual
@export var enemy_color: Color = Color(0.7, 0.2, 0.8, 1.0)       # Purple
@export var dark_color: Color = Color(0.4, 0.1, 0.5, 1.0)
@export var glow_color: Color = Color(0.8, 0.2, 0.9, 0.4)
@export var edge_color: Color = Color(1.0, 0.4, 0.8, 0.6)
@export var enemy_size: float = 14.0

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = enemy_size * 0.8
	_collision_shape.shape = shape
	add_child(_collision_shape)

	collision_layer = 2
	collision_mask = 1

	area_entered.connect(_on_area_entered)


## Configures the moving enemy from level/enemy data.
func initialize(data: Dictionary) -> void:
	speed = float(data.get("speed", 0.5))
	patrol = data.get("patrol", false)
	orbit_index = data.get("orbit_index", 0)
	enemy_size = float(data.get("size", 14.0))

	var parent_system = _get_orbit_system()

	# Path nodes: list of node_ids to follow
	var node_ids: Array = data.get("path_nodes", [])
	path_nodes.clear()
	for nid in node_ids:
		var node_ref = parent_system.get_node_by_id(nid)
		if node_ref:
			path_nodes.append(node_ref)

	current_path_index = data.get("start_index", 0)
	angle = deg_to_rad(float(data.get("angle", 0.0)))
	_transit_progress = 0.0
	_transit_direction = 1

	# If we have a path, start in transit mode
	if path_nodes.size() >= 2:
		move_mode = MoveMode.TRANSIT
	elif path_nodes.size() == 1:
		move_mode = MoveMode.ORBITAL

	# Update collision shape
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape.radius = enemy_size * 0.8

	_update_position()


## Finds the OrbitSystem ancestor.
func _get_orbit_system() -> OrbitSystem:
	var parent = get_parent()
	while parent:
		if parent is OrbitSystem:
			return parent
		parent = parent.get_parent()
	return null


## Updates position based on current movement mode.
func _update_position() -> void:
	match move_mode:
		MoveMode.TRANSIT:
			_update_transit_position()
		MoveMode.ORBITAL:
			_update_orbital_position()


## Linear interpolation between current and next path node.
func _update_transit_position() -> void:
	if path_nodes.size() < 2:
		return

	var idx = current_path_index
	var next_idx = (idx + 1) % path_nodes.size()

	var start_pos = path_nodes[idx].position
	var end_pos = path_nodes[next_idx].position
	position = start_pos.lerp(end_pos, _transit_progress)

	# Update the orbit angle for drawing orientation
	if start_node_for_idx(idx):
		var radius = start_node_for_idx(idx).get_orbit_radius(orbit_index)
		# Rough approximation of angle for visual orientation
		angle = atan2(position.y - start_pos.y, position.x - start_pos.x)


func start_node_for_idx(idx: int) -> OrbitNode:
	if idx >= 0 and idx < path_nodes.size():
		return path_nodes[idx]
	return null


## Orbital position around current path node.
func _update_orbital_position() -> void:
	if path_nodes.size() == 0:
		return
	var node_ref = path_nodes[0]
	var radius = node_ref.get_orbit_radius(orbit_index)
	position = node_ref.position + Vector2(cos(angle), sin(angle)) * radius


func _process(delta: float) -> void:
	match move_mode:
		MoveMode.TRANSIT:
			_transit_progress += speed * _transit_direction * delta
			if _transit_progress >= 1.0:
				_transit_progress = 1.0
				current_path_index = (current_path_index + 1) % path_nodes.size()
				if current_path_index == 0 and not patrol:
					# Reached end of one-way path
					_transit_progress = 0.0
					move_mode = MoveMode.ORBITAL
				else:
					_transit_progress = 0.0
			_update_transit_position()

		MoveMode.ORBITAL:
			if path_nodes.size() > 0:
				var node_ref = path_nodes[0]
				if node_ref:
					var orbit_speed = node_ref.get_orbit_speed(orbit_index)
					angle += (orbit_speed + speed * 0.05) * delta
					_update_orbital_position()

	queue_redraw()


func _draw() -> void:
	# Glow behind
	draw_circle(Vector2.ZERO, enemy_size * 1.2, glow_color)

	# Diamond/rhombus shape using 4 points
	var points = PackedVector2Array()
	points.append(Vector2(0.0, -enemy_size))                     # Top
	points.append(Vector2(enemy_size * 0.7, 0.0))                # Right
	points.append(Vector2(0.0, enemy_size))                      # Bottom
	points.append(Vector2(-enemy_size * 0.7, 0.0))               # Left

	draw_colored_polygon(points, enemy_color)

	# Inner darker diamond
	var inner_points = PackedVector2Array()
	inner_points.append(Vector2(0.0, -enemy_size * 0.65))
	inner_points.append(Vector2(enemy_size * 0.45, 0.0))
	inner_points.append(Vector2(0.0, enemy_size * 0.65))
	inner_points.append(Vector2(-enemy_size * 0.45, 0.0))
	draw_colored_polygon(inner_points, dark_color)

	# Edge glow lines
	draw_line(Vector2(0.0, -enemy_size), Vector2(enemy_size * 0.7, 0.0), edge_color, 1.5)
	draw_line(Vector2(enemy_size * 0.7, 0.0), Vector2(0.0, enemy_size), edge_color, 1.5)
	draw_line(Vector2(0.0, enemy_size), Vector2(-enemy_size * 0.7, 0.0), edge_color, 1.5)
	draw_line(Vector2(-enemy_size * 0.7, 0.0), Vector2(0.0, -enemy_size), edge_color, 1.5)

	# Bright center
	var core = Color.WHITE
	core.a = 0.5
	draw_circle(Vector2.ZERO, enemy_size * 0.15, core)


func _on_area_entered(area: Area2D) -> void:
	if area is PlayerOrbiter:
		SignalBus.player_hit.emit(1, self)
