extends Area2D
class_name Laser

## A laser turret enemy that periodically fires a thin bright red laser beam.
## The laser alternates between active (visible + damaging) and cooldown phases.

# State
var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var laser_length: float = 80.0
var laser_width: float = 6.0
var active_duration: float = 2.0
var cooldown_duration: float = 3.0
var current_state: String = "cooldown"   # "active" or "cooldown"
var timer: float = 0.0

# Visual
@export var laser_color: Color = Color(1.0, 0.1, 0.1, 1.0)       # Bright red
@export var glow_color: Color = Color(1.0, 0.05, 0.05, 0.4)
@export var core_color: Color = Color(1.0, 0.6, 0.6, 1.0)        # White-hot core
@export var turret_color: Color = Color(0.8, 0.2, 0.2, 1.0)      # Turret base

# Pulso animation
var _pulse_phase: float = 0.0
var _flash_intensity: float = 0.0

# Collision shape (dynamically sized based on laser length)
var _collision_shape: CollisionShape2D = null
var _collision_rect: RectangleShape2D = null


func _ready() -> void:
	# Setup collision as a thin rectangle
	_collision_shape = CollisionShape2D.new()
	_collision_rect = RectangleShape2D.new()
	_collision_rect.size = Vector2(laser_width, laser_length)
	_collision_shape.shape = _collision_rect
	# Offset so the origin is at the turret base, beam extends forward
	_collision_shape.position = Vector2(0.0, -laser_length / 2.0)
	add_child(_collision_shape)

	collision_layer = 2  # enemies layer
	# Start disabled — only collide when active
	collision_mask = 0

	area_entered.connect(_on_area_entered)

	timer = cooldown_duration
	current_state = "cooldown"


## Configures the laser from level/enemy data.
func initialize(data: Dictionary) -> void:
	var parent_system = _get_orbit_system()
	var node_id = data.get("node_id", "")
	if parent_system:
		node_ref = parent_system.get_node_by_id(node_id)
	orbit_index = data.get("orbit_index", 0)
	angle = deg_to_rad(float(data.get("angle", 0.0)))
	laser_length = float(data.get("laser_length", 80.0))
	laser_width = float(data.get("laser_width", 6.0))
	active_duration = float(data.get("active_duration", 2.0))
	cooldown_duration = float(data.get("cooldown_duration", 3.0))

	# Update collision shape
	if _collision_rect:
		_collision_rect.size = Vector2(laser_width, laser_length)
		_collision_shape.position = Vector2(0.0, -laser_length / 2.0)

	_update_position()


## Finds the OrbitSystem ancestor.
func _get_orbit_system() -> OrbitSystem:
	var parent = get_parent()
	while parent:
		if parent is OrbitSystem:
			return parent
		parent = parent.get_parent()
	return null


## Updates position using polar coordinates.
func _update_position() -> void:
	if not node_ref:
		return
	var radius = node_ref.get_orbit_radius(orbit_index)
	position = node_ref.position + Vector2(cos(angle), sin(angle)) * radius


## Activates the laser beam (visible + damaging).
func activate() -> void:
	current_state = "active"
	timer = active_duration
	collision_mask = 1  # Enable detection of player
	_flash_intensity = 1.0
	queue_redraw()


## Deactivates the laser beam (hidden + safe).
func deactivate() -> void:
	current_state = "cooldown"
	timer = cooldown_duration
	collision_mask = 0  # Disable collision
	_flash_intensity = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not node_ref:
		return

	# Orbit rotation
	var orbit_speed = node_ref.get_orbit_speed(orbit_index)
	angle += orbit_speed * delta
	_update_position()

	# Timer countdown
	timer -= delta
	if timer <= 0.0:
		if current_state == "active":
			deactivate()
		else:
			activate()

	# Pulse animation
	_pulse_phase += delta * 4.0
	if current_state == "active":
		_flash_intensity = 0.8 + 0.2 * sin(_pulse_phase * 3.0)
	else:
		_flash_intensity = max(0.0, _flash_intensity - delta * 2.0)

	queue_redraw()


func _draw() -> void:
	# Draw turret base (small circle at origin)
	var turret_glow = glow_color
	turret_glow.a = 0.3
	draw_circle(Vector2.ZERO, 10.0, turret_glow)
	draw_circle(Vector2.ZERO, 7.0, turret_color)

	# Laser beam (only when active or fading out)
	if current_state == "active" or _flash_intensity > 0.01:
		var intensity = _flash_intensity

		# Outer glow (wide, faint)
		var outer_glow = glow_color
		outer_glow.a = 0.15 * intensity
		var glow_rect = Rect2(-laser_width * 2.0, -laser_length, laser_width * 4.0, laser_length)
		draw_rect(glow_rect, outer_glow)

		# Main laser beam
		var beam_color = laser_color
		beam_color.a = intensity
		var beam_rect = Rect2(-laser_width / 2.0, -laser_length, laser_width, laser_length)
		draw_rect(beam_rect, beam_color)

		# White-hot core
		var core = core_color
		core.a = 0.7 * intensity
		var core_rect = Rect2(-laser_width * 0.3, -laser_length, laser_width * 0.6, laser_length)
		draw_rect(core_rect, core)


func _on_area_entered(area: Area2D) -> void:
	if current_state != "active":
		return
	if area is PlayerOrbiter:
		SignalBus.player_hit.emit(1, self)
