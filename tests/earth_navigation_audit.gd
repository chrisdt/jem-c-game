extends SceneTree

# Artwork waypoints are independent of the polygons under test. Grid sweeps
# additionally check every floor branch, including approaches not in the routes.
const EARTH = preload("res://earth_regions.gd")
const MOSS = preload("res://mine_layout.gd")
const GROUND = preload("res://ore_spawns.gd")
const MOTION = preload("res://floor_motion.gd")
const TRAVEL = preload("res://tests/support/area_travel.gd")
const GRID := 24.0
const ROUTES := [
	[0,false,"camp to mine",[Vector2(420,350),Vector2(560,450),Vector2(710,500),Vector2(900,430),Vector2(1040,350),Vector2(1100,320)]],
	[0,false,"east and southern trails",[Vector2(1380,445),Vector2(1120,470),Vector2(760,515),Vector2(690,700),Vector2(740,835),Vector2(750,925)]],
	[0,false,"pond rim",[Vector2(760,600),Vector2(840,560),Vector2(1000,565),Vector2(1150,625),Vector2(1150,780),Vector2(1020,845),Vector2(850,850),Vector2(750,800)]],
	[1,false,"full east-west trail",[Vector2(200,495),Vector2(500,530),Vector2(750,510),Vector2(1090,530),Vector2(1300,510)]],
	[1,false,"campsite and mine approach",[Vector2(750,510),Vector2(650,360),Vector2(450,260),Vector2(315,220),Vector2(250,190)]],
	[1,false,"mine and south trail",[Vector2(750,880),Vector2(750,650),Vector2(750,510),Vector2(950,380),Vector2(1085,285)]],
	[2,false,"whole bridge deck",[Vector2(640,205),Vector2(650,310),Vector2(720,425),Vector2(920,480),Vector2(970,490),Vector2(1040,490),Vector2(1100,490),Vector2(1310,500)]],
	[2,false,"west meadow loop",[Vector2(650,310),Vector2(400,295),Vector2(275,350),Vector2(275,425),Vector2(570,440),Vector2(720,425)]],
	[2,false,"southern pond banks",[Vector2(1200,520),Vector2(1230,640),Vector2(1150,755),Vector2(950,830),Vector2(700,880),Vector2(470,855),Vector2(270,785),Vector2(215,715)]],
	[3,false,"north to west trail",[Vector2(710,205),Vector2(830,290),Vector2(800,400),Vector2(700,460),Vector2(500,520),Vector2(400,555),Vector2(200,480)]],
	[3,false,"southern ridge loop",[Vector2(400,555),Vector2(350,690),Vector2(350,770),Vector2(600,820),Vector2(800,865),Vector2(1050,860),Vector2(1190,780),Vector2(1220,660),Vector2(1100,540),Vector2(900,470),Vector2(700,460)]],
	[3,false,"circular ruins",[Vector2(900,470),Vector2(1010,405),Vector2(1170,390),Vector2(1200,300),Vector2(1200,250)]],
	[4,false,"quarry rails to mine",[Vector2(200,440),Vector2(430,485),Vector2(800,520),Vector2(980,375),Vector2(1100,270)]],
	[4,false,"quarry eastern and southern loop",[Vector2(800,520),Vector2(1050,610),Vector2(1310,645),Vector2(1260,800),Vector2(1030,900),Vector2(760,920),Vector2(750,740),Vector2(800,520)]],
	[0,true,"central doorway apron regression",[Vector2(490,460),Vector2(550,445),Vector2(580,415),Vector2(610,400),Vector2(650,400),Vector2(690,405),Vector2(710,425),Vector2(720,470),Vector2(750,520),Vector2(820,520),Vector2(875,480)]],
	[0,true,"northwest side chamber",[Vector2(210,455),Vector2(320,460),Vector2(430,440),Vector2(490,390),Vector2(500,350),Vector2(470,320),Vector2(425,280),Vector2(410,240),Vector2(360,230)]],
	[0,true,"north side chamber",[Vector2(500,460),Vector2(680,460),Vector2(720,400),Vector2(780,330),Vector2(790,280),Vector2(780,235),Vector2(800,200)]],
	[0,true,"northeast side chamber",[Vector2(870,520),Vector2(940,450),Vector2(990,400),Vector2(1090,390),Vector2(1160,410),Vector2(1220,340),Vector2(1300,270),Vector2(1350,245)]],
	[0,true,"far east gallery",[Vector2(1090,390),Vector2(1160,440),Vector2(1190,470),Vector2(1300,470),Vector2(1360,460)]],
	[0,true,"southeast gallery",[Vector2(1120,540),Vector2(1050,580),Vector2(1060,650),Vector2(1120,750),Vector2(1250,820),Vector2(1320,850)]],
	[0,true,"south pool rim and gallery",[Vector2(520,480),Vector2(570,530),Vector2(570,620),Vector2(560,650),Vector2(610,720),Vector2(650,780),Vector2(650,850),Vector2(675,880)]],
	[0,true,"southwest side chamber",[Vector2(500,520),Vector2(480,590),Vector2(435,650),Vector2(360,700),Vector2(330,720)]],
	[1,true,"central copper galleries",[Vector2(750,770),Vector2(750,660),Vector2(775,550),Vector2(790,470),Vector2(690,440),Vector2(585,360),Vector2(545,280),Vector2(430,280),Vector2(250,260)]],
	[1,true,"north copper loop",[Vector2(545,280),Vector2(610,185),Vector2(750,130),Vector2(890,180),Vector2(980,270),Vector2(1000,340),Vector2(930,395),Vector2(790,470)]],
	[1,true,"west and southwest copper loop",[Vector2(250,260),Vector2(325,355),Vector2(350,470),Vector2(310,560),Vector2(230,605),Vector2(370,625),Vector2(470,650),Vector2(590,625),Vector2(650,660),Vector2(750,720)]],
	[1,true,"east copper gallery",[Vector2(1000,340),Vector2(1180,280),Vector2(1290,265),Vector2(1240,350),Vector2(1200,440),Vector2(1250,540),Vector2(1330,590),Vector2(1200,635),Vector2(1120,660)]],
	[4,true,"crystal central and north galleries",[Vector2(290,790),Vector2(350,690),Vector2(400,590),Vector2(430,540),Vector2(560,505),Vector2(650,480),Vector2(690,410),Vector2(810,340),Vector2(805,230),Vector2(770,170)]],
	[4,true,"crystal western gallery",[Vector2(560,505),Vector2(570,425),Vector2(500,370),Vector2(450,290),Vector2(350,205)]],
	[4,true,"crystal northeast gallery",[Vector2(810,340),Vector2(910,390),Vector2(1000,425),Vector2(1130,355),Vector2(1200,270),Vector2(1310,240)]],
	[4,true,"crystal dry lake rim",[Vector2(1000,425),Vector2(990,530),Vector2(970,590),Vector2(850,640),Vector2(800,710),Vector2(870,760)]],
]
var failures := 0
var movement_samples := 0
var audited_edges := 0
var report: Dictionary = {"routes":[],"areas":[],"trail_approaches":0,"mine_approaches":0}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func can_walk(region: int, cave: bool, point: Vector2) -> bool:
	return (MOSS.can_walk(point) if cave else GROUND.can_walk(0,false,point)) if region == 0 else EARTH.can_walk(region,cave,point)

