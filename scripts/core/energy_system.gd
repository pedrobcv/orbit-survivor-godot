extends Node
## EnergySystem

## Gestiona la energía del jugador.
## La energía se gasta en órbitas externas y se recarga en la órbita más interna.
## Si llega a 0, el jugador muere.

signal energy_changed(current: float, max_energy: float)
signal energy_depleted()

# Config
const MAX_ENERGY := 100.0

# Drain rates por tipo de órbita (por segundo)
const DRAIN_OUTER := 15.0    # Órbita más lejana
const DRAIN_MID := 10.0      # Órbita media
const DRAIN_INNER := 5.0     # Órbita más cercana (todavía gasta)
const RECHARGE_RATE := 20.0  # Recarga en órbita 0 (la más interna)

var _current_energy: float = MAX_ENERGY
var _current_drain: float = 0.0
var _active: bool = false

func _ready() -> void:
	reset()

func reset() -> void:
	_current_energy = MAX_ENERGY
	_current_drain = 0.0
	_active = true
	energy_changed.emit(_current_energy, MAX_ENERGY)

func start() -> void:
	_active = true

func stop() -> void:
	_active = false

func set_orbit(orbit_index: int, total_orbits: int) -> void:
	if total_orbits <= 1:
		# Solo una órbita: consume lento
		_current_drain = DRAIN_INNER * 0.5
	elif orbit_index == 0:
		# Órbita más interna = recarga
		_current_drain = -RECHARGE_RATE
	elif orbit_index == total_orbits - 1:
		# Órbita más externa = máximo gasto
		_current_drain = DRAIN_OUTER * (1.0 + total_orbits * 0.1)
	else:
		# Órbitas intermedias
		var t = float(orbit_index) / float(total_orbits - 1)
		_current_drain = lerpf(DRAIN_INNER, DRAIN_OUTER, t)

func _process(delta: float) -> void:
	if not _active:
		return
	
	if _current_drain != 0.0:
		_current_energy -= _current_drain * delta
		_current_energy = clampf(_current_energy, 0.0, MAX_ENERGY)
		energy_changed.emit(_current_energy, MAX_ENERGY)
		
		if _current_energy <= 0.0:
			_active = false
			energy_depleted.emit()

func add_energy(amount: float) -> void:
	_current_energy = clampf(_current_energy + amount, 0.0, MAX_ENERGY)
	energy_changed.emit(_current_energy, MAX_ENERGY)

func get_energy() -> float:
	return _current_energy

func get_energy_percent() -> float:
	return _current_energy / MAX_ENERGY
