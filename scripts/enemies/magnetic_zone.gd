extends Area2D
class_name MagneticZone

## A zone of effect (not a direct enemy) that attracts or repels the player's orbital motion.
## Visual: large semi-transparent circle with wave animation, blue (attract) or red (repel).

# State
var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var zone_type: String = "attract"     # "attract" or "repel"
var strength: float = 1.0
var zone_radius: float = 50.0

# Visual
@export var attract_color: Color = Color(0.2, 0.4, 1.0, 0.25)    # Semi-transparent blue
@export var repel_color: Color = Color(1.0, 0.2, 0.2, 0.25)      # Semi-transparent red
@export var attract_border: Color = Color(0.3, 0.6, 1.0, 0.5)
@export var repel_border: Color = Color(1.0, 0.3, 0.3, 0.5)
@export var attract_core: Color = Color(0.5, 0.8, 1.0, 0.15)
@export var repel_core: Color = Color(1.0, 0.5, 0.5, 0.15)

# Animation
var _wave_phase: float = 0.0
var _wave_count: int = 3

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = zone_radius
	_collision_shape.shape = shape
	add_child(_collision_shape)

	# No collision layers — zones don't directly interact
	collision_layer = 0
	collision_mask = 0


## Configures the magnetic zone from level data.
func initialize(data: Dictionary) -> void:
	var parent_system = _get_orbit_system()
	var node_id = data.get("node_id", "")
	if parent_system:
		node_ref = parent_system.get_node_by_id(node_id)
	orbit_index = data.get("orbit_index", 0)
	angle = deg_to_rad(float(data.get("angle", 0.0)))
	zone_type = data.get("type", "attract")
	strength = float(data.get("strength", 1.0))
	zone_radius = float(data.get("radius", 50.0))

	# Update collision shape
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape.radius = zone_radius

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
	if not node_ref:
		return

	# Orbit with the node
	var orbit_speed = node_ref.get_orbit_speed(orbit_index)
	angle += orbit_speed * delta
	_update_position()

	# Wave animation
	_wave_phase += delta * 2.0

	# Apply magnetic effect to the player if they are on the same orbit
	_apply_magnetic_effect()

	queue_redraw()


## Applies magnetic attraction/repulsion to the player's orbital speed.
func _apply_magnetic_effect() -> void:
	var player = _find_player()
	if not player or not player.current_node:
		return

	# Only affect the player if they're orbiting the same node and same orbit index
	if player.current_node != node_ref:
		return
	if player.current_orbit_index != orbit_index:
		return

	# Calculate distance from player to this zone's center
	var dist = player.global_position.distance_to(global_position)

	# If player is within the zone radius, modify their orbital speed
	if dist <= zone_radius:
		# Strength falloff from center (linear)
		var influence = 1.0 - (dist / zone_radius)
		var speed_mod = strength * influence * 0.5  # Max 50% speed modification

		if zone_type == "attract":
			# Attract: increase orbital speed (pull player faster)
			player.speed_mult += speed_mod * get_process_delta_time()
		else:
			# Repel: decrease or reverse orbital speed
			player.speed_mult -= speed_mod * get_process_delta_time()

		# Clamp speed_mult to reasonable range
		player.speed_mult = clamp(player.speed_mult, 0.1, 5.0)


## Finds the PlayerOrbiter in the scene.
func _find_player() -> PlayerOrbiter:
	var system = _get_orbit_system()
	if system and system.player:
		return system.player
	return null


func _draw() -> void:
	var current_color = attract_color if zone_type == "attract" else repel_color
	var border_color = attract_border if zone_type == "attract" else repel_border
	var core_color = attract_core if zone_type == "attract" else repel_core

	# Main filled circle (semi-transparent)
	draw_circle(Vector2.ZERO, zone_radius, current_color)

	# Inner glow zone
	draw_circle(Vector2.ZERO, zone_radius * 0.5, core_color)

	# Wave rings
	for i in range(_wave_count):
		var wave_progress = fmod(_wave_phase + (float(i) / _wave_count) * TAU, TAU) / TAU
		var wave_radius = zone_radius * (0.3 + wave_progress * 0.7)
		var alpha = (1.0 - wave_progress) * 0.4

		var wave_color = border_color
		wave_color.a = alpha
		draw_arc(Vector2.ZERO, wave_radius, 0, TAU, 48, wave_color, 1.5)

	# Border ring
	draw_arc(Vector2.ZERO, zone_radius, 0, TAU, 48, border_color, 2.0)

	# Direction indicator icon
	var icon_size = zone_radius * 0.25
	if zone_type == "attract":
		# Arrow pointing inward (toward center)
		draw_line(Vector2(icon_size, 0.0), Vector2(0.0, 0.0), border_color, 2.0)
		draw_line(Vector2(0.0, 0.0), Vector2(-icon_size * 0.5, -icon_size * 0.3), border_color, 1.5)
		draw_line(Vector2(0.0, 0.0), Vector2(-icon_size * 0.5, icon_size * 0.3), border_color, 1.5)
		# "A" label
	else:
		# Arrow pointing outward (away from center)
		draw_line(Vector2(-icon_size, 0.0), Vector2(0.0, 0.0), border_color, 2.0)
		draw_line(Vector2(0.0, 0.0), Vector2(icon_size * 0.5, -icon_size * 0.3), border_color, 1.5)
		draw_line(Vector2(0.0, 0.0), Vector2(icon_size * 0.5, icon_size * 0.3), border_color, 1.5)
