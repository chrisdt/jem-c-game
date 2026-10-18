extends RefCounted

const ART_SIZE := Vector2(1500, 1049)
const WORLD_SIZE := Vector2(2000, 1400)
const FOOT_OFFSET := Vector2(0, 20)
const RADIUS := 8.0
const FLOOR_MOTION = preload("res://floor_motion.gd")
const SURFACE_TEXTURE: Texture2D = preload("res://assets/desert_planet.png")
const MINE_TEXTURE: Texture2D = preload("res://assets/lava_mine.png")
static var ground_images: Array[Image] = []
const CAMP := Vector2(1035, 775) / ART_SIZE * WORLD_SIZE
const SHIP := Vector2(1280, 825) / ART_SIZE * WORLD_SIZE
const CAVE := Vector2(293, 214) / ART_SIZE * WORLD_SIZE
const ARRIVAL := Vector2(1220, 900) / ART_SIZE * WORLD_SIZE
const OUTSIDE := Vector2(300, 320) / ART_SIZE * WORLD_SIZE
const MINE_EXIT := Vector2(268, 934) / ART_SIZE * WORLD_SIZE
const MINE_SPAWN := Vector2(280, 810) / ART_SIZE * WORLD_SIZE

# The outer sandy clearing and the solid central mesa follow the painting.
# Both sides of the mesa remain open, creating two routes to the mine.
static var SURFACE_FLOOR := PackedVector2Array([
	Vector2(95,275),Vector2(210,245),Vector2(230,220),Vector2(350,215),
	Vector2(390,245),Vector2(510,208),Vector2(600,196),Vector2(640,210),
	Vector2(850,215),Vector2(920,185),Vector2(1080,210),Vector2(1260,260),
	Vector2(1350,300),Vector2(1340,390),Vector2(1380,470),Vector2(1390,620),
	Vector2(1450,650),Vector2(1450,820),Vector2(1380,900),Vector2(1280,930),
	Vector2(1110,930),Vector2(1000,885),Vector2(925,900),Vector2(830,865),
	Vector2(760,900),Vector2(650,885),Vector2(570,920),Vector2(430,900),
	Vector2(330,920),Vector2(250,860),Vector2(230,800),Vector2(210,740),
	Vector2(155,700),Vector2(130,620),Vector2(125,550),Vector2(150,480),
	Vector2(115,450),Vector2(100,380)])
static var MESA := PackedVector2Array([
	Vector2(605,248),Vector2(650,256),Vector2(690,276),Vector2(785,261),
	Vector2(875,280),Vector2(924,325),Vector2(957,372),Vector2(1001,405),
	Vector2(1023,452),Vector2(1060,485),Vector2(1090,532),Vector2(1090,585),
	Vector2(1055,617),Vector2(1025,642),Vector2(960,651),Vector2(906,686),
	Vector2(855,700),Vector2(812,701),Vector2(770,686),Vector2(710,705),
	Vector2(648,681),Vector2(602,651),Vector2(546,647),Vector2(507,611),
	Vector2(456,594),Vector2(442,541),Vector2(410,520),Vector2(420,485),
	Vector2(444,450),Vector2(459,411),Vector2(480,365),Vector2(500,334),
	Vector2(505,300),Vector2(535,277),Vector2(580,264)])
const SURFACE_ROCKS := [Vector4(365,480,48,50),Vector4(435,720,57,64)]