func art_point(region: int, cave: bool, point: Vector2) -> Vector2:
	return (MOSS.from_art(point) if region == 0 and cave else EARTH.from_art(point))-EARTH.FOOT_OFFSET

func walk_route(game, spec: Array, reverse := false) -> void:
	game.world = 0
	game.earth_region = spec[0]
	game.underground = spec[1]
	game.mine_transition_cooldown = 10000
	game.earth_trail_cooldown = 10000
	var points: Array = spec[3].duplicate()
	if reverse: points.reverse()
	game.player = art_point(spec[0],spec[1],points[0])
	for point in points:
		var goal := art_point(spec[0],spec[1],point)
		check(can_walk(spec[0],spec[1],goal),"Painted route endpoint blocked: %s, %s" % [spec[2],point])
		var attempts := 0
		while game.player.distance_to(goal) > 0.2 and attempts < 600:
			var motion: Vector2 = goal-game.player
			game.move_player(motion.normalized(),minf(motion.length(),6)/game.SPEED)
			attempts += 1
			movement_samples += 1
		check(game.player.distance_to(goal) < 1,"Real walking stopped on %s at art %s; goal %s" % [spec[2],game.player/EARTH.SIZE*EARTH.ART_SIZE,point])
	if not reverse: report.routes.append({"district":EARTH.NAMES[spec[0]],"mine":spec[1],"route":spec[2],"waypoints":points.size(),"directions":"both"})

