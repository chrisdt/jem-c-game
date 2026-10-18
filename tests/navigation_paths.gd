extends SceneTree

const MOTION = preload("res://floor_motion.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run_route(game, kind: String, art_points: Array) -> void:
	game.world = 0 if kind == "moss" else 1
	game.underground = kind != "ice"
	var layout = game.MINE_LAYOUT if kind == "moss" else game.FROST_LAYOUT
	var first: Vector2 = layout.from_art(art_points[0]) - layout.FOOT_OFFSET
	game.player = first
	for point in art_points:
		var goal: Vector2 = layout.from_art(point) - layout.FOOT_OFFSET
		var valid: bool = layout.can_walk(goal) if kind == "moss" else layout.can_walk(goal,game.underground)
		check(valid,"Painted floor blocked in %s at %s" % [kind,point])
		var attempts := 0
		while game.player.distance_to(goal) > 0.1 and attempts < 1500:
			var remaining: Vector2 = goal-game.player
			game.move_player(remaining.normalized(),minf(remaining.length(),4.0)/game.SPEED)
			attempts += 1
		check(game.player.distance_to(goal) < 1,"Cannot walk along painted %s path to %s; stopped at %s" % [kind,point,game.player])

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	# These waypoints come from visible paths/clearings in the artwork, not
	# from the navigation geometry. Walk each segment with real player controls.
	run_route(game,"ice",[Vector2(300,840),Vector2(500,820),Vector2(500,720),Vector2(410,680),Vector2(330,610),Vector2(340,550),Vector2(400,490),Vector2(520,495),Vector2(630,500),Vector2(770,500),Vector2(920,500),Vector2(1000,470),Vector2(1090,400),Vector2(1110,320),Vector2(1190,330),Vector2(1270,280),Vector2(1210,230)])
	run_route(game,"ice",[Vector2(340,550),Vector2(335,440),Vector2(340,365),Vector2(370,320),Vector2(355,275),Vector2(300,275),Vector2(270,300)])
	run_route(game,"ice",[Vector2(1000,470),Vector2(1080,560),Vector2(1160,620),Vector2(1230,690)])
	run_route(game,"ice",[Vector2(330,610),Vector2(260,620)])
	run_route(game,"frost",[Vector2(725,800),Vector2(680,790),Vector2(700,735),Vector2(750,650),Vector2(700,590),Vector2(680,520),Vector2(600,460),Vector2(520,420),Vector2(440,380),Vector2(465,330),Vector2(350,300),Vector2(300,285),Vector2(350,230),Vector2(310,160)])
	run_route(game,"frost",[Vector2(725,800),Vector2(800,755),Vector2(750,650),Vector2(860,590),Vector2(885,520),Vector2(960,480),Vector2(1030,400),Vector2(1100,430),Vector2(1180,440),Vector2(1290,420),Vector2(1350,340),Vector2(1270,280),Vector2(1230,210),Vector2(1240,160)])
	run_route(game,"moss",[Vector2(210,455),Vector2(320,460),Vector2(430,440),Vector2(490,390),Vector2(500,350),Vector2(470,320),Vector2(425,280),Vector2(410,240),Vector2(360,230)])
	check(not game.MINE_LAYOUT.can_walk(game.MINE_LAYOUT.from_art(Vector2(380,320))-game.MINE_LAYOUT.FOOT_OFFSET),"Moss mine rock wall became walkable")
	var frost = game.FROST_LAYOUT
	for point in [Vector2(675,493),Vector2(770,493),Vector2(865,493),Vector2(675,522),Vector2(770,522),Vector2(865,522)]:
		check(frost.can_walk(frost.from_art(point)-frost.FOOT_OFFSET),"Bridge deck edge blocked at %s" % point)
	for sample in [[Vector2(770,350),false],[Vector2(770,650),false],[Vector2(1300,790),false],[Vector2(740,300),true],[Vector2(790,510),true]]:
		check(not frost.can_walk(frost.from_art(sample[0])-frost.FOOT_OFFSET,sample[1]),"Hazard became walkable at %s" % sample[0])
	# A single arrow key should slide along a slanted boundary instead of
	# stopping. Straight walls and concave corners must remain solid.
	var slope := func(p: Vector2): return p.x+p.y <= 100.0
	var sloped: Vector2 = MOTION.move(Vector2(40,40),Vector2(60,0),slope)
	check(sloped.x > 75 and sloped.y < 25 and slope.call(sloped),"Single-axis movement snags on a diagonal wall")
	var corner := func(p: Vector2): return p.x <= 60 and p.y <= 60
	var stopped: Vector2 = MOTION.move(Vector2(40,40),Vector2(40,40),corner)
	check(stopped.distance_to(Vector2(60,60)) < 0.1 and corner.call(stopped),"Corner collision leaked or stopped too early")
	var positions: Array[Vector2] = []
	for fps in [30,144]:
		var position := Vector2(40,40)
		for i in fps:
			position = MOTION.move(position,Vector2(60.0/fps,0),slope)
		positions.append(position)
	check(positions[0].distance_to(positions[1]) < 0.5,"Wall sliding depends on frame rate")
	if failures == 0:
		print("PASS: walking painted clearings and mine routes, bridge deck width, hazards, smooth wall sliding and frame-rate independence")
	quit(1 if failures else 0)
