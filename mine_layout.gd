extends RefCounted

# Coordinates trace the walkable floor in the painted 1499 x 1049 map.
# Keep art and navigation together when changing the mine layout.
const ART_SIZE := Vector2(1499, 1049)
const WORLD_SIZE := Vector2(2000, 1400)
const PLAYER_RADIUS := 8.0
const FLOOR_MOTION = preload("res://floor_motion.gd")
const FOOT_OFFSET := Vector2(0, 20)
const MARKUP = preload("res://earth_mine_markup.gd")
static var FLOOR: PackedVector2Array = MARKUP.FLOORS[0]
static var LAMPS := PackedVector2Array([
	Vector2(295, 180), Vector2(417, 118), Vector2(797, 115),
	Vector2(970, 285), Vector2(1330, 155), Vector2(1405, 425),
	Vector2(1295, 790), Vector2(640, 880), Vector2(330, 700),
	Vector2(288, 685), Vector2(160, 425)
])

static func from_art(point: Vector2) -> Vector2:
	return point / ART_SIZE * WORLD_SIZE

static func floor_contains(point: Vector2) -> bool:
	var art_point := point / WORLD_SIZE * ART_SIZE
	if not Geometry2D.is_point_in_polygon(art_point, FLOOR):
		return false
	for wall in MARKUP.WALLS[0]:
		if Geometry2D.is_point_in_polygon(art_point,wall): return false
	return true

static func can_walk(point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not floor_contains(point + FOOT_OFFSET + offset * PLAYER_RADIUS):
			return false
	return true

static func move_on_floor(start: Vector2, motion: Vector2) -> Vector2:
	return FLOOR_MOTION.move(start, motion, can_walk)
