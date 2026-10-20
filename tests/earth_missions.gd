extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const CREATURE = preload("res://environment/ambient_creature.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func next_alert(trial) -> void:
	for seed_value in 100:
		trial.encounter_rng.seed = seed_value
		if trial.encounter_rng.randf() < 0.35:
			trial.encounter_rng.seed = seed_value
			return

func press(code: Key) -> void:
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform()*point
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func check_mine_alert(game) -> void:
	var habitat = game.local_life
	for enemy in habitat.creatures: enemy.set_process(false)
	var count: int = game.trial.encounter_count
	var found := false
	for enemy in habitat.creatures:
		for ray in 16:
			var point: Vector2 = enemy.position+Vector2.from_angle(ray*TAU/16.0)*145
			if game.trial.safe_at(point) or not game.trial.floor_at(point) or not game.trial.clear_line(point,enemy.position): continue
			game.player = point
			game.fog.observe(game.area_id(),enemy.position)
			next_alert(game.trial)
			var rock := {"pos":point,"cave":true}
			if game.trial.mining_encounter(rock):
				found = true
				check(not game.trial.mining_encounter(rock),"Mine deposit repeatedly alerted a creature")
				break
		if found: break
	check(found and game.trial.encounter_count == count+1 and habitat.creatures.size() == 5,"Mine alert added enemies or could not reuse a nearby rat/bat")
	var alerted: Array = habitat.creatures.filter(func(c): return c.state == "alert")
	check(alerted.size() == 1,"Mine encounter did not show its warning state")
	if not alerted.is_empty():
		var health: int = game.trial.health
		alerted[0].advance(0.8)
		check(alerted[0].state == "alert" and game.trial.health == health,"Mine alert attacked before its warning ended")
	var other := {"pos":game.player,"cave":true}
	next_alert(game.trial)
	check(not game.trial.mining_encounter(other),"Another deposit bypassed the area's mine alert cap")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.companion.set_process(false)
	game.gardens.set_process(false)
	check(game.missions.completed() == 0 and game.missions.entries().size() == 11,"Fresh expedition inherited completed missions")
	check(game.hud.mission_panel.size.y <= 52,"Mission HUD became a large overlay")
	# Follow the normal journal shortcut. Opening pauses mining and all combat.
	var index: int = game.rocks.find_custom(func(r): return not r.cave)
	game.player = game.rocks[index].pos+Vector2(-65,0)
	game.update_exploration()
	game.start_mining(index)
	game.advance_mining(0.7)
	await press(KEY_J)
	check(game.mission_journal.visible and game.menu_open() and game.mining_target == -1,"J did not open the journal and pause mining")
	check(is_equal_approx(game.rocks[index].work,0.7),"Opening journal discarded mining work")
	var before: float = game.trial.seconds
	game.trial.advance(2)
	check(game.trial.seconds == before and not game.trial.start_jab(),"Combat continued beneath journal")
	await press(KEY_J)
	check(not game.mission_journal.visible and not game.menu_open(),"J did not close the journal")
	game.hud.set_touch_mode(true)
	game.refresh_ui()
	var pad = game.hud.touch_controls
	await touch(0,pad.position+pad.CENTER+Vector2(50,0),true)
	var button_at: Vector2 = game.hud.missions_button.get_global_rect().get_center()
	await touch(1,button_at,true)
	await touch(1,button_at,false)
	check(game.mission_journal.visible and pad.finger == -1 and pad.direction.is_zero_approx(),"Second-finger journal tap left movement held")
	await touch(0,pad.position+pad.CENTER,false)
	var close_at: Vector2 = game.mission_journal.close_button.get_global_rect().get_center()
	await touch(2,close_at,true)
	await touch(2,close_at,false)
	check(not game.mission_journal.visible and pad.direction.is_zero_approx(),"Touch journal close resumed stale movement")
	game.hud.set_touch_mode(false)
	game.start_mining(index)
	check(is_equal_approx(game.mining_elapsed,0.7),"Journal return did not resume the same deposit")
	game.advance_mining(0.4)
	game.move_player(Vector2.LEFT,0.03)
	check(game.mining_target == -1 and is_equal_approx(game.rocks[index].work,1.1),"Walking discarded partial work")
	# Save a second deposit independently, then unload and cross a rocket trip.
	var second: int = 1-index
	game.player = game.rocks[second].pos
	game.update_exploration()
	game.start_mining(second)
	game.advance_mining(0.3)
	game.cancel_mining()
	await TRAVEL.enter(game,1,false)
	await TRAVEL.enter(game,0,false)
	TRAVEL.depart(game,1)
	game.advance_flight(10)
	check(not game.hud.mission_panel.visible,"Earth journal leaked into Frost")
	await press(KEY_J)
	check(not game.mission_journal.visible,"Earth journal opened on another planet")
	TRAVEL.depart(game,0)
	game.advance_flight(10)
	check(is_equal_approx(game.rocks[index].work,1.1) and is_equal_approx(game.rocks[second].work,0.3),"Area unload or rocket trip reset deposit work")
	game.player = game.rocks[index].pos
	game.update_exploration()
	game.start_mining(index)
	game.advance_mining(0.89)
	check(game.ore == 0,"Resumed deposit awarded early")
	game.advance_mining(0.02)
	game.start_mining(index)
	game.advance_mining(10)
	check(game.ore == 1 and game.rocks[index].hp == 0,"Resumed deposit rewarded more than once")
	# A nonfatal hit and changing equipment both pause the remaining deposit.
	game.player = game.rocks[second].pos+Vector2(-60,0)
	game.update_exploration()
	game.start_mining(second)
	game.advance_mining(0.2)
	game.trial.invulnerable = 0
	check(game.trial.hurt_player(1) and game.mining_target == -1 and is_equal_approx(game.rocks[second].work,0.5),"A nonfatal hit did not pause and retain mining")
	game.start_mining(second)
	game.trial.sword_owned = true
	game.trial.equip(1)
	check(game.mining_target == -1 and is_equal_approx(game.rocks[second].work,0.5),"Sword switch discarded work")
	game.trial.equip(0)
	# Surface encounter uses the actual mining action and a seeded random roll.
	# Keep this fixture independent of randomized ore landing beside two
	# existing snakes (where the production crowding guard should refuse it).
	var nearby_snake = game.trial.snakes[0]
	for snake in game.trial.snakes:
		snake.health = 0
		snake.state = "gone"
		snake.hide()
	nearby_snake.health = 9
	for ray in 24:
		var point: Vector2 = game.player+Vector2.from_angle(ray*TAU/24)*145
		nearby_snake.home = point
		if nearby_snake.can_stand(point) and game.trial.clear_line(point,game.player):
			nearby_snake.position = point
			nearby_snake.state = "roam"
			nearby_snake.show()
			game.fog.observe(game.area_id(),point)
			break
	game.trial.encounter_rng.seed = 123
	game.rocks[second].erase("encounter_checked")
	next_alert(game.trial)
	game.start_mining(second)
	game.advance_mining(0.2)
	check(game.trial.encounter_count == 1 and game.trial.snakes.size() <= 4,"Mining did not create a bounded surface alert")
	var alerted: Array = game.trial.snakes.filter(func(s): return s.state == "stir")
	check(alerted.size() == 1,"Mining alert has no visible warned snake")
	if not alerted.is_empty():
		var snake = alerted[0]
		var health: int = game.trial.health
		snake.advance(0.8)
		check(snake.state == "stir" and game.trial.health == health,"Mining creature attacked before its warning finished")
		check(snake.can_stand(snake.position),"Mining snake spawned on a rock, doorway or water")
	game.cancel_mining()
	game.start_mining(second)
	game.advance_mining(0.1)
	check(game.trial.encounter_count == 1,"Resuming a deposit summoned another creature")
	game.cancel_mining()
	await TRAVEL.enter(game,1,false)
	await TRAVEL.enter(game,0,false)
	check(game.trial.snakes.size() <= 4 and game.rocks[second].encounter_checked,"Reloading lost the encounter cap or deposit marker")
	# Safe camp cannot summon encounters or mark a deposit as checked.
	game.player = game.CAMP
	var safe_rock := {"pos":game.player,"cave":false}
	next_alert(game.trial)
	check(not game.trial.mining_encounter(safe_rock) and not safe_rock.has("encounter_checked"),"Camp is no longer safe")
	# Mine creatures complete their objectives through real defeat/scare events.
	await TRAVEL.enter(game,0,true)
	check(game.missions.mines.size() == 1,"Entering Moss Mine was not recorded")
	check_mine_alert(game)
	for creature in game.local_life.creatures:
		creature.set_process(false)
		game.fog.observe(game.area_id(),creature.position)
		if creature.kind == CREATURE.Kind.BAT:
			creature.take_hit(2000+creature.scare_id,game.player,creature.max_health())
			break
	var rat = game.local_life.creatures.filter(func(c): return c.kind == CREATURE.Kind.RAT)[0]
	game.fog.observe(game.area_id(),rat.position)
	check(rat.scare_from(game.player),"Buddy-style scare was rejected")
	check(game.missions.cleared_kinds.size() == 2,"Sword and Buddy scare did not both count toward mine mission")
	var rare: int = game.rocks.find_custom(func(r): return r.hard)
	game.upgraded = true
	game.player = game.rocks[rare].pos
	game.update_exploration()
	game.start_mining(rare)
	game.advance_mining(3.4)
	game.cancel_mining()
	await TRAVEL.enter(game,0,false)
	await TRAVEL.enter(game,0,true)
	game.player = game.rocks[rare].pos
	game.start_mining(rare)
	check(is_equal_approx(game.mining_elapsed,3.4),"Rare mining progress reset on mine exit")
	game.advance_mining(5.61)
	check(game.blue_crystals == 1,"Interrupted rare deposit could not finish")
	await TRAVEL.enter(game,0,false)
	for region in [1,2,3,4]:
		await TRAVEL.enter(game,region,false)
		if game.EARTH.has_mine(region):
			await TRAVEL.enter(game,region,true)
			await TRAVEL.enter(game,region,false)
	check(game.missions.mines.size() == 3 and game.earth_visited.size() == 5,"Earth exploration missions missed a district or mine")
	game.trial.defeated = 1
	game.companion.recruited = true
	check(game.missions.entries().filter(func(e): return e.id in ["trails","mines","buddy"]).all(func(e): return e.done),"Optional exploration objectives did not finish")
	game.mission_journal.open()
	check(game.mission_journal.summary.text.contains("/ 7 story quests"),"Journal failed to display the character mission count")
	game.mission_journal.dismiss()
	game.queue_free()
	await process_frame
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.missions.completed() == 0 and game.missions.mines.is_empty() and game.trial.encounter_count == 0 and game.rocks.all(func(r): return not r.has("work")),"Fresh game inherited mission, encounter or mining state")
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: journal shortcuts/modal pause, per-deposit retained work across movement/hit/equipment/mines/rocket travel, exact remaining duration and one reward, warned/capped/no-repeat mining encounters and camp protection, Earth-only missions, real defeat/scare objectives, all district/mine discovery and fresh reset")
	quit(1 if failures else 0)
