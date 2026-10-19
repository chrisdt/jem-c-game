@tool
extends RefCounted

# Use the same dominant-axis rule as Scout; an idle actor keeps its last view.
static func from_movement(movement: Vector2, previous: Vector2) -> Vector2:
	if movement.is_zero_approx():
		return previous
	if absf(movement.x) > absf(movement.y):
		return Vector2.LEFT if movement.x < 0 else Vector2.RIGHT
	return Vector2.UP if movement.y < 0 else Vector2.DOWN
