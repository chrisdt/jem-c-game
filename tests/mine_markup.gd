extends SceneTree

const MARKUP = preload("res://earth_mine_markup.gd")
const MOSS = preload("res://mine_layout.gd")
const EARTH = preload("res://earth_regions.gd")
const SAMPLES := {
	0: {
		"red":[Vector2(900,180),Vector2(440,215),Vector2(630,385),Vector2(950,395),Vector2(1400,475),Vector2(1160,700),Vector2(1265,820),Vector2(535,660),Vector2(680,520)],
		"solid":[Vector2(330,720),Vector2(675,880),Vector2(755,640),Vector2(780,425),Vector2(1070,480),Vector2(380,320),Vector2(100,900)]},
	1: {
		"red":[Vector2(750,130),Vector2(520,225),Vector2(240,260),Vector2(320,450),Vector2(230,600),Vector2(750,755),Vector2(930,330),Vector2(1240,270),Vector2(1280,600)],
		"solid":[Vector2(750,300),Vector2(500,450),Vector2(1050,500),Vector2(600,700),Vector2(50,500),Vector2(750,980),Vector2(1090,150)]},
	4: {
		"red":[Vector2(750,150),Vector2(350,205),Vector2(400,340),Vector2(150,410),Vector2(400,650),Vector2(200,870),Vector2(1200,220),Vector2(1300,530),Vector2(900,810)],
		"solid":[Vector2(800,470),Vector2(1090,500),Vector2(1050,760),Vector2(600,580),Vector2(500,750),Vector2(50,650),Vector2(900,940)]},
}
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func can_walk(region: int, point: Vector2) -> bool:
	return MOSS.can_walk(point) if region == 0 else EARTH.can_walk(region,true,point)

func run() -> void:
	for region in [0,1,4]:
		check(not Geometry2D.triangulate_polygon(MARKUP.FLOORS[region]).is_empty(),"Invalid mine floor contour")
		for wall in MARKUP.WALLS[region]:
			check(not Geometry2D.triangulate_polygon(wall).is_empty(),"Invalid mine rock contour")
		for kind in ["red","solid"]:
			for art in SAMPLES[region][kind]:
				var point: Vector2 = art/MARKUP.ART_SIZE*EARTH.SIZE-EARTH.FOOT_OFFSET
				check(can_walk(region,point) == (kind == "red"),"%s sample mismatches mine %d: %s" % [kind,region,art])
		check(can_walk(region,EARTH.MINE_SPAWNS[region]),"Mine arrival is outside marked floor")
		check(can_walk(region,EARTH.MINE_EXITS[region]),"Mine exit is outside marked floor")
	# This was a legal deposit across Crystal Depths' narrow entrance path,
	# leaving no route around it for Buddy. It stays walking ground, not ore.
	var passage := Vector2(735.6613,641.9327)
	check(EARTH.can_walk(4,true,passage),"Mineral clearance changed walkable ground")
	check(not EARTH.spawn_clear(4,true,passage,false),"Deposit can still block the companion's corridor")
	if failures == 0: print("PASS: three annotated mine contours, independent red/solid samples, blocked lower Moss alcoves, pools, pillars, safe arrivals and usable exits")
	quit(1 if failures else 0)
