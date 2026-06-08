extends Area2D
class_name KeyItem

## A key collectible that orbits around an OrbitNode.
## Used to unlock locked portals.

# State
var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var collected: bool = false
var key_id: String = ""

# Visual
@export var key_size: float = 6.0
@export var key_color: Color = Color(1.0, 0.85, 0.2, 1.0)     # Gold/yellow neon
@export var glow_color: Color = Color(1.0, 0.7, 0.1, 0.5)

# Animation
var _rotation_angle: float = 0.0
var _pulse_phase: float = 0.0

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	# Setup collision
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = key_size + 4.0
	_collision_shape.shape = shape
	add_child(_collision_shape)
	
	collision_layer = 0
	collision_mask = 1  # Detect player
	
	area_entered.connect(_on_area_entered)


## Initializes the key on a specific node, orbit, angle, with a key_id.
func initialize(node: OrbitNode, orbit_idx: int, ang: float, key: String) -> void:
	node_ref = node
	orbit_index = orbit_idx
	angle = ang
	key_id = key
	collected = false
	
	_update_position()


## Updates position using polar coordinates.
func _update_position() -> void:
	if not node_ref:
		return
	var radius = node_ref.get_orbit_radius(orbit_index)
	position = node_ref.position + Vector2(cos(angle), sin(angle)) * radius


func _process(delta: float) -> void:
	if collected or not node_ref:
		return
	
	# Gentle floating rotation
	_rotation_angle += delta * 1.2
	_pulse_phase += delta * 1.5
	
	queue_redraw()


func _draw() -> void:
	if collected:
		return
	
	var pulse = sin(_pulse_phase) * 1.5 + key_size  # Gentle pulse
	
	# Glow
	draw_circle(Vector2.ZERO, pulse + 2.5, glow_color)
	
	# Draw a simple key shape
	var scale_factor = pulse / key_size
	var s = key_size * scale_factor
	
	# Key head (circle with hole)
	draw_circle(Vector2.ZERO, s, key_color)
	draw_circle(Vector2.ZERO, s * 0.4, Color(0.1, 0.1, 0.1, 1.0))  # Hole
	
	# Key shaft (rectangle extending right)
	var shaft_rect = Rect2(s * 0.2, -s * 0.2, s * 1.5, s * 0.4)
	draw_rect(shaft_rect, key_color)
	
	# Key teeth
	var tooth_y = s * 0.2
	var tooth_start_x = s * 1.0
	draw_rect(Rect2(tooth_start_x, tooth_y, s * 0.3, s * 0.3), key_color)
	draw_rect(Rect2(tooth_start_x + s * 0.4, -tooth_y - s * 0.3, s * 0.3, s * 0.3), key_color)
	
	# Bright core
	var core = Color.WHITE
	core.a = 0.4
	draw_circle(Vector2.ZERO, s * 0.25, core)


## Collects the key item.
func collect() -> void:
	if collected:
		return
	collected = true
	hide()
	SignalBus.key_collected.emit(self)
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if collected:
		return
	if area is PlayerOrbiter:
		collect()
