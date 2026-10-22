extends SceneTree

# Artwork waypoints are independent of the polygons under test. Grid sweeps
# additionally check every floor branch, including approaches not in the routes.
var REGIONS = preload("res://outer_regions.gd").new(2)
const HOME_LAYOUT = preload("res://desert_layout.gd")
const MOTION = preload("res://floor_motion.gd")
const TRAVEL = preload("res://tests/support/area_travel.gd")
const GRID := 24.0
const ROUTES := [
	[0,false,"camp around western mesa to mine",[Vector2(1200,850),Vector2(1000,830),Vector2(850,800),Vector2(650,790),Vector2(520,800),Vector2(340,790),Vector2(270,690),Vector2(220,590),Vector2(230,480),Vector2(280,380),Vector2(300,300)]],
	[0,false,"eastern and northern mesa loop",[Vector2(1220,840),Vector2(1340,820),Vector2(1340,720),Vector2(1270,670),Vector2(1240,570),Vector2(1220,440),Vector2(1220,330),Vector2(1100,270),Vector2(970,240),Vector2(850,235),Vector2(720,215),Vector2(650,210),Vector2(590,215),Vector2(470,270),Vector2(350,290),Vector2(300,300)]],
	[0,false,"signed west trail",[Vector2(300,300),Vector2(270,330),Vector2(240,380),Vector2(160,390),Vector2(80,390)]],
	[0,false,"southern trail",[Vector2(850,800),Vector2(850,900),Vector2(850,980)]],
	[0,false,"marked northern spur",[Vector2(1100,270),Vector2(1100,200),Vector2(1070,150),Vector2(1070,100),Vector2(1030,50),Vector2(990,25)]],
	[0,true,"lava bridge",[Vector2(550,450),Vector2(650,450),Vector2(800,450),Vector2(950,450),Vector2(1100,450),Vector2(1220,430)]],
	[0,true,"lava west gallery and entrance",[Vector2(260,850),Vector2(300,780),Vector2(300,650),Vector2(280,580),Vector2(280,480),Vector2(400,440),Vector2(550,450)]],
	[0,true,"lava upper western ledge",[Vector2(400,440),Vector2(350,350),Vector2(325,270),Vector2(330,200),Vector2(330,170),Vector2(450,180),Vector2(550,150),Vector2(680,120),Vector2(720,115)]],
	[0,true,"lava east gallery",[Vector2(1220,430),Vector2(1260,350),Vector2(1320,300),Vector2(1340,240),Vector2(1330,190),Vector2(1240,170),Vector2(1170,210),Vector2(1100,210),Vector2(1000,170),Vector2(920,140)]],
	[0,true,"lava southeast gallery",[Vector2(1220,430),Vector2(1300,470),Vector2(1300,550),Vector2(1330,620),Vector2(1350,710),Vector2(1250,710),Vector2(1200,700),Vector2(1280,670)]],
	[1,false,"dune east to mine",[Vector2(1300,380),Vector2(1100,430),Vector2(850,500),Vector2(650,500),Vector2(450,340),Vector2(300,250)]],
	[1,false,"dune south trail",[Vector2(850,500),Vector2(750,600),Vector2(600,600),Vector2(600,680),Vector2(650,700),Vector2(750,820),Vector2(800,915)]],
	[1,false,"dune western dunes",[Vector2(650,500),Vector2(570,590),Vector2(400,640),Vector2(200,600),Vector2(150,440),Vector2(250,420)]],
	[1,true,"sunfire complete ring",[Vector2(750,780),Vector2(750,720),Vector2(550,700),Vector2(380,620),Vector2(300,500),Vector2(320,400),Vector2(300,350),Vector2(340,290),Vector2(450,240),Vector2(550,200),Vector2(600,160),Vector2(630,140),Vector2(680,140),Vector2(720,150),Vector2(780,155),Vector2(850,160),Vector2(950,200),Vector2(1000,250),Vector2(1120,280),Vector2(1200,420),Vector2(1230,530),Vector2(1170,650),Vector2(1190,740),Vector2(1100,800),Vector2(950,740),Vector2(750,720)]],
	[1,true,"sunfire northwest chamber",[Vector2(320,400),Vector2(200,360),Vector2(150,300),Vector2(150,240)]],
	[1,true,"sunfire northeast chamber",[Vector2(1120,280),Vector2(1190,240),Vector2(1200,205),Vector2(1220,190),Vector2(1260,185),Vector2(1320,190)]],
	[2,false,"oasis northern and eastern trails",[Vector2(790,205),Vector2(830,310),Vector2(1030,430),Vector2(1320,455)]],
	[2,false,"oasis west trail",[Vector2(200,385),Vector2(250,410),Vector2(350,350),Vector2(350,315),Vector2(650,270),Vector2(830,310)]],
	[2,false,"oasis southern circuit",[Vector2(350,315),Vector2(270,430),Vector2(250,570),Vector2(350,700),Vector2(650,780),Vector2(950,780),Vector2(1120,800),Vector2(1200,690),Vector2(1200,520),Vector2(1280,480),Vector2(1320,455)]],
	[3,false,"arch north to east connection",[Vector2(750,205),Vector2(800,350),Vector2(900,430),Vector2(1050,480),Vector2(1320,510)]],
	[3,false,"walk under redrock arch",[Vector2(900,430),Vector2(1100,300),Vector2(1140,250),Vector2(1160,210)]],
	[3,false,"redrock southern circuit",[Vector2(800,350),Vector2(850,450),Vector2(800,500),Vector2(750,550),Vector2(600,630),Vector2(600,750),Vector2(700,840),Vector2(900,900),Vector2(1150,900),Vector2(1340,780),Vector2(1320,700),Vector2(1310,690),Vector2(1300,660),Vector2(1280,630),Vector2(1280,600),Vector2(1320,510)]],
	[3,false,"redrock east passage inner lane",[Vector2(1320,560),Vector2(1320,620),Vector2(1320,680),Vector2(1320,740),Vector2(1320,790)]],
	[3,false,"redrock east passage outer lane",[Vector2(1340,560),Vector2(1340,620),Vector2(1340,680),Vector2(1340,740),Vector2(1340,790)]],
	[4,false,"obsidian west to mine",[Vector2(200,415),Vector2(300,430),Vector2(350,390),Vector2(420,430),Vector2(500,480),Vector2(650,450),Vector2(950,420),Vector2(1100,370),Vector2(1160,240)]],
	[4,false,"obsidian lower circuit",[Vector2(300,430),Vector2(250,550),Vector2(300,700),Vector2(550,800),Vector2(800,740),Vector2(1000,750),Vector2(1150,700),Vector2(1250,630),Vector2(1300,600),Vector2(1330,450),Vector2(1330,350),Vector2(1160,240)]],
	[4,false,"observatory landmark",[Vector2(300,430),Vector2(350,320),Vector2(380,260),Vector2(460,220),Vector2(530,200)]],
	[4,true,"magma vault cleared junction",[Vector2(280,800),Vector2(300,700),Vector2(350,600),Vector2(400,500),Vector2(550,500),Vector2(700,520),Vector2(900,520),Vector2(1000,520),Vector2(1200,500),Vector2(1300,500)]],
	[4,true,"magma vault northwest chamber",[Vector2(400,500),Vector2(350,400),Vector2(300,300),Vector2(320,230),Vector2(300,180),Vector2(240,150)]],
	[4,true,"magma vault upper gallery",[Vector2(300,180),Vector2(450,180),Vector2(550,150),Vector2(650,140),Vector2(750,135),Vector2(900,150),Vector2(1000,190),Vector2(1130,220),Vector2(1200,200),Vector2(1250,170),Vector2(1360,220)]],
	[4,true,"magma vault central to northeast gallery",[Vector2(650,400),Vector2(650,300),Vector2(700,270),Vector2(750,260),Vector2(800,270),Vector2(850,300),Vector2(950,350),Vector2(1050,400),Vector2(1100,400),Vector2(1160,400),Vector2(1185,395),Vector2(1185,370),Vector2(1185,360),Vector2(1190,345),Vector2(1200,330),Vector2(1210,300),Vector2(1200,260),Vector2(1230,220),Vector2(1220,170)]],
	[4,true,"magma vault dry lava rim",[Vector2(550,500),Vector2(650,550),Vector2(750,600),Vector2(750,650),Vector2(770,700),Vector2(850,760),Vector2(950,820),Vector2(1000,830)]],
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
	game.world = 2
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

func flood_grid(region: int, cave: bool, floor_cells: Dictionary, visited: Dictionary, queue: Array[Vector2i]) -> void:
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

func join_artwork_routes(region: int, cave: bool, floor_cells: Dictionary, visited: Dictionary) -> void:
	# A narrow bend can fit the body but fall between coarse grid samples.
	# Join its components only through independently authored routes whose every
	# segment is proven by the same swept motion, then flood their floor cells.
	if visited.size() == floor_cells.size(): return
	var walkable := func(p: Vector2): return can_walk(region,cave,p)
	for spec in ROUTES:
		if spec[0] != region or spec[1] != cave: continue
		var points: Array[Vector2] = []
		for point in spec[3]: points.append(art_point(region,cave,point))
		var proved := true
		for i in range(1,points.size()):
			if MOTION.move(points[i-1],points[i]-points[i-1],walkable).distance_to(points[i]) > 0.1:
				proved = false
				break
		if not proved: continue
		var connected := false
		for point in points:
			for cell in visited:
				var from := Vector2(cell)*GRID
				if from.distance_to(point) > GRID*3: continue
				if MOTION.move(from,point-from,walkable).distance_to(point) < 0.1:
					connected = true
					break
			if connected: break
		if not connected: continue
		var seeds: Array[Vector2i] = []
		for cell in floor_cells:
			if visited.has(cell): continue
			var target := Vector2(cell)*GRID
			for point in points:
				if target.distance_to(point) > GRID*3: continue
				if MOTION.move(point,target-point,walkable).distance_to(target) < 0.1:
					visited[cell] = true
					seeds.append(cell)
					audited_edges += 1
					break
		flood_grid(region,cave,floor_cells,visited,seeds)

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
	flood_grid(region,cave,floor_cells,visited,queue)
	join_artwork_routes(region,cave,floor_cells,visited)
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
	# Independent samples from the annotations: sand and bridge are open;
	# unpainted mesa bases, cactus islands, oasis water and lava stay closed.
	var samples := [
		[0,false,true,Vector2(850,980)],[0,false,true,Vector2(990,25)],[0,false,false,Vector2(780,500)],
		[0,false,false,Vector2(435,700)],[0,false,false,Vector2(1240,755)],
		[0,true,false,Vector2(600,350)],[0,true,true,Vector2(800,450)],[0,true,false,Vector2(900,350)],
		[1,false,true,Vector2(700,500)],[1,false,false,Vector2(900,300)],[1,false,false,Vector2(370,500)],
		[1,true,true,Vector2(750,720)],[1,true,false,Vector2(750,450)],[1,true,false,Vector2(230,275)],
		[2,false,true,Vector2(790,50)],[2,false,false,Vector2(625,525)],[2,false,false,Vector2(1070,710)],
		[3,false,true,Vector2(1140,250)],[3,false,false,Vector2(465,410)],[3,false,false,Vector2(1050,710)],
		# Reported clear-sand passage stays open between both solid cactus beds.
		[3,false,true,Vector2(1330,640)],[3,false,true,Vector2(1340,700)],
		[3,false,false,Vector2(1240,645)],[3,false,false,Vector2(1400,605)],[3,false,false,Vector2(1450,650)],
		[4,false,true,Vector2(1160,240)],[4,false,false,Vector2(430,560)],[4,false,false,Vector2(1000,670)],
		[4,true,true,Vector2(600,390)],[4,true,true,Vector2(400,500)],[4,true,false,Vector2(780,400)],[4,true,false,Vector2(1210,730)],
	]
	for sample in samples:
		check(can_walk(sample[0],sample[1],art_point(sample[0],sample[1],sample[3])) == sample[2],"Marked/unmarked Ember landmark disagrees: "+str(sample))

func finish_transition(game) -> void:
	var deadline := Time.get_ticks_msec()+12000
	while game.earth_transition and Time.get_ticks_msec() < deadline:
		game.advance_earth_transition(0.05)
		await process_frame
	check(not game.earth_transition,"Audit doorway did not finish loading")

func audit_trails(game) -> void:
	for region in 5:
		for link in REGIONS.LINKS[region]:
			check(can_walk(region,false,REGIONS.portal(region,link.side)),"Trail gate lies outside the marked ground")
			check(can_walk(region,false,REGIONS.arrival(region,link.side)),"Trail arrival lies outside the marked ground")
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
				check(can_walk(link.target,false,game.player),"Trail returned outside marked ground")
				check(not game.EARTH.crosses_opening(game.player,game.player,REGIONS.portal(link.target,link.arrival),game.EARTH.trail_trigger_extents(link.arrival)),"Arrival is inside the enlarged return trigger")
				game.move_player(Vector2.ZERO,1)
				check(not game.earth_transition,"Arrival automatically bounced back after cooldown")
				report.trail_approaches += 1
func audit_mines(game) -> void:
	for region in [0,1,4]:
		for cave in [false,true]:
			var door: Vector2 = REGIONS.MINE_EXITS[region] if cave else REGIONS.MINE_ENTRANCES[region]
			var inward := Vector2.UP if cave else Vector2.DOWN
			var lateral := inward.orthogonal()
			var approach_distance := 155.0
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
				check(can_walk(region,not cave,game.player),"Mine arrival lies outside the marked ground")
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
	game.travel_to_other_planet(2)
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
	var file := FileAccess.open("res://build/ember-navigation-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: %d artwork routes walked both ways (%d real-control steps), all eight Ember areas (%d swept grid edges), %d broad trail approaches, %d broad mine approaches, safe arrivals and solid hazards" % [ROUTES.size(),movement_samples,audited_edges,report.trail_approaches,report.mine_approaches])
	quit(1 if failures else 0)
