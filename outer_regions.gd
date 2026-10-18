extends RefCounted

# Data for the two off-world trail networks. Backgrounds are string paths, so
# importing this catalogue never loads an unvisited district's textures.
const SIZE := Vector2(2000,1400)
const ART_SIZE := Vector2(1500,1050)
const FOOT_OFFSET := Vector2(0,20)
const MOTION = preload("res://floor_motion.gd")
var world: int
var NAMES: Array
var SURFACE_IDS: Array
var MINE_IDS: Array
var SURFACE_KEYS: Array
var MINE_KEYS: Array
var MINE_NAMES: Array
var ASSETS: Dictionary = {}
var LINKS: Array
var GATES: Array
var MINE_ENTRANCES: Array
var MINE_EXITS: Array
var MINE_SPAWNS: Array
var TREES := {1:[],2:[],3:[],4:[]}
var MINE_LAMPS := {1:[Vector2(300,300),Vector2(1200,300),Vector2(650,780),Vector2(850,780)],4:[Vector2(300,750),Vector2(600,250),Vector2(1150,350)]}
var SURFACE_BLOCKERS: Dictionary
var MINE_BLOCKERS := {1:[Vector4(750,420,180,120)],4:[Vector4(800,440,75,90),Vector4(1140,800,200,100)]}
var SURFACE_WALLS := {1:[],2:[],3:[],4:[]}
var CAVE_LAVA := {1:[Vector4(750,450,350,175)],4:[Vector4(1140,800,200,100)]}
var MINE_CONNECTORS := {1:[],4:[]}
var MINE_FLOORS: Dictionary
var ORE_ZONES: Dictionary
var MINE_ORE_ZONES := {
	1:[Rect2(270,330,180,190),Rect2(1020,330,180,190),Rect2(570,165,360,75),Rect2(270,640,190,100),Rect2(1040,640,190,100)],
	4:[Rect2(300,220,170,110),Rect2(1000,220,240,110),Rect2(490,460,170,120),Rect2(900,430,140,150),Rect2(600,640,220,90)],
}

