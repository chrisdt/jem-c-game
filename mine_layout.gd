extends RefCounted

# Coordinates trace the walkable floor in the painted 1499 x 1049 map.
# Keep art and navigation together when changing the mine layout.
const ART_SIZE := Vector2(1499, 1049)
const WORLD_SIZE := Vector2(2000, 1400)
const PLAYER_RADIUS := 8.0
const FLOOR_MOTION = preload("res://floor_motion.gd")
const FOOT_OFFSET := Vector2(0, 20)
static var FLOOR := PackedVector2Array([
	Vector2(30, 430), Vector2(180, 410), Vector2(320, 435),
	Vector2(400, 400), Vector2(400, 365), Vector2(410, 330),
	Vector2(390, 300), Vector2(375, 270), Vector2(330, 245),
	Vector2(320, 220), Vector2(365, 200), Vector2(430, 195),
	Vector2(465, 210), Vector2(470, 245), Vector2(470, 275),
	Vector2(495, 305), Vector2(520, 335), Vector2(540, 380), Vector2(550, 425),
	# The apron below the central timber doorway is painted open floor.
	# The old straight edge from (580,420) to (660,425) cut that path off.
	Vector2(580, 390), Vector2(620, 380), Vector2(675, 380),
	Vector2(710, 385), Vector2(730, 365),
	Vector2(760, 300), Vector2(720, 250), Vector2(735, 200),
	Vector2(800, 160), Vector2(870, 180), Vector2(875, 245),
	Vector2(830, 290), Vector2(870, 360), Vector2(920, 380),
	Vector2(970, 350), Vector2(1010, 365), Vector2(1080, 380),
	Vector2(1160, 370), Vector2(1220, 300), Vector2(1290, 240),
	Vector2(1330, 205), Vector2(1390, 220), Vector2(1380, 270),
	Vector2(1320, 300), Vector2(1260, 370), Vector2(1210, 430),
	Vector2(1310, 440), Vector2(1370, 430), Vector2(1410, 455),
	Vector2(1370, 500), Vector2(1340, 545), Vector2(1260, 555),
	Vector2(1200, 575), Vector2(1110, 600), Vector2(1100, 650),
	Vector2(1140, 720), Vector2(1230, 780), Vector2(1320, 800),
	Vector2(1360, 850), Vector2(1330, 890), Vector2(1270, 860),
	Vector2(1200, 820), Vector2(1110, 790), Vector2(1050, 710),
	Vector2(1000, 650), Vector2(930, 635), Vector2(900, 600),
	Vector2(820, 560), Vector2(740, 550), Vector2(650, 565),
	Vector2(610, 600), Vector2(630, 680), Vector2(690, 730),
	Vector2(700, 800), Vector2(740, 850), Vector2(720, 900),
	Vector2(660, 920), Vector2(610, 890), Vector2(610, 830),
	Vector2(590, 750), Vector2(540, 700), Vector2(510, 680),
	Vector2(460, 700), Vector2(400, 740), Vector2(340, 760),
	Vector2(290, 750), Vector2(280, 710), Vector2(330, 680),
	Vector2(390, 650), Vector2(440, 600), Vector2(420, 565),
	Vector2(360, 540), Vector2(300, 520), Vector2(200, 500),
	Vector2(130, 490), Vector2(50, 470)
])
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
	# Stone pillars and the underground pool, including their rims.
	for obstacle in [Vector4(780, 425, 46, 78), Vector4(1070, 480, 51, 75), Vector4(755, 640, 150, 83)]:
		if ((art_point - Vector2(obstacle.x, obstacle.y)) / Vector2(obstacle.z, obstacle.w)).length() < 1.0:
			return false
	return true

static func can_walk(point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not floor_contains(point + FOOT_OFFSET + offset * PLAYER_RADIUS):
			return false
	return true

static func move_on_floor(start: Vector2, motion: Vector2) -> Vector2:
	return FLOOR_MOTION.move(start, motion, can_walk)
