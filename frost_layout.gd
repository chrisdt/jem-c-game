extends RefCounted

const ART_SIZE := Vector2(1499, 1049)
const WORLD_SIZE := Vector2(2000, 1400)
const FOOT_OFFSET := Vector2(0, 20)
const RADIUS := 9.0
static var SURFACE_ROUTES := [
	[PackedVector2Array([Vector2(360,820),Vector2(350,700),Vector2(320,610),Vector2(370,520),Vector2(480,500),Vector2(660,500),Vector2(770,500),Vector2(900,500),Vector2(1010,470),Vector2(1080,390),Vector2(1070,320),Vector2(1150,250),Vector2(1210,220)]), 48.0],
	[PackedVector2Array([Vector2(370,520),Vector2(350,430),Vector2(370,370),Vector2(420,310),Vector2(390,250),Vector2(320,220),Vector2(230,230)]), 40.0],
	[PackedVector2Array([Vector2(1010,470),Vector2(1090,570),Vector2(1180,640),Vector2(1190,700)]), 42.0],
]
static var MINE_ROUTES := [
	[PackedVector2Array([Vector2(725,820),Vector2(725,735),Vector2(750,650),Vector2(740,580)]), 49.0],
	[PackedVector2Array([Vector2(740,550),Vector2(620,495),Vector2(520,425),Vector2(430,375),Vector2(340,320)]), 52.0],
	[PackedVector2Array([Vector2(340,280),Vector2(350,210),Vector2(310,165),Vector2(285,140)]), 33.0],
	[PackedVector2Array([Vector2(840,550),Vector2(960,480),Vector2(1030,400),Vector2(1100,320),Vector2(1210,300)]), 53.0],
	[PackedVector2Array([Vector2(1210,270),Vector2(1240,210),Vector2(1230,150),Vector2(1240,125)]), 34.0],
]
static var LAMPS := PackedVector2Array([Vector2(280,110),Vector2(195,275),Vector2(470,290),Vector2(565,390),Vector2(670,455),Vector2(860,450),Vector2(980,325),Vector2(1115,235),Vector2(1245,90),Vector2(1380,320),Vector2(620,570),Vector2(895,600),Vector2(705,700),Vector2(825,705),Vector2(665,920),Vector2(805,920)])

static func from_art(point: Vector2) -> Vector2:
	return point / ART_SIZE * WORLD_SIZE

static func in_ellipse(point: Vector2, shape: Vector4) -> bool:
	return ((point - Vector2(shape.x, shape.y)) / Vector2(shape.z, shape.w)).length() < 1.0

static func floor_contains(world_point: Vector2, cave: bool) -> bool:
	var p := world_point / WORLD_SIZE * ART_SIZE
	var inside := false
	if cave:
		for shape in [Vector4(760,550,181,104),Vector4(320,300,145,73),Vector4(300,150,62,37),Vector4(1200,330,158,75),Vector4(1240,140,57,36)]:
			inside = inside or in_ellipse(p,shape)
		for shape in [Vector4(790,505,39,57),Vector4(1215,352,43,46)]:
			if in_ellipse(p,shape): return false
	else:
		inside = Rect2(110,790,440,110).has_point(p) or Rect2(245,760,280,130).has_point(p)
		# The only canyon crossing is the narrow bridge deck.
		if p.x > 650 and p.x < 885 and (p.y < 485 or p.y > 520): return false
		for shape in [Vector4(1250,790,100,85),Vector4(430,590,35,52)]:
			if in_ellipse(p,shape): return false
	var routes: Array = MINE_ROUTES if cave else SURFACE_ROUTES
	for route in routes:
		var points: PackedVector2Array = route[0]
		for i in range(points.size()-1):
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,points[i],points[i+1])) < route[1]:
				inside = true
	return inside

static func can_walk(point: Vector2, cave := false) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not floor_contains(point + FOOT_OFFSET + offset * RADIUS,cave): return false
	return true

static func move_on_floor(start: Vector2, motion: Vector2, cave := false) -> Vector2:
	var steps := maxi(1,ceili(motion.length()/8.0))
	var step := motion / steps
	var result := start
	for i in steps:
		if can_walk(result+step,cave): result += step
		else:
			if can_walk(result+Vector2(step.x,0),cave): result.x += step.x
			if can_walk(result+Vector2(0,step.y),cave): result.y += step.y
	return result