func _init(planet: int) -> void:
	world = planet
	if world == 1:
		NAMES = ["Canyon Camp","Frozen Basin","Prism Pass","Aurora Shelf","Glacier Crown"]
		SURFACE_IDS = [2,12,14,15,16]
		MINE_IDS = [3,13,-1,-1,17]
		SURFACE_KEYS = ["frost_home","frozen_basin","prism_pass","aurora_shelf","glacier_crown"]
		MINE_KEYS = ["frost_mine","blue_echo","","","deep_prism"]
		MINE_NAMES = ["Frost Mine","Blue Echo Mine","","","Deep Prism Mine"]
		LINKS = [
			[{"side":"west","target":1,"arrival":"east"},{"side":"east","target":2,"arrival":"west"}],
			[{"side":"east","target":0,"arrival":"west"},{"side":"south","target":3,"arrival":"north_west"}],
			[{"side":"west","target":0,"arrival":"east"},{"side":"south","target":3,"arrival":"north_east"},{"side":"east","target":4,"arrival":"west"}],
			[{"side":"north_west","target":1,"arrival":"south"},{"side":"north_east","target":2,"arrival":"south"}],
			[{"side":"west","target":2,"arrival":"east"}],
		]
		GATES = [{"west":Vector2(85,480),"east":Vector2(1420,320)}, {"east":Vector2(1420,465),"south":Vector2(790,955)}, {"west":Vector2(85,425),"east":Vector2(1420,455),"south":Vector2(750,955)}, {"north_west":Vector2(315,90),"north_east":Vector2(1190,90)}, {"west":Vector2(85,520)}]
		MINE_ENTRANCES = [Vector2(1620,280),from_art(Vector2(425,205)),Vector2.ZERO,Vector2.ZERO,from_art(Vector2(1220,205))]
		MINE_EXITS = [Vector2(968,1230),from_art(Vector2(750,920)),Vector2.ZERO,Vector2.ZERO,from_art(Vector2(200,850))]
		MINE_SPAWNS = [Vector2(968,1115),from_art(Vector2(750,780)),Vector2.ZERO,Vector2.ZERO,from_art(Vector2(350,780))]
		SURFACE_BLOCKERS = {1:[Vector4(1030,250,190,85),Vector4(400,860,145,65),Vector4(425,110,170,65),Vector4(365,350,50,40),Vector4(1100,755,70,45)],2:[Vector4(750,345,155,100),Vector4(1270,170,160,90),Vector4(340,435,95,45),Vector4(1120,430,95,45),Vector4(960,720,120,55),Vector4(500,655,115,65)],3:[Vector4(750,710,225,90),Vector4(750,240,100,60),Vector4(480,450,90,55),Vector4(1010,380,100,65),Vector4(980,550,45,30),Vector4(730,600,35,20)],4:[Vector4(1240,800,145,75),Vector4(1210,120,160,65),Vector4(460,250,65,35),Vector4(770,570,135,65),Vector4(590,390,100,65),Vector4(1010,460,95,60),Vector4(570,680,130,50)]}
	else:
		NAMES = ["Mesa Camp","Dune Sea","Sunken Oasis","Redrock Arches","Obsidian Rise"]
		SURFACE_IDS = [4,18,20,21,22]
		MINE_IDS = [5,19,-1,-1,23]
		SURFACE_KEYS = ["ember_home","dune_sea","sunken_oasis","redrock_arches","obsidian_rise"]
		MINE_KEYS = ["lava_mine","sunfire_cavern","","","magma_vault"]
		MINE_NAMES = ["Lava Mine","Sunfire Cavern","","","Magma Vault"]
		LINKS = [
			[{"side":"west","target":1,"arrival":"east"},{"side":"south","target":2,"arrival":"north"}],
			[{"side":"east","target":0,"arrival":"west"},{"side":"south","target":3,"arrival":"north"}],
			[{"side":"north","target":0,"arrival":"south"},{"side":"west","target":3,"arrival":"east"},{"side":"east","target":4,"arrival":"west"}],
			[{"side":"north","target":1,"arrival":"south"},{"side":"east","target":2,"arrival":"west"}],
			[{"side":"west","target":2,"arrival":"east"}],
		]
		GATES = [{"west":Vector2(120,380),"south":Vector2(870,955)}, {"east":Vector2(1420,375),"south":Vector2(800,955)}, {"north":Vector2(790,90),"west":Vector2(85,375),"east":Vector2(1420,440)}, {"north":Vector2(750,90),"east":Vector2(1420,520)}, {"west":Vector2(85,390)}]
		var legacy = load("res://desert_layout.gd")
		MINE_ENTRANCES = [legacy.CAVE,from_art(Vector2(300,190)),Vector2.ZERO,Vector2.ZERO,from_art(Vector2(1190,205))]
		MINE_EXITS = [legacy.MINE_EXIT,from_art(Vector2(750,920)),Vector2.ZERO,Vector2.ZERO,from_art(Vector2(200,850))]
		MINE_SPAWNS = [legacy.MINE_SPAWN,from_art(Vector2(750,780)),Vector2.ZERO,Vector2.ZERO,from_art(Vector2(350,780))]
		SURFACE_BLOCKERS = {1:[Vector4(300,110,160,60),Vector4(900,305,80,50),Vector4(370,500,70,40),Vector4(1070,830,75,50),Vector4(545,830,75,40),Vector4(770,660,50,40)],2:[Vector4(625,525,225,120),Vector4(630,650,75,40),Vector4(705,410,60,40),Vector4(1070,710,40,25)],3:[Vector4(465,410,240,145),Vector4(1050,710,255,155),Vector4(930,300,70,35),Vector4(1250,360,70,50)],4:[Vector4(1320,800,170,105),Vector4(1460,720,80,65),Vector4(1190,110,150,70),Vector4(430,180,65,45),Vector4(500,360,90,60),Vector4(750,260,120,50),Vector4(1180,500,120,70),Vector4(430,560,140,60),Vector4(1000,670,130,50),Vector4(810,850,60,35),Vector4(510,700,80,45)]}
	var folder := "frost" if world == 1 else "ember"
	for region in range(1,5):
		ASSETS[SURFACE_KEYS[region]] = "res://assets/"+folder+"/"+SURFACE_KEYS[region]+".png"
		if has_mine(region): ASSETS[MINE_KEYS[region]] = "res://assets/"+folder+"/"+MINE_KEYS[region]+".png"
	MINE_FLOORS = {
		1:PackedVector2Array([Vector2(140,280),Vector2(330,180),Vector2(550,120),Vector2(900,120),Vector2(1200,180),Vector2(1380,300),Vector2(1380,680),Vector2(1190,800),Vector2(890,820),Vector2(850,1040),Vector2(650,1040),Vector2(610,820),Vector2(300,800),Vector2(140,680)]),
		4:PackedVector2Array([Vector2(120,950),Vector2(280,950),Vector2(420,800),Vector2(500,650),Vector2(900,750),Vector2(950,650),Vector2(1350,600),Vector2(1390,230),Vector2(1230,150),Vector2(320,150),Vector2(150,250),Vector2(170,570),Vector2(340,650),Vector2(250,770),Vector2(120,800)]),
	}
	ORE_ZONES = {
		1:[Rect2(500,350,460,230),Rect2(300,640,780,180),Rect2(1100,550,180,150)],
		2:[Rect2(530,400,470,150),Rect2(800,650,390,170),Rect2(280,280,260,120)],
		3:[Rect2(580,400,360,240),Rect2(230,650,240,150),Rect2(950,500,270,160)],
		4:[Rect2(500,360,450,250),Rect2(270,620,600,180),Rect2(1140,460,180,140)],
	}

	if world == 1:
		MINE_CONNECTORS[4] = [PackedVector2Array([Vector2(950,380),Vector2(1120,320)])]
		MINE_EXITS[4] = from_art(Vector2(250,850))
		MINE_SPAWNS[4] = from_art(Vector2(350,740))
		MINE_BLOCKERS[4] = [Vector4(785,450,100,85),Vector4(1130,735,210,115),Vector4(500,410,65,55),Vector4(640,665,120,80),Vector4(1000,290,100,55)]
		MINE_FLOORS[4] = PackedVector2Array([Vector2(315,970),Vector2(185,950),Vector2(140,900),Vector2(170,845),Vector2(240,790),Vector2(280,740),Vector2(270,700),Vector2(320,640),Vector2(330,560),Vector2(350,510),Vector2(300,465),Vector2(260,420),Vector2(200,375),Vector2(140,350),Vector2(130,300),Vector2(230,250),Vector2(250,210),Vector2(240,160),Vector2(310,130),Vector2(400,145),Vector2(430,200),Vector2(480,230),Vector2(600,240),Vector2(680,260),Vector2(790,220),Vector2(870,230),Vector2(940,280),Vector2(1040,260),Vector2(1070,190),Vector2(1140,130),Vector2(1250,150),Vector2(1320,190),Vector2(1380,240),Vector2(1370,290),Vector2(1300,335),Vector2(1280,370),Vector2(1220,400),Vector2(1170,390),Vector2(1120,350),Vector2(1060,350),Vector2(1030,385),Vector2(1050,420),Vector2(1150,440),Vector2(1260,450),Vector2(1270,500),Vector2(1210,535),Vector2(1170,540),Vector2(1130,570),Vector2(1030,580),Vector2(1000,630),Vector2(950,670),Vector2(900,700),Vector2(840,680),Vector2(800,660),Vector2(730,650),Vector2(680,610),Vector2(630,600),Vector2(610,640),Vector2(550,675),Vector2(500,700),Vector2(490,740),Vector2(430,755),Vector2(400,800),Vector2(345,810),Vector2(340,870),Vector2(350,915)])
		MINE_ORE_ZONES[4] = [Rect2(270,200,150,100),Rect2(1130,200,140,100),Rect2(540,320,140,130),Rect2(650,540,300,60),Rect2(950,380,180,100),Rect2(420,290,350,55)]
		MINE_BLOCKERS[1] = [Vector4(750,430,260,180),Vector4(370,310,95,45),Vector4(1130,310,95,45),Vector4(1210,490,70,50),Vector4(500,690,100,55),Vector4(1020,680,90,50),Vector4(290,480,70,40)]
		MINE_FLOORS[1] = PackedVector2Array([Vector2(650,1040),Vector2(800,1040),Vector2(900,950),Vector2(870,830),Vector2(1010,790),Vector2(1130,800),Vector2(1300,710),Vector2(1350,660),Vector2(1300,600),Vector2(1220,560),Vector2(1270,500),Vector2(1350,470),Vector2(1410,390),Vector2(1340,340),Vector2(1270,300),Vector2(1250,230),Vector2(1150,180),Vector2(1090,160),Vector2(1000,200),Vector2(960,150),Vector2(900,110),Vector2(800,135),Vector2(690,120),Vector2(620,110),Vector2(550,135),Vector2(480,200),Vector2(410,180),Vector2(330,200),Vector2(250,260),Vector2(260,320),Vector2(180,340),Vector2(110,380),Vector2(140,450),Vector2(260,500),Vector2(300,550),Vector2(210,610),Vector2(170,665),Vector2(260,720),Vector2(360,770),Vector2(470,760),Vector2(560,800),Vector2(610,830),Vector2(620,930)])
		ORE_ZONES[2] = [Rect2(530,470,470,100),Rect2(650,570,160,150),Rect2(1120,500,190,130),Rect2(530,175,400,60)]
		ORE_ZONES[3] = [Rect2(540,330,365,230),Rect2(920,460,210,110),Rect2(300,500,100,90),Rect2(1090,240,100,140)]
		ORE_ZONES[4] = [Rect2(600,400,330,110),Rect2(900,620,230,110),Rect2(320,320,150,130),Rect2(1060,240,100,110),Rect2(340,750,400,70)]

	else:
		MINE_EXITS[4] = from_art(Vector2(260,930))
		MINE_SPAWNS[4] = from_art(Vector2(280,800))
		CAVE_LAVA[4] = [Vector4(1200,740,250,120)]
		MINE_BLOCKERS[4] = [Vector4(780,400,105,90),Vector4(570,700,210,100),Vector4(455,275,130,70),Vector4(1290,250,35,45),Vector4(1180,450,150,55),Vector4(820,220,230,45),Vector4(1210,730,270,125)]
		MINE_FLOORS[4] = PackedVector2Array([Vector2(350,1040),Vector2(180,1020),Vector2(140,980),Vector2(150,900),Vector2(170,850),Vector2(130,800),Vector2(180,760),Vector2(190,660),Vector2(160,620),Vector2(200,550),Vector2(230,500),Vector2(200,450),Vector2(140,420),Vector2(150,380),Vector2(200,340),Vector2(240,320),Vector2(230,270),Vector2(185,240),Vector2(160,220),Vector2(170,140),Vector2(220,115),Vector2(300,130),Vector2(400,125),Vector2(460,150),Vector2(550,160),Vector2(620,120),Vector2(700,110),Vector2(800,140),Vector2(940,130),Vector2(1030,160),Vector2(1080,200),Vector2(1140,160),Vector2(1240,130),Vector2(1360,180),Vector2(1410,240),Vector2(1410,290),Vector2(1370,330),Vector2(1320,360),Vector2(1300,400),Vector2(1370,440),Vector2(1380,500),Vector2(1330,530),Vector2(1280,500),Vector2(1250,480),Vector2(1210,520),Vector2(1140,510),Vector2(1080,540),Vector2(1000,550),Vector2(950,580),Vector2(900,620),Vector2(850,650),Vector2(880,700),Vector2(940,740),Vector2(1000,760),Vector2(1050,800),Vector2(1080,860),Vector2(1000,860),Vector2(920,830),Vector2(850,800),Vector2(800,770),Vector2(750,740),Vector2(700,700),Vector2(650,650),Vector2(600,610),Vector2(520,590),Vector2(480,570),Vector2(420,600),Vector2(380,630),Vector2(400,680),Vector2(390,740),Vector2(350,770),Vector2(390,820),Vector2(400,870),Vector2(360,915),Vector2(360,980)])
		MINE_ORE_ZONES[4] = [Rect2(200,150,190,65),Rect2(560,135,340,45),Rect2(1160,180,140,85),Rect2(530,335,130,140),Rect2(650,510,230,55),Rect2(910,340,150,160)]
		MINE_BLOCKERS[1] = [Vector4(750,450,400,220),Vector4(230,275,35,40),Vector4(1310,290,35,40),Vector4(410,720,70,55),Vector4(1100,720,70,55)]
		MINE_FLOORS[1] = PackedVector2Array([Vector2(570,125),Vector2(750,110),Vector2(900,130),Vector2(970,175),Vector2(980,225),Vector2(1050,235),Vector2(1100,240),Vector2(1190,200),Vector2(1250,190),Vector2(1380,240),Vector2(1390,290),Vector2(1330,330),Vector2(1290,380),Vector2(1320,410),Vector2(1370,430),Vector2(1350,510),Vector2(1290,540),Vector2(1260,590),Vector2(1330,640),Vector2(1320,700),Vector2(1220,760),Vector2(1200,820),Vector2(1100,850),Vector2(1020,790),Vector2(930,800),Vector2(880,820),Vector2(865,915),Vector2(880,990),Vector2(780,1045),Vector2(650,1045),Vector2(610,1000),Vector2(630,920),Vector2(620,850),Vector2(550,800),Vector2(450,820),Vector2(360,800),Vector2(240,750),Vector2(180,700),Vector2(160,650),Vector2(220,600),Vector2(210,550),Vector2(140,500),Vector2(135,440),Vector2(200,410),Vector2(190,360),Vector2(130,320),Vector2(100,270),Vector2(170,230),Vector2(250,200),Vector2(330,210),Vector2(390,240),Vector2(460,225),Vector2(510,170)])
		ORE_ZONES[4] = [Rect2(600,400,400,190),Rect2(320,700,420,100),Rect2(950,340,150,100),Rect2(1120,580,150,75)]
		ORE_ZONES[2] = [Rect2(850,370,380,200),Rect2(350,700,600,90),Rect2(540,230,400,90),Rect2(1140,600,130,100)]
		ORE_ZONES[3] = [Rect2(760,260,150,210),Rect2(510,580,230,210),Rect2(1160,420,160,90),Rect2(810,870,430,50)]

