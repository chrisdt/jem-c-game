extends RefCounted

# Landing Meadow: the revised red-ground annotation supplied on 23 October 2026.
# Coordinates are pixels in the 1499 x 1049 background. Only navigation changes;
# the red overlay is never rendered. Unpainted landmarks remain solid.
const ART_SIZE := Vector2(1499,1049)
const WORLD_SIZE := Vector2(2000,1400)
const FOOT_OFFSET := Vector2(0,20)
const PLAYER_RADIUS := 8.0
const MOTION = preload("res://floor_motion.gd")
static var FLOOR := PackedVector2Array([
	Vector2(88,29),Vector2(760,29),Vector2(737,44),Vector2(711,54),
	Vector2(697,84),Vector2(669,99),Vector2(656,124),Vector2(663,145),
	Vector2(691,161),Vector2(733,184),Vector2(757,206),Vector2(781,224),
	Vector2(755,241),Vector2(738,256),Vector2(734,278),Vector2(752,291),
	Vector2(786,300),Vector2(829,301),Vector2(858,294),Vector2(882,310),
	Vector2(907,333),Vector2(950,340),Vector2(994,338),Vector2(1024,324),
	Vector2(1036,298),Vector2(1039,240),Vector2(1167,240),Vector2(1167,270),
	Vector2(1139,285),Vector2(1129,305),Vector2(1145,321),Vector2(1201,331),
	Vector2(1249,347),Vector2(1293,355),Vector2(1368,363),Vector2(1377,390),
	Vector2(1407,414),Vector2(1436,411),Vector2(1462,381),Vector2(1472,369),
	Vector2(1499,366),Vector2(1499,1049),Vector2(1106,1049),Vector2(1096,1037),
	Vector2(1072,1031),Vector2(1054,1011),Vector2(1033,995),Vector2(1020,970),
	Vector2(1010,945),Vector2(987,933),Vector2(953,930),Vector2(918,936),
	Vector2(897,949),Vector2(865,954),Vector2(833,953),Vector2(809,966),
	Vector2(791,982),Vector2(786,1000),Vector2(799,1017),Vector2(823,1028),
	Vector2(855,1036),Vector2(871,1049),Vector2(80,1049)
])
static var CAMP := PackedVector2Array([
	Vector2(145,265),Vector2(159,246),Vector2(185,234),Vector2(220,225),
	Vector2(251,215),Vector2(278,202),Vector2(299,207),Vector2(332,194),
	Vector2(389,171),Vector2(417,203),Vector2(433,245),Vector2(446,263),
	Vector2(441,282),Vector2(419,299),Vector2(386,309),Vector2(345,317),
	Vector2(302,319),Vector2(251,321),Vector2(202,319),Vector2(177,311),
	Vector2(158,294),Vector2(146,278)
])
# Trace the irregular pond bank and boulder groups, rather than blocking the
# surrounding red ground with the former broad elliptical approximations.
static var WALLS := [
	PackedVector2Array([
		Vector2(759,710),Vector2(768,681),Vector2(789,666),Vector2(823,649),
		Vector2(855,631),Vector2(882,617),Vector2(915,605),Vector2(951,601),
		Vector2(986,605),Vector2(1020,615),Vector2(1055,634),Vector2(1083,653),
		Vector2(1107,682),Vector2(1123,707),Vector2(1128,738),Vector2(1114,764),
		Vector2(1091,783),Vector2(1061,800),Vector2(1026,809),Vector2(989,815),
		Vector2(951,813),Vector2(915,805),Vector2(879,794),Vector2(847,780),
		Vector2(814,769),Vector2(788,756),Vector2(773,738)
	]),
	PackedVector2Array([
		Vector2(84,506),Vector2(99,498),Vector2(123,502),Vector2(147,510),
		Vector2(170,526),Vector2(189,548),Vector2(207,576),Vector2(223,599),
		Vector2(224,614),Vector2(211,623),Vector2(190,621),Vector2(171,615),
		Vector2(144,613),Vector2(122,607),Vector2(98,610),Vector2(83,604)
	]),
	PackedVector2Array([
		Vector2(199,852),Vector2(207,839),Vector2(230,834),Vector2(249,831),
		Vector2(274,832),Vector2(296,841),Vector2(314,849),Vector2(337,853),
		Vector2(362,864),Vector2(377,878),Vector2(382,892),Vector2(369,903),
		Vector2(349,908),Vector2(323,904),Vector2(301,902),Vector2(281,909),
		Vector2(261,903),Vector2(246,893),Vector2(224,890),Vector2(208,880),
		Vector2(199,868)
	]),
]
# Only the small islands left unpainted in the revised annotation are blocked.
# Rocks and shrubs covered in red are deliberately no longer collision islands.
const ISLANDS := [
	Vector4(207,422,39,31),Vector4(192,716,46,33),
	Vector4(520,658,55,39),Vector4(222,926,25,26),
	Vector4(336,1005,44,31),Vector4(625,966,37,29),
	Vector4(1310,715,27,24)
]

static func from_art(point: Vector2) -> Vector2:
	return point/ART_SIZE*WORLD_SIZE

static func floor_contains(point: Vector2) -> bool:
	var art := point/WORLD_SIZE*ART_SIZE
	if not Geometry2D.is_point_in_polygon(art,FLOOR): return false
	if Geometry2D.is_point_in_polygon(art,CAMP): return false
	for wall in WALLS:
		if Geometry2D.is_point_in_polygon(art,wall): return false
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
