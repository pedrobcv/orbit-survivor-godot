extends Area2D
class_name PlayerOrbiter

## The player character that orbits around OrbitNodes.
## Responds to screen taps to switch orbits or jump between nodes.

# Signals
signal orbit_changed(node_id: String, orbit_index: int)

# Constants
const TWEEN_TIME: float = 0.25  # Duration for smooth orbit transitions
const JUMP_TIME: float = 0.35   # Duration for node-to-node jumps

# Orbit state
var current_node: OrbitNode = null
var current_orbit_index: int = 0
var orbit_angle: float = 0.0
var speed_mult: float = 1.0

# Jump / transition state
var _is_transitioning: bool = false
var _target_node: OrbitNode = null
var _target_orbit_index: int = 0
var _target_angle: float = 0.0
var _transition_t: float = 0.0
var _start_position: Vector2 = Vector2.ZERO
var _start_angle: float = 0.0

# Visual
@export var player_radius: float = 6.0
@export var player_color: Color = Color(0.0, 0.8, 1.0, 1.0)  # Cyan
@export var glow_color: Color = Color(0.0, 0.5, 1.0, 0.4)

# Collision
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	# Setup collision shape
	_collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = player_radius + 2.0  # Slightly larger than visual for forgiving collision
	_collision_shape.shape = shape
	add_child(_collision_shape)
	
	# Set collision layers/masks
	# Player is on layer 1, collides with obstacles (layer 2)
	collision_layer = 1
	collision_mask = 2  # "obstacles" layer
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Draw the player circle
	queue_redraw()


func _draw() -> void:
	_draw_player()


## Draws the player's visual (small glowing circle).
func _draw_player() -> void:
	# Outer glow
	draw_circle(Vector2.ZERO, player_radius + 3.0, glow_color)
	# Main body
	draw_circle(Vector2.ZERO, player_radius, player_color)
	# Bright core
	draw_circle(Vector2.ZERO, player_radius * 0.4, Color.WHITE)


## Initializes the player on a specific node, orbit, and angle.
func initialize(node_ref: OrbitNode, orbit_index: int, angle: float) -> void:
	current_node = node_ref
	current_orbit_index = orbit_index
	orbit_angle = angle
	
	_update_position()
	
	# Emit orbit changed signal
	SignalBus.orbit_changed.emit(self, node_ref.get_orbit_radius(orbit_index), node_ref.get_orbit_speed(orbit_index) * speed_mult)
	orbit_changed.emit(node_ref.node_id, orbit_index)


## Called every frame. Moves player along the current orbit.
func _process(delta: float) -> void:
	if not current_node:
		return
	
	if _is_transitioning:
		_handle_transition(delta)
		return
	
	# Normal orbital movement
	var speed = current_node.get_orbit_speed(current_orbit_index) * speed_mult
	orbit_angle += speed * delta
	
	_update_position()


## Updates the player's position using polar coordinates.
func _update_position() -> void:
	if not current_node:
		return
	
	var radius = current_node.get_orbit_radius(current_orbit_index)
	position = current_node.position + Vector2(cos(orbit_angle), sin(orbit_angle)) * radius


## Smooth transition to a different orbit on the same or different node.
func _handle_transition(delta: float) -> void:
	_transition_t += delta
	
	if _transition_t >= (_target_is_node_jump() if _target_node != current_node else JUMP_TIME if _target_node != current_node else TWEEN_TIME):
		# Transition complete
		_finish_transition()
		return
	
	var duration = TWEEN_TIME
	if _target_node != current_node:
		duration = JUMP_TIME
	
	var t = clamp(_transition_t / duration, 0.0, 1.0)
	# Ease in-out cubic for smooth motion
	t = t * t * (3.0 - 2.0 * t)
	
	if _target_node != current_node:
		# Interpolate position from start to target
		var target_pos = _target_node.position + Vector2(cos(_target_angle), sin(_target_angle)) * _target_node.get_orbit_radius(_target_orbit_index)
		position = _start_position.lerp(target_pos, t)
	else:
		# Same node: interpolate the angle
		var angle_diff = _target_angle - _start_angle
		# Shortest path
		if angle_diff > PI:
			angle_diff -= TAU
		elif angle_diff < -PI:
			angle_diff += TAU
		orbit_angle = _start_angle + angle_diff * t
		_update_position()
	
	queue_redraw()


