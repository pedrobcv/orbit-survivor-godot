extends Area2D
class_name Crystal

## A collectible crystal that orbits around an OrbitNode.
## Emits SignalBus.crystal_collected when collected.

# State
var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var collected: bool = false

# Visual
@export var crystal_size: float = 5.0
@export var crystal_color: Color = Color(0.3, 0.9, 1.0, 1.0)   # Cyan neon
@export var glow_color: Color = Color(0.2, 0.8, 1.0, 0.5)

# Animation
var _rotation_angle: float = 0.0
var _pulse_phase: float = 0.0

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	# Setup collision as area
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = crystal_size + 3.0
	_collision_shape.shape = shape
	add_child(_collision_shape)
	
	# Set collision layers
	collision_layer = 0
	collision_mask = 1  # Detect player on layer 1
	
	area_entered.connect(_on_area_entered)


## Initializes the crystal on a specific node, orbit, and angle.
func initialize(node: OrbitNode, orbit_idx: int, ang: float) -> void:
	node_ref = node
	orbit_index = orbit_idx
	angle = ang
	collected = false
	
	_update_position()


## Updates position using polar coordinates relative to the node.
func _update_position() -> void:
	if not node_ref:
		return
	var radius = node_ref.get_orbit_radius(orbit_index)
	position = node_ref.position + Vector2(cos(angle), sin(angle)) * radius


func _process(delta: float) -> void:
	if collected or not node_ref:
		return
	
	# Slow rotation animation
	_rotation_angle += delta * 1.5
	_pulse_phase += delta * 2.0
	
	queue_redraw()


func _draw() -> void:
	if collected:
		return
	
	# Diamond/rhombus shape - rotating
	var size = crystal_size + sin(_pulse_phase) * 1.5  # Pulse effect
	
	# Glow
	draw_circle(Vector2.ZERO, size + 2.0, glow_color)
	
	# Crystal body (diamond using 4 points with rotation)
	var points = PackedVector2Array()
	var r = _rotation_angle
	points.append(Vector2(cos(r), sin(r)) * size)                  # Top
	points.append(Vector2(cos(r + PI * 0.5), sin(r + PI * 0.5)) * size * 0.6)  # Right
	points.append(Vector2(cos(r + PI), sin(r + PI)) * size)        # Bottom
	points.append(Vector2(cos(r + PI * 1.5), sin(r + PI * 1.5)) * size * 0.6)  # Left
	
	draw_colored_polygon(points, crystal_color)
	
	# Bright inner highlight
	var core = Color.WHITE
	core.a = 0.5
	draw_circle(Vector2.ZERO, size * 0.3, core)


## Called when the player area overlaps this crystal.
func collect() -> void:
	if collected:
		return
	collected = true
	hide()
	SignalBus.crystal_collected.emit(self, 100)
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if collected:
		return
	if area is PlayerOrbiter:
		collect()
