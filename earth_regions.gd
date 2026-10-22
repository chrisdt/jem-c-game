extends RefCounted

# Five full-size districts: 14 million square world units of surface to explore.
# Coordinates stay local to each district, so navigation, fog and ore can sleep
# independently while the player follows a trail into a different district.
const SIZE := Vector2(2000,1400)
const ART_SIZE := Vector2(1500,1050)
const NAMES := ["Landing Meadow","Pinewood Trail","Willow Marsh","Sunstone Ridge","Old Quarry"]
const SURFACE_IDS := [0,6,8,9,10]
const MINE_IDS := [1,7,-1,-1,11]
const SURFACE_KEYS := ["home","pinewood","willow","ridge","quarry"]
const MINE_KEYS := ["moss","copper_hollow","","","crystal_depths"]
const MINE_NAMES := ["Moss Mine","Copper Hollow","","","Crystal Depths"]
const ASSETS := {
	"pinewood":"res://assets/earth/pinewood.png",
	"willow":"res://assets/earth/willow.png",
	"ridge":"res://assets/earth/ridge.png",
	"quarry":"res://assets/earth/quarry.png",
	"copper_hollow":"res://assets/earth/copper_hollow.png",
	"crystal_depths":"res://assets/earth/crystal_depths.png",
}
const LINKS := [
	[{"side":"east","target":1,"arrival":"west"},{"side":"south","target":2,"arrival":"north"}],
	[{"side":"west","target":0,"arrival":"east"},{"side":"east","target":4,"arrival":"west"},{"side":"south","target":3,"arrival":"north"}],
	[{"side":"north","target":0,"arrival":"south"},{"side":"east","target":3,"arrival":"west"}],
	[{"side":"north","target":1,"arrival":"south"},{"side":"west","target":2,"arrival":"east"}],
	[{"side":"west","target":1,"arrival":"east"}],
]
# Trigger/arrival coordinates follow each painting's trail mouth. Keep arrivals
# well inside the district so held movement cannot immediately bounce back.
const GATES := [
	{"east":Vector2(1420,445),"south":Vector2(745,955)},
	{"west":Vector2(85,495),"east":Vector2(1420,505),"south":Vector2(750,955)},
	{"north":Vector2(640,90),"east":Vector2(1420,500)},
	{"north":Vector2(710,90),"west":Vector2(85,465)},
	{"west":Vector2(85,440)},
]
const MINE_ENTRANCES := [Vector2(1480,340),Vector2(1090,245) / ART_SIZE * SIZE,Vector2.ZERO,Vector2.ZERO,Vector2(1100,225) / ART_SIZE * SIZE]
const MINE_EXITS := [Vector2(150,610),Vector2(750,875) / ART_SIZE * SIZE,Vector2.ZERO,Vector2.ZERO,Vector2(160,835) / ART_SIZE * SIZE]
const MINE_SPAWNS := [Vector2(420,620),Vector2(750,745) / ART_SIZE * SIZE,Vector2.ZERO,Vector2.ZERO,Vector2(290,790) / ART_SIZE * SIZE]
const MOTION = preload("res://floor_motion.gd")
const DENSITY = preload("res://ore_density.gd")
const FOOT_OFFSET := Vector2(0,20)
const MINE_TRIGGER_EXTENTS := Vector2(110,100)
const BEA_FOOT := Vector2(1632,1138)
const NPC_CLEARANCE := {
	0:[Vector2(590,454),Vector2(195,470)],
	1:[BEA_FOOT,Vector2(1660,790),Vector2(1480,847),Vector2(410,278)],
	2:[Vector2(1187,853)],
	3:[Vector2(1370,600),Vector2(1600,345)],
	4:[Vector2(1040,550)],
}

static func clear_of_people(region: int, point: Vector2, radius := 120.0) -> bool:
	for foot in NPC_CLEARANCE.get(region,[]):
		if point.distance_to(foot-FOOT_OFFSET) < radius: return false
	return true

