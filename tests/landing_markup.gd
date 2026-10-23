extends SceneTree

const LANDING = preload("res://landing_layout.gd")
const GROUND = preload("res://ore_spawns.gd")
var failures := 0
var steps := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func at(art: Vector2) -> Vector2:
	return LANDING.from_art(art)-LANDING.FOOT_OFFSET

func walk(game, points: Array) -> void:
	game.player = at(points[0])
	for point in points:
		var goal := at(point)
		for attempt in 800:
			var motion: Vector2 = goal-game.player
			if motion.length() < 0.1: break
			game.move_player(motion.normalized(),minf(6,motion.length())/game.SPEED)
			check(LANDING.can_walk(game.player),"Walking left the marked floor")
			steps += 1
		check(game.player.distance_to(goal) < 1,"Marked route stopped at %s before %s" % [(game.player+LANDING.FOOT_OFFSET)/LANDING.WORLD_SIZE*LANDING.ART_SIZE,point])
		if game.player.distance_to(goal) >= 1: return

func run() -> void:
	# Independent samples read from the annotation, including floor beyond the
	# old rectangle and areas that the former decoration mask rejected.
	for point in [Vector2(120,75),Vector2(500,60),Vector2(675,65),Vector2(160,170),Vector2(500,185),Vector2(700,220),Vector2(900,400),Vector2(1110,255),Vector2(1475,440),Vector2(1450,650),Vector2(1430,1010),Vector2(700,1030),Vector2(110,930),Vector2(100,660),Vector2(400,930),Vector2(750,790),Vector2(371,385),Vector2(491,319),Vector2(529,152),Vector2(666,189),Vector2(700,559),Vector2(1119,519),Vector2(1257,936)]:
		check(LANDING.can_walk(at(point)),"Revised red-marked floor is blocked: "+str(point))
		check(GROUND.can_walk(0,false,at(point)),"Ore navigation disagrees with marked floor")
	for point in [Vector2(50,350),Vector2(80,930),Vector2(120,15),Vector2(750,70),Vector2(1350,200),Vector2(950,710),Vector2(780,710),Vector2(300,250),Vector2(170,270),Vector2(200,420),Vector2(150,560),Vector2(525,658),Vector2(270,875),Vector2(222,926),Vector2(336,1005),Vector2(625,966),Vector2(1310,715),Vector2(1405,385),Vector2(950,995)]:
		check(not LANDING.can_walk(at(point)),"Unpainted obstacle became walkable: "+str(point))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.companion.set_process(false)
	game.story.set_process(false)
	game.trial.invulnerable = 10000
	game.mine_transition_cooldown = 10000
	game.earth_trail_cooldown = 10000
	check(LANDING.can_walk(game.EARTH_START),"Starting position is blocked")
	check(LANDING.can_walk(game.surface_arrival_position()),"Rocket arrival is blocked")
	check(LANDING.can_walk(game.surface_exit_position()),"Mine return position is blocked")
	var routes := [
		[Vector2(400,340),Vector2(470,330),Vector2(460,220),Vector2(500,185),Vector2(600,230),Vector2(700,220),Vector2(710,320),Vector2(780,350),Vector2(970,400),Vector2(1080,330),Vector2(1110,255)],
		[Vector2(450,360),Vector2(490,320),Vector2(535,150),Vector2(500,60),Vector2(120,75),Vector2(120,190),Vector2(120,350)],
		[Vector2(120,350),Vector2(115,470),Vector2(255,495),Vector2(250,640),Vector2(120,650),Vector2(120,800),Vector2(145,960),Vector2(240,970),Vector2(410,950),Vector2(435,1020),Vector2(700,1030)],
		[Vector2(1200,440),Vector2(1475,440)],
		[Vector2(1400,480),Vector2(1400,680),Vector2(1420,760),Vector2(1430,950),Vector2(1430,1010),Vector2(1150,1010)],
		[Vector2(750,600),Vector2(850,570),Vector2(1030,570),Vector2(1160,625),Vector2(1160,870),Vector2(1040,870),Vector2(850,850),Vector2(750,790)],
		[Vector2(500,60),Vector2(640,65),Vector2(640,160),Vector2(690,220),Vector2(710,320),Vector2(900,400)],
	]

	for route in routes:
		walk(game,route)
		route.reverse()
		walk(game,route)
	# A long frame cannot tunnel through water, rock or the camp footprint.
	for segment in [[Vector2(730,710),Vector2(1180,710)],[Vector2(400,660),Vector2(650,660)],[Vector2(340,340),Vector2(340,150)]]:
		var start := at(segment[0])
		var goal := at(segment[1])
		var result := LANDING.move_on_floor(start,goal-start)
		check(LANDING.can_walk(result) and result.distance_to(goal) > 20,"Fast movement crossed an unpainted island")
	# A companion/enemy must be able to use newly marked ground too.
	for point in [Vector2(120,75),Vector2(500,60),Vector2(1430,1010),Vector2(110,930)]:
		check(game.trial.floor_at(at(point)),"Enemy floor still uses the old placement mask")
		check(game.companion.can_stand(at(point),false),"Companion cannot reach newly marked ground")
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: revised annotated Landing Meadow floor/obstacles, %d real movement steps in both directions, safe arrivals, swept collision and shared enemy/companion navigation" % steps)
	quit(1 if failures else 0)
