extends Area2D
class_name Obstacle

## An obstacle that orbits around an OrbitNode.
## Colliding with the player emits SignalBus.player_hit.

# State
var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var obstacle_size: float = 10.0
var moving: bool = false
var move_speed: float = 0.0
var move_range: float = 0.0

# Offset from normal orbital position (for moving obstacles)
var _move_offset: float = 0.0
var _move_direction: float = 1.0

# Visual
@export var obstacle_color: Color = Color(1.0, 0.2, 0.2, 1.0)      # Red neon
@export var glow_color: Color = Color(1.0, 0.1, 0.1, 0.4)
@export var line_width: float = 2.0

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	# Setup collision
	_collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(obstacle_size * 2.0, obstacle_size * 2.0)
	_collision_shape.shape = shape
	add_child(_collision_shape)
	
	collision_layer = 2  # "obstacles" layer
	collision_mask = 1   # Detect player
	
	area_entered.connect(_on_area_entered)
	
	_move_offset = 0.0
	_move_direction = 1.0 if randf() > 0.5 else -1.0


## Initializes the obstacle from level data.
func initialize(data: Dictionary) -> void:
	node_ref = get_node_by_id_from_parent(data.get("node_id", ""))
	orbit_index = data.get("orbit_index", 0)
	angle = deg_to_rad(float(data.get("angle", 0)))
	obstacle_size = float(data.get("size", 10.0))
	
	# Movement parameters
	moving = data.get("moving", false)
	move_speed = float(data.get("move_speed", 0.0))
	move_range = float(data.get("move_range", 0.0))
	
	# Update collision shape size
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape.size = Vector2(obstacle_size * 2.0, obstacle_size * 2.0)
	
	_update_position()


## Finds an OrbitNode by ID from the parent OrbitSystem.
func get_node_by_id_from_parent(node_id: String) -> OrbitNode:
	var parent = get_parent()
	while parent:
		if parent is OrbitSystem:
			return parent.get_node_by_id(node_id)
		parent = parent.get_parent()
	return null


## Updates position using polar coordinates, with optional movement offset.
func _update_position() -> void:
	if not node_ref:
		return
	
	var radius = node_ref.get_orbit_radius(orbit_index)
	var current_angle = angle + _move_offset if moving else angle
	position = node_ref.position + Vector2(cos(current_angle), sin(current_angle)) * radius


func _process(delta: float) -> void:
	if not node_ref:
		return
	
	# Orbit with the same speed as the player on this orbit
	var speed = node_ref.get_orbit_speed(orbit_index)
	angle += speed * delta
	
	# Movement animation (oscillation along the orbit)
	if moving and move_range > 0:
		_move_offset += _move_direction * move_speed * delta
		if abs(_move_offset) >= move_range:
			_move_direction *= -1
			_move_offset = clamp(_move_offset, -move_range, move_range)
	
	_update_position()
	queue_redraw()


func _draw() -> void:
	# Glow behind
	var glow = glow_color
	
	# Draw as a square/rectangle with neon glow
	
	# Glow layer
	draw_rect(Rect2(-obstacle_size - 3.0, -obstacle_size - 3.0, obstacle_size * 2.0 + 6.0, obstacle_size * 2.0 + 6.0), glow)
	
	# Main body - neon red square
	draw_rect(Rect2(-obstacle_size, -obstacle_size, obstacle_size * 2.0, obstacle_size * 2.0), obstacle_color)
	
	# Bright inner
	var inner_color = Color(1.0, 0.5, 0.5, 0.8)
	draw_rect(Rect2(-obstacle_size * 0.5, -obstacle_size * 0.5, obstacle_size, obstacle_size), inner_color)
	
	# If moving, draw direction indicators (small triangles)
	if moving:
		var arrow_color = Color(1.0, 0.8, 0.3, 0.7)
		# Left arrow
		draw_line(Vector2(-obstacle_size * 0.8, 0), Vector2(-obstacle_size * 1.3, 0), arrow_color, 1.5)
		draw_line(Vector2(-obstacle_size * 1.3, 0), Vector2(-obstacle_size * 1.0, -obstacle_size * 0.3), arrow_color, 1.0)
		draw_line(Vector2(-obstacle_size * 1.3, 0), Vector2(-obstacle_size * 1.0, obstacle_size * 0.3), arrow_color, 1.0)
		# Right arrow
		draw_line(Vector2(obstacle_size * 0.8, 0), Vector2(obstacle_size * 1.3, 0), arrow_color, 1.5)
		draw_line(Vector2(obstacle_size * 1.3, 0), Vector2(obstacle_size * 1.0, -obstacle_size * 0.3), arrow_color, 1.0)
		draw_line(Vector2(obstacle_size * 1.3, 0), Vector2(obstacle_size * 1.0, obstacle_size * 0.3), arrow_color, 1.0)


func _on_area_entered(area: Area2D) -> void:
	if area is PlayerOrbiter:
		SignalBus.player_hit.emit(1, self)
