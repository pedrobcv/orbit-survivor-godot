extends Camera2D
class_name CameraController

## Camera controller that smoothly follows the player
## and adjusts zoom based on level size (number of orbit nodes).

# Smoothing
@export var follow_smoothing: float = 5.0

# Base zoom settings
@export var base_zoom: float = 0.8
@export var zoom_per_node: float = 0.04
@export var max_zoom: float = 1.5
@export var min_zoom: float = 0.4

var _target_position: Vector2 = Vector2.ZERO
var _target_zoom: float = 1.0


func _ready() -> void:
	# Default zoom level (will be adjusted once nodes are known)
	_target_zoom = base_zoom
	zoom = Vector2(_target_zoom, _target_zoom)


## Focus camera on the player character with smooth interpolation.
func focus_on_player() -> void:
	if not is_inside_tree():
		return

	# Find player through the orbit system (sibling or child structure)
	var orbit_system := _find_orbit_system()
	if orbit_system and orbit_system.player and is_instance_valid(orbit_system.player):
		_target_position = orbit_system.player.global_position

		# Dynamically adjust zoom based on number of orbit nodes
		var node_count := orbit_system.nodes.size()
		_adjust_zoom_for_level(node_count)

	# Smoothly move towards target
	global_position = global_position.lerp(_target_position, follow_smoothing * get_process_delta_time())


## Focus camera on an arbitrary position.
func focus_on_position(pos: Vector2) -> void:
	_target_position = pos
	global_position = global_position.lerp(_target_position, follow_smoothing * get_process_delta_time())


## Adjusts the camera zoom based on the number of nodes in the level.
## More nodes = zoom out to see more of the level.
func _adjust_zoom_for_level(node_count: int) -> void:
	# Base zoom adjusted by node count: more nodes = wider view (smaller zoom value)
	var adjusted_zoom: float = base_zoom - (node_count - 1) * zoom_per_node
	adjusted_zoom = clamp(adjusted_zoom, min_zoom, max_zoom)

	# Smoothly interpolate zoom
	_target_zoom = adjusted_zoom
	var current_zoom: float = zoom.x
	var new_zoom: float = lerp(current_zoom, _target_zoom, follow_smoothing * get_process_delta_time())
	zoom = Vector2(new_zoom, new_zoom)


## Finds the OrbitSystem in the scene tree (should be a sibling or child of level scene).
func _find_orbit_system() -> OrbitSystem:
	var parent := get_parent()
	while parent:
		if parent is OrbitSystem:
			return parent
		# Check children of the level scene (which is our grandparent typically)
		if parent is LevelScene or parent.name == "LevelScene":
			for child in parent.get_children():
				if child is OrbitSystem:
					return child
			break
		parent = parent.get_parent()
	return null


func _process(delta: float) -> void:
	# Continuous follow when not explicitly targeting a position
	focus_on_player()
