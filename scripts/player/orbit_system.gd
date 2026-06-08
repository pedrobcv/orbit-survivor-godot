extends Node2D
class_name OrbitSystem

## Manages all OrbitNodes and the PlayerOrbiter.
## Builds orbital environments from level data JSON.
## All objects (crystals, portals, keys, obstacles) should be children of this node.

# Signals
signal level_built(level_id: String)
signal object_registered(object: Node, node_id: String, orbit_index: int, angle: float)

# References
var nodes: Array = []           # Array of OrbitNode
var player: PlayerOrbiter = null
var level_id: String = ""

# Object tracking
var _objects: Array = []        # All placed objects (obstacles, crystals, etc.)

# Difficulty reference
var _difficulty_manager: DifficultyManager = null


func _ready() -> void:
	_difficulty_manager = Engine.get_main_loop().root.find_child("DifficultyManager", true, false)


## Destroys all existing nodes, player, and objects, then rebuilds from level data JSON.
func build_from_level_data(level_data_json: Dictionary) -> void:
	# Clear existing
	_clear_all()
	
	level_id = level_data_json.get("id", "")
	
	# Get level-specific speed multiplier
	var orbital_speed_mult: float = 1.0
	if _difficulty_manager:
		orbital_speed_mult = _difficulty_manager.get_orbital_speed(level_id)
	
	# Get level's own orbital speed
	var level_orbital_speed: float = float(level_data_json.get("orbital_speed", 1.0))
	var total_speed_mult: float = orbital_speed_mult * level_orbital_speed
	
	# 1. Create OrbitNodes from level data
	var node_data_list = level_data_json.get("nodes", [])
	for node_data in node_data_list:
		var orbit_node = OrbitNode.new()
		orbit_node.initialize(node_data)
		add_child(orbit_node)
		nodes.append(orbit_node)
	
	# 2. Create and position the player at the start node
	var start_node = get_start_node()
	if start_node:
		player = PlayerOrbiter.new()
		player.speed_mult = total_speed_mult
		add_child(player)
		player.initialize(start_node, 0, 0.0)
	
	# 3. Create objects (crystals, portal, key, obstacles)
	_spawn_crystals(level_data_json)
	_spawn_portal(level_data_json)
	_spawn_key(level_data_json)
	_spawn_obstacles(level_data_json)
	
	level_built.emit(level_id)


## Spawns crystal collectibles from level data.
func _spawn_crystals(level_data: Dictionary) -> void:
	var crystal_data = level_data.get("crystals", [])
	for data in crystal_data:
		var node_ref = get_node_by_id(data.get("node_id", ""))
		if not node_ref:
			continue
		var crystal = Crystal.new()
		crystal.initialize(
			node_ref,
			data.get("orbit_index", 0),
			deg_to_rad(float(data.get("angle", 0)))
		)
		add_child(crystal)
		_objects.append(crystal)
		object_registered.emit(crystal, node_ref.node_id, data.get("orbit_index", 0), crystal.angle)


## Spawns the exit portal from level data.
func _spawn_portal(level_data: Dictionary) -> void:
	var portal_data = level_data.get("portal", null)
	if not portal_data:
		return
	
	var node_ref = get_node_by_id(portal_data.get("node_id", ""))
	if not node_ref:
		return
	
	var portal = Portal.new()
	var requires_key = level_data.get("requires_key", false)
	var key_id = ""
	if requires_key:
		var key_data = level_data.get("key", {})
		if key_data:
			key_id = key_data.get("id", "")
	
	portal.initialize(
		node_ref,
		portal_data.get("orbit_index", 0),
		deg_to_rad(float(portal_data.get("angle", 0))),
		requires_key,
		key_id
	)
	add_child(portal)
	_objects.append(portal)
	object_registered.emit(portal, node_ref.node_id, portal_data.get("orbit_index", 0), portal.angle)


## Spawns the key item (if any).
func _spawn_key(level_data: Dictionary) -> void:
	if not level_data.get("requires_key", false):
		return
	
	var key_data = level_data.get("key", null)
	if not key_data:
		return
	
	var node_ref = get_node_by_id(key_data.get("node_id", ""))
	if not node_ref:
		return
	
	var key_item = KeyItem.new()
	key_item.initialize(
		node_ref,
		key_data.get("orbit_index", 0),
		deg_to_rad(float(key_data.get("angle", 0))),
		key_data.get("id", "default_key")
	)
	add_child(key_item)
	_objects.append(key_item)
	object_registered.emit(key_item, node_ref.node_id, key_data.get("orbit_index", 0), key_item.angle)


## Spawns obstacles from level data.
func _spawn_obstacles(level_data: Dictionary) -> void:
	var obstacle_data = level_data.get("obstacles", [])
	for data in obstacle_data:
		var node_ref = get_node_by_id(data.get("node_id", ""))
		if not node_ref:
			continue
		var obstacle = Obstacle.new()
		obstacle.initialize(data)
		add_child(obstacle)
		_objects.append(obstacle)
		object_registered.emit(obstacle, node_ref.node_id, data.get("orbit_index", 0), obstacle.angle)


## Finds an OrbitNode by its node_id string.
func get_node_by_id(node_id: String) -> OrbitNode:
	for node_ref in nodes:
		if node_ref.node_id == node_id:
			return node_ref
	return null


## Returns the OrbitNode closest to the given position.
func get_closest_node(from_position: Vector2) -> OrbitNode:
	var closest: OrbitNode = null
	var closest_dist: float = INF
	
	for node_ref in nodes:
		var dist = from_position.distance_squared_to(node_ref.position)
		if dist < closest_dist:
			closest_dist = dist
			closest = node_ref
	
	return closest


## Returns the start node (marked with start_node=true).
func get_start_node() -> OrbitNode:
	for node_ref in nodes:
		if node_ref.start_node:
			return node_ref
	# Fallback: return first node
	if nodes.size() > 0:
		return nodes[0]
	return null


## Returns the player's current orbit speed from the node they're on.
func get_current_orbit_speed() -> float:
	if not player or not player.current_node:
		return 1.0
	return player.current_node.get_orbit_speed(player.current_orbit_index) * player.speed_mult


## Clears all nodes, player, and objects from the scene.
func _clear_all() -> void:
	# Remove all existing objects
	for obj in _objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_objects.clear()
	
	# Remove player
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	# Remove nodes
	for node_ref in nodes:
		if is_instance_valid(node_ref):
			node_ref.queue_free()
	nodes.clear()
	
	level_id = ""