static var WEST_FLOOR := PackedVector2Array([
	Vector2(175,1010),Vector2(130,975),Vector2(135,920),Vector2(155,865),
	Vector2(135,815),Vector2(170,745),Vector2(182,715),Vector2(162,665),
	Vector2(200,605),Vector2(210,580),Vector2(225,545),Vector2(220,530),
	Vector2(220,505),Vector2(220,450),Vector2(230,415),Vector2(245,395),
	Vector2(210,370),Vector2(210,330),Vector2(205,300),Vector2(190,270),
	Vector2(180,240),Vector2(140,218),Vector2(135,175),Vector2(150,138),
	Vector2(185,115),Vector2(270,118),Vector2(310,130),Vector2(380,128),
	Vector2(420,145),Vector2(450,155),Vector2(475,162),Vector2(490,162),
	Vector2(520,140),Vector2(545,130),Vector2(570,128),Vector2(585,110),
	Vector2(610,97),Vector2(660,90),Vector2(700,90),Vector2(750,108),
	Vector2(770,125),Vector2(746,145),Vector2(700,160),Vector2(640,176),
	Vector2(607,194),Vector2(570,210),Vector2(560,238),Vector2(545,255),
	Vector2(508,278),Vector2(486,291),Vector2(455,300),Vector2(440,326),
	Vector2(431,350),Vector2(443,365),Vector2(465,390),Vector2(490,395),
	Vector2(525,416),Vector2(565,426),Vector2(605,434),Vector2(652,434),
	Vector2(660,476),Vector2(630,503),Vector2(602,510),Vector2(560,509),
	Vector2(515,500),Vector2(476,492),Vector2(440,494),Vector2(416,510),
	Vector2(380,523),Vector2(345,540),Vector2(335,555),Vector2(335,580),
	Vector2(350,615),Vector2(365,630),Vector2(378,649),Vector2(382,680),
	Vector2(380,710),Vector2(370,738),Vector2(343,760),Vector2(355,782),
	Vector2(376,807),Vector2(394,837),Vector2(398,868),Vector2(385,895),
	Vector2(366,920),Vector2(370,953),Vector2(354,990),Vector2(326,1010),
	Vector2(275,1030),Vector2(220,1030)])
static var EAST_FLOOR := PackedVector2Array([
	Vector2(825,90),Vector2(870,70),Vector2(910,80),Vector2(940,102),
	Vector2(980,110),Vector2(1015,126),Vector2(1045,130),Vector2(1060,135),
	Vector2(1090,143),Vector2(1120,140),Vector2(1170,115),Vector2(1225,110),
	Vector2(1280,123),Vector2(1320,125),Vector2(1380,148),Vector2(1400,180),
	Vector2(1415,205),Vector2(1420,225),Vector2(1410,250),Vector2(1385,290),
	Vector2(1380,310),Vector2(1355,315),Vector2(1325,340),Vector2(1305,358),
	Vector2(1280,365),Vector2(1280,390),Vector2(1310,405),Vector2(1330,425),
	Vector2(1370,452),Vector2(1380,480),Vector2(1355,512),Vector2(1325,523),
	Vector2(1290,522),Vector2(1260,535),Vector2(1240,548),Vector2(1245,585),
	Vector2(1280,620),Vector2(1305,640),Vector2(1320,675),Vector2(1375,700),
	Vector2(1420,733),Vector2(1430,765),Vector2(1425,803),Vector2(1405,825),
	Vector2(1365,826),Vector2(1320,808),Vector2(1280,803),Vector2(1235,790),
	Vector2(1205,772),Vector2(1185,742),Vector2(1145,736),Vector2(1115,710),
	Vector2(1095,688),Vector2(1080,655),Vector2(1095,628),Vector2(1115,597),
	Vector2(1145,575),Vector2(1155,552),Vector2(1160,520),Vector2(1155,494),
	Vector2(1125,480),Vector2(1125,426),Vector2(1135,406),Vector2(1135,388),
	Vector2(1155,360),Vector2(1170,325),Vector2(1170,305),Vector2(1145,280),
	Vector2(1115,257),Vector2(1100,230),Vector2(1075,210),Vector2(1030,200),
	Vector2(1000,193),Vector2(960,180),Vector2(925,160),Vector2(890,145),Vector2(850,130)])
static var BRIDGE := PackedVector2Array([Vector2(650,426),Vector2(1132,426),Vector2(1132,477),Vector2(650,477)])
static var LAVA := PackedVector2Array([
	Vector2(680,0),Vector2(830,0),Vector2(835,35),Vector2(870,50),
	Vector2(880,75),Vector2(840,88),Vector2(810,105),Vector2(825,145),
	Vector2(828,173),Vector2(865,185),Vector2(910,200),Vector2(945,235),
	Vector2(970,270),Vector2(1030,290),Vector2(1055,350),Vector2(1085,385),
	Vector2(1105,420),Vector2(1125,480),Vector2(1125,530),Vector2(1085,580),
	Vector2(1085,635),Vector2(1125,680),Vector2(1145,710),Vector2(1195,780),
	Vector2(1270,840),Vector2(1350,880),Vector2(1385,930),Vector2(1500,980),
	Vector2(1500,1049),Vector2(1450,1049),Vector2(1360,1010),Vector2(1310,980),
	Vector2(1260,945),Vector2(1170,905),Vector2(1120,855),Vector2(1055,820),
	Vector2(980,800),Vector2(885,770),Vector2(820,710),Vector2(780,655),
	Vector2(735,615),Vector2(700,570),Vector2(680,520),Vector2(680,480),
	Vector2(700,420),Vector2(780,370),Vector2(820,340),Vector2(800,320),
	Vector2(740,300),Vector2(710,275),Vector2(700,230),Vector2(725,200),
	Vector2(760,170),Vector2(770,120),Vector2(740,100),Vector2(705,80),Vector2(685,55)])
