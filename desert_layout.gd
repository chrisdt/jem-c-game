extends RefCounted

const ART_SIZE := Vector2(1500, 1049)
const WORLD_SIZE := Vector2(2000, 1400)
const FOOT_OFFSET := Vector2(0, 20)
const RADIUS := 8.0
const MARKUP = preload("res://ember_markup.gd")
const FLOOR_MOTION = preload("res://floor_motion.gd")
const SURFACE_TEXTURE: Texture2D = preload("res://assets/desert_planet.png")
const MINE_TEXTURE: Texture2D = preload("res://assets/lava_mine.png")
static var ground_images: Array[Image] = []
const CAMP := Vector2(1035, 775) / ART_SIZE * WORLD_SIZE
const SHIP := Vector2(1280, 825) / ART_SIZE * WORLD_SIZE
const CAVE := Vector2(293, 214) / ART_SIZE * WORLD_SIZE
const ARRIVAL := Vector2(1220, 900) / ART_SIZE * WORLD_SIZE
const OUTSIDE := Vector2(300, 320) / ART_SIZE * WORLD_SIZE
const MINE_EXIT := Vector2(268, 910) / ART_SIZE * WORLD_SIZE
const MINE_SPAWN := Vector2(280, 810) / ART_SIZE * WORLD_SIZE

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
	return MARKUP.floor_contains(0,cave,point)

static func can_walk(point: Vector2, cave := false) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not floor_contains(point + FOOT_OFFSET + offset * RADIUS, cave):
			return false
	return true

static func move_on_floor(start: Vector2, motion: Vector2, cave := false) -> Vector2:
	return FLOOR_MOTION.move(start, motion, can_walk.bind(cave))