func from_art(point: Vector2) -> Vector2:
	return point/ART_SIZE*SIZE

func portal(region: int, side: String) -> Vector2:
	return from_art(GATES[region][side])

func arrival(region: int, side: String) -> Vector2:
	var inward := Vector2.DOWN if side.begins_with("north") else (Vector2.UP if side == "south" else (Vector2.RIGHT if side == "west" else Vector2.LEFT))
	return portal(region,side)+inward*150

func key(region: int, cave: bool) -> String:
	return MINE_KEYS[region] if cave else SURFACE_KEYS[region]

func has_mine(region: int) -> bool:
	return MINE_IDS[region] >= 0

func floor_contains(region: int, cave: bool, point: Vector2) -> bool:
	var art := point/SIZE*ART_SIZE
	if cave:
		var inside_mine := Geometry2D.is_point_in_polygon(art,MINE_FLOORS[region])
		for path in MINE_CONNECTORS[region]:
			if art.distance_to(Geometry2D.get_closest_point_to_segment(art,path[0],path[1])) < 50: inside_mine = true
		if not inside_mine: return false
		for wall in MINE_BLOCKERS[region]:
			if ((art-Vector2(wall.x,wall.y))/Vector2(wall.z,wall.w)).length_squared() < 1: return false
		return true
	var inside := Rect2(85,145,1330,835).has_point(art)
	for side in GATES[region]:
		if Rect2(GATES[region][side]-Vector2(110,100),Vector2(220,200)).has_point(art): inside = true
	if not inside or not Rect2(Vector2.ZERO,ART_SIZE).has_point(art): return false
	for wall in SURFACE_WALLS[region]:
		if Geometry2D.is_point_in_polygon(art,wall): return false
	for wall in SURFACE_BLOCKERS[region]:
		if ((art-Vector2(wall.x,wall.y))/Vector2(wall.z,wall.w)).length_squared() < 1: return false
	return true

