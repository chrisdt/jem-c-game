extends RefCounted

const ART_SIZE := Vector2(1499, 1049)
const WORLD_SIZE := Vector2(2000, 1400)
const FOOT_OFFSET := Vector2(0, 20)
const RADIUS := 8.0
const FLOOR_MOTION = preload("res://floor_motion.gd")
const MARKUP = preload("res://frost_markup.gd")
static var LAMPS := PackedVector2Array([Vector2(280,110),Vector2(195,275),Vector2(470,290),Vector2(565,390),Vector2(670,455),Vector2(860,450),Vector2(980,325),Vector2(1115,235),Vector2(1245,90),Vector2(1380,320),Vector2(620,570),Vector2(895,600),Vector2(705,700),Vector2(825,705),Vector2(665,920),Vector2(805,920)])

static func from_art(point: Vector2) -> Vector2:
	return point / ART_SIZE * WORLD_SIZE

static func floor_contains(world_point: Vector2, cave: bool) -> bool:
	return MARKUP.floor_contains(0,cave,world_point)

static func can_walk(point: Vector2, cave := false) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not floor_contains(point + FOOT_OFFSET + offset * RADIUS,cave): return false
	return true

static func move_on_floor(start: Vector2, motion: Vector2, cave := false) -> Vector2:
	return FLOOR_MOTION.move(start, motion, can_walk.bind(cave))