## Checks if the current transition involves jumping to another node.
func _target_is_node_jump() -> bool:
	return _target_node != current_node


## Finishes the current transition by snapping to the target.
func _finish_transition() -> void:
	current_node = _target_node
	current_orbit_index = _target_orbit_index
	orbit_angle = _target_angle
	_is_transitioning = false
	
	_update_position()
	queue_redraw()
	
	# Emit signal
	SignalBus.orbit_changed.emit(self, current_node.get_orbit_radius(current_orbit_index), current_node.get_orbit_speed(current_orbit_index) * speed_mult)
	orbit_changed.emit(current_node.node_id, current_orbit_index)


## Jumps to a different orbit on the same node (or a different node).
## smooth: if true, animate the transition.
func jump_to_orbit(node_ref: OrbitNode, orbit_index: int, angle: float, smooth: bool = true) -> void:
	if not node_ref or orbit_index < 0 or orbit_index >= node_ref.get_orbit_count():
		return
	
	if smooth:
		_start_transition(node_ref, orbit_index, angle)
	else:
		current_node = node_ref
		current_orbit_index = orbit_index
		orbit_angle = angle
		_update_position()
		SignalBus.orbit_changed.emit(self, node_ref.get_orbit_radius(orbit_index), node_ref.get_orbit_speed(orbit_index) * speed_mult)
		orbit_changed.emit(node_ref.node_id, orbit_index)


## Jumps to a different node at the specified orbit and entry angle.
func jump_to_node(new_node_ref: OrbitNode, orbit_index: int, entry_angle: float, smooth: bool = true) -> void:
	if not new_node_ref or orbit_index < 0 or orbit_index >= new_node_ref.get_orbit_count():
		return
	
	if smooth:
		_start_transition(new_node_ref, orbit_index, entry_angle)
	else:
		current_node = new_node_ref
		current_orbit_index = orbit_index
		orbit_angle = entry_angle
		_update_position()
		SignalBus.orbit_changed.emit(self, new_node_ref.get_orbit_radius(orbit_index), new_node_ref.get_orbit_speed(orbit_index) * speed_mult)
		orbit_changed.emit(new_node_ref.node_id, orbit_index)


## Starts a smooth transition to a target node/orbit/angle.
func _start_transition(node_ref: OrbitNode, orbit_index: int, angle: float) -> void:
	_target_node = node_ref
	_target_orbit_index = orbit_index
	_target_angle = angle
	_start_position = position
	_start_angle = orbit_angle
	_transition_t = 0.0
	_is_transitioning = true


## Handles screen tap: switch to next orbit or jump to closest node.
func handle_tap() -> void:
	if _is_transitioning or not current_node:
		return
	
	var orbit_system = _get_orbit_system()
	if not orbit_system:
		return
	
	var node_count = current_node.get_orbit_count()
	var next_orbit = current_orbit_index + 1
	
	if next_orbit < node_count:
		# Move to the next orbit on the same node
		jump_to_orbit(current_node, next_orbit, orbit_angle)
	else:
		# All orbits exhausted: jump to the closest node
		var closest = orbit_system.get_closest_node(position)
		if closest and closest != current_node:
			jump_to_node(closest, 0, orbit_angle)
		elif closest == current_node:
			# Same node, wrap back to first orbit
			jump_to_orbit(current_node, 0, orbit_angle)


## Returns the OrbitSystem ancestor.
func _get_orbit_system() -> OrbitSystem:
	var parent = get_parent()
	while parent:
		if parent is OrbitSystem:
			return parent
		parent = parent.get_parent()
	return null


## Called when the player body/area collides with another body.
func _on_body_entered(body: Node) -> void:
	_handle_collision(body)


func _on_area_entered(area: Area2D) -> void:
	_handle_collision(area)


func _handle_collision(other: Node) -> void:
	# Check if it's an obstacle
	if other is Obstacle:
		SignalBus.player_hit.emit(1, other)
	
	# Check if it's a crystal
	if other is Crystal:
		if not other.collected:
			other.collect()
	
	# Check if it's a key
	if other is KeyItem:
		if not other.collected:
			other.collect()
	
	# Check if it's a portal
	if other is Portal:
		if not other.locked:
			SignalBus.portal_reached.emit(other)
