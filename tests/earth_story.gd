extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func position_player(game, point: Vector2) -> void:
	game.player = point
	game.scout.position = point
	game.camera.position = point
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.update_exploration()
	game.cooldown = 0
	game.refresh_ui()
	game.story._process(0.8)

func person(game, role: String):
	return game.npcs.filter(func(n): return str(n.name).to_lower() == role)[0]

func talk(game, role: String) -> void:
	var npc = person(game,role)
	position_player(game,npc.position+Vector2(0,30))
	game.interact()
	check(game.dialogue_open() and game.dialogue_npc == npc,"Talk action chose the wrong person: "+role)

func finish_dialogue(game) -> void:
	for i in 8:
		if not game.dialogue_open(): break
		game.character_bubble.advance()
	check(not game.dialogue_open(),"Conversation did not finish")

func finish_touch_dialogue(game) -> void:
	for page in 8:
		if not game.dialogue_open(): break
		var button = game.character_bubble.next_button
		var point: Vector2 = root.get_final_transform()*button.get_global_transform_with_canvas()*(button.size*0.5)
		for down in [true,false]:
			var event := InputEventScreenTouch.new()
			event.index = 2
			event.position = point
			event.pressed = down
			Input.parse_input_event(event)
			await process_frame
	check(not game.dialogue_open(),"Touch conversation did not finish")

func gather(game) -> void:
	game.trial.selected_tool = 0
	for i in game.rocks.size():
		var rock: Dictionary = game.rocks[i]
		if rock.cave != game.underground or rock.hp <= 0: continue
		if rock.hard and not game.upgraded: continue
		position_player(game,rock.pos)
		game.start_mining(i)
		game.advance_mining(rock.seconds+0.01)
		check(rock.hp == 0,"Real mining could not gather the story supply")
	if not game.underground:
		for pile in game.wood_supplies.piles:
			if pile.collected: continue
			position_player(game,pile.position)
			game.wood_supplies._process(0.8)
			game.interact()
			check(pile.collected,"Real fallen wood could not be collected")

func use_prop(game, id: String) -> void:
	game.story.sync_area()
	check(game.story.props.has(id),"Missing reachable quest prop: "+id)
	if not game.story.props.has(id): return
	var prop = game.story.props[id]
	position_player(game,prop.position+Vector2(-65,0))
	game.trial.selected_tool = 0
	game.interact()
	check(not game.dialogue_open(),"An NPC stole the quest prop interaction: "+id)
	if game.story.working():
		game.story.advance_actions(0.7)
		game.move_player(Vector2.LEFT,0.01)
		check(not game.story.working() and is_equal_approx(game.story.job_progress[id],0.7),"Moving did not pause a world drilling job")
		position_player(game,prop.position+Vector2(-65,0))
		game.interact()
		game.story.advance_actions(1.31)
		check(not game.story.working(),"World drilling did not resume and finish")

func defeat(game, slot: int) -> void:
	var snake = game.trial.snakes.filter(func(s): return s.spawn_id == "%d/%d" % [game.earth_region,slot])[0]
	game.fog.observe(game.area_id(),snake.position)
	snake.seen = true
	var damage := 5 if game.story.sword_improved else 3
	var strike := 0
	while snake.health > 0:
		check(snake.take_hit(10000+strike,game.player,damage),"Designated snake could not take a real hit")
		strike += 1
		if strike > 10: break
	check(snake.health == 0,"Designated encounter did not finish")

func craft(game, recipe: String) -> void:
	position_player(game,game.CAMP)
	game.interact()
	check(game.camp_menu.visible,"Camp workbench is blocked by a neighbour")
	game.camp_menu.craft(recipe)
	game.camp_menu.dismiss()