func can_walk(region: int, cave: bool, point: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not floor_contains(region,cave,point+FOOT_OFFSET+offset*8): return false
	return true

func move_on_floor(region: int, cave: bool, start: Vector2, motion: Vector2) -> Vector2:
	var walkable := func(point: Vector2) -> bool: return can_walk(region,cave,point)
	return MOTION.move(start,motion,walkable)

func lava_pools(region: int, cave: bool) -> Array:
	if world != 2: return []
	if cave: return CAVE_LAVA[region]
	return [SURFACE_BLOCKERS[4][0],SURFACE_BLOCKERS[4][1]] if region == 4 else []

func spawn_clear(region: int, cave: bool, point: Vector2, hard: bool) -> bool:
	for offset in [Vector2.ZERO,Vector2(-45,0),Vector2(45,0),Vector2(0,-35),Vector2(0,25)]:
		if not can_walk(region,cave,point+offset): return false
	if cave: return point.distance_to(MINE_EXITS[region]) >= 220 and (not hard or point.distance_to(MINE_SPAWNS[region]) >= 450)
	for side in GATES[region]:
		if point.distance_to(portal(region,side)) < 200: return false
	return not has_mine(region) or point.distance_to(MINE_ENTRANCES[region]) >= 185

func generate(region: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var rocks: Array[Dictionary] = []
	for cave in [false,true]:
		if cave and not has_mine(region): continue
		var zones: Array = MINE_ORE_ZONES[region] if cave else ORE_ZONES[region]
		for i in (7 if cave else 8):
			var hard: bool = cave and i < 3
			var chosen := Vector2.INF
			for attempt in 4000:
				var zone: Rect2 = zones[rng.randi_range(0,zones.size()-1)]
				var point := from_art(zone.position+Vector2(rng.randf(),rng.randf())*zone.size)
				if not spawn_clear(region,cave,point,hard): continue
				var separated := true
				for previous in rocks:
					if previous.cave == cave and previous.pos.distance_to(point) < 155: separated = false; break
				if separated: chosen = point; break
			assert(chosen.is_finite(),"No clear space for outer-world ore in %d/%d" % [world,region])
			rocks.append({"pos":chosen,"hp":4 if hard else 2,"seconds":10.0 if hard else 3.0,"hard":hard,"cave":cave,"discovered":false})
	return rocks
