extends SceneTree

const EARTH = preload("res://earth_regions.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func connected(region: int, cave: bool) -> Dictionary:
	var start: Vector2 = EARTH.MINE_SPAWNS[region] if cave else EARTH.arrival(region,EARTH.LINKS[region][0].side)
	var first := Vector2i((start/20).round())
	var visited := {first:true}
	var queue: Array[Vector2i] = [first]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = at+direction
			if visited.has(next): continue
			if EARTH.can_walk(region,cave,Vector2(next)*20):
				visited[next] = true
				queue.append(next)
	return visited

# Art-based waypoints exercise actual input and swept collision. Disable travel
# only while following these routes; automatic doorways are tested below.
func route(game, region: int, cave: bool, points: Array) -> void:
	game.world = 0
	game.earth_region = region
	game.underground = cave
	game.mine_transition_cooldown = 100
	game.earth_trail_cooldown = 100
	game.player = EARTH.from_art(points[0])-EARTH.FOOT_OFFSET
	for point in points:
		var goal: Vector2 = EARTH.from_art(point)-EARTH.FOOT_OFFSET
		check(EARTH.can_walk(region,cave,goal),"Painted Earth floor blocked: %d %s %s" % [region,cave,point])
		var attempts := 0
		while game.player.distance_to(goal) > 0.2 and attempts < 800:
			var remaining: Vector2 = goal-game.player
			game.move_player(remaining.normalized(),minf(remaining.length(),6)/game.SPEED)
			attempts += 1
		check(game.player.distance_to(goal) < 1,"Cannot follow painted Earth path: %d %s %s; stopped %s" % [region,cave,point,game.player/EARTH.SIZE*EARTH.ART_SIZE])

func finish_transition(game) -> void:
	var deadline := Time.get_ticks_msec()+12000
	while game.earth_transition and Time.get_ticks_msec() < deadline:
		game.advance_earth_transition(0.05)
		await process_frame
	check(not game.earth_transition,"Earth loading transition did not finish")
	check(game.travel_fade.color.a == 0,"Travel fade stayed opaque")
	check(game.earth_stream.textures.size() <= 3 and game.earth_stream.jobs.size() <= 2,"Earth streaming exceeded its resource budget")
	check(game.earth_stream.get_child_count() <= 3,"Old scenery or requests remained active")

func walk_trail(game, side: String) -> void:
	game.mine_transition_cooldown = 0
	game.earth_trail_cooldown = 0
	game.player = EARTH.arrival(game.earth_region,side)
	var gate := EARTH.portal(game.earth_region,side)
	for i in 30:
		if game.earth_transition: break
		game.move_player((gate-game.player).normalized(),0.04)
	check(game.earth_transition,"Walking into trail did not automatically travel: %s" % side)
	var before: Vector2 = game.player
	game.move_player(Vector2.RIGHT,1)
	game.interact()
	check(game.player == before and game.mining_target == -1,"Input was not locked during terrain loading")
	await finish_transition(game)

func walk_mine(game) -> void:
	game.mine_transition_cooldown = 0
	game.earth_trail_cooldown = 0
	var entering: bool = not game.underground
	game.player = game.surface_exit_position() if entering else game.mine_spawn_position()
	var door: Vector2 = game.cave_position() if entering else game.exit_position()
	for i in 60:
		if game.earth_transition: break
		game.move_player((door-game.player).normalized(),0.04)
	check(game.earth_transition,"Walking into new mine doorway did not automatically travel")
	await finish_transition(game)
	check(game.underground == entering,"New mine arrived on wrong floor")
	check(EARTH.can_walk(game.earth_region,game.underground,game.player),"Mine arrival outside floor")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(EARTH.NAMES.size() == 5 and EARTH.NAMES.size()*EARTH.SIZE.x*EARTH.SIZE.y == 14000000,"Earth is not five original-sized districts")
	check(game.earth_stream.texture_loads == 0 and game.earth_rocks.size() == 1 and game.fog.maps.size() == 1,"Unvisited districts loaded/generated/revealed at startup")
	for link in EARTH.LINKS[0]:
		for cover in game.tree_cover():
			check(not cover.has_point(EARTH.portal(0,link.side)) and not cover.has_point(EARTH.arrival(0,link.side)),"Home trail or arrival hidden beneath a tree canopy")
	# The three-way trail loop and quarry spur, including the full bridge deck.
	route(game,1,false,[Vector2(200,495),Vector2(500,530),Vector2(750,510),Vector2(1090,530),Vector2(1310,510)])
	route(game,1,false,[Vector2(750,880),Vector2(750,650),Vector2(750,510),Vector2(950,380),Vector2(1085,285)])
	route(game,2,false,[Vector2(640,205),Vector2(650,310),Vector2(720,425),Vector2(920,480),Vector2(970,490),Vector2(1040,490),Vector2(1100,490),Vector2(1310,500)])
	route(game,2,false,[Vector2(650,310),Vector2(400,295),Vector2(275,350),Vector2(275,425),Vector2(570,440),Vector2(720,425)])
	route(game,2,false,[Vector2(1200,520),Vector2(1230,640),Vector2(1150,755),Vector2(950,830),Vector2(700,880),Vector2(470,855),Vector2(270,785),Vector2(215,715)])
	route(game,3,false,[Vector2(710,205),Vector2(830,290),Vector2(800,400),Vector2(700,460),Vector2(500,520),Vector2(400,555),Vector2(200,480)])
	route(game,3,false,[Vector2(400,555),Vector2(350,690),Vector2(350,770),Vector2(600,820),Vector2(800,865),Vector2(1050,860),Vector2(1190,780),Vector2(1220,660),Vector2(1100,540),Vector2(900,470),Vector2(700,460)])
	route(game,4,false,[Vector2(200,440),Vector2(430,485),Vector2(800,520),Vector2(980,375),Vector2(1100,270)])
	route(game,4,false,[Vector2(800,520),Vector2(1050,610),Vector2(1310,645),Vector2(1260,800),Vector2(1030,900),Vector2(760,920),Vector2(750,740),Vector2(800,520)])
	# Galleries circle the copper mine's three rock islands.
	route(game,1,true,[Vector2(750,770),Vector2(750,660),Vector2(775,550),Vector2(790,470),Vector2(690,440),Vector2(585,360),Vector2(545,280),Vector2(430,280),Vector2(250,260)])
	route(game,1,true,[Vector2(545,280),Vector2(610,185),Vector2(750,130),Vector2(890,180),Vector2(980,270),Vector2(1000,340),Vector2(930,395),Vector2(790,470)])
	route(game,1,true,[Vector2(250,260),Vector2(325,355),Vector2(350,470),Vector2(310,560),Vector2(230,605),Vector2(370,625),Vector2(470,650),Vector2(590,625),Vector2(650,660),Vector2(750,720)])
	route(game,1,true,[Vector2(1000,340),Vector2(1180,280),Vector2(1290,265),Vector2(1240,350),Vector2(1200,440),Vector2(1250,540),Vector2(1330,590),Vector2(1200,635),Vector2(1120,660)])
	# Crystal galleries and the dry western rim of the underground lake.
	route(game,4,true,[Vector2(290,790),Vector2(350,690),Vector2(400,590),Vector2(430,540),Vector2(560,505),Vector2(650,480),Vector2(690,410),Vector2(810,340),Vector2(805,230),Vector2(770,170)])
	route(game,4,true,[Vector2(560,505),Vector2(570,425),Vector2(500,370),Vector2(450,290),Vector2(350,205)])
	route(game,4,true,[Vector2(810,340),Vector2(910,390),Vector2(1000,425),Vector2(1130,355),Vector2(1200,270),Vector2(1310,240)])
	route(game,4,true,[Vector2(1000,425),Vector2(990,530),Vector2(970,590),Vector2(850,640),Vector2(800,710),Vector2(870,760)])
	for hazard in [[2,false,Vector2(490,645)],[2,false,Vector2(1060,245)],[2,false,Vector2(1000,560)],[3,false,Vector2(690,590)],[4,false,Vector2(440,750)],[4,false,Vector2(600,180)],[1,true,Vector2(750,310)],[1,true,Vector2(500,480)],[1,true,Vector2(1000,550)],[4,true,Vector2(800,470)],[4,true,Vector2(1130,510)],[4,true,Vector2(1160,780)]]:
		check(not EARTH.can_walk(hazard[0],hazard[1],EARTH.from_art(hazard[2])-EARTH.FOOT_OFFSET),"Earth water/rock wall became walkable: %s" % [hazard])
	var rng := RandomNumberGenerator.new()
	for region in range(1,5):
		var floors := {false:connected(region,false)}
		if EARTH.has_mine(region): floors[true] = connected(region,true)
		for link in EARTH.LINKS[region]:
			check(EARTH.can_walk(region,false,EARTH.portal(region,link.side)),"Trail trigger is outside painted floor")
			check(floors[false].has(Vector2i((EARTH.arrival(region,link.side)/20).round())),"District trails are disconnected")
		var seen := {}
		for seed_value in 50:
			rng.seed = seed_value*1009+17
			var deposits := EARTH.generate(region,rng)
			check(deposits.size() == (4 if EARTH.has_mine(region) else 2),"Earth district did not retain sparse supplies")
			check(deposits.filter(func(rock): return not rock.cave).size() == 2,"Earth surface contains too many deposits")
			check(deposits.filter(func(rock): return rock.hard).size() == (1 if EARTH.has_mine(region) else 0),"Earth mine must retain one rare deposit")
			var signature := str(deposits.map(func(rock): return rock.pos))
			check(not seen.has(signature),"District did not randomize ore")
			seen[signature] = true
			for rock in deposits:
				check(not rock.discovered and rock.seconds == (9 if rock.hard else 2),"New district changed mining/reveal rules")
				check(floors[rock.cave].has(Vector2i((rock.pos/20).round())),"New Earth ore is unreachable in %d: %s" % [region,rock.pos/EARTH.SIZE*EARTH.ART_SIZE])
	# Restore a real home state after the geometry checks above.
	game.earth_region = 0
	game.underground = false
	game.rocks = game.earth_rocks[0]
	game.ore = 9
	game.upgraded = true
	var home_ore: Vector2 = game.rocks[0].pos
	game.rocks[0].hp = 0
	game.rocks[0].discovered = true
	game.fog.observe(0,Vector2(800,600))
	var home_pixels: PackedByteArray = game.fog.maps[0].pixels.duplicate()
	# Prefetching must not create ore, discovery masks or visited progress.
	game.earth_stream.prepare(0,false,EARTH.portal(0,"east")+Vector2(-350,0))
	await process_frame
	check(game.earth_rocks.size() == 1 and game.earth_visited.size() == 1,"Prefetch discovered an unvisited district")
	await walk_trail(game,"east")
	check(game.earth_region == 1 and not game.underground,"East meadow trail did not reach Pinewood")
	check(not game.green_surface.visible and not game.rocket.visible,"Home actors remained active in another district")
	check(game.scout.sprite_frames == game.DRILL_VISUAL.WALK[0],"New district lost the miner's drill")
	var pine_ore: Vector2 = game.rocks[0].pos
	game.rocks[0].hp = 0
	game.rocks[0].discovered = true
	await walk_mine(game)
	check(game.area_id() == 7,"Copper Hollow reused another mine's discovery map")
	var hard_index := -1
	for i in game.rocks.size():
		if game.rocks[i].hard: hard_index = i; break
	game.player = game.rocks[hard_index].pos+Vector2(0,55)
	game.update_exploration()
	game.start_mining(hard_index)
	game.advance_mining(9.1)
	check(game.blue_crystals == 1 and game.rocks[hard_index].hp == 0,"New cave crystal could not be mined with the hand drill")
	await walk_mine(game)
	await walk_trail(game,"east")
	check(game.earth_region == 4,"Quarry spur did not reach Old Quarry")
	await walk_mine(game)
	check(game.area_id() == 11,"Crystal Depths did not have independent fog")
	await walk_mine(game)
	await walk_trail(game,"west")
	check(game.rocks[0].pos == pine_ore and game.rocks[0].hp == 0 and game.rocks[hard_index].hp == 0,"Returning regenerated depleted district ore")
	await walk_trail(game,"south")
	check(game.earth_region == 3,"Pinewood south trail did not reach the ridge")
	await walk_trail(game,"west")
	check(game.earth_region == 2,"Ridge west trail did not cross to the marsh")
	await walk_trail(game,"north")
	check(game.earth_region == 0 and game.earth_visited.size() == 5,"Earth loop did not return to landing meadow")
	check(game.ore == 9 and game.upgraded and game.rocks[0].pos == home_ore and game.rocks[0].hp == 0,"Stream eviction lost inventory, tools or home ore")
	for i in home_pixels.size():
		if home_pixels[i] == 255:
			check(game.fog.maps[0].pixels[i] == 255,"Reloading a district forgot explored ground")
	check(game.earth_stream.evictions > 0 and game.earth_stream.peak_textures <= 3 and game.earth_stream.peak_jobs <= 2,"Cache did not evict scenery within its fixed budget")
	# Failed loads leave the old world and progress intact, with a safe retry.
	game.earth_stream.deactivate()
	game.begin_earth_transition(1,false,EARTH.arrival(1,"west"),EARTH.arrival(0,"east"))
	game.earth_stream.failures["pinewood"] = game.earth_stream.clock
	await finish_transition(game)
	check(game.earth_region == 0 and game.ore == 9 and game.rocks[0].hp == 0,"Failed terrain load changed game progress")
	check(game.player == EARTH.arrival(0,"east"),"Failed terrain load did not return to a safe arrival")
	await walk_trail(game,"east")
	check(game.earth_region == 1 and game.rocks[0].hp == 0,"Failed trail could not retry or lost district progress")
	game.flight_destination = 1
	game.switch_planet()
	check(game.earth_stream.textures.is_empty() and game.earth_stream.scenery == null,"Leaving Earth retained new terrain textures/actors")
	game.flight_destination = 0
	game.switch_planet()
	check(game.earth_region == 0 and game.earth_visited.size() == 5 and game.rocks[0].hp == 0,"Rocket return lost larger Earth's progress")
	print("Earth streaming stats: peak textures=%d jobs=%d evictions=%d max install=%.2fms" % [game.earth_stream.peak_textures,game.earth_stream.peak_jobs,game.earth_stream.evictions,game.earth_stream.max_install_ms])
	if failures == 0:
		print("PASS: 5x Earth, painted paths/bridge/galleries, 200 ore layouts, automatic trails/mines, independent exploration, bounded streaming, failure/retry and session persistence")
	quit(1 if failures else 0)