func run() -> void:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.story.set_process(false)
	game.companion.set_process(false)
	game.gardens.set_process(false)
	game.trial.invulnerable = 10000
	check(game.npcs.size() == 7 and not game.story.launch_ready(),"Earth does not begin with seven neighbours and a broken rocket")
	game.travel_to_other_planet(1)
	check(game.flight == 0 and game.world == 0,"The broken rocket can launch before the story")
	for npc in game.npcs:
		check(absf(npc.height-game.rowan.height) < 0.01,"A new character is larger than Scout: "+str(npc.name))
	# Rowan's accepted craft still owns its original recipe and reward.
	talk(game,"rowan")
	finish_dialogue(game)
	check(game.rowan.mission == game.rowan.Mission.ACTIVE,"Rowan's mission could not be accepted")
	gather(game)
	await TRAVEL.enter(game,1,false)
	gather(game)
	await TRAVEL.enter(game,0,false)
	craft(game,"sword")
	check(game.rowan.mission == game.rowan.Mission.COMPLETE and game.trial.sword_owned,"Real sword craft did not complete Rowan")
	await TRAVEL.enter(game,1,false)
	# An unrelated snake cannot unlock Bea's box. Early designated kills count.
	defeat(game,0)
	use_prop(game,"supplies")
	check(not game.story.cache_held,"An unrelated snake unlocked Bea's supplies")
	defeat(game,1)
	use_prop(game,"supplies")
	check(game.story.cache_held,"Early designated kill and pickup were not recognized")
	talk(game,"bea")
	check(game.character_bubble.final_action == "Return supplies","Early supply recovery has no return action")
	game.character_bubble.dismiss()
	check(game.story.cache_held and not game.story.done("bea"),"Cancelling consumed the mission box")
	talk(game,"bea")
	finish_dialogue(game)
	check(game.story.done("bea") and not game.story.cache_held,"Supply return did not complete exactly once")
	# The actual quarry transition and rock collider remain blocked until drilled.
	game.begin_earth_transition(4,false,game.EARTH.arrival(4,"west"),game.player)
	check(not game.earth_transition and game.earth_region == 1,"Locked quarry accepted a trail transition")
	position_player(game,Vector2(1730,674))
	game.move_player(Vector2.RIGHT,0.3)
	check(game.player.x < 1755,"Walking passed through the rockfall")
	talk(game,"otis")
	finish_dialogue(game)
	check(game.story.accepted.get("otis",false),"Otis's mission could not be accepted")
	use_prop(game,"rockfall")
	check(not game.story.quarry_open,"Starter pick cleared the rockfall")
	# All supplies for the starter drill exist before the quarry gate.
	for region in [2,3]:
		await TRAVEL.enter(game,region,false)
		gather(game)
	await TRAVEL.enter(game,0,false)
	craft(game,"drill")
	check(game.upgraded,"The quarry gate made the starter drill unaffordable")
	for region in [0,1]:
		await TRAVEL.enter(game,region,true)
		gather(game)
	await TRAVEL.enter(game,1,false)
	use_prop(game,"rockfall")
	check(game.story.quarry_open,"Hand drill did not clear the persistent rockfall")
	talk(game,"otis")
	finish_dialogue(game)
	check(game.story.done("otis"),"Reporting clearance did not complete Otis")
	await TRAVEL.enter(game,4,false)
	gather(game)
	check(game.ore == 4 and game.blue_crystals == 2,"Pre-upgrade resource budget is wrong: %d copper, %d crystals" % [game.ore,game.blue_crystals])
	talk(game,"mara")
	check(game.character_bubble.final_action == "Upgrade both tools","Mara did not recognize real upgrade ingredients")
	game.character_bubble.dismiss()
	check(game.ore == 4 and not game.story.drill_improved,"Cancelling upgraded or spent ingredients")
	talk(game,"mara")
	game.hud.set_touch_mode(true)
	game.character_bubble.set_touch_mode(true)
	await finish_touch_dialogue(game)
	check(game.story.done("mara") and game.story.drill_improved and game.story.sword_improved and game.ore == 0 and game.blue_crystals == 0,"Mara did not spend exactly 4 copper + 2 crystals for both upgrades")
	talk(game,"mara")
	finish_dialogue(game)
	check(game.ore == 0 and game.blue_crystals == 0,"Repeated Mara conversation charged again")
	await TRAVEL.enter(game,4,true)
	# The upgrade changes real mining speed, rather than just a mission flag.
	var common: int = game.rocks.find_custom(func(r): return r.cave and not r.hard)
	position_player(game,game.rocks[common].pos)
	game.trial.selected_tool = 0
	game.start_mining(common)
	game.advance_mining(1.49)
	check(game.rocks[common].hp > 0,"Upgraded drill awarded before 1.5 seconds")
	game.advance_mining(0.02)
	check(game.rocks[common].hp == 0,"Mara's drill did not speed real copper mining up to 1.5 seconds")
	gather(game)
	use_prop(game,"engine")
	check(game.story.engine_part,"Early engine recovery did not persist")
	await TRAVEL.enter(game,3,false)
	talk(game,"iris")
	finish_dialogue(game)
	var ruins_snake = game.trial.snakes.filter(func(s): return s.spawn_id == "3/1")[0]
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
		var point: Vector2 = ruins_snake.position-direction*57
		if not game.trial.floor_at(point) or not game.trial.clear_line(point,ruins_snake.position): continue
		position_player(game,point)
		game.trial.selected_tool = 1
		game.face_direction(direction)
		game.trial.jab_cooldown = 0
		game.trial.start_jab()
		game.trial.advance(0.12)
		check(ruins_snake.health == 4,"Mara's sword did not deal five damage in a real directional jab")
		game.trial.advance(0.5)
		break
	defeat(game,1)
	use_prop(game,"locker")
	check(game.story.damaged_suit and game.story.navigation_part,"Expedition locker did not grant its two distinct items")
	talk(game,"iris")
	finish_dialogue(game)
	check(game.story.done("iris"),"Discovery report did not complete Iris")
	await TRAVEL.enter(game,2,false)
	use_prop(game,"seals")
	check(game.story.seal_kit,"Waterside seal kit could not be recovered")
	var wood: int = game.trial.wood
	talk(game,"finn")
	finish_dialogue(game)
	check(game.story.done("finn") and game.story.suit_ready and game.story.regulator and not game.story.damaged_suit and not game.story.seal_kit and game.trial.wood == wood-2,"Finn repaired the suit with the wrong supplies or lost its distinct ready state")
	await TRAVEL.enter(game,0,false)
	talk(game,"nova")
	check(game.character_bubble.final_action == "Repair and check rocket","Final mission did not recognize all early recovered components")
	game.character_bubble.dismiss()
	check(game.story.engine_part and game.story.navigation_part and game.story.regulator and not game.story.rocket_repaired,"Cancelled rocket repair consumed parts")
	talk(game,"nova")
	finish_dialogue(game)
	check(game.story.done("nova") and game.story.launch_ready() and not game.story.engine_part and not game.story.navigation_part and not game.story.regulator,"Nova did not fit each unique part once")
	check(game.missions.completed() == 7,"Earth journal did not complete all seven story missions")
	game.mission_journal.open()
	check(game.mission_journal.summary.text.begins_with("7 / 7") and game.mission_journal.progress.slice(0,7).all(func(l): return l.text == "Complete"),"Completed character missions are missing from the journal")
	game.mission_journal.dismiss()
	game.travel_to_other_planet(1)
	game.advance_flight(10)
	check(game.world == 1 and not game.hud.mission_panel.visible and game.npcs.all(func(n): return not n.visible),"Repaired rocket could not travel or Earth people leaked off-world")
	game.travel_to_other_planet(0)
	game.advance_flight(10)
	await TRAVEL.enter(game,4,false)
	check(game.story.quarry_open and game.missions.completed() == 7 and game.story.suit_ready,"Travel reset the open quarry or completed story")
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await process_frame
	check(current_scene.missions.completed() == 0 and not current_scene.story.quarry_open and not current_scene.story.launch_ready() and not current_scene.story.engine_part,"Confirmed reset inherited the story")
	if failures == 0: print("PASS: seven fitted Earth neighbours, actual gathering and exact affordable recipes, identity-specific early snake/cache recovery, cancel/retry and one-time handoffs, quarry collision/transition/drilling gate, reinforced tools, locker/suit/unique parts, final launch gates, journal completion, off-world exclusion, travel memory and confirmed reset")
	quit(1 if failures else 0)