func audit_grid(region: int, cave: bool) -> void:
	var floor_cells := {}
	for y in range(1,ceili(EARTH.SIZE.y/GRID)):
		for x in range(1,ceili(EARTH.SIZE.x/GRID)):
			var cell := Vector2i(x,y)
			if can_walk(region,cave,Vector2(cell)*GRID): floor_cells[cell] = true
	var entry: Vector2 = EARTH.MINE_SPAWNS[region] if cave else (Vector2(620,530) if region == 0 else EARTH.arrival(region,EARTH.LINKS[region][0].side))
	var first := Vector2i((entry/GRID).round())
	var visited := {first:true}
	var queue: Array[Vector2i] = [first]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN,Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
			var next: Vector2i = cell+direction
			if visited.has(next) or not floor_cells.has(next): continue
			var from := Vector2(cell)*GRID
			var to := Vector2(next)*GRID
			var walkable := func(p: Vector2): return can_walk(region,cave,p)
			var arrived: Vector2 = MOTION.move(from,to-from,walkable)
			if arrived.distance_to(to) > 0.1: continue
			audited_edges += 1
			visited[next] = true
			queue.append(next)
	var missed: Array = []
	for cell in floor_cells:
		if not visited.has(cell): missed.append(cell)
	# A diagonal bend narrower than the coarse grid can still be accessible.
	# Prove the local connection with the same swept player collision, rather
	# than reporting a sampling artifact as an unreachable room.
	for cell in missed.duplicate():
		var joined := false
		for y in range(-2,3):
			for x in range(-2,3):
				var neighbour: Vector2i = cell+Vector2i(x,y)
				if not visited.has(neighbour): continue
				var point := Vector2(cell)*GRID
				var from := Vector2(neighbour)*GRID
				var walkable := func(p: Vector2): return can_walk(region,cave,p)
				if MOTION.move(from,point-from,walkable).distance_to(point) < 0.1:
					joined = true
					break
			if joined: break
		if joined:
			visited[cell] = true
			missed.erase(cell)
			audited_edges += 1
	# Boundary slivers smaller than a body footprint are not walkable rooms.
	var interior_missed := 0
	for cell in missed:
		var neighbours := 0
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if floor_cells.has(cell+direction): neighbours += 1
		if neighbours >= 3: interior_missed += 1
	check(interior_missed == 0,"Disconnected walkable floor in %s cave=%s: %d interior grid cells" % [EARTH.NAMES[region],cave,interior_missed])
	check(missed.is_empty(),"Isolated floor samples remain in %s cave=%s: %s" % [EARTH.NAMES[region],cave,missed])
	report.areas.append({"district":EARTH.NAMES[region],"mine":cave,"floor_samples":floor_cells.size(),"reachable":visited.size(),"unreachable_interior":interior_missed,"boundary_slivers":missed.map(func(p): return str(Vector2(p)*GRID/EARTH.SIZE*EARTH.ART_SIZE))})

func finish_transition(game) -> void:
	var deadline := Time.get_ticks_msec()+12000
	while game.earth_transition and Time.get_ticks_msec() < deadline:
		game.advance_earth_transition(0.05)
		await process_frame
	check(not game.earth_transition,"Audit doorway did not finish loading")

