extends SceneTree

# Artwork waypoints are independent of the polygons under test. Grid sweeps
# additionally check every floor branch, including approaches not in the routes.
var REGIONS = preload("res://outer_regions.gd").new(1)
const HOME_LAYOUT = preload("res://frost_layout.gd")
const MOTION = preload("res://floor_motion.gd")
const TRAVEL = preload("res://tests/support/area_travel.gd")
const GRID := 24.0
const ROUTES := [
	[0,false,"cleared Frozen Basin junction",[Vector2(70,450),Vector2(150,450),Vector2(240,455),Vector2(300,470),Vector2(345,485),Vector2(400,490),Vector2(520,495)]],
	[0,false,"cleared Prism Pass junction",[Vector2(1190,330),Vector2(1280,330),Vector2(1340,340),Vector2(1400,330),Vector2(1460,320)]],
	[2,false,"Glacier Crown signed exit",[Vector2(1320,455),Vector2(1400,450),Vector2(1460,435),Vector2(1490,435)]],
	[0,false,"camp and canyon bridge",[Vector2(300,840),Vector2(500,820),Vector2(500,720),Vector2(410,680),Vector2(330,610),Vector2(340,550),Vector2(400,490),Vector2(520,495),Vector2(630,500),Vector2(770,500),Vector2(920,500),Vector2(1000,470),Vector2(1090,400),Vector2(1110,320),Vector2(1190,330),Vector2(1210,290)]],
	[0,false,"northern ice arch",[Vector2(340,550),Vector2(335,440),Vector2(340,365),Vector2(370,320),Vector2(355,275),Vector2(300,275),Vector2(270,270),Vector2(260,220),Vector2(300,200)]],
	[0,false,"eastern frozen pool",[Vector2(1000,470),Vector2(1080,560),Vector2(1160,620),Vector2(1160,700),Vector2(1240,755),Vector2(1300,790),Vector2(1360,800)]],
	[0,true,"mine west branch",[Vector2(725,800),Vector2(750,650),Vector2(700,590),Vector2(680,520),Vector2(600,460),Vector2(520,420),Vector2(440,380),Vector2(465,330),Vector2(350,300),Vector2(300,285),Vector2(315,230),Vector2(340,210),Vector2(310,160)]],
	[0,true,"mine east branch",[Vector2(725,800),Vector2(800,755),Vector2(750,650),Vector2(860,590),Vector2(885,520),Vector2(960,480),Vector2(1030,400),Vector2(1100,430),Vector2(1180,440),Vector2(1290,420),Vector2(1350,340),Vector2(1270,280),Vector2(1230,210),Vector2(1240,160)]],
	[1,false,"basin mine and east trail",[Vector2(1300,480),Vector2(1100,505),Vector2(750,450),Vector2(590,340),Vector2(450,245)]],
	[1,false,"basin south trail",[Vector2(750,450),Vector2(600,540),Vector2(650,660),Vector2(760,800),Vector2(790,920)]],
	[1,false,"basin frozen pool",[Vector2(750,450),Vector2(840,350),Vector2(930,290),Vector2(1040,250),Vector2(1130,250)]],
	[1,false,"basin west clearing",[Vector2(750,450),Vector2(550,470),Vector2(430,530),Vector2(330,570),Vector2(280,600)]],
	[1,false,"basin southwest frozen pool",[Vector2(280,650),Vector2(265,700),Vector2(285,745),Vector2(310,780),Vector2(350,815),Vector2(390,845),Vector2(450,850),Vector2(495,855)]],
	[1,true,"blue echo full ring",[Vector2(750,780),Vector2(750,680),Vector2(580,630),Vector2(440,570),Vector2(420,460),Vector2(500,350),Vector2(540,260),Vector2(650,205),Vector2(830,205),Vector2(980,250),Vector2(1040,400),Vector2(1080,490),Vector2(1050,580),Vector2(900,650),Vector2(750,680)]],
	[1,true,"blue echo west branch",[Vector2(420,460),Vector2(290,400),Vector2(180,400)]],
	[1,true,"blue echo southeast chamber",[Vector2(1080,490),Vector2(1120,550),Vector2(1190,630),Vector2(1200,690)]],
	[2,false,"prism west to east trail",[Vector2(170,455),Vector2(260,495),Vector2(430,510),Vector2(650,525),Vector2(800,500),Vector2(1000,480),Vector2(1200,500),Vector2(1320,455)]],
	[2,false,"prism central island circuit",[Vector2(650,525),Vector2(540,430),Vector2(505,330),Vector2(600,220),Vector2(750,175),Vector2(890,230),Vector2(950,330),Vector2(950,400),Vector2(800,500)]],
	[2,false,"prism south trail",[Vector2(800,500),Vector2(750,650),Vector2(820,770),Vector2(750,900)]],
	[2,false,"heart crystal landmark",[Vector2(1200,500),Vector2(1280,425),Vector2(1280,325),Vector2(1250,285),Vector2(1260,230),Vector2(1270,200)]],
	[3,false,"aurora north connections",[Vector2(315,205),Vector2(390,300),Vector2(330,450),Vector2(420,560),Vector2(620,575),Vector2(760,520),Vector2(1000,590),Vector2(1070,600),Vector2(1100,570),Vector2(1100,520),Vector2(1190,430),Vector2(1120,290),Vector2(1190,205)]],
	[3,false,"aurora frozen lake",[Vector2(760,520),Vector2(800,610),Vector2(800,730),Vector2(700,740),Vector2(600,710)]],
	[3,false,"aurora southern circuit",[Vector2(600,710),Vector2(470,740),Vector2(550,810),Vector2(700,870),Vector2(850,880),Vector2(1000,830),Vector2(1090,750),Vector2(1100,650),Vector2(1000,590)]],
	[4,false,"crown mine approach",[Vector2(200,520),Vector2(330,540),Vector2(440,420),Vector2(450,350),Vector2(470,320),Vector2(550,300),Vector2(750,380),Vector2(950,350),Vector2(1120,285),Vector2(1210,240)]],
	[4,false,"crown south circuit",[Vector2(330,540),Vector2(430,650),Vector2(400,770),Vector2(600,805),Vector2(820,760),Vector2(1050,650),Vector2(1150,650),Vector2(1140,530),Vector2(1200,430)]],
	[4,false,"crown frozen pool",[Vector2(1050,650),Vector2(1150,650),Vector2(1200,750),Vector2(1240,800),Vector2(1290,790)]],
	[4,false,"crown sundial",[Vector2(440,420),Vector2(420,340),Vector2(460,260)]],
	[4,true,"deep prism western gallery",[Vector2(350,780),Vector2(420,730),Vector2(490,650),Vector2(580,550),Vector2(590,430),Vector2(620,360),Vector2(750,320),Vector2(880,310),Vector2(900,400),Vector2(950,490),Vector2(900,570),Vector2(750,580),Vector2(620,530),Vector2(590,430)]],
	[4,true,"deep prism northwest chamber",[Vector2(620,360),Vector2(500,300),Vector2(400,260),Vector2(320,210)]],
	[4,true,"deep prism northeast chamber",[Vector2(900,400),Vector2(1030,380),Vector2(1100,330),Vector2(1140,300),Vector2(1220,240)]],
	[4,true,"deep prism direct stair entrance",[Vector2(1090,440),Vector2(1150,420),Vector2(1150,395),Vector2(1145,370),Vector2(1150,345),Vector2(1180,300),Vector2(1220,240)]],
	[4,true,"deep prism lakeside path",[Vector2(900,570),Vector2(925,600),Vector2(950,620),Vector2(1000,610),Vector2(1050,615),Vector2(1075,615),Vector2(1100,590),Vector2(1180,580)]],
	[4,true,"deep prism lakeside southern tip",[Vector2(950,620),Vector2(925,640),Vector2(900,665),Vector2(880,690),Vector2(870,715)]],
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
	return REGIONS.can_walk(region,cave,point)

func art_point(_region: int, _cave: bool, point: Vector2) -> Vector2:
	return HOME_LAYOUT.from_art(point)-REGIONS.FOOT_OFFSET

func walk_route(game, spec: Array, reverse := false) -> void:
	game.world = 1
	game.set_current_region(spec[0])
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
		check(game.player.distance_to(goal) < 1,"Real walking stopped on %s at art %s; goal %s" % [spec[2],game.player/REGIONS.SIZE*REGIONS.ART_SIZE,point])
		if game.player.distance_to(goal) >= 1: return
	if not reverse: report.routes.append({"district":REGIONS.NAMES[spec[0]],"mine":spec[1],"route":spec[2],"waypoints":points.size(),"directions":"both"})

func audit_grid(region: int, cave: bool) -> void:
	var floor_cells := {}
	for y in range(1,ceili(REGIONS.SIZE.y/GRID)):
		for x in range(1,ceili(REGIONS.SIZE.x/GRID)):
			var cell := Vector2i(x,y)
			if can_walk(region,cave,Vector2(cell)*GRID): floor_cells[cell] = true
	var entry: Vector2 = REGIONS.MINE_SPAWNS[region] if cave else REGIONS.arrival(region,REGIONS.LINKS[region][0].side)
	var first := Vector2i((entry/GRID).round())
	# Rounding a safe arrival can put the seed on a nearby sign/rock. Join
	# the arrival to a valid floor sample before auditing its component.
	if not floor_cells.has(first):
		var closest := floor_cells.keys()
		closest.sort_custom(func(a,b): return (Vector2(a)*GRID).distance_squared_to(entry) < (Vector2(b)*GRID).distance_squared_to(entry))
		for cell in closest:
			var point := Vector2(cell)*GRID
			var floor_check := func(p: Vector2): return can_walk(region,cave,p)
			if MOTION.move(entry,point-entry,floor_check).distance_to(point) < 0.1:
				first = cell
				break
	check(floor_cells.has(first),"Area arrival cannot join any marked floor sample")
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
	check(interior_missed == 0,"Disconnected walkable floor in %s cave=%s: %d interior grid cells" % [REGIONS.NAMES[region],cave,interior_missed])
	check(missed.is_empty(),"Isolated floor samples remain in %s cave=%s: %d samples, first %s" % [REGIONS.NAMES[region],cave,missed.size(),missed.slice(0,12)])
	report.areas.append({"district":REGIONS.NAMES[region],"mine":cave,"floor_samples":floor_cells.size(),"reachable":visited.size(),"unreachable_interior":interior_missed,"boundary_slivers":missed.map(func(p): return str(Vector2(p)*GRID/REGIONS.SIZE*REGIONS.ART_SIZE))})

func audit_landmarks() -> void:
	# Expected samples are selected from the supplied red paintings, not from
	# the navigation data. Red frozen pools and the landmark are usable ground.
	var samples := [
		[0,false,true,Vector2(250,500)],[0,false,true,Vector2(1340,355)],
		[0,false,false,Vector2(160,405)],
		[0,false,true,Vector2(300,840)],[0,false,true,Vector2(770,500)],[0,false,true,Vector2(1300,790)],
		[0,false,false,Vector2(770,350)],[0,false,false,Vector2(770,650)],[0,false,false,Vector2(430,590)],
		[0,true,true,Vector2(750,650)],[0,true,false,Vector2(790,510)],[0,true,false,Vector2(1220,350)],
		[1,false,true,Vector2(1040,250)],[1,false,true,Vector2(450,850)],[1,false,false,Vector2(350,390)],
		[1,true,true,Vector2(750,680)],[1,true,false,Vector2(750,430)],[1,true,false,Vector2(500,690)],
		[2,false,true,Vector2(1270,200)],[2,false,true,Vector2(800,500)],[2,false,false,Vector2(750,345)],
		[3,false,true,Vector2(800,730)],[3,false,false,Vector2(480,450)],[3,false,false,Vector2(1010,400)],
		[4,false,true,Vector2(1240,800)],[4,false,true,Vector2(460,260)],[4,false,false,Vector2(770,570)],
		[4,true,true,Vector2(620,360)],[4,true,false,Vector2(785,450)],[4,true,false,Vector2(1130,735)],
		# The direct stairs and shoreline must be usable without opening the
		# adjacent cliff faces, central island or water beneath the stone bank.
		[4,true,true,Vector2(1150,395)],[4,true,true,Vector2(1075,615)],[4,true,true,Vector2(870,715)],
		[4,true,false,Vector2(1200,400)],[4,true,false,Vector2(1000,675)],
		[4,true,false,Vector2(1120,650)],[4,true,false,Vector2(900,770)],
	]
	for sample in samples:
		check(can_walk(sample[0],sample[1],art_point(sample[0],sample[1],sample[3])) == sample[2],"Marked/unmarked Frost landmark disagrees: "+str(sample))
	for region in 5:
		for cave in [false,true]:
			if cave and not REGIONS.has_mine(region): continue
			var start := art_point(region,cave,Vector2(100,100))
			check(not can_walk(region,cave,start),"Unmarked cliff/wall corner became walkable")

func finish_transition(game) -> void:
	var deadline := Time.get_ticks_msec()+12000
	while game.earth_transition and Time.get_ticks_msec() < deadline:
		game.advance_earth_transition(0.05)
		await process_frame
	check(not game.earth_transition,"Audit doorway did not finish loading")

func audit_trails(game) -> void:
	for region in 5:
		for link in REGIONS.LINKS[region]:
			var gate: Vector2 = REGIONS.portal(region,link.side)
			var inward: Vector2 = {"west":Vector2.RIGHT,"east":Vector2.LEFT,"north":Vector2.DOWN,"north_west":Vector2.DOWN,"north_east":Vector2.DOWN,"south":Vector2.UP}[link.side]
			var lateral := inward.orthogonal()
			# Probe the outermost straight approaches on the marked path, plus
			# its middle. Old fixed offsets can now start on an unpainted rock.
			var approaches: Array[float] = []
			for offset in range(-120,121,5):
				var start: Vector2 = gate+inward*150+lateral*offset
				var end: Vector2 = gate+inward*30+lateral*offset
				if not can_walk(region,false,start): continue
				var floor_check := func(p: Vector2): return can_walk(region,false,p)
				if MOTION.move(start,end-start,floor_check).distance_to(end) < 0.1: approaches.append(float(offset))
			check(approaches.size() >= 3,"No broad marked trail approach: %s %s" % [REGIONS.NAMES[region],link.side])
			if approaches.size() < 3: continue
			var offsets := [approaches[0],approaches[approaches.size()/2],approaches[-1]]
			for offset in offsets:
				await TRAVEL.enter(game,region,false)
				game.mine_transition_cooldown = 0
				game.earth_trail_cooldown = 0
				game.player = gate+inward*150+lateral*offset
				var deadline := 0
				while not game.earth_transition and deadline < 60:
					game.move_player(-inward,0.04)
					deadline += 1
				check(game.earth_transition,"Trail edge failed: %s %s lateral=%s" % [REGIONS.NAMES[region],link.side,offset])
				await finish_transition(game)
				check(game.current_region() == link.target and not game.underground,"Trail edge reached wrong area: wanted %s got %s" % [link.target,game.current_region()])
				check(not game.EARTH.crosses_opening(game.player,game.player,REGIONS.portal(link.target,link.arrival),game.EARTH.trail_trigger_extents(link.arrival)),"Arrival is inside the enlarged return trigger")
				game.move_player(Vector2.ZERO,1)
				check(not game.earth_transition,"Arrival automatically bounced back after cooldown")
				report.trail_approaches += 1
func audit_mines(game) -> void:
	for region in [0,1,4]:
		for cave in [false,true]:
			var door: Vector2 = REGIONS.MINE_EXITS[region] if cave else REGIONS.MINE_ENTRANCES[region]
			var inward := Vector2(100,-110).normalized() if cave and region == 4 else (Vector2.UP if cave else Vector2.DOWN)
			var lateral := inward.orthogonal()
			var approach_distance := 190.0 if cave and region == 4 else 155.0
			var approaches: Array[float] = []
			for offset in range(-90,91,10):
				var start := door+inward*approach_distance+lateral*offset
				var end := door+inward*40+lateral*offset
				if not can_walk(region,cave,start): continue
				var floor_check := func(p: Vector2): return can_walk(region,cave,p)
				if MOTION.move(start,end-start,floor_check).distance_to(end) < 0.1: approaches.append(float(offset))
			check(approaches.size() >= 3,"No marked mine approach: %d cave=%s" % [region,cave])
			if approaches.size() < 3: continue
			for offset in [approaches[0],approaches[approaches.size()/2],approaches[-1]]:
				await TRAVEL.enter(game,region,cave)
				game.mine_transition_cooldown = 0
				game.earth_trail_cooldown = 100
				game.player = door+inward*approach_distance+lateral*offset
				check(can_walk(region,cave,game.player),"Mine probe starts outside marked floor: %d/%s offset=%s" % [region,cave,offset])
				for step in 80:
					if game.earth_transition or game.underground != cave: break
					game.move_player(-inward,0.04)
				check(game.earth_transition or game.underground != cave,"Mine edge failed: region=%d cave=%s offset=%s; art=%s door=%s" % [region,cave,offset,game.player/REGIONS.SIZE*REGIONS.ART_SIZE,door/REGIONS.SIZE*REGIONS.ART_SIZE])
				await finish_transition(game)
				check(game.underground != cave,"Mine edge stayed on the same floor")
				var return_door: Vector2 = game.exit_position() if game.underground else game.cave_position()
				check(not game.EARTH.crosses_opening(game.player,game.player,return_door,game.EARTH.MINE_TRIGGER_EXTENTS),"Mine arrival is inside enlarged return trigger")
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
	game.travel_to_other_planet(1)
	game.advance_flight(10)
	for route in ROUTES:
		walk_route(game,route)
		walk_route(game,route,true)
	for region in 5:
		audit_grid(region,false)
		if REGIONS.has_mine(region): audit_grid(region,true)
	audit_landmarks()
	await audit_trails(game)
	await audit_mines(game)
	report.movement_steps = movement_samples
	report.swept_grid_edges = audited_edges
	report.failures = failures
	var file := FileAccess.open("res://build/frost-navigation-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: %d artwork routes walked both ways (%d real-control steps), all eight Frost areas (%d swept grid edges), %d broad trail approaches, %d broad mine approaches, safe arrivals and solid hazards" % [ROUTES.size(),movement_samples,audited_edges,report.trail_approaches,report.mine_approaches])
	quit(1 if failures else 0)
