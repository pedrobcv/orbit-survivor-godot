extends Node
## Central signal bus for Orbit Survivor.
## All cross-system communication happens through this autoload.

class_name SignalBus

# --- Game Flow ---
signal game_started()
signal game_over(result: Dictionary)
signal level_completed(level_id: String, stars: int, score: int)
signal pause_toggled(is_paused: bool)

# --- Player ---
signal player_hit(damage: int, source: Node)
signal orbit_changed(target: Node, radius: float, speed: float)

# --- Collectibles ---
signal crystal_collected(crystal: Node, value: int)
signal key_collected(key: Node)
signal portal_reached(portal: Node)

# --- Progression ---
signal star_earned(level_id: String, star_index: int)
signal level_selected(level_id: String)

# --- System ---
signal scene_changed(from: String, to: String)
signal settings_changed(setting: String, value: Variant)
signal save_loaded(data: Dictionary)
