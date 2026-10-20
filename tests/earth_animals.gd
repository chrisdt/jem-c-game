extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")

const EARTH = preload("res://earth_regions.gd")
const PASTURES = preload("res://environment/earth_pastures.gd")
const ART = preload("res://environment/earth_animal_art.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		if failures < 20: push_error(message)

func follow_route(game, region: int, cave: bool, points: Array) -> void:
	game.world = 0
	game.earth_region = region
	game.underground = cave
	game.reset_rocks()
	game.mine_transition_cooldown = 1000
	game.earth_trail_cooldown = 1000
	game.player = (game.MINE_LAYOUT.from_art(points[0]) if region == 0 and cave else EARTH.from_art(points[0]))-EARTH.FOOT_OFFSET
	game.refresh_ui()
	var dog = game.companion
	for point in points:
		var goal: Vector2 = (game.MINE_LAYOUT.from_art(point) if region == 0 and cave else EARTH.from_art(point))-EARTH.FOOT_OFFSET
		for attempt in 1000:
			var remaining: Vector2 = goal-game.player
			if remaining.length() < 0.2: break
			var dt: float = minf(remaining.length(),6.0)/game.SPEED
			game.move_player(remaining.normalized(),dt)
			dog.advance(dt)
			check(dog.can_stand(dog.position),"Buddy crossed a wall, water or deposit: %d/%s %s" % [region,cave,dog.position])
		check(game.player.distance_to(goal) < 1,"Invalid player route in companion test")
		for frame in 200:
			dog.advance(0.05)
			check(dog.can_stand(dog.position),"Buddy's catch-up route crossed a hazard")
		check(dog.position.distance_to(game.player) < 100,"Buddy could not catch up: %d/%s, player %s dog %s" % [region,cave,game.player,dog.position])
		check(dog.state == "sit","Buddy did not sit after catching up")
	print("Companion route: %d/%s" % [region,cave])

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.companion.set_process(false)
	check(not game.companion.recruited and not game.companion.visible,"Dog was already found at game start")
	var total := 0
	for region in [1,2,3]:
		game.earth_region = region
		var painting: Texture2D = load(EARTH.ASSETS[EARTH.key(region,false)])
		for seed_value in 4:
			game.ore_rng.seed = 2039+region*101+seed_value*37
			game.reset_rocks()
			var parent := Node2D.new()
			root.add_child(parent)
			var herd = PASTURES.add_to(parent,region,painting,game)
			check(herd.creatures.size() == (4 if region == 3 else 2),"Wrong pasture population")
			for actor in herd.creatures:
				actor.set_process(false)
				check(actor.can_stand(actor.position),"No safe grass for a herd animal: %d %s" % [region,actor.position])
			if seed_value == 0:
				total += herd.creatures.size()
				for frame in 900:
					for actor in herd.creatures:
						actor.advance(0.1)
						check(actor.can_stand(actor.position),"Herd left grass or crossed ore/water/rocks")
				for actor in herd.creatures:
					check(actor.walk_distance > 90 and actor.stops >= 3,"Herd animal did not walk and graze: region %d %s, distance %.1f stops %d at %s" % [region,actor.name,actor.walk_distance,actor.stops,actor.position/EARTH.SIZE*EARTH.ART_SIZE])
					for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
						actor.facing = direction
						actor.state = "graze"
						actor.update_pose()
						check(actor.sprite.texture == ART.pose(actor.species,direction,3).texture,"Grazing lost directional artwork")
				var before: Vector2 = herd.creatures[0].position
				herd.hide()
				herd.creatures[0]._process(5)
				check(herd.creatures[0].position == before,"Hidden herd kept roaming")
			var previous: WeakRef = weakref(herd.creatures[0])
			parent.free()
			check(previous.get_ref() == null,"Herd remained after unloading")
		print("Pastures: region %d, four ore layouts" % region)
	# Keep this movement fixture in Pinewood; randomized starts have their own
	# checks. Finding the dog still requires only approach, never a key press.
	for seed_value in 30:
		game.companion.choose_discovery(seed_value)
		if game.companion.discovery_region == 1: break
	game.earth_region = 1
	game.underground = false
	game.reset_rocks()
	game.refresh_ui()
	var dog = game.companion
	check(dog.visible and dog.can_stand(dog.position),"Pinewood dog missing or standing in scenery")
	game.player = dog.position+Vector2(280,0)
	dog.advance(1)
	check(not dog.recruited,"Dog recruited before being found")
	game.player = dog.position+Vector2(25,0)
	game.update_exploration()
	dog.advance(0.05)
	check(dog.recruited and game.message.contains("Buddy"),"Approaching the dog did not recruit him")
	var dog_identity: Node = dog
	for frame in 30: dog.advance(0.05)
	check(dog.state == "sit","Dog did not sit when Scout stopped")
	var wag_frames: Dictionary = {}
	for frame in 20:
		dog.advance(0.12)
		wag_frames[dog.current_frame] = true
	check(wag_frames.size() == 4,"Seated tail does not wag through its poses")
	game.player += Vector2(150,0)
	dog.advance(1.0/60)
	check(dog.state == "walk","Dog did not get up when Scout moved")
	check(float(dog.tail.get_shader_parameter("wag_amount")) > 0,"Walking dog has no tail wag")
	var player_before: Vector2 = game.player
	var ore_before: int = game.ore
	for frame in 100: dog.advance(0.05)
	check(game.player == player_before and game.ore == ore_before,"Companion changed player movement or materials")
	check(dog.state == "sit" and dog.position.distance_to(game.player) >= 45,"Companion overlapped Scout or failed to sit")
	game.planet_menu.visible = true
	var before: Vector2 = dog.position
	var time_before: float = dog.elapsed
	dog.advance(5)
	check(dog.position == before and dog.elapsed == time_before,"Dog kept moving behind the planet menu")
	game.planet_menu.visible = false
	follow_route(game,2,false,[Vector2(215,715),Vector2(270,785),Vector2(470,855),Vector2(700,880),Vector2(950,830),Vector2(1150,755),Vector2(1230,640),Vector2(1200,520),Vector2(1100,490),Vector2(1040,490),Vector2(970,490),Vector2(920,480),Vector2(720,425),Vector2(650,310)])
	follow_route(game,1,true,[Vector2(750,770),Vector2(750,660),Vector2(775,550),Vector2(790,470),Vector2(690,440),Vector2(585,360),Vector2(545,280),Vector2(430,280),Vector2(250,260)])
	check(dog.navigation != null,"Companion never exercised a route around a wall")
	follow_route(game,4,true,[Vector2(290,790),Vector2(350,690),Vector2(400,590),Vector2(430,540),Vector2(560,505),Vector2(650,480),Vector2(690,410),Vector2(810,340),Vector2(805,230),Vector2(770,170)])
	follow_route(game,0,true,[Vector2(210,455),Vector2(320,460),Vector2(430,440),Vector2(490,390),Vector2(500,350),Vector2(470,320),Vector2(425,280),Vector2(410,240),Vector2(360,230)])
	# Real streamed transition preserves the same companion and resets its route.
	game.earth_stream.store_texture("willow",load(EARTH.ASSETS.willow))
	game.begin_earth_transition(2,false,EARTH.arrival(2,"north"),game.player)
	dog.advance(0)
	check(not dog.visible,"Dog appeared over the loading fade")
	for frame in 20: game.advance_earth_transition(0.05)
	check(not game.earth_transition and game.earth_region == 2 and dog.visible,"Dog did not arrive in the streamed district")
	check(game.companion == dog_identity and dog.recruited and dog.can_stand(dog.position),"Streamed transition lost or duplicated the dog")
	check(dog.path.is_empty() and dog.navigation == null,"Dog kept a route from the previous map")
	# The pet stays on Earth during real rocket travel and resumes on return.
	game.earth_stream.deactivate()
	game.earth_region = 0
	game.underground = false
	game.reset_rocks()
	game.player = game.surface_arrival_position()
	game.refresh_ui()
	TRAVEL.depart(game,1)
	for frame in 40: game.advance_flight(0.2)
	check(game.world == 1 and not dog.visible and dog.recruited,"Dog followed the rocket without a space suit or lost recruitment")
	TRAVEL.depart(game,0)
	for frame in 40: game.advance_flight(0.2)
	check(game.world == 0 and dog.visible and dog.recruited and dog.can_stand(dog.position),"Dog did not greet Scout on return to Earth")
	game.free()
	if failures == 0:
		print("PASS: %d grazing sheep/cows in three districts, four ore layouts, directional poses and cleanup; discoverable Buddy, walking/seated tail wag, safe following around ponds/bridge/mine walls, menu pause, streamed travel and Earth return" % total)
	quit(1 if failures else 0)
