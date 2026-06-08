extends Area2D
class_name Mine

## A mine enemy that explodes when the player gets too close.
## Visual: spiked sphere with neon red pulsing danger glow.

# State
var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var mine_size: float = 12.0
var trigger_radius: float = 30.0
var explosive_damage: int = 3

# Visual
@export var mine_color: Color = Color(1.0, 0.2, 0.1, 1.0)        # Neon red
@export var dark_color: Color = Color(0.6, 0.1, 0.05, 1.0)
@export var glow_color: Color = Color(1.0, 0.1, 0.05, 0.5)
@export var spike_color: Color = Color(1.0, 0.4, 0.1, 1.0)

# Animation
var _pulse_phase: float = 0.0
var _pulse_scale: float = 1.0
var _exploded: bool = false

# Collision
var _collision_shape: CollisionShape2D = null
var _trigger_shape: CollisionShape2D = null


func _ready() -> void:
	# Small collision shape for the mine itself
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = mine_size
	_collision_shape.shape = shape
	add_child(_collision_shape)

	collision_layer = 2
	collision_mask = 0  # We detect player via distance, not Godot collision

	area_entered.connect(_on_area_entered)


## Configures the mine from level/enemy data.
func initialize(data: Dictionary) -> void:
	var parent_system = _get_orbit_system()
	var node_id = data.get("node_id", "")
	if parent_system:
		node_ref = parent_system.get_node_by_id(node_id)
	orbit_index = data.get("orbit_index", 0)
	angle = deg_to_rad(float(data.get("angle", 0.0)))
	mine_size = float(data.get("size", 12.0))
	trigger_radius = float(data.get("trigger_radius", 30.0))
	explosive_damage = int(data.get("damage", 3))

	# Update collision shape
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape.radius = mine_size

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


func _process(delta: float) -> void:
	if _exploded or not node_ref:
		return

	# Orbit movement
	var orbit_speed = node_ref.get_orbit_speed(orbit_index)
	angle += orbit_speed * delta
	_update_position()

	# Pulse animation — size oscillates for danger warning
	_pulse_phase += delta * 3.0
	_pulse_scale = 1.0 + 0.15 * sin(_pulse_phase)

	# Detect player by distance (world space)
	var player = _find_player()
	if player and not _exploded:
		var dist = global_position.distance_to(player.global_position)
		if dist <= trigger_radius:
			_explode(player)

	queue_redraw()


## Finds the PlayerOrbiter in the scene.
func _find_player() -> PlayerOrbiter:
	var system = _get_orbit_system()
	if system and system.player:
		return system.player
	return null


## Triggers the mine explosion.
func _explode(player: PlayerOrbiter) -> void:
	if _exploded:
		return
	_exploded = true

	# Create explosion particles
	var particles = ExplosionParticles.new()
	get_tree().current_scene.add_child(particles)
	particles.explode(global_position, mine_color)

	# Hide the mine
	hide()
	set_process(false)
	set_physics_process(false)
	collision_layer = 0

	# Damage the player
	SignalBus.player_hit.emit(explosive_damage, self)

	# Auto-free after a delay
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(queue_free)


func _draw() -> void:
	if _exploded:
		return

	var size = mine_size * _pulse_scale

	# Outer danger glow (pulsing)
	var glow = glow_color
	glow.a = 0.3 + 0.2 * sin(_pulse_phase * 2.0)
	draw_circle(Vector2.ZERO, size + 6.0 + 3.0 * sin(_pulse_phase), glow)

	# Main sphere body
	draw_circle(Vector2.ZERO, size, mine_color)

	# Darker core
	draw_circle(Vector2.ZERO, size * 0.5, dark_color)

	# Spikes around the sphere
	var spike_count = 8
	for i in range(spike_count):
		var spike_angle = (float(i) / spike_count) * TAU + _pulse_phase * 0.5
		var spike_base = Vector2(cos(spike_angle), sin(spike_angle)) * size
		var spike_tip = Vector2(cos(spike_angle), sin(spike_angle)) * (size * 1.35)
		var spike_width = 2.5

		# Draw each spike as a small triangle (line with width)
		draw_line(spike_base, spike_tip, spike_color, spike_width)
		# Spike tip highlight
		draw_circle(spike_tip, spike_width * 0.5, Color(1.0, 0.7, 0.3, 0.8))

	# Bright inner core
	var core = Color.WHITE
	core.a = 0.4
	draw_circle(Vector2.ZERO, size * 0.2, core)


func _on_area_entered(area: Area2D) -> void:
	if _exploded:
		return
	if area is PlayerOrbiter:
		_explode(area)
