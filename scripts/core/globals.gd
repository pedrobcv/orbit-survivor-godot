extends Node
## Global game constants for Orbit Survivor.
## This autoload provides centralized access to game-wide values.

class_name GameConstants

# --- Scene Paths ---
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings.tscn"

# --- Gameplay ---
const PLAYER_SPEED := 400.0
const ORBIT_RADIUS_MIN := 50.0
const ORBIT_RADIUS_MAX := 300.0
const ORBIT_SPEED_DEFAULT := 2.0
const CRYSTAL_SCORE_VALUE := 100
const COOLDOWN_TIME := 0.5

# --- UI ---
const MAX_STARS_PER_LEVEL := 3

# --- Grid / World ---
const TILE_SIZE := 64
const WORLD_WIDTH := 3200
const WORLD_HEIGHT := 3200

# --- Save ---
const SAVE_FILE := "user://save_data.dat"
const SETTINGS_FILE := "user://settings.cfg"

# --- Layers & Masks ---
const LAYER_PLAYER := 1
const LAYER_ENEMIES := 2
const LAYER_PROJECTILES := 3
const LAYER_CRYSTALS := 4
const LAYER_WALLS := 5
const LAYER_PORTAL := 6
const LAYER_KEY := 7
