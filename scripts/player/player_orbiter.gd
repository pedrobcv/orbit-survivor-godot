extends Area2D
class_name PlayerOrbiter

## Player with lives, combat, and orbit mechanics.
## Tap to switch orbit. Collide with enemy = lose life. Enemy in same orbit = destroy it.

signal orbit_changed(node_id: String, orbit_index: int)
signal lives_changed(lives: int)

# Constants
const TWEEN_TIME: float = 0.2
const JUMP_TIME: float = 0.3

# Orbit state
var current_node: OrbitNode = null
var current_orbit_index: int = 0
var orbit_angle: float = 0.0
var speed_mult: float = 1.0
var invulnerable: bool = false

# Jump state
var _is_transitioning: bool = false
var _target_node: OrbitNode = null
var _target_orbit_index: int = 0
var _target_angle: float = 0.0
var _transition_t: float = 0.0
var _start_position: Vector2 = Vector2.ZERO
var _start_angle: float = 0.0

# Lives
var lives: int = 3
var max_lives: int = 3

# Visual
@export var player_radius: float = 8.0
@export var player_color: Color = Color(0.0, 0.8, 1.0, 1.0)
var _blink_timer: float = 0.0

func _ready() -> void:
	lives = max_lives
	# Collision
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = player_radius + 2.0
	shape.shape = circle
	add_child(shape)
	
	collision_layer = 1
	collision_mask = 2 | 4  # Layer 2 (obstacles) + Layer 4 (enemies)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _draw() -> void:
	if invulnerable and int(_blink_timer * 10) % 2 == 0:
		return  # Blink when invulnerable
	# Glow
	draw_circle(Vector2.ZERO, player_radius + 4.0, Color(0.0, 0.5, 1.0, 0.3))
	# Body - draw as a small ship triangle
	var points = PackedVector2Array()
	points.append(Vector2(0, -player_radius))
	points.append(Vector2(-player_radius * 0.7, player_radius * 0.5))
	points.append(Vector2(player_radius * 0.7, player_radius * 0.5))
	draw_colored_polygon(points, player_color)
	# Core
	draw_circle(Vector2.ZERO, player_radius * 0.3, Color.WHITE)

func initialize(node_ref: OrbitNode, orbit_index: int, angle: float) -> void:
	current_node = node_ref
	current_orbit_index = orbit_index
	orbit_angle = angle
	_update_position()
	emit_orbits()

func _process(delta: float) -> void:
	if invulnerable:
		_blink_timer += delta
		queue_redraw()
	if not current_node:
		return
	if _is_transitioning:
		_handle_transition(delta)
		return
	var speed = current_node.get_orbit_speed(current_orbit_index) * speed_mult
	orbit_angle += speed * delta
	_update_position()

func _update_position() -> void:
	if not current_node: return
	var radius = current_node.get_orbit_radius(current_orbit_index)
	position = current_node.position + Vector2(cos(orbit_angle), sin(orbit_angle)) * radius

func _handle_transition(delta: float) -> void:
	_transition_t += delta
	var duration = JUMP_TIME if _target_node != current_node else TWEEN_TIME
	if _transition_t >= duration:
		_finish_transition()
		return
	var t = clamp(_transition_t / duration, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	if _target_node != current_node:
		var target_pos = _target_node.position + Vector2(cos(_target_angle), sin(_target_angle)) * _target_node.get_orbit_radius(_target_orbit_index)
		position = _start_position.lerp(target_pos, t)
	else:
		var diff = _target_angle - _start_angle
		if diff > PI: diff -= TAU
		elif diff < -PI: diff += TAU
		orbit_angle = _start_angle + diff * t
		_update_position()

func _finish_transition() -> void:
	current_node = _target_node
	current_orbit_index = _target_orbit_index
	orbit_angle = _target_angle
	_is_transitioning = false
	_update_position()
	queue_redraw()
	emit_orbits()
	# Check if we landed on an enemy — destroy it!
	_check_enemy_contact()

func jump_to_orbit(node_ref: OrbitNode, orbit_index: int, angle: float, smooth: bool = true) -> void:
	if not node_ref or orbit_index < 0 or orbit_index >= node_ref.get_orbit_count(): return
	if smooth:
		_start_transition(node_ref, orbit_index, angle)
	else:
		current_node = node_ref
		current_orbit_index = orbit_index
		orbit_angle = angle
		_update_position()
		emit_orbits()
		_check_enemy_contact()

func jump_to_node(new_node: OrbitNode, orbit_index: int, entry_angle: float, smooth: bool = true) -> void:
	if not new_node or orbit_index < 0 or orbit_index >= new_node.get_orbit_count(): return
	if smooth:
		_start_transition(new_node, orbit_index, entry_angle)
	else:
		current_node = new_node
		current_orbit_index = orbit_index
		orbit_angle = entry_angle
		_update_position()
		emit_orbits()
		_check_enemy_contact()

func _start_transition(node_ref: OrbitNode, orbit_index: int, angle: float) -> void:
	_target_node = node_ref
	_target_orbit_index = orbit_index
	_target_angle = angle
	_start_position = position
	_start_angle = orbit_angle
	_transition_t = 0.0
	_is_transitioning = true

func handle_tap() -> void:
	if _is_transitioning or not current_node: return
	var orbit_system = _get_orbit_system()
	if not orbit_system: return
	var node_count = current_node.get_orbit_count()
	var next = current_orbit_index + 1
	if next < node_count:
		jump_to_orbit(current_node, next, orbit_angle)
	else:
		var closest = orbit_system.get_closest_node(position)
		if closest and closest != current_node:
			jump_to_node(closest, 0, orbit_angle)
		elif closest == current_node:
			jump_to_orbit(current_node, 0, orbit_angle)

func _check_enemy_contact() -> void:
	# Look for enemies at our current position
	if not current_node: return
	var orbit_sys = _get_orbit_system()
	if not orbit_sys: return
	for child in orbit_sys.get_children():
		if child is EnemyShip and child.node_ref == current_node and child.orbit_index == current_orbit_index:
			# Check if close enough
			var dist = position.distance_to(child.position)
			if dist < player_radius + child.enemy_radius + 5.0:
				child.destroy()
				SignalBus.enemy_killed.emit(child)

func _on_body_entered(body: Node) -> void:
	if invulnerable: return
	if body is Obstacle:
		_take_damage()
	elif body is EnemyShip:
		_take_damage()

func _on_area_entered(area: Area2D) -> void:
	if invulnerable: return
	if area is Obstacle:
		_take_damage()
	elif area is EnemyShip:
		_take_damage()
	elif area is Portal:
		if not area.locked:
			SignalBus.portal_reached.emit(area)

func _take_damage() -> void:
	if invulnerable: return
	lives -= 1
	lives_changed.emit(lives)
	invulnerable = true
	_blink_timer = 0.0
	SignalBus.player_hit.emit(1, null)
	if lives <= 0:
		SignalBus.player_died.emit()
	else:
		# Invulnerable for 1.5 seconds
		await get_tree().create_timer(1.5).timeout
		invulnerable = false
		queue_redraw()

func emit_orbits() -> void:
	if not current_node: return
	var r = current_node.get_orbit_radius(current_orbit_index)
	var s = current_node.get_orbit_speed(current_orbit_index) * speed_mult
	SignalBus.orbit_changed.emit(self, r, s)
	orbit_changed.emit(current_node.node_id, current_orbit_index)

func _get_orbit_system() -> OrbitSystem:
	var p = get_parent()
	while p:
		if p is OrbitSystem: return p
		p = p.get_parent()
	return null