func audit_trails(game) -> void:
	for region in 5:
		for link in EARTH.LINKS[region]:
			var gate: Vector2 = EARTH.portal(region,link.side)
			var inward: Vector2 = {"west":Vector2.RIGHT,"east":Vector2.LEFT,"north":Vector2.DOWN,"south":Vector2.UP}[link.side]
			var lateral := inward.orthogonal()
			# The markup excludes the sign beside the east path and a shrub
			# beside the south path. Probe clear ground beside those islands.
			var offsets := [-90.0,0.0,90.0]
			if region == 0: offsets[0] = -60.0 if link.side == "south" else -45.0
			for offset in offsets:
				await TRAVEL.enter(game,region,false)
				game.story.quarry_open = true
				game.mine_transition_cooldown = 0
				game.earth_trail_cooldown = 0
				game.player = gate+inward*150+lateral*offset
				var deadline := 0
				while not game.earth_transition and deadline < 60:
					game.move_player(-inward,0.04)
					deadline += 1
				check(game.earth_transition,"Trail edge failed: %s %s lateral=%s" % [EARTH.NAMES[region],link.side,offset])
				await finish_transition(game)
				check(game.earth_region == link.target and not game.underground,"Trail edge reached wrong area")
				check(not EARTH.crosses_opening(game.player,game.player,EARTH.portal(link.target,link.arrival),EARTH.trail_trigger_extents(link.arrival)),"Arrival is inside the enlarged return trigger")
				game.move_player(Vector2.ZERO,1)
				check(not game.earth_transition,"Arrival automatically bounced back after cooldown")
				report.trail_approaches += 1
	# Even a broad lateral trigger must never bypass the story's closed quarry.
	await TRAVEL.enter(game,1,false)
	game.story.quarry_open = false
	for offset in [-90.0,0.0,90.0]:
		game.earth_trail_cooldown = 0
		game.player = EARTH.portal(1,"east")+Vector2(0,offset)
		game.check_earth_trail(game.player-Vector2(200,0))
		check(not game.earth_transition and game.earth_region == 1,"Larger trail trigger bypassed the quarry gate")
	game.story.quarry_open = true

func audit_mines(game) -> void:
	for region in [0,1,4]:
		for cave in [false,true]:
			for offset in ([-25.0,0.0,25.0] if cave and region == 0 else ([-45.0,0.0,45.0] if cave else [-75.0,0.0,75.0])):
				await TRAVEL.enter(game,region,cave)
				game.mine_transition_cooldown = 0
				game.earth_trail_cooldown = 100
				var door: Vector2 = game.exit_position() if cave else game.cave_position()
				var inward := Vector2.RIGHT if cave and region in [0,4] else (Vector2.UP if cave else Vector2.DOWN)
				var lateral := inward.orthogonal()
				var approach_distance := 120.0 if cave and region == 4 else 155.0
				game.player = door+inward*approach_distance+lateral*offset
				for step in 80:
					if game.earth_transition or game.underground != cave: break
					game.move_player(-inward,0.04)
				check(game.earth_transition or game.underground != cave,"Mine edge failed: region=%d cave=%s offset=%s" % [region,cave,offset])
				await finish_transition(game)
				check(game.underground != cave,"Mine edge stayed on the same floor")
				var return_door: Vector2 = game.exit_position() if game.underground else game.cave_position()
				check(not EARTH.crosses_opening(game.player,game.player,return_door,EARTH.MINE_TRIGGER_EXTENTS),"Mine arrival is inside enlarged return trigger")
				game.move_player(Vector2.ZERO,1)
				check(game.underground != cave and not game.earth_transition,"Mine arrival bounced back after cooldown")
				report.mine_approaches += 1

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.story.set_process(false)
	game.companion.set_process(false)
	game.trial.invulnerable = 10000
	game.story.quarry_open = true
	for route in ROUTES:
		walk_route(game,route)
		walk_route(game,route,true)
	for region in 5:
		audit_grid(region,false)
		if EARTH.has_mine(region): audit_grid(region,true)
	# Original solid landmarks remain forbidden after correcting the apron.
	for sample in [Vector2(380,320),Vector2(650,345),Vector2(780,425),Vector2(1070,480),Vector2(755,640)]:
		check(not MOSS.can_walk(MOSS.from_art(sample)-MOSS.FOOT_OFFSET),"Apron fix opened a mine wall/pillar/pool: "+str(sample))
	await audit_trails(game)
	await audit_mines(game)
	report.movement_steps = movement_samples
	report.swept_grid_edges = audited_edges
	report.failures = failures
	var file := FileAccess.open("res://build/earth-navigation-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: %d artwork routes walked both ways (%d real-control steps), all eight Earth areas (%d swept grid edges), %d broad trail approaches, %d broad mine approaches, safe arrivals, locked quarry and solid hazards" % [ROUTES.size(),movement_samples,audited_edges,report.trail_approaches,report.mine_approaches])
	quit(1 if failures else 0)
