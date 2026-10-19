extends RefCounted

const MINE = preload("res://mine_layout.gd")
const FROST = preload("res://frost_layout.gd")
const DESERT = preload("res://desert_layout.gd")
const DENSITY = preload("res://ore_density.gd")
const GRID := 16.0
const SPACING := 150.0
const FOOTPRINT := [Vector2.ZERO, Vector2(-38,0), Vector2(38,0), Vector2(0,-20), Vector2(0,20)]

# Open grass and paths in the painting. The cliff, border forest and southern
# rock outcrops are outside this region; individual boulders are cut out below.
static var GREEN_GROUND := PackedVector2Array([
	Vector2(110,260), Vector2(450,160), Vector2(720,170),
	Vector2(770,300), Vector2(900,365), Vector2(1000,380),
	Vector2(1120,360), Vector2(1190,400), Vector2(1390,435),
	Vector2(1440,700), Vector2(1400,900), Vector2(1340,940),
	Vector2(1240,920), Vector2(1130,870), Vector2(1030,890),
	Vector2(870,880), Vector2(790,915), Vector2(630,900),
	Vector2(550,850), Vector2(390,820), Vector2(280,780),
	Vector2(180,700), Vector2(150,600), Vector2(190,540),
	Vector2(220,470), Vector2(100,430)
])
const GREEN_BOULDERS := [
	Vector4(210,410,55,45), Vector4(390,385,42,40),
	Vector4(505,300,45,38), Vector4(525,645,66,52),
	Vector4(650,475,28,25), Vector4(1090,500,70,52),
	Vector4(1250,740,55,50), Vector4(1110,900,60,50),
	Vector4(430,780,35,30), Vector4(600,550,30,24),
	Vector4(1350,555,24,22), Vector4(950,720,170,115)
]
# Spawn clearance includes the visible height of snowy props. Player collision
# permits walking behind some of these, which is unsuitable for a deposit.
const FROST_OUTCROPS := [
	Vector4(15,245,40,70), Vector4(85,220,40,50),
	Vector4(173,260,46,50), Vector4(290,155,35,45),
	Vector4(370,190,50,65), Vector4(450,325,75,85),
	Vector4(540,225,37,75), Vector4(275,315,36,28),
	Vector4(243,495,75,85), Vector4(53,430,65,95),
	Vector4(427,575,65,70), Vector4(180,600,85,85),
	Vector4(59,590,65,110), Vector4(130,673,36,35),
	Vector4(294,895,33,38), Vector4(350,920,47,63),
	Vector4(555,885,85,80), Vector4(465,970,60,65),
	Vector4(1015,245,42,50), Vector4(1000,335,50,40),
	Vector4(1120,410,45,60), Vector4(1250,295,30,55),
	Vector4(1340,340,65,80), Vector4(1415,290,75,100),
	Vector4(1425,420,65,55), Vector4(1225,570,90,95),
	Vector4(1015,660,80,90), Vector4(1105,820,75,85),
	Vector4(1170,930,65,90), Vector4(1340,960,100,100),
	Vector4(1440,805,75,75), Vector4(1465,670,55,85),
	Vector4(1350,680,100,70)
]
static var point_cache: Dictionary = {}

static func generate(world: int, rng: RandomNumberGenerator, entries: Array[Vector2], tree_cover: Array[Rect2], green_times: Vector2) -> Array[Dictionary]:
	var deposits: Array[Dictionary] = []
	for cave in [false, true]:
		var candidates := candidate_points(world, cave, entries[int(cave)])
		var basic_count: int = DENSITY.MINE_COMMON if cave else DENSITY.SURFACE_COMMON
		for i in DENSITY.count(cave):
			var hard := i >= basic_count
			var point := choose_point(candidates, world, cave, hard, deposits, rng, entries[int(cave)], tree_cover, i == 0 and world == 0 and not cave)
			assert(point.is_finite(), "No reachable space for a required ore deposit")
			var seconds := (10.0 if hard else 3.0) if world > 0 else (green_times.y if hard else green_times.x)
			deposits.append({"pos":point, "hp":4 if hard else 2, "seconds":seconds, "hard":hard, "cave":cave, "discovered":false})
	return deposits

static func can_walk(world: int, cave: bool, point: Vector2) -> bool:
	if world == 2:
		return DESERT.can_walk(point, cave)
	if world == 1:
		return FROST.can_walk(point, cave)
	if cave:
		return MINE.can_walk(point)
	return Rect2(90,180,1810,1110).has_point(point) and ((point - Vector2(1270,960)) / Vector2(173,117)).length_squared() >= 1

