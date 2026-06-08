extends RefCounted
class_name Helpers

## Static utility helper methods for Orbit Survivor.
## NOT a Node subclass — pure utility functions.

## Linearly interpolates between two angles, taking the shortest path around the circle.
## Returns a value in [-PI, PI].
static func lerp_angle_shortest(from: float, to: float, weight: float) -> float:
	var diff = to - from
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return from + diff * weight

## Clamps a Vector2's length to the given magnitude.
static func clamp_vector(v: Vector2, max_length: float) -> Vector2:
	var len_sq = v.length_squared()
	if len_sq > max_length * max_length:
		return v.normalized() * max_length
	return v

## Returns true if `angle` is within `tolerance` radians of `target_angle` (shortest path).
static func is_in_orbit(angle: float, target_angle: float, tolerance: float) -> bool:
	var diff = abs(angle - target_angle)
	if diff > PI:
		diff = TAU - diff
	return diff <= tolerance

## Converts polar coordinates (center, angle, radius) to a Vector2 position.
static func polar_to_cartesian(center: Vector2, angle: float, radius: float) -> Vector2:
	return center + Vector2(cos(angle), sin(angle)) * radius
