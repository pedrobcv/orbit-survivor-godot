extends Node
## StarSystem

## Calculates star ratings per level based on completion time and death count.
## Returns 1, 2, or 3 stars depending on performance thresholds.

signal stars_calculated(level_id: String, stars: int)


## Calculates and emits the star rating for a level.
## level_id: Identifier for the level.
## completion_time: Time taken to complete the level (seconds).
## deaths: Number of player deaths during the attempt.
## time_target: The target/par time in seconds for 3-star rating.
## Returns: 1, 2, or 3 stars.
func calculate_stars(level_id: String, completion_time: float, deaths: int, time_target: float) -> int:
	var stars := _evaluate_stars(completion_time, deaths, time_target)
	stars_calculated.emit(level_id, stars)
	return stars


## Internal star evaluation logic.
## 3 stars: under time_target with 0 deaths.
## 2 stars: under 2x time_target with <= 2 deaths.
## 1 star: anything else.
func _evaluate_stars(completion_time: float, deaths: int, time_target: float) -> int:
	if time_target <= 0.0:
		# Safety: degenerate time target
		if deaths == 0:
			return 3
		elif deaths <= 2:
			return 2
		return 1

	if completion_time <= time_target and deaths == 0:
		return 3
	elif completion_time <= time_target * 2.0 and deaths <= 2:
		return 2
	else:
		return 1
