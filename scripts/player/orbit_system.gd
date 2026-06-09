extends Node2D
class_name OrbitSystem

## Manages all OrbitNodes, PlayerOrbiter, and enemies.
## Builds orbital environments from level data JSON.

signal level_built(level_id: String)

var nodes: Array = []
var player: PlayerOrbiter = null
var enemies: Array = []
var level_id: String = ""

var _difficulty_manager: DifficultyManager = null

func _ready() -> void:
	_difficulty_manager = Engine.get_main_loop().root.find_child("DifficultyManager", true, false)

func build_from_level_data(level_data_json: Dictionary) -> void:
	_clear_all()
	
	level_id = level_data_json.get("id", "")
	
	var orbital_speed_mult: float = 1.0
	if _difficulty_manager:
		orbital_speed_mult = _difficulty_manager.get_orbital_speed(level_id)
	
	var level_orbital_speed: float = float(level_data_json.get("orbital_speed", 1.0))
	var total_speed_mult: float = orbital_speed_mult * level_orbital_speed
	
	# Create nodes
	var node_data_list = level_data_json.get("nodes", [])
	for node_data in node_data_list:
		var orbit_node = OrbitNode.new()
		orbit_node.initialize(node_data)
		add_child(orbit_node)
		nodes.append(orbit_node)
	
	# Create player at start node
	var start_node = get_start_node()
	if start_node:
		player = PlayerOrbiter.new()
		player.speed_mult = total_speed_mult
		add_child(player)
		player.initialize(start_node, 0, 0.0)
	
	# Spawn enemies from level data
	_spawn_enemies(level_data_json)
	
	level_built.emit(level_id)

func _spawn_enemies(level_data: Dictionary) -> void:
	var enemy_data = level_data.get("enemies", [])
	for data in enemy_data:
		var node_ref = get_node_by_id(data.get("node_id", ""))
		if not node_ref: continue
		var enemy = EnemyShip.new()
		var orbit_idx = data.get("orbit_index", 0)
		enemy.initialize(node_ref, orbit_idx, float(data.get("angle", 0)), float(data.get("speed", 1.0)))
		enemy.patrol_min = float(data.get("patrol_min", 0.0))
		enemy.patrol_max = float(data.get("patrol_max", 0.0))
		add_child(enemy)
		enemies.append(enemy)
	
	# If no enemies defined, auto-generate some based on difficulty
	if enemy_data.size() == 0 and nodes.size() > 0:
		_auto_generate_enemies(level_data)

func _auto_generate_enemies(level_data: Dictionary) -> void:
	var enemy_count = 1 + nodes.size()  # At least 1 per node
	if _difficulty_manager:
		enemy_count = _difficulty_manager.get_enemy_count(level_id)
	enemy_count = max(1, min(enemy_count, 8))  # Cap at 8
	
	var node_data_list = level_data.get("nodes", [])
	for i in range(enemy_count):
		var node_idx = i % nodes.size()
		var node_ref = nodes[node_idx]
		var node_data = node_data_list[node_idx] if node_idx < node_data_list.size() else {}
		var orbit_count = node_ref.get_orbit_count()
		if orbit_count == 0: continue
		var oi = i % orbit_count
		var a = (i * 60) % 360
		var enemy = EnemyShip.new()
		var spd = 0.8 + (i * 0.15)
		enemy.initialize(node_ref, oi, float(a), spd)
		add_child(enemy)
		enemies.append(enemy)

# Other methods unchanged...
func get_node_by_id(node_id: String) -> OrbitNode:
	for node_ref in nodes:
		if node_ref.node_id == node_id: return node_ref
	return null

func get_closest_node(from_position: Vector2) -> OrbitNode:
	var closest: OrbitNode = null
	var closest_dist: float = INF
	for node_ref in nodes:
		var dist = from_position.distance_squared_to(node_ref.position)
		if dist < closest_dist:
			closest_dist = dist
			closest = node_ref
	return closest

func get_start_node() -> OrbitNode:
	for node_ref in nodes:
		if node_ref.start_node: return node_ref
	if nodes.size() > 0: return nodes[0]
	return null

func get_current_orbit_speed() -> float:
	if not player or not player.current_node: return 1.0
	return player.current_node.get_orbit_speed(player.current_orbit_index) * player.speed_mult

func _clear_all() -> void:
	for e in enemies:
		if is_instance_valid(e): e.queue_free()
	enemies.clear()
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	for node_ref in nodes:
		if is_instance_valid(node_ref): node_ref.queue_free()
	nodes.clear()
	level_id = ""
