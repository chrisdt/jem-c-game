extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")

var failures := 0
const OUTER = preload("res://outer_regions.gd")

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func reachable(data, region: int, cave: bool) -> Dictionary:
	var entry: Vector2 = data.MINE_SPAWNS[region] if cave else data.arrival(region,data.LINKS[region][0].side)
	var first := Vector2i((entry/20).round())
	var visited := {first:true}
	var queue: Array[Vector2i] = [first]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = at+direction
			if visited.has(next): continue
			var point := Vector2(next)*20
			if data.can_walk(region,cave,point):
				visited[next] = true
				queue.append(next)
	return visited

func finish(game) -> void:
	var deadline := Time.get_ticks_msec()+12000
	while game.earth_transition and Time.get_ticks_msec() < deadline:
		game.advance_earth_transition(0.05)
		await process_frame
	check(not game.earth_transition and game.travel_fade.color.a == 0,"Area loading did not finish cleanly")
	check(game.earth_stream.textures.size() <= 3 and game.earth_stream.jobs.size() <= 2,"Shared scenery cache exceeded its budget")
	check(game.earth_stream.get_child_count() <= 3,"An old district/HTTP request remained active")
	if game.current_region() > 0:
		check(game.regions().can_walk(game.current_region(),game.underground,game.player),"District arrival is not on walkable ground")
		check(game.scout.sprite_frames == game.DRILL_VISUAL.WALK[1],"Off-world district lost the fitted drill/spacesuit")
		check(not game.rocket.visible and not game.green_surface.visible and not game.lava_environment.visible,"Home scenery remained visible in new district")

func trail(game, side: String, target: int) -> void:
	game.mine_transition_cooldown = 0
	game.earth_trail_cooldown = 0
	var data = game.regions()
	game.player = data.arrival(game.current_region(),side)
	var gate: Vector2 = data.portal(game.current_region(),side)
	for i in 45:
		if game.earth_transition: break
		game.move_player((gate-game.player).normalized(),0.04)
	check(game.earth_transition,"Signed trail did not trigger automatically: %s %s" % [data.NAMES[game.current_region()],side])
	var before: Vector2 = game.player
	game.move_player(Vector2.RIGHT,1)
	game.interact()
	check(game.player == before and game.mining_target == -1,"Movement/mining was accepted during loading")
	await finish(game)
	check(game.current_region() == target and not game.underground,"Trail arrived in wrong district")

func mine(game) -> void:
	game.mine_transition_cooldown = 0
	game.earth_trail_cooldown = 0
	var entering: bool = not game.underground
	game.player = game.surface_exit_position() if entering else game.mine_spawn_position()
	var door: Vector2 = game.cave_position() if entering else game.exit_position()
	for i in 70:
		if game.earth_transition: break
		game.move_player((door-game.player).normalized(),0.04)
	check(game.earth_transition,"New mine did not change screens by walking")
	await finish(game)
	check(game.underground == entering,"Mine doorway reached wrong screen")
	if game.world == 2 and entering:
		var ground = game.earth_stream.scenery.get_child(0)
		check(ground.material is ShaderMaterial,"New lava mine lost its flowing lava layer")
		var mask: Texture2D = ground.material.get_shader_parameter("lava_mask")
		check(mask != null and mask.get_width() == 64,"Lava animation did not use its small reusable mask")

func fly(game, planet: int) -> void:
	game.underground = false
	game.player = game.ship_position()
	game.cooldown = 0
	game.interact()
	game.planet_menu.choose(planet)
	for i in 10:
		if game.flight == game.Flight.IDLE: break
		game.advance_flight(5)
	check(game.world == planet and game.flight == game.Flight.IDLE and game.current_region() == 0,"Rocket did not reset arrival to this planet's home district")
	check(game.earth_stream.REGIONS == game.regions(),"Loader retained another planet's catalogue")
	check(game.earth_stream.textures.is_empty(),"Leaving a planet retained its streamed backgrounds")

