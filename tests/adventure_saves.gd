extends SceneTree

const SNAPSHOT = preload("res://ui/adventure_snapshot.gd")
const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0
var pulses := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)
func settle_save(session: Node) -> void:
	var deadline := Time.get_ticks_msec()+18000
	while session.busy and Time.get_ticks_msec()<deadline: await process_frame
	check(not session.busy,"Save did not settle")
func freeze(game: Node) -> void:
	game.set_process(false)
	for object in [game.story,game.frost_story,game.ember_story,game.gardens,game.wood_supplies,game.companion,game.save_totem]: object.set_process(false)
func floor_points(game: Node) -> Array[Vector2]:
	var start := Vector2i((game.player/20).round())
	var queue: Array[Vector2i] = [start]
	var visited := {start:true}
	var points: Array[Vector2] = []
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		points.append(Vector2(cell)*20)
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+offset
			if visited.has(next): continue
			var point := Vector2(next)*20
			if Rect2(90,180,1810,1110).has_point(point) and game.trial.floor_at(point):
				visited[next] = true
				queue.append(next)
	return points
func fresh() -> Node:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	freeze(current_scene)
	return current_scene
func run() -> void:
	var session := root.get_node("AdventureSave")
	session.storage_path = "user://test-explore-checkpoint.json"
	session.endpoint_override = "http://127.0.0.1:9/disabled"
	session.saved = {}
	session.new_adventure()
	session.checkpoint_saved.connect(func(): pulses += 1)
	root.get_node("RunSession").choose(false)
	var game: Node = await fresh()
	var locations := []
	# The real streamed maps must provide an accessible approach to all three
	# camps. No totem can accidentally appear on the other twelve maps.
	for world in [0,1,2]:
		if game.world != world:
			game.flight_destination = world
			game.switch_planet()
			game.finish_flight()
		for region in 5:
			await TRAVEL.enter(game,region,false)
			game.save_totem.refresh_area()
			var expected: bool = game.save_totem.HOMES[world].has(region)
			if not expected:
				check(not game.save_totem.visible,"Unexpected save totem on district %d/%d" % [world,region])
				continue
			var point: Vector2 = game.save_totem.position
			check(point.is_finite() and game.trial.floor_at(point),"Totem not on floor %d/%d: %s" % [world,region,point])
			if world == 1: check(point.distance_to(Vector2(580,1165)) < 25,"Frost totem moved away from the front clearing: %s" % point)
			if world == 2: check(point.distance_to(Vector2(1555,970)) < 25,"Ember totem moved away from the sand above the camp sign: %s" % point)
			var reached := false
			for candidate in floor_points(game):
				if candidate.distance_to(point) < 60 and game.trial.clear_line(candidate,point): reached = true
			check(reached,"Unreachable totem %d/%d: %s" % [world,region,point])
			locations.append({"world":world,"region":region,"point":point})
	check(locations.size()==3,"Expected exactly one camp totem on each world")
	for world in [0,1,2]: check(game.save_totem.HOMES[world].keys()==[0],"A totem remained outside camp")
	# Complete data from all three planets, including previously visited maps,
	# spent fruit/wood, boss health, fog and partially mined rare deposits.
	for enemy in game.ember_story.scorpions: enemy.health = 0
	game.rocks[0].hp = 0
	game.rocks[1]["work"] = 1.25
	var mined_at: Vector2 = game.rocks[1].pos
	await TRAVEL.enter(game,0,false)
	game.save_totem.refresh_area()
	# Approach on the authored floor, including the narrow camp clearing.
	var approach := Vector2.INF
	for candidate in floor_points(game):
		var distance := candidate.distance_to(game.save_totem.position)
		if distance >= 30 and distance < 60 and game.trial.clear_line(candidate,game.save_totem.position):
			approach = candidate
			break
	check(approach.is_finite(),"No clear camp approach for saving")
	game.player = approach
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.ore = 17
	game.blue_crystals = 4
	game.frost_ore = 9
	game.amethysts = 3
	game.gold_ore = 6
	game.rubies = 2
	game.upgraded = true
	game.story.complete["mara"] = true
	game.story.drill_improved = true
	game.story.sword_improved = true
	game.story.quarry_open = true
	game.frost_story.frostfang = true
	game.frost_story.crystal_drill = true
	game.frost_story.collected["coupling"] = true
	game.ember_story.magma_drill = true
	game.ember_story.sunfang = true
	game.ember_story.antidote_owned = true
	game.ember_story.antidote_doses = 2
	game.ember_story.records["4/0"] = {"health":0,"position":Vector2(1100,700),"seen":true,"fade":0.75,"slow":0.0}
	game.trial.health = 7
	game.trial.wood = 5
	game.trial.sword_owned = true
	game.trial.mine_health[23] = {"2/4/1":0}
	game.companion.recruited = true
	game.update_exploration()
	var codec := SNAPSHOT.new()
	var snapshot := SNAPSHOT.capture(game)
	var json: String = JSON.stringify(snapshot)
	var data := codec.unpack(JSON.parse_string(json),game)
	check(not data.is_empty(),"Snapshot failed a real JSON round trip")
	check(json.length() < 524288,"Snapshot too large")
	print("Checkpoint JSON bytes: ",json.length())
	var original: Dictionary = SNAPSHOT.new().decode(snapshot.state)
	for broken in ["rock","enemy","floor","resource"]:
		var corrupt: Dictionary = original.duplicate(true)
		match broken:
			"rock": corrupt.game.outer_rocks[2][4][0].hp = "broken"
			"enemy": corrupt.ember_story.records["4/0"].position = "broken"
			"floor": corrupt.game.player = Vector2(10,10)
			"resource": corrupt.game.ore = -4
		check(codec.unpack({"version":1,"mode":"explore","state":SNAPSHOT.encode(corrupt)},game).is_empty(),"Malformed "+broken+" data accepted")
	var bad := snapshot.duplicate(true)
	bad.mode = "speedrun"
	check(codec.unpack(bad,game).is_empty(),"Timed state accepted as Explore")
	game.save_totem.refresh_area()
	game.fog.observe(game.area_id(),game.save_totem.position)
	game.save_totem.refresh_area()
	var count_before := pulses
	session.checkpoint(game)
	check(game.save_totem.feedback=="Saving..." and game.save_totem.bubble.visible,"Saving speech bubble not shown")
	await settle_save(session)
	var feedback_deadline := Time.get_ticks_msec()+2000
	while game.save_totem.feedback=="Saving..." and Time.get_ticks_msec()<feedback_deadline: await process_frame
	check(session.has_save(),"Offline device checkpoint failed")
	check(session.has_save() and session.saved.pending and session.device_saved,"Offline copy not retained")
	check(pulses==count_before+1 and game.save_totem.flare>0,"Successful local checkpoint didn't pulse crystal")
	check(game.save_totem.feedback=="Saved on this device" and game.save_totem.bubble.visible,"Offline save was incorrectly announced as online")
	game.save_totem.entered = true
	game.save_totem.retry_after = 20
	game.save_totem._process(0.81)
	check(game.save_totem.flare==0 and pulses==count_before+1,"Crystal pulse repeated without a new save")
	check(session.saved.code.length()==32 and session.recovery_code().split("-").size()==8,"Recovery code format invalid")
	var code: String = session.saved.code
	var place: Vector2 = game.player
	session.saved = {}
	session.load_device()
	check(session.saved.code==code,"Checkpoint did not survive device reload")
	check(await session.continue_adventure(),"Couldn't stage offline Continue")
	game = await fresh()
	while game.earth_transition:
		game.advance_earth_transition(0.02)
		await process_frame
	check(game.world==2 and game.current_region()==0 and game.player.is_equal_approx(place),"Continue restored wrong world/position")
	check(game.ore==17 and game.frost_ore==9 and game.gold_ore==6 and game.rubies==2,"Inventory was lost")
	check(game.upgraded and game.story.drill_improved and game.frost_story.crystal_drill and game.ember_story.sunfang,"Upgrades were lost")
	check(game.trial.health==7 and game.trial.wood==5 and game.companion.recruited,"Health/wood/Buddy were lost")
	check(game.ember_story.antidote_doses==2 and game.ember_story.records["4/0"].health==0,"Canteen/guardian were lost")
	var found := false
	for rock in game.outer_rocks[2][4]:
		if rock.pos.is_equal_approx(mined_at): found = is_equal_approx(rock.get("work",0),1.25)
	check(found and game.outer_rocks[2][4][0].hp==0,"Depleted/partially mined deposits reset")
	check(game.fog.is_revealed(game.area_id(),place),"Exploration mask was lost")
	# A new Explore does not erase the existing saved checkpoint. Timed mode
	# does not render totems, create checkpoints or modify saved Explore data.
	session.new_adventure()
	check(session.saved.code==code,"Starting new Explore erased the previous checkpoint")
	root.get_node("RunSession").timed = true
	game.save_totem.refresh_area()
	check(not game.save_totem.visible and not game.save_totem.can_save(),"Totem present in speedrun")
	check(not await session.checkpoint(game) and session.saved.code==code,"Speedrun overwrote Explore save")
	root.get_node("RunSession").timed = false
	# Modal touch controls still work while gameplay is paused.
	game.adventure_panel.open()
	check(paused and game.adventure_panel.visible,"Save panel did not pause")
	game.adventure_panel.dismiss()
	check(not paused,"Save panel did not restore pause state")
	var report := FileAccess.open("/workspace/artifacts/save-totems/locations.json",FileAccess.WRITE)
	if report: report.store_string(JSON.stringify(locations))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.storage_path))
	if failures==0: print("PASS: three reachable camp totems, Saving/Saved speech bubbles, JSON state round trip, local offline persistence/Continue, all-world progress and partial mining restore, single coloured pulse and speedrun isolation")
	quit(1 if failures else 0)
