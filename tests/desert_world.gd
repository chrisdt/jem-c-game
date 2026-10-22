extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")

const LAYOUT = preload("res://desert_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func connected(entry: Vector2, cave: bool) -> Dictionary:
	var first := Vector2i((entry / 16).round())
	var cells := {first:true}
	var queue: Array[Vector2i] = [first]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = at + direction
			if cells.has(next): continue
			if LAYOUT.can_walk(Vector2(next) * 16, cave):
				cells[next] = true
				queue.append(next)
	return cells

func walk_route(game, points: Array, cave: bool) -> void:
	game.underground = cave
	game.earth_trail_cooldown = 999
	game.mine_transition_cooldown = 999
	game.player = LAYOUT.from_art(points[0]) - LAYOUT.FOOT_OFFSET
	game.update_exploration()
	for point in points:
		var goal: Vector2 = LAYOUT.from_art(point) - LAYOUT.FOOT_OFFSET
		check(LAYOUT.can_walk(goal,cave),"Painted desert floor is blocked at %s (mine: %s)" % [point,cave])
		var attempts := 0
		while game.player.distance_to(goal) > 0.1 and attempts < 600:
			var remaining: Vector2 = goal - game.player
			game.move_player(remaining, minf(remaining.length(),4.0) / game.SPEED)
			attempts += 1
		if game.player.distance_to(goal) > 1:
			check(false,"Desert route to %s stopped at art %s (mine: %s)" % [point,game.player / LAYOUT.WORLD_SIZE * LAYOUT.ART_SIZE,cave])
			return

func fly(game, destination: int) -> void:
	game.player = game.ship_position()
	game.update_exploration()
	game.cooldown = 0
	game.interact()
	check(game.planet_menu.visible,"Rocket did not offer destinations")
	game.planet_menu.choose(destination)
	game.advance_flight(10)
	check(game.world == destination and game.flight == game.Flight.IDLE,"Rocket did not land on the chosen planet")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	TRAVEL.arm_launch(game) # Campaign preconditions; full repair is tested in earth_story.gd.
	game.player = game.SHIP
	game.update_exploration()
	game.cooldown = 0
	game.interact()
	check(game.planet_menu.visible and game.planet_menu.buttons[0].disabled,"Planet picker does not identify the current world")
	var before: Vector2 = game.player
	game.move_player(Vector2.RIGHT,1)
	game.planet_menu.choose(0)
	check(game.player == before and game.planet_menu.visible and game.flight == game.Flight.IDLE,"Picker allowed walking or travel to the current planet")
	game.planet_menu.dismiss()
	check(not game.planet_menu.visible and game.world == 0,"Cancelling the picker changed planets")
	fly(game,2)
	check(LAYOUT.can_walk(game.player) and not game.green_surface.visible,"Desert landing is blocked or shows the wrong environment")
	check(game.fog.active_map == 4 and game.fog.is_revealed(4,game.player),"Desert exploration did not start at its landing site")
	check(not game.fog.is_revealed(4,LAYOUT.CAVE),"Landing revealed the distant desert mine")
	var surface := connected(LAYOUT.ARRIVAL,false)
	var mine := connected(LAYOUT.MINE_SPAWN,true)
	check(surface.has(Vector2i((LAYOUT.CAVE / 16).round())),"Desert entrance is disconnected from the rocket")
	check(mine.has(Vector2i((LAYOUT.MINE_EXIT / 16).round())),"Lava mine exit is disconnected from its arrival")
	for trial in 50:
		game.ore_rng.seed = trial * 1013 + 29
		game.reset_rocks()
		check(game.rocks.size() == 4,"Desert should have two surface and two mine deposits")
		if game.rocks.size() != 4:
			quit(1)
			return
		for rock in game.rocks:
			var cells: Dictionary = mine if rock.cave else surface
			check(cells.has(Vector2i((rock.pos / 16).round())),"Desert ore is unreachable: %s" % rock.pos)
			check(rock.seconds == (10 if rock.hard else 3) and not rock.discovered,"Desert ore starts discovered or uses the wrong mining duration")
			check(not rock.cave or not LAYOUT.lava_contains(rock.pos + LAYOUT.FOOT_OFFSET),"Ore spawned in lava")
	var locations: Array = game.rocks.map(func(rock): return rock.pos)
	# These waypoints follow the visible lower and upper sandy routes.
	walk_route(game,[Vector2(1200,850),Vector2(1000,830),Vector2(850,800),Vector2(650,790),Vector2(520,800),Vector2(340,790),Vector2(270,690),Vector2(220,590),Vector2(230,480),Vector2(280,380),Vector2(300,300)],false)
	walk_route(game,[Vector2(1220,840),Vector2(1340,820),Vector2(1340,720),Vector2(1270,670),Vector2(1240,570),Vector2(1220,440),Vector2(1220,330),Vector2(1100,270),Vector2(970,240),Vector2(850,235),Vector2(720,215),Vector2(650,210),Vector2(590,215),Vector2(470,270),Vector2(350,290),Vector2(300,300)],false)
	walk_route(game,[Vector2(300,300),Vector2(270,330),Vector2(240,380),Vector2(160,390),Vector2(80,390)],false)
	walk_route(game,[Vector2(850,800),Vector2(850,900),Vector2(850,980)],false)
	walk_route(game,[Vector2(1100,270),Vector2(1100,200),Vector2(1070,150),Vector2(1070,100),Vector2(1030,50),Vector2(990,25)],false)
	check(not LAYOUT.can_walk(LAYOUT.from_art(Vector2(780,500))),"Player can walk onto the central sandstone mesa")
	for i in 3:
		game.underground = game.rocks[i].cave
		game.player = game.rocks[i].pos
		game.update_exploration()
		game.start_mining(i)
		game.advance_mining(2.99)
		check(game.gold_ore == i,"Gold mining completed early")
		game.advance_mining(0.02)
	check(game.gold_ore == 3,"Gold mining did not award the third-world material")
	game.underground = false
	game.player = LAYOUT.CAVE + Vector2(0,110)
	game.mine_transition_cooldown = 0
	game.move_player(Vector2.UP,0.3)
	check(game.underground and game.player == LAYOUT.MINE_SPAWN and game.lava_environment.visible,"Walking into the desert entrance did not open the Lava Mine")
	check(game.fog.active_map == 5,"Lava Mine shares the surface exploration mask")
	walk_route(game,[Vector2(550,450),Vector2(650,450),Vector2(800,450),Vector2(950,450),Vector2(1100,450),Vector2(1220,430)],true)
	walk_route(game,[Vector2(260,850),Vector2(300,780),Vector2(300,650),Vector2(280,580),Vector2(280,480),Vector2(400,440),Vector2(550,450)],true)
	walk_route(game,[Vector2(400,440),Vector2(350,350),Vector2(325,270),Vector2(330,200),Vector2(330,170),Vector2(450,180),Vector2(550,150),Vector2(680,120),Vector2(720,115)],true)
	walk_route(game,[Vector2(1220,430),Vector2(1260,350),Vector2(1320,300),Vector2(1340,240),Vector2(1330,190),Vector2(1240,170),Vector2(1170,210),Vector2(1100,210),Vector2(1000,170),Vector2(920,140)],true)
	walk_route(game,[Vector2(1220,430),Vector2(1300,470),Vector2(1300,550),Vector2(1330,620),Vector2(1350,710),Vector2(1250,710),Vector2(1200,700),Vector2(1280,670)],true)
	for point in [Vector2(880,300),Vector2(920,560),Vector2(1050,780)]:
		check(not LAYOUT.can_walk(LAYOUT.from_art(point) - LAYOUT.FOOT_OFFSET,true),"Lava is walkable at %s" % point)
	check(not LAYOUT.can_walk(LAYOUT.from_art(Vector2(130,480)) - LAYOUT.FOOT_OFFSET,true),"Player can stand on the painted western rock wall")
	check(not LAYOUT.can_walk(LAYOUT.from_art(Vector2(600,350))-LAYOUT.FOOT_OFFSET,true),"Raised rock above the bridge became walkable")
	for x in [665,880,1120]:
		check(LAYOUT.can_walk(LAYOUT.from_art(Vector2(x,451)) - LAYOUT.FOOT_OFFSET,true),"Stone bridge deck is blocked")
	var rare: int = game.rocks.find_custom(func(rock): return rock.hard)
	game.player = game.rocks[rare].pos
	game.update_exploration()
	game.start_mining(rare)
	check(game.mining_target == -1,"Fire ruby bypassed the stronger-pick upgrade")
	game.upgraded = true
	game.start_mining(rare)
	game.advance_mining(9.9)
	check(game.rubies == 0 and not game.desert_won,"Ruby mining completed early")
	game.advance_mining(0.11)
	check(game.rubies == 1 and game.desert_won,"Third-world mission did not complete")
	game.lava_environment.set_process(false)
	for frame in 240:
		game.lava_environment.advance(0.05)
	check(not game.lava_environment.embers.is_empty() and game.lava_environment.embers.size() <= 32,"Lava embers are missing or accumulating without bounds")
	game.player = LAYOUT.MINE_EXIT + Vector2(0,-110)
	game.mine_transition_cooldown = 0
	game.move_player(Vector2.DOWN,0.3)
	check(not game.underground and game.player == LAYOUT.OUTSIDE and not game.lava_environment.visible,"Walking out of the Lava Mine did not restore its safe surface arrival")
	var clock: float = game.lava_environment.emission_clock
	game.lava_environment._process(5)
	check(game.lava_environment.emission_clock == clock,"Hidden Lava Mine kept emitting particles")
	fly(game,1)
	fly(game,0)
	fly(game,2)
	check(game.gold_ore == 3 and game.rubies == 1 and game.desert_won and game.rocks[rare].hp == 0,"Three-planet trips lost desert mission progress")
	check(game.rocks.map(func(rock): return rock.pos) == locations and game.fog.is_revealed(5,LAYOUT.MINE_SPAWN),"Three-planet travel reset ore locations or discoveries")
	if failures == 0:
		print("PASS: destination picker, all three planets, desert loop routes, lava/mesa collision, bridge and galleries, 50 reachable layouts, 3s/10s mining, mission and session progress")
	quit(1 if failures else 0)