static func footprint_fits(world: int, cave: bool, point: Vector2) -> bool:
	for offset in FOOTPRINT:
		if not can_walk(world, cave, point + offset):
			return false
		if world == 2 and not cave and not DESERT.deposit_floor_clear(point + offset, cave):
			return false
		if world == 0 and not cave and not green_ground(point + offset):
			return false
		if world == 1 and not cave:
			var art: Vector2 = (point + offset) / Vector2(2000,1400) * Vector2(1499,1049)
			for outcrop in FROST_OUTCROPS:
				if ((art - Vector2(outcrop.x,outcrop.y)) / Vector2(outcrop.z,outcrop.w)).length_squared() < 1:
					return false
	if world == 2:
		if not DESERT.deposit_floor_clear(point, cave) or not DESERT.deposit_floor_clear(point + Vector2(0,-30 if cave else -50), cave):
			return false
	return true

static func green_ground(point: Vector2) -> bool:
	var art := point / Vector2(2000,1400) * Vector2(1499,1049)
	if not Geometry2D.is_point_in_polygon(art, GREEN_GROUND):
		return false
	for boulder in GREEN_BOULDERS:
		if ((art - Vector2(boulder.x,boulder.y)) / Vector2(boulder.z,boulder.w)).length_squared() < 1:
			return false
	return true

static func candidate_points(world: int, cave: bool, entry: Vector2) -> PackedVector2Array:
	var key := world * 2 + int(cave)
	if point_cache.has(key):
		return point_cache[key]
	var points := PackedVector2Array()
	# Flood the actual walkable floor, so disconnected pockets never receive ore.
	var first := Vector2i((entry / GRID).round())
	var queue: Array[Vector2i] = [first]
	var visited := {first:true}
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var point := Vector2(cell) * GRID
		if footprint_fits(world, cave, point):
			points.append(point)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if visited.has(next):
				continue
			visited[next] = true
			var position := Vector2(next) * GRID
			if position.x < 0 or position.y < 0 or position.x > 2000 or position.y > 1400:
				continue
			if can_walk(world, cave, position):
				queue.append(next)
	point_cache[key] = points
	return points

static func choose_point(points: PackedVector2Array, world: int, cave: bool, hard: bool, placed: Array[Dictionary], rng: RandomNumberGenerator, entry: Vector2, tree_cover: Array[Rect2], starter: bool) -> Vector2:
	var first := rng.randi_range(0, points.size() - 1)
	for offset in points.size():
		var point := points[(first + offset) % points.size()] + Vector2(rng.randf_range(-6,6),rng.randf_range(-6,6))
		if not footprint_fits(world, cave, point):
			continue
		if hard and point.distance_to(entry) < 400:
			continue
		if starter and point.distance_to(Vector2(560,550)) > 430:
			continue
		if not clear_of_landmarks(world, cave, point, tree_cover):
			continue
		var separated := true
		for rock in placed:
			if rock.cave == cave and rock.pos.distance_to(point) < SPACING:
				separated = false
				break
		if separated:
			return point
	return Vector2.INF

static func clear_of_landmarks(world: int, cave: bool, point: Vector2, tree_cover: Array[Rect2]) -> bool:
	if world == 2:
		if cave:
			var art := point / DESERT.WORLD_SIZE * DESERT.ART_SIZE
			return point.distance_to(DESERT.MINE_EXIT) >= 180 and not Rect2(600,375,590,160).has_point(art)
		if point.distance_to(DESERT.CAMP) < 225 or point.distance_to(DESERT.SHIP) < 190 or point.distance_to(DESERT.CAVE) < 180:
			return false
		var art := point / DESERT.WORLD_SIZE * DESERT.ART_SIZE
		return not Rect2(925,675,235,155).grow(30).has_point(art)
	if cave:
		return point.distance_to(Vector2(968,1230) if world == 1 else Vector2(150,610)) >= 180
	var camp := Vector2(570,1060) if world == 1 else Vector2(470,400)
	var rocket := Vector2(260,1070) if world == 1 else Vector2(240,400)
	var entrance := Vector2(1620,280) if world == 1 else Vector2(1480,340)
	if point.distance_to(camp) < 225 or point.distance_to(rocket) < 190 or point.distance_to(entrance) < 180:
		return false
	if world == 1:
		var art := point / Vector2(2000,1400) * Vector2(1499,1049)
		# The painted camp includes a tall dome between the rocket and bench.
		# Reserve its whole silhouette so an ore sprite cannot overlap the roof.
		if Rect2(140,650,380,195).grow(35).has_point(art):
			return false
	if world == 0:
		for canopy in tree_cover:
			if canopy.has_point(point):
				return false
	return true
