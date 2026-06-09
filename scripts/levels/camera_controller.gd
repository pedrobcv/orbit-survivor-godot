extends Camera2D
class_name CameraController

## Simple camera for Orbit Survivor.
## Follows the player with smooth interpolation.

@export var follow_speed: float = 5.0
var _target: Node2D = null

func _ready() -> void:
	# Set zoom for the gameplay area (720x1280 viewport)
	zoom = Vector2(1.0, 1.0)
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed

func focus_on_player() -> void:
	# The camera follows the player by tracking their position
	# We look for the player in the scene tree
	if not _target or not is_instance_valid(_target):
		_find_player()

func _find_player() -> void:
	var level_scene = get_parent()
	if level_scene and level_scene.has_method("get_player"):
		_target = level_scene.get_player()
	elif level_scene:
		for child in level_scene.get_children():
			if child is PlayerOrbiter:
				_target = child
				break

func _process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		global_position = _target.global_position
