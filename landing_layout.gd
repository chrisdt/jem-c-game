extends RefCounted

# Landing Meadow: traced from the player's red walkable-ground markup.
# These are background pixels, not screen/camera coordinates. The painting is
# unchanged; only navigation uses this outline and its unpainted islands.
const ART_SIZE := Vector2(1499,1049)
const WORLD_SIZE := Vector2(2000,1400)
const FOOT_OFFSET := Vector2(0,20)
const PLAYER_RADIUS := 8.0
const MOTION = preload("res://floor_motion.gd")
static var FLOOR := PackedVector2Array([
	Vector2(30,165),Vector2(75,153),Vector2(110,160),Vector2(110,135),
	Vector2(280,135),Vector2(460,136),Vector2(620,135),Vector2(710,145),
	Vector2(735,183),Vector2(754,211),Vector2(779,239),Vector2(803,269),
	Vector2(842,288),Vector2(869,294),Vector2(880,319),Vector2(922,335),
	Vector2(968,338),Vector2(1000,319),Vector2(1029,291),Vector2(1055,274),
	Vector2(1055,211),Vector2(1075,198),Vector2(1149,198),Vector2(1167,218),
	Vector2(1164,276),Vector2(1183,304),Vector2(1204,330),Vector2(1247,350),
	Vector2(1290,358),Vector2(1371,360),Vector2(1371,387),Vector2(1440,396),
	Vector2(1499,394),Vector2(1499,485),Vector2(1470,494),Vector2(1470,558),
	Vector2(1443,564),Vector2(1447,586),Vector2(1470,596),Vector2(1470,679),
	Vector2(1455,697),Vector2(1470,714),Vector2(1470,778),Vector2(1445,785),
	Vector2(1444,807),Vector2(1470,820),Vector2(1470,862),Vector2(1438,871),
	Vector2(1439,899),Vector2(1470,918),Vector2(1470,1020),Vector2(1066,1020),
	Vector2(1030,982),Vector2(1009,950),Vector2(965,930),Vector2(921,922),
	Vector2(866,941),Vector2(828,970),Vector2(812,1012),Vector2(830,1049),
	Vector2(620,1049),Vector2(620,1020),Vector2(379,1020),Vector2(131,1020),
	Vector2(109,989),Vector2(66,963),Vector2(31,946),Vector2(31,906),
	Vector2(56,883),Vector2(84,875),Vector2(82,839),Vector2(33,814),
	Vector2(32,713),Vector2(61,700),Vector2(61,679),Vector2(33,672),
	Vector2(32,626),Vector2(75,609),Vector2(74,579),Vector2(33,575),
	Vector2(33,521),Vector2(55,506),Vector2(61,480),Vector2(32,455),
	Vector2(31,322),Vector2(52,311),Vector2(52,287),Vector2(31,279),
	Vector2(31,245),Vector2(93,229),Vector2(111,211),Vector2(75,192),
	Vector2(30,186)
])
static var CAMP := PackedVector2Array([
	Vector2(122,244),Vector2(152,230),Vector2(204,224),Vector2(246,219),
	Vector2(278,200),Vector2(299,207),Vector2(392,172),Vector2(417,212),
	Vector2(433,267),Vector2(418,296),Vector2(386,309),Vector2(303,310),
	Vector2(249,300),Vector2(194,303),Vector2(148,292),Vector2(122,278)
])
# The rocky pond rim is excluded as well as the water. Small isolated islands
# follow the unpainted rocks/plants, rather than the old approximate blockers.
const ISLANDS := [
	Vector4(955,710,175,103),Vector4(90,402,22,19),
	Vector4(202,422,42,31),Vector4(371,385,40,29),
	Vector4(491,319,28,23),Vector4(529,152,18,20),
	Vector4(666,189,25,23),Vector4(780,274,47,32),
	Vector4(134,559,89,62),Vector4(190,718,49,35),
	Vector4(525,658,66,38),Vector4(270,874,108,42),
	Vector4(326,1007,44,32),Vector4(457,812,25,23),
	Vector4(520,935,46,28),Vector4(603,871,23,24),
	Vector4(840,899,27,18),Vector4(1125,831,24,20),
	Vector4(1257,936,34,43),Vector4(1331,738,58,47),
	Vector4(1372,826,43,29),Vector4(1435,571,26,18),
	Vector4(1119,519,47,28),Vector4(700,559,23,20),
	Vector4(216,922,29,25),Vector4(1400,384,27,34),
	Vector4(625,967,34,30)
]

static func from_art(point: Vector2) -> Vector2:
	return point/ART_SIZE*WORLD_SIZE

static func floor_contains(point: Vector2) -> bool:
	var art := point/WORLD_SIZE*ART_SIZE
	if not Geometry2D.is_point_in_polygon(art,FLOOR): return false
	if Geometry2D.is_point_in_polygon(art,CAMP): return false
	for island in ISLANDS:
		if ((art-Vector2(island.x,island.y))/Vector2(island.z,island.w)).length_squared() < 1:
			return false
	return true

static func can_walk(point: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not floor_contains(point+FOOT_OFFSET+offset*PLAYER_RADIUS): return false
	return true

static func move_on_floor(start: Vector2, motion: Vector2) -> Vector2:
	return MOTION.move(start,motion,can_walk)
