extends SceneTree

const EARTH = preload("res://earth_regions.gd")
const MARKUP = preload("res://earth_surface_markup.gd")
const SAMPLES := {
	1:{"red":[Vector2(700,40),Vector2(400,140),Vector2(650,200),Vector2(1110,220),Vector2(600,240),Vector2(80,495),Vector2(1430,500),Vector2(740,1020),Vector2(1380,810),Vector2(1000,700)],
		"solid":[Vector2(250,120),Vector2(510,325),Vector2(1070,150),Vector2(1180,790),Vector2(560,815),Vector2(200,730)]},
	2:{"red":[Vector2(630,30),Vector2(200,300),Vector2(700,200),Vector2(1000,490),Vector2(250,675),Vector2(1200,400),Vector2(1350,250),Vector2(1240,730),Vector2(500,870),Vector2(890,630)],
		"solid":[Vector2(1050,245),Vector2(500,645),Vector2(1090,375),Vector2(1000,610),Vector2(440,375),Vector2(310,215),Vector2(20,100),Vector2(1050,120)]},
	3:{"red":[Vector2(720,50),Vector2(100,450),Vector2(1190,220),Vector2(1180,320),Vector2(1320,620),Vector2(800,400),Vector2(1100,870),Vector2(430,940)],
		"solid":[Vector2(1195,125),Vector2(1080,280),Vector2(1300,320),Vector2(685,575),Vector2(1267,622),Vector2(277,300)]},
	4:{"red":[Vector2(1100,200),Vector2(950,350),Vector2(1300,630),Vector2(1000,870),Vector2(350,920),Vector2(700,600),Vector2(200,675)],
		"solid":[Vector2(440,750),Vector2(1180,470),Vector2(1080,765),Vector2(500,430),Vector2(200,550),Vector2(700,150)]},
}
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func run() -> void:
	for region in range(1,5):
		check(not Geometry2D.triangulate_polygon(MARKUP.FLOORS[region]).is_empty(),"Invalid surface outline")
		for wall in MARKUP.WALLS[region]:
			check(not Geometry2D.triangulate_polygon(wall).is_empty(),"Invalid surface wall outline")
		for kind in ["red","solid"]:
			for art in SAMPLES[region][kind]:
				var point: Vector2 = art/MARKUP.ART_SIZE*EARTH.SIZE-EARTH.FOOT_OFFSET
				check(EARTH.can_walk(region,false,point) == (kind == "red"),"%s sample mismatches region %d: %s" % [kind,region,art])
		for link in EARTH.LINKS[region]:
			check(EARTH.can_walk(region,false,EARTH.arrival(region,link.side)),"Trail arrival is outside marked floor: %d/%s" % [region,link.side])
	if failures == 0: print("PASS: four annotated Earth surfaces, red/solid samples, bridge, jetty, ruin interior, arch, pond ledge and safe trail arrivals")
	quit(1 if failures else 0)