# The points in this fixture follow visible trails/galleries in the final art.
func walk_route(game, planet: int, region: int, cave: bool, points: Array) -> void:
	game.world = planet
	game.set_current_region(region)
	game.underground = cave
	game.mine_transition_cooldown = 100
	game.earth_trail_cooldown = 100
	var data = game.regions()
	game.player = data.from_art(points[0])-data.FOOT_OFFSET
	for point in points:
		var goal: Vector2 = data.from_art(point)-data.FOOT_OFFSET
		check(data.can_walk(region,cave,goal),"Painted %d/%d floor is blocked at %s" % [planet,region,point])
		var attempts := 0
		while game.player.distance_to(goal) > 0.2 and attempts < 700:
			var remaining: Vector2 = goal-game.player
			game.move_player(remaining.normalized(),minf(remaining.length(),6)/game.SPEED)
			attempts += 1
		check(game.player.distance_to(goal) < 1,"Cannot walk painted %d/%d route to %s; stopped at %s" % [planet,region,point,game.player/data.SIZE*data.ART_SIZE])

func art_routes(game) -> void:
	walk_route(game,1,1,false,[Vector2(1300,480),Vector2(1100,505),Vector2(750,450),Vector2(590,340),Vector2(450,245)])
	walk_route(game,1,1,false,[Vector2(750,450),Vector2(600,540),Vector2(650,660),Vector2(760,800),Vector2(790,920)])
	walk_route(game,1,1,false,[Vector2(750,450),Vector2(840,350),Vector2(930,290),Vector2(1040,250),Vector2(1130,250)])
	walk_route(game,1,1,false,[Vector2(750,450),Vector2(550,470),Vector2(430,530),Vector2(330,570),Vector2(280,600)])
	walk_route(game,1,1,false,[Vector2(280,650),Vector2(265,700),Vector2(285,745),Vector2(310,780),Vector2(350,815),Vector2(390,845),Vector2(450,850),Vector2(495,855)])
	walk_route(game,1,1,true,[Vector2(750,780),Vector2(750,680),Vector2(580,630),Vector2(440,570),Vector2(420,460),Vector2(500,350),Vector2(540,260),Vector2(650,205),Vector2(830,205),Vector2(980,250),Vector2(1040,400),Vector2(1080,490),Vector2(1050,580),Vector2(900,650),Vector2(750,680)])
	walk_route(game,1,1,true,[Vector2(420,460),Vector2(290,400),Vector2(180,400)])
	walk_route(game,1,1,true,[Vector2(1080,490),Vector2(1120,550),Vector2(1190,630),Vector2(1200,690)])
	walk_route(game,1,2,false,[Vector2(170,455),Vector2(260,495),Vector2(430,510),Vector2(650,525),Vector2(800,500),Vector2(1000,480),Vector2(1200,500),Vector2(1320,455)])
	walk_route(game,1,2,false,[Vector2(650,525),Vector2(540,430),Vector2(505,330),Vector2(600,220),Vector2(750,175),Vector2(890,230),Vector2(950,330),Vector2(950,400),Vector2(800,500)])
	walk_route(game,1,2,false,[Vector2(800,500),Vector2(750,650),Vector2(820,770),Vector2(750,900)])
	walk_route(game,1,2,false,[Vector2(1200,500),Vector2(1280,425),Vector2(1280,325),Vector2(1250,285),Vector2(1260,230),Vector2(1270,200)])
	walk_route(game,1,3,false,[Vector2(315,205),Vector2(390,300),Vector2(330,450),Vector2(420,560),Vector2(620,575),Vector2(760,520),Vector2(1000,590),Vector2(1070,600),Vector2(1100,570),Vector2(1100,520),Vector2(1190,430),Vector2(1120,290),Vector2(1190,205)])
	walk_route(game,1,3,false,[Vector2(760,520),Vector2(800,610),Vector2(800,730),Vector2(700,740),Vector2(600,710)])
	walk_route(game,1,3,false,[Vector2(600,710),Vector2(470,740),Vector2(550,810),Vector2(700,870),Vector2(850,880),Vector2(1000,830),Vector2(1090,750),Vector2(1100,650),Vector2(1000,590)])
	walk_route(game,1,4,false,[Vector2(200,520),Vector2(330,540),Vector2(440,420),Vector2(450,350),Vector2(470,320),Vector2(550,300),Vector2(750,380),Vector2(950,350),Vector2(1120,285),Vector2(1210,240)])
	walk_route(game,1,4,false,[Vector2(330,540),Vector2(430,650),Vector2(400,770),Vector2(600,805),Vector2(820,760),Vector2(1050,650),Vector2(1150,650),Vector2(1140,530),Vector2(1200,430)])
	walk_route(game,1,4,false,[Vector2(1050,650),Vector2(1150,650),Vector2(1200,750),Vector2(1240,800),Vector2(1290,790)])
	walk_route(game,1,4,false,[Vector2(440,420),Vector2(420,340),Vector2(460,260)])
	walk_route(game,1,4,true,[Vector2(350,780),Vector2(420,730),Vector2(490,650),Vector2(580,550),Vector2(590,430),Vector2(620,360),Vector2(750,320),Vector2(880,310),Vector2(900,400),Vector2(950,490),Vector2(900,570),Vector2(750,580),Vector2(620,530),Vector2(590,430)])
	walk_route(game,1,4,true,[Vector2(620,360),Vector2(500,300),Vector2(400,260),Vector2(320,210)])
	walk_route(game,1,4,true,[Vector2(900,400),Vector2(1030,380),Vector2(1100,330),Vector2(1140,300),Vector2(1220,240)])

	walk_route(game,2,1,false,[Vector2(1300,380),Vector2(1100,430),Vector2(850,500),Vector2(650,500),Vector2(450,340),Vector2(300,250)])
	walk_route(game,2,1,false,[Vector2(850,500),Vector2(750,600),Vector2(600,600),Vector2(600,680),Vector2(650,700),Vector2(750,820),Vector2(800,915)])
	walk_route(game,2,1,false,[Vector2(650,500),Vector2(570,590),Vector2(400,640),Vector2(200,600),Vector2(150,440),Vector2(250,420)])
	walk_route(game,2,1,true,[Vector2(750,780),Vector2(750,720),Vector2(550,700),Vector2(380,620),Vector2(300,500),Vector2(320,400),Vector2(300,350),Vector2(340,290),Vector2(450,240),Vector2(550,200),Vector2(600,160),Vector2(630,140),Vector2(680,140),Vector2(720,150),Vector2(780,155),Vector2(850,160),Vector2(950,200),Vector2(1000,250),Vector2(1120,280),Vector2(1200,420),Vector2(1230,530),Vector2(1170,650),Vector2(1190,740),Vector2(1100,800),Vector2(950,740),Vector2(750,720)])
	walk_route(game,2,1,true,[Vector2(320,400),Vector2(200,360),Vector2(150,300),Vector2(150,240)])
	walk_route(game,2,1,true,[Vector2(1120,280),Vector2(1190,240),Vector2(1200,205),Vector2(1220,190),Vector2(1260,185),Vector2(1320,190)])
	walk_route(game,2,2,false,[Vector2(790,205),Vector2(830,310),Vector2(1030,430),Vector2(1320,455)])
	walk_route(game,2,2,false,[Vector2(200,385),Vector2(250,410),Vector2(350,350),Vector2(350,315),Vector2(650,270),Vector2(830,310)])
	walk_route(game,2,2,false,[Vector2(350,315),Vector2(270,430),Vector2(250,570),Vector2(350,700),Vector2(650,780),Vector2(950,780),Vector2(1120,800),Vector2(1200,690),Vector2(1200,520),Vector2(1280,480),Vector2(1320,455)])
	walk_route(game,2,3,false,[Vector2(750,205),Vector2(800,350),Vector2(900,430),Vector2(1050,480),Vector2(1320,510)])
	walk_route(game,2,3,false,[Vector2(900,430),Vector2(1100,300),Vector2(1140,250),Vector2(1160,210)])
	walk_route(game,2,3,false,[Vector2(800,350),Vector2(850,450),Vector2(800,500),Vector2(750,550),Vector2(600,630),Vector2(600,750),Vector2(700,840),Vector2(900,900),Vector2(1150,900),Vector2(1340,780),Vector2(1320,700),Vector2(1310,690),Vector2(1300,660),Vector2(1280,630),Vector2(1280,600),Vector2(1320,510)])
	walk_route(game,2,4,false,[Vector2(200,415),Vector2(300,430),Vector2(350,390),Vector2(420,430),Vector2(500,480),Vector2(650,450),Vector2(950,420),Vector2(1100,370),Vector2(1160,240)])
	walk_route(game,2,4,false,[Vector2(300,430),Vector2(250,550),Vector2(300,700),Vector2(550,800),Vector2(800,740),Vector2(1000,750),Vector2(1150,700),Vector2(1250,630),Vector2(1300,600),Vector2(1330,450),Vector2(1330,350),Vector2(1160,240)])
	walk_route(game,2,4,false,[Vector2(300,430),Vector2(350,320),Vector2(380,260),Vector2(460,220),Vector2(530,200)])
	walk_route(game,2,4,true,[Vector2(280,800),Vector2(300,700),Vector2(350,600),Vector2(400,500),Vector2(550,500),Vector2(700,520),Vector2(900,520),Vector2(1000,520),Vector2(1200,500),Vector2(1300,500)])
	walk_route(game,2,4,true,[Vector2(400,500),Vector2(350,400),Vector2(300,300),Vector2(320,230),Vector2(300,180),Vector2(240,150)])
	walk_route(game,2,4,true,[Vector2(300,180),Vector2(450,180),Vector2(550,150),Vector2(650,140),Vector2(750,135),Vector2(900,150),Vector2(1000,190),Vector2(1130,220),Vector2(1200,200),Vector2(1250,170),Vector2(1360,220)])
	walk_route(game,2,4,true,[Vector2(650,400),Vector2(650,300),Vector2(700,270),Vector2(750,260),Vector2(800,270),Vector2(850,300),Vector2(950,350),Vector2(1050,400),Vector2(1100,400),Vector2(1160,400),Vector2(1185,395),Vector2(1185,370),Vector2(1185,360),Vector2(1190,345),Vector2(1200,330),Vector2(1210,300),Vector2(1200,260),Vector2(1230,220),Vector2(1220,170)])
	walk_route(game,2,4,true,[Vector2(550,500),Vector2(650,550),Vector2(750,600),Vector2(750,650),Vector2(770,700),Vector2(850,760),Vector2(950,820),Vector2(1000,830)])

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	TRAVEL.arm_launch(game) # Campaign preconditions; full repair is tested in earth_story.gd.
	game.upgraded = true
	var ids := {}
	for data in game.world_regions:
		check(data.NAMES.size() == 5,"A planet was not expanded to five original-sized districts")
		for region in 5:
			for id in [data.SURFACE_IDS[region],data.MINE_IDS[region]]:
				if id < 0: continue
				check(not ids.has(id),"Two districts share a discovery mask")
				ids[id] = true
			for link in data.LINKS[region]:
				var reverse := false
				for back in data.LINKS[link.target]:
					if back.target == region and back.side == link.arrival and back.arrival == link.side: reverse = true
				check(reverse,"A signed trail cannot return to its source district")
	check(ids.size() == 24,"Expected 15 surface districts and 9 independent mine maps")
	var rng := RandomNumberGenerator.new()
	for planet in [1,2]:
		var data = game.world_regions[planet]
		for side in data.GATES[0]:
			check(game.ORE_SPAWNS.can_walk(planet,false,data.portal(0,side)),"New home trail trigger is outside existing floor: %d %s" % [planet,side])
			check(game.ORE_SPAWNS.can_walk(planet,false,data.arrival(0,side)),"New home trail arrival is outside existing floor: %d %s" % [planet,side])
		for region in range(1,5):
			var floors := {false:reachable(data,region,false)}
			if data.has_mine(region): floors[true] = reachable(data,region,true)
			for side in data.GATES[region]:
				check(data.can_walk(region,false,data.portal(region,side)),"New district exit is outside visible trail")
				check(floors[false].has(Vector2i((data.arrival(region,side)/20).round())),"New district has disconnected trails")
			var seen := {}
			for seed_value in 50:
				rng.seed = seed_value*1009+17
				var deposits: Array[Dictionary] = data.generate(region,rng)
				check(deposits.size() == (4 if data.has_mine(region) else 2),"New district did not retain sparse supplies")
				check(deposits.filter(func(rock): return not rock.cave).size() == 2,"Off-world surface contains too many deposits")
				check(deposits.filter(func(rock): return rock.hard).size() == (1 if data.has_mine(region) else 0),"Off-world mine must retain one rare deposit")
				var signature := str(deposits.map(func(rock):return rock.pos))
				check(not seen.has(signature),"Off-world ore did not randomize between games")
				seen[signature] = true
				for i in deposits.size():
					var rock: Dictionary = deposits[i]
					check(not rock.discovered and rock.seconds == (5 if rock.hard else 3),"New world changed reveal/tool/mining rules")
					check(floors[rock.cave].has(Vector2i((rock.pos/20).round())),"New ore is unreachable in %d/%d: %s" % [planet,region,rock.pos/data.SIZE*data.ART_SIZE])
					for j in i:
						if deposits[j].cave == rock.cave: check(deposits[j].pos.distance_to(rock.pos) >= 155,"New deposits overlap")
			for cave in [false,true]:
				if cave and not data.has_mine(region): continue
				if planet == 1:
					# Frozen pools and the ruined circle were explicitly painted
					# walkable. Test unpainted islands independently of old ellipses.
					var hazard: Vector2 = ({1:Vector2(750,430),4:Vector2(785,450)} if cave else {1:Vector2(350,390),2:Vector2(750,345),3:Vector2(480,450),4:Vector2(770,570)})[region]
					check(not data.can_walk(region,cave,data.from_art(hazard)-data.FOOT_OFFSET),"Unmarked Frost rock became walkable")
				else:
					var hazard: Vector2 = ({1:Vector2(750,450),4:Vector2(780,400)} if cave else {1:Vector2(370,500),2:Vector2(625,525),3:Vector2(465,410),4:Vector2(430,560)})[region]
					check(not data.can_walk(region,cave,data.from_art(hazard)-data.FOOT_OFFSET),"Unmarked Ember rock/water/lava became walkable")
	art_routes(game)
	game.world = 0
	game.set_current_region(0)
	game.underground = false
	game.rocks = game.earth_rocks[0]
	game.earth_stream.REGIONS = game.regions()
	for planet in [1,2]:
		fly(game,planet)
		var data = game.regions()
		var home_pos: Vector2 = game.rocks[0].pos
		game.rocks[0].hp = 0
		var fog_before: int = game.fog.maps.size()
		game.earth_stream.prepare(0,false,data.portal(0,"west"))
		await process_frame
		check(game.district_rocks().size() == 1 and game.visited_regions().size() == 1 and game.fog.maps.size() == fog_before,"Prefetch generated or revealed an unvisited district")
		await trail(game,"west",1)
		var first_ore: Vector2 = game.rocks[0].pos
		game.rocks[0].hp = 0
		await mine(game)
		var hard_index := -1
		for i in game.rocks.size():
			if game.rocks[i].hard: hard_index = i; break
		game.player = game.rocks[hard_index].pos+Vector2(0,55)
		game.update_exploration()
		game.upgraded = false
		game.start_mining(hard_index)
		check(game.mining_target == -1,"New mine's rare material did not require a hand drill")
		game.upgraded = true
		game.start_mining(hard_index)
		game.advance_mining(10.1)
		check(game.rocks[hard_index].hp == 0 and (game.amethysts if planet == 1 else game.rubies) == 1,"New mine rare material did not collect with correct world inventory")
		await mine(game)
		await trail(game,"south",3)
		await trail(game,"north_east" if planet == 1 else "east",2)
		await trail(game,"east",4)
		await mine(game)
		await mine(game)
		await trail(game,"west",2)
		if planet == 1:
			await trail(game,"west",0)
		else:
			await trail(game,"north",0)
		check(game.visited_regions().size() == 5 and game.rocks[0].pos == home_pos and game.rocks[0].hp == 0,"Home return lost exploration or depleted home ore")
		await trail(game,"west",1)
		check(game.rocks[0].pos == first_ore and game.rocks[0].hp == 0 and game.rocks[hard_index].hp == 0,"Cache eviction regenerated surface/mine ore")
		await trail(game,"east",0)
		# Discard this world's scenery, force a failed load, then retry normally.
		game.earth_stream.deactivate()
		game.begin_earth_transition(1,false,data.arrival(1,"east"),data.arrival(0,"west"))
		game.earth_stream.failures[data.key(1,false)] = game.earth_stream.clock
		await finish(game)
		check(game.current_region() == 0 and game.rocks[0].hp == 0,"Failed outer-world download lost progress")
		await trail(game,"west",1)
		check(game.current_region() == 1 and game.rocks[0].hp == 0,"Failed trail could not recover on retry")
		await trail(game,"east",0)
		fly(game,0)
		fly(game,planet)
		check(game.visited_regions().size() == 5 and game.rocks[0].hp == 0,"Rocket return lost expanded world's progress")
		fly(game,0)
	check(game.amethysts == 1 and game.rubies == 1 and game.upgraded,"World changes lost minerals or fitted drill")
	check(game.earth_stream.peak_textures <= 3 and game.earth_stream.peak_jobs <= 2 and game.earth_stream.evictions > 0,"All-world streaming did not honor a single bounded cache")
	print("Shared streaming stats: textures=%d requests=%d evictions=%d install=%.2fms" % [game.earth_stream.peak_textures,game.earth_stream.peak_jobs,game.earth_stream.evictions,game.earth_stream.max_install_ms])
	if failures == 0: print("PASS: two 5x worlds, 24 discovery maps, 400 ore layouts, automatic trails/mines, real rocket travel, tools, bounded streaming, failure/retry and persistent progress")
	quit(1 if failures else 0)
