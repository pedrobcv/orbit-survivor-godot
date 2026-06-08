extends GPUParticles2D
class_name ExplosionParticles

## Particle effect for player death or mine explosion.
## Auto-frees after animation completes.

# Config
@export var explosion_duration: float = 0.8
@export var particle_count: int = 24
@export var explosion_speed: float = 200.0
@export var particle_size_min: float = 2.0
@export var particle_size_max: float = 6.0


func _ready() -> void:
	emitting = false
	one_shot = true
	explosiveness = 1.0
	lifetime = explosion_duration
	amount = particle_count
	process_material = _create_process_material()
	draw_order = DRAW_ORDER_LIFETIME


## Creates and configures the particle process material.
func _create_process_material() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.initial_velocity_min = explosion_speed * 0.5
	mat.initial_velocity_max = explosion_speed
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.angular_velocity_min = 0.0
	mat.angular_velocity_max = 2.0
	mat.scale_min = particle_size_min
	mat.scale_max = particle_size_max
	mat.gravity = Vector3.ZERO
	mat.lifetime_randomness = 0.3
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 180.0
	mat.flatness = 1.0
	return mat


## Triggers the explosion at the given world position with the given color.
## The node auto-frees after the animation completes.
func explode(position_world: Vector2, explode_color: Color = Color(1.0, 0.3, 0.1, 1.0)) -> void:
	global_position = position_world

	# Set color via a ColorRect gradient or by modifying material
	if process_material is ParticleProcessMaterial:
		# Set a simple color ramp
		var gradient = Gradient.new()
		gradient.add_point(0.0, explode_color)
		var fade_color = explode_color
		fade_color.a = 0.0
		gradient.add_point(1.0, fade_color)
		process_material.color_ramp = gradient

	restart()
	emitting = true

	# Auto-free after the particles finish
	var timer = get_tree().create_timer(explosion_duration + 0.5)
	timer.timeout.connect(_on_explosion_finished)


## Called when the explosion animation is done.
func _on_explosion_finished() -> void:
	queue_free()
