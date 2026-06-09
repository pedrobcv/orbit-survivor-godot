extends Area2D
class_name EnemyShip

## Enemy ship that orbits around nodes.
## Player can destroy it by jumping to its orbit.

signal destroyed(enemy: Node)

var node_ref: OrbitNode = null
var orbit_index: int = 0
var angle: float = 0.0
var speed_mult: float = 1.0
var alive: bool = true
var patrol_min: float = 0.0
var patrol_max: float = 0.0
var _hover_offset: float = 0.0
var _hover_dir: float = 1.0

@export var enemy_radius: float = 8.0
@export var enemy_color: Color = Color(1.0, 0.2, 0.2, 1.0)

func _ready() -> void:
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = enemy_radius
	shape.shape = circle
	add_child(shape)
	
	collision_layer = 4  # Layer 4 = enemies
	collision_mask = 1   # Detect player on layer 1
	
	area_entered.connect(_on_area_entered)
	_hover_dir = 1.0 if randf() > 0.5 else -1.0
	queue_redraw()

func _draw() -> void:
	if not alive: return
	# Draw as red triangle pointing "forward" in orbit direction
	var r = enemy_radius
	# Main body
	var pts = PackedVector2Array()
	pts.append(Vector2(0, -r))
	pts.append(Vector2(-r * 0.6, r * 0.4))
	pts.append(Vector2(r * 0.6, r * 0.4))
	draw_colored_polygon(pts, enemy_color)
	# Glow
	draw_circle(Vector2.ZERO, r + 2.0, Color(1.0, 0.1, 0.1, 0.3))
	# Inner eye
	draw_circle(Vector2(0, -r*0.2), r*0.2, Color(1.0, 0.8, 0.2, 0.8))

func initialize(node: OrbitNode, idx: int, ang: float, speed: float = 1.0) -> void:
	node_ref = node
	orbit_index = idx
	angle = deg_to_rad(ang)
	speed_mult = speed
	_update_pos()

func _process(delta: float) -> void:
	if not alive or not node_ref: return
	# Orbit
	var spd = node_ref.get_orbit_speed(orbit_index) * speed_mult
	angle += spd * delta
	# Hover (patrol along orbit)
	if patrol_max > 0:
		_hover_offset += _hover_dir * delta * 0.5
		if abs(_hover_offset) >= patrol_max:
			_hover_dir *= -1
			_hover_offset = clampf(_hover_offset, -patrol_max, patrol_max)
	_update_pos()
	queue_redraw()

func _update_pos() -> void:
	if not node_ref: return
	var r = node_ref.get_orbit_radius(orbit_index)
	var a = angle + _hover_offset
	position = node_ref.position + Vector2(cos(a), sin(a)) * r

func destroy() -> void:
	if not alive: return
	alive = false
	destroyed.emit(self)
	# Explosion visual
	var explosion = ExplosionParticles.new()
	get_parent().add_child(explosion)
	explosion.explode(position, enemy_color)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not alive: return
	if area is PlayerOrbiter:
		SignalBus.player_hit.emit(1, self)
