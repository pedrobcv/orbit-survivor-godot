extends Area2D
class_name Portal

## Exit portal that completes the level when reached.
## Can be locked, requiring a key to open.

# State
var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var locked: bool = false
var required_key: String = ""

# Visual
@export var portal_radius: float = 12.0
@export var portal_color: Color = Color(0.8, 0.9, 1.0, 1.0)     # White-blue neon
@export var glow_color: Color = Color(0.4, 0.6, 1.0, 0.5)
@export var locked_color: Color = Color(0.8, 0.3, 0.3, 1.0)     # Red when locked

# Animation
var _rotation_angle: float = 0.0
var _pulse_phase: float = 0.0

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	# Setup collision
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = portal_radius + 4.0
	_collision_shape.shape = shape
	add_child(_collision_shape)
	
	collision_layer = 0
	collision_mask = 1  # Detect player
	
	area_entered.connect(_on_area_entered)


## Initializes the portal on a specific node, orbit, and angle.
func initialize(node: OrbitNode, orbit_idx: int, ang: float, is_locked: bool, key: String) -> void:
	node_ref = node
	orbit_index = orbit_idx
	angle = ang
	locked = is_locked
	required_key = key
	
	_update_position()


## Updates position using polar coordinates.
func _update_position() -> void:
	if not node_ref:
		return
	var radius = node_ref.get_orbit_radius(orbit_index)
	position = node_ref.position + Vector2(cos(angle), sin(angle)) * radius


func _process(delta: float) -> void:
	if not node_ref:
		return
	
	# Rotation animation
	_rotation_angle += delta * 2.0
	_pulse_phase += delta * 3.0
	
	queue_redraw()


func _draw() -> void:
	var current_color = portal_color if not locked else locked_color
	var pulse = sin(_pulse_phase) * 0.15 + 0.85  # Range 0.7 to 1.0
	
	# Outer glow ring
	var glow = glow_color
	if locked:
		glow = Color(0.8, 0.2, 0.2, 0.4)
	
	draw_circle(Vector2.ZERO, portal_radius * 1.3 * pulse, glow)
	
	# Portal ring (circle with thick border effect)
	draw_arc(Vector2.ZERO, portal_radius * pulse, _rotation_angle, _rotation_angle + TAU * 0.75, 32, current_color, 2.5)
	draw_arc(Vector2.ZERO, portal_radius * pulse, _rotation_angle + TAU * 0.25, _rotation_angle + TAU * 0.5, 32, current_color, 1.5)
	
	# Inner circle
	var inner_color = current_color
	inner_color.a = 0.3
	draw_circle(Vector2.ZERO, portal_radius * 0.6 * pulse, inner_color)
	
	# Center bright point
	var core = Color.WHITE
	core.a = 0.6
	draw_circle(Vector2.ZERO, portal_radius * 0.2 * pulse, core)
	
	# If locked, draw a lock symbol
	if locked:
		var lock_color = Color(1.0, 0.3, 0.3, 0.9)
		# Simple lock body (rectangle)
		var lock_rect = Rect2(-3.0, -4.0, 6.0, 7.0)
		draw_rect(lock_rect, lock_color)
		# Lock shackle (arc)
		draw_arc(Vector2(0.0, -4.0), 3.0, PI, TAU, 16, lock_color, 1.5)


## Unlocks the portal with the given key_id.
func unlock(key_id: String) -> bool:
	if locked and key_id == required_key:
		locked = false
		queue_redraw()
		return true
	return false


## Called when player enters the portal area.
func _on_area_entered(area: Area2D) -> void:
	if area is PlayerOrbiter and not locked:
		SignalBus.portal_reached.emit(self)