# Only solid side features are excluded; broad grassy clearings remain open.
# The artwork and these outlines are reviewed together in earth_expansion.gd.
const SURFACE_BLOCKERS := {
	1:[Vector4(1085,150,215,80),Vector4(510,330,32,23),Vector4(170,835,75,55),Vector4(630,920,45,30),Vector4(1050,980,55,35)],
	2:[Vector4(490,645,270,140),Vector4(1060,245,205,85),Vector4(435,370,45,30),Vector4(945,555,58,52),Vector4(975,660,60,35)],
	3:[Vector4(265,310,105,65),Vector4(430,225,110,48),Vector4(690,590,65,45),Vector4(460,700,65,35),Vector4(1025,785,80,45),Vector4(1185,215,85,25),Vector4(1090,315,55,40),Vector4(1275,315,50,35),Vector4(1350,690,50,30)],
	4:[Vector4(440,750,240,120),Vector4(1180,470,110,70),Vector4(1080,765,100,55),Vector4(580,660,85,40),Vector4(380,610,90,50),Vector4(1325,355,85,70)],
}
# Extra outlines for cliffs and the marsh's winding water. The bridge deck is
# explicitly exempt, so the visible crossing remains usable across its width.
static var SURFACE_WALLS := {
	1:[PackedVector2Array([Vector2(845,180),Vector2(980,150),Vector2(1020,220),Vector2(960,300),Vector2(850,300)]),PackedVector2Array([Vector2(1200,190),Vector2(1370,140),Vector2(1400,300),Vector2(1310,350),Vector2(1210,300)]),PackedVector2Array([Vector2(1260,135),Vector2(1500,135),Vector2(1500,300),Vector2(1390,300)])],
	2:[PackedVector2Array([Vector2(1100,325),Vector2(1150,350),Vector2(1125,400),Vector2(1080,430),Vector2(1045,465),Vector2(990,455),Vector2(1030,405),Vector2(1090,375)]),PackedVector2Array([Vector2(970,510),Vector2(1045,520),Vector2(1030,580),Vector2(1000,615),Vector2(1030,665),Vector2(950,705),Vector2(820,710),Vector2(815,675),Vector2(930,655),Vector2(965,625),Vector2(925,595)])],
	3:[],
	4:[PackedVector2Array([Vector2(80,145),Vector2(550,80),Vector2(825,140),Vector2(990,100),Vector2(1000,235),Vector2(890,310),Vector2(820,360),Vector2(710,300),Vector2(640,280),Vector2(600,210),Vector2(400,230),Vector2(330,300),Vector2(200,330),Vector2(145,260)])],
}
const TREES := {
	1:[Vector3(360,360,2),Vector3(620,255,2),Vector3(410,745,2),Vector3(950,740,0)],
	2:[Vector3(235,265,0),Vector3(555,210,1),Vector3(790,920,0),Vector3(1260,670,1)],
	3:[Vector3(250,220,2),Vector3(600,930,0),Vector3(1130,690,2),Vector3(925,900,1)],
	4:[],
}
const ORE_ZONES := {
	1:[Rect2(360,430,250,160),Rect2(790,520,190,150),Rect2(420,780,240,130),Rect2(1100,760,180,130)],
	2:[Rect2(650,390,250,160),Rect2(780,680,220,140),Rect2(290,260,220,130),Rect2(1150,550,180,130)],
	3:[Rect2(600,380,280,170),Rect2(330,690,230,130),Rect2(800,730,260,130),Rect2(1000,480,230,130)],
	4:[Rect2(500,440,250,180),Rect2(800,650,230,130),Rect2(1100,470,220,130),Rect2(470,250,230,130)],
}
# Navigation follows the red-ground annotations; the paintings stay unchanged.
const MINE_MARKUP = preload("res://earth_mine_markup.gd")
static var MINE_FLOORS: Dictionary = MINE_MARKUP.FLOORS
static var MINE_WALLS: Dictionary = MINE_MARKUP.WALLS
const MINE_ORE_ZONES := {
	1:[Rect2(225,245,240,65),Rect2(1080,250,230,65),Rect2(200,570,155,70),Rect2(1180,580,160,65),Rect2(650,115,190,50),Rect2(690,450,135,65)],
	4:[Rect2(550,425,155,120),Rect2(680,140,150,80),Rect2(1180,220,210,75),Rect2(740,690,130,80),Rect2(930,420,120,140),Rect2(310,195,90,50),Rect2(690,550,225,65)],
}
const MINE_LAMPS := {
	1:[Vector2(620,845),Vector2(880,700),Vector2(580,440),Vector2(280,200),Vector2(1050,190),Vector2(215,600),Vector2(1300,620)],
	4:[Vector2(200,800),Vector2(340,550),Vector2(580,370),Vector2(720,140),Vector2(1190,160),Vector2(1110,590),Vector2(760,750)],
}

static func from_art(point: Vector2) -> Vector2:
	return point / ART_SIZE * SIZE

static func portal(region: int, side: String) -> Vector2:
	return from_art(GATES[region][side])

static func trail_trigger_extents(side: String) -> Vector2:
	# Broad across the painted path, shallow along it: arrival points remain
	# safely outside the trigger even before the return cooldown expires.
	return Vector2(85,135) if side in ["west","east"] else Vector2(135,85)

