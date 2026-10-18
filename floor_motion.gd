extends RefCounted

# Sweep short steps so dropped frames cannot skip a wall or chasm.
# At contact, project the remaining motion along the local floor boundary.
# Axis-only sliding would snag when a single arrow key met a sloping edge.
static func move(start: Vector2, motion: Vector2, walkable: Callable) -> Vector2:
	if motion.is_zero_approx():
		return start
	var steps := maxi(1, ceili(motion.length() / 4.0))
	var step := motion / steps
	var result := start
	for i in steps:
		if walkable.call(result + step):
			result += step
			continue
		var low := 0.0
		var high := 1.0
		for iteration in 7:
			var fraction := (low + high) * 0.5
			if walkable.call(result + step * fraction):
				low = fraction
			else:
				high = fraction
		result += step * low
		var remaining := step * (1.0 - low)
		var inward := Vector2.ZERO
		for probe_index in 16:
			var probe := Vector2.RIGHT.rotated((probe_index + 0.5) * TAU / 16.0)
			if walkable.call(result + probe * 3.0):
				inward += probe
		var slid := false
		if inward.length_squared() > 0.01:
			var slide := remaining.slide(inward.normalized())
			if slide.dot(remaining) > 0.001 and walkable.call(result + slide):
				result += slide
				slid = true
		# Keep a safe component at concave corners where the estimated tangent
		# still enters another wall. Never move to a point outside the floor.
		if not slid:
			if walkable.call(result + Vector2(remaining.x, 0)):
				result.x += remaining.x
			elif walkable.call(result + Vector2(0, remaining.y)):
				result.y += remaining.y
	return result