const PILLARS := [Vector4(410,230,40,65),Vector4(250,350,38,65),
	Vector4(390,460,38,53),Vector4(1290,250,44,70),Vector4(1225,515,30,50),
	Vector4(1280,680,30,50)]
static var LAMPS := PackedVector2Array([Vector2(220,90),Vector2(345,110),
	Vector2(255,240),Vector2(170,390),Vector2(440,365),Vector2(645,420),
	Vector2(260,605),Vector2(150,725),Vector2(145,840),Vector2(330,850),
	Vector2(635,65),Vector2(925,65),Vector2(1255,90),Vector2(1390,135),
	Vector2(1355,305),Vector2(1355,410),Vector2(1165,485),Vector2(1390,590),Vector2(1400,705)])

static func from_art(point: Vector2) -> Vector2:
	return point / ART_SIZE * WORLD_SIZE

static func deposit_floor_clear(point: Vector2, cave: bool) -> bool:
	# Spawn clearance also checks the painted ground. A broad walkable polygon
	# alone cannot describe every tall cliff, timber brace or dark rock edge.
	if ground_images.is_empty():
		ground_images.append(SURFACE_TEXTURE.get_image())
		ground_images.append(MINE_TEXTURE.get_image())
	var image: Image = ground_images[int(cave)]
	var center := Vector2i(point / WORLD_SIZE * ART_SIZE)
	var clear_samples := 0
	for dy in [-3,0,3]:
		for dx in [-3,0,3]:
			var pixel := (center + Vector2i(dx,dy)).clamp(Vector2i.ZERO, image.get_size() - Vector2i.ONE)
			var colour := image.get_pixelv(pixel)
			if cave:
				if colour.r > 0.25 and colour.g > 0.19 and colour.b > 0.12 and colour.r > colour.g and colour.g > colour.b:
					clear_samples += 1
			elif colour.r > 0.55 and colour.g > 0.35 and colour.g > colour.r * 0.67:
				clear_samples += 1
	return clear_samples >= 5

static func lava_contains(point: Vector2) -> bool:
	var art := point / WORLD_SIZE * ART_SIZE
	return Geometry2D.is_point_in_polygon(art, LAVA) and not Geometry2D.is_point_in_polygon(art, BRIDGE)

static func floor_contains(point: Vector2, cave: bool) -> bool:
	var art := point / WORLD_SIZE * ART_SIZE
	if cave:
		if Geometry2D.is_point_in_polygon(art, BRIDGE):
			return true
		if lava_contains(point):
			return false
		if not Geometry2D.is_point_in_polygon(art, WEST_FLOOR) and not Geometry2D.is_point_in_polygon(art, EAST_FLOOR):
			return false
		for pillar in PILLARS:
			if ((art - Vector2(pillar.x,pillar.y)) / Vector2(pillar.z,pillar.w)).length_squared() < 1:
				return false
		return true
	# New southern trail cuts through the former border cliff.
	if Rect2(805,820,130,229).has_point(art): return true
	if not Geometry2D.is_point_in_polygon(art, SURFACE_FLOOR) or Geometry2D.is_point_in_polygon(art, MESA):
		return false
	for rock in SURFACE_ROCKS:
		if ((art - Vector2(rock.x,rock.y)) / Vector2(rock.z,rock.w)).length_squared() < 1:
			return false
	return true

static func can_walk(point: Vector2, cave := false) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not floor_contains(point + FOOT_OFFSET + offset * RADIUS, cave):
			return false
	return true

static func move_on_floor(start: Vector2, motion: Vector2, cave := false) -> Vector2:
	return FLOOR_MOTION.move(start, motion, can_walk.bind(cave))