static func crosses_opening(start: Vector2, finish: Vector2, centre: Vector2, extents: Vector2) -> bool:
	# Sweep in normalized ellipse space, so diagonal/slow frames cannot skip
	# a doorway and the whole visible opening responds to either input method.
	var first := (start-centre)/extents
	var last := (finish-centre)/extents
	return Geometry2D.get_closest_point_to_segment(Vector2.ZERO,first,last).length_squared() < 1.0

static func arrival(region: int, side: String) -> Vector2:
	var inward: Vector2 = {"west":Vector2.RIGHT,"east":Vector2.LEFT,"north":Vector2.DOWN,"south":Vector2.UP}[side]
	return portal(region,side)+inward*150.0

static func has_mine(region: int) -> bool:
	return MINE_IDS[region] >= 0

static func key(region: int, cave: bool) -> String:
	return MINE_KEYS[region] if cave else SURFACE_KEYS[region]

static func floor_contains(region: int, cave: bool, point: Vector2) -> bool:
	var art := point / SIZE * ART_SIZE
	if cave:
		art = point / SIZE * MINE_MARKUP.ART_SIZE
		if not Geometry2D.is_point_in_polygon(art,MINE_FLOORS[region]): return false
		for wall in MINE_WALLS[region]:
			if Geometry2D.is_point_in_polygon(art,wall): return false
		return true
	var inside := Rect2(100,180,1800,1110).has_point(point)
	for link in LINKS[region]:
		var gate: Vector2 = portal(region,link.side)
		var opening := Rect2(gate-Vector2(150,180),Vector2(300,360))
		inside = inside or opening.has_point(point)
	if not inside or not Rect2(Vector2.ZERO,SIZE).has_point(point):
		return false
	if region == 2 and Rect2(935,465,165,52).has_point(art):
		return true
	for wall in SURFACE_WALLS[region]:
		if Geometry2D.is_point_in_polygon(art,wall): return false
	for obstacle in SURFACE_BLOCKERS[region]:
		if ((art-Vector2(obstacle.x,obstacle.y))/Vector2(obstacle.z,obstacle.w)).length_squared() < 1:
			return false
	return true

static func can_walk(region: int, cave: bool, point: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not floor_contains(region,cave,point+FOOT_OFFSET+offset*8):
			return false
	return true

static func move_on_floor(region: int, cave: bool, start: Vector2, motion: Vector2) -> Vector2:
	var walkable := func(point: Vector2) -> bool: return can_walk(region,cave,point)
	return MOTION.move(start,motion,walkable)

static func spawn_clear(region: int, cave: bool, point: Vector2, hard: bool) -> bool:
	for offset in [Vector2.ZERO,Vector2(-45,0),Vector2(45,0),Vector2(0,-35),Vector2(0,25)]:
		if not can_walk(region,cave,point+offset):
			return false
	if cave:
		if not MINE_MARKUP.ore_clear(point,func(p: Vector2): return can_walk(region,true,p)): return false
		if region == 4 and point.distance_to(Vector2(1230,440)) < 125: return false
		return point.distance_to(MINE_EXITS[region]) >= 210 and (not hard or point.distance_to(MINE_SPAWNS[region]) >= 450)
	if not clear_of_people(region,point): return false
	for link in LINKS[region]:
		if point.distance_to(portal(region,link.side)) < 200:
			return false
	if has_mine(region) and point.distance_to(MINE_ENTRANCES[region]) < 185:
		return false
	for tree in TREES[region]:
		var root := from_art(Vector2(tree.x,tree.y))
		if Rect2(root+Vector2(-85,-170),Vector2(170,200)).has_point(point):
			return false
	return true

static func generate(region: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var rocks: Array[Dictionary] = []
	for cave in [false,true]:
		if cave and not has_mine(region):
			continue
		var zones: Array = MINE_ORE_ZONES[region] if cave else ORE_ZONES[region]
		for i in DENSITY.count(cave):
			var hard: bool = cave and i < DENSITY.MINE_RARE
			var chosen := Vector2.INF
			for attempt in 3000:
				var zone: Rect2 = zones[rng.randi_range(0,zones.size()-1)]
				var point := from_art(zone.position+Vector2(rng.randf(),rng.randf())*zone.size)
				if not spawn_clear(region,cave,point,hard):
					continue
				var separated := true
				for previous in rocks:
					if previous.cave == cave and previous.pos.distance_to(point) < 155:
						separated = false
						break
				if separated:
					chosen = point
					break
			assert(chosen.is_finite(),"No clear space: region=%d cave=%s deposit=%d seed=%d" % [region,cave,i,rng.seed])
			rocks.append({"pos":chosen,"hp":4 if hard else 2,"seconds":9.0 if hard else 2.0,"hard":hard,"cave":cave,"discovered":false})
	return rocks
