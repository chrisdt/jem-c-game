extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func touch(point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 2
	event.position = root.get_final_transform()*point
	event.pressed = down
	Input.parse_input_event(event)
	await process_frame

func tap(button: Button) -> void:
	var point: Vector2 = button.get_global_transform_with_canvas()*(button.size*0.5)
	await touch(point,true)
	await touch(point,false)

func place(game, point: Vector2) -> void:
	game.player = point
	game.scout.position = point
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()
	game.story._process(0.8)

func run() -> void:
	ProjectSettings.set_setting("gameplay/rocket_repair_required",true)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.story.set_process(false)
	game.trial.set_process(false)
	game.companion.set_process(false)
	game.gardens.set_process(false)
	var scout_height: float = game.HUMAN_NPC.visible_bounds(game.MINER_FRAMES.get_frame_texture(&"idle_down",0).get_image()).size.y*0.15
	for npc in game.npcs:
		check(is_equal_approx(npc.height,scout_height),"Earth character exceeds Scout's visible height: "+str(npc.name))
	var nova = game.npcs.filter(func(n): return n.name == "Nova")[0]
	game.fog.observe(0,nova.position)
	game.refresh_ui()
	check(not nova.visible and not nova.can_talk(),"Nova appears before the rocket-repair quest")
	check(nova.position.distance_to(game.SHIP) < 100,"Nova is no longer beside the rocket")
	check(game.rocket.damaged and game.rocket.body.texture.atlas == game.rocket.BROKEN_ART,"Opening rocket still uses the working illustration")
	game.rocket.advance_smoke(0.9)
	check(game.rocket.smoke.size() > 0 and game.rocket.smoke.size() <= 10,"Broken rocket has no bounded smoke animation")
	game.rocket.damaged = false
	check(game.rocket.smoke.is_empty() and game.rocket.body.texture.atlas == game.rocket.ART,"Repair did not stop smoke and restore the clean rocket")
	game.refresh_ui()
	# The HUD is only a button. Touch expands/collapses instructions in the popup.
	check(game.hud.mission_panel.size.y <= 52 and game.hud.missions_button.text.begins_with("Quests"),"The large mission overlay remains")
	game.hud.set_touch_mode(true)
	await tap(game.hud.missions_button)
	var journal = game.mission_journal
	check(journal.visible and journal.statuses[0].text.contains("Incomplete") and not journal.descriptions[0].visible,"Quests did not start with compact unfinished titles")
	await tap(journal.headers[0])
	check(journal.descriptions[0].visible and journal.progress[0].visible and journal.descriptions[0].text.contains("3 copper"),"Touch did not expand useful quest instructions")
	await tap(journal.headers[0])
	check(not journal.descriptions[0].visible,"Touch did not collapse quest instructions")
	game.rowan.mission = game.rowan.Mission.COMPLETE
	journal.present()
	check(journal.statuses[0].text.contains("Complete") and journal.progress[0].text == "Complete","Completed quest is not distinct from unfinished quests")
	# Swipe on a header scrolls; it must not accidentally expand it on release.
	var start: Vector2 = journal.headers[3].get_global_transform_with_canvas()*(journal.headers[3].size*0.5)
	await touch(start,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = root.get_final_transform()*(start-Vector2(0,80))
	drag.relative = root.get_final_transform().basis_xform(Vector2(0,-80))
	Input.parse_input_event(drag)
	await process_frame
	await touch(start-Vector2(0,80),false)
	check(journal.scroll.scroll_vertical > 0 and not journal.descriptions[3].visible,"Quest swipe expanded a row or failed to scroll")
	var clipped: Vector2 = journal.headers[0].get_global_transform_with_canvas()*Vector2(30,5)
	check(not journal.headers[0].contains_touch(clipped),"A scrolled-off quest can intercept touches outside the list")
	await tap(journal.close_button)
	check(not journal.visible and not game.menu_open(),"Quests could not return to exploration")
	await TRAVEL.enter(game,1,false)
	check(game.story.props.supplies.position.distance_to(Vector2(1480,847)) < 1,"Supplies moved away from their reviewed grass clearing")
	# The complete painted path is blocked, including the previously open side.
	for y in [600,640,680,720,760,790]:
		place(game,Vector2(game.story.ROCKFALL_BARRIER.position.x-15,y))
		game.move_player(Vector2.RIGHT,0.3)
		check(game.player.x < game.story.ROCKFALL_BARRIER.position.x,"Player bypassed the rockfall at path height "+str(y))
	game.upgraded = true
	place(game,game.story.interaction_position("rockfall")+Vector2(-60,-30))
	check(game.story.nearest_prop() == "rockfall" and game.nearest_npc() == null,"Rockfall cannot be reached from the unblocked side without Otis stealing the prompt")
	game.interact()
	game.story.advance_actions(2.1)
	check(game.story.quarry_open,"The full-width rockfall cannot be drilled away")
	# Buddy frightens a living, identified quest snake; it stays in the district.
	var dog = game.companion
	dog.recruited = true
	dog.sync_area()
	var snake = game.trial.snakes.filter(func(s): return s.spawn_id == "1/1")[0]
	var origin := Vector2.INF
	for ray in 16:
		var candidate: Vector2 = snake.position+Vector2.from_angle(ray*TAU/16)*90
		if dog.can_stand(candidate) and dog.clear_route(candidate,snake.position,false):
			origin = candidate
			break
	check(origin.is_finite(),"No real path to the supplies snake")
	if origin.is_finite():
		place(game,origin)
		dog.position = origin
		snake.advance(0)
		var before: Vector2 = snake.position
		var health: int = snake.health
		var defeated: int = game.trial.defeated
		check(dog.try_bark() and snake.state == "flee","Buddy did not frighten the nearby snake")
		check(not dog.try_bark(),"Buddy's bark cooldown was bypassed")
		for step in 45:
			snake.advance(0.05)
			check(snake.can_stand(snake.position),"Frightened snake crossed blocked scenery")
		check(snake.position.distance_to(before) > 35 and snake.health == health and snake.visible and snake.state == "flee","Snake vanished, took damage or failed to slither away")
		check(game.trial.defeated == defeated and not game.story.snake_cleared(1,1),"Barking counted as defeating a quest snake")
		await TRAVEL.enter(game,0,false)
		await TRAVEL.enter(game,1,false)
		snake = game.trial.snakes.filter(func(s): return s.spawn_id == "1/1")[0]
		check(snake.health == health and snake.state == "flee" and snake.fear_seconds > 0,"Travel lost the living snake's retreat or identity")
	await TRAVEL.enter(game,3,false)
	check(not game.story.props.has("locker") and not game.story.prop_exists("locker"),"Ruins chest appears before both tool upgrades")
	game.story.drill_improved = true
	game.story.sword_improved = true
	game.story.sync_area()
	check(game.story.props.locker.position.distance_to(Vector2(1600,345)) < 1,"Upgraded-tools chest is not centered inside the ruins")
	await TRAVEL.enter(game,1,false)
	check(game.story.props.has("seals") and game.story.props.seals.position.distance_to(Vector2(410,278)) < 1,"Seal kit is missing from Pinewood's campsite")
	await TRAVEL.enter(game,0,true)
	check(not game.story.props.has("seals"),"Seal kit still appears inside Moss Mine")
	await TRAVEL.enter(game,2,false)
	var finn = game.npcs.filter(func(n): return n.name == "Finn")[0]
	check(finn.position.distance_to(Vector2(1187,853)) < 1 and not game.story.props.has("seals"),"Finn or the seal kit remains on the old bridge bank")
	game.story.complete.finn = true
	await TRAVEL.enter(game,0,false)
	place(game,nova.position+Vector2(0,35))
	check(nova.visible and nova.can_talk(),"Nova never appears for the rocket quest")
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: shared character head scale, hidden-until-ready Nova, broken/working rocket and smoke, compact expandable/touch-scrollable Quests, full path rockfall and reachable drilling, grass supplies, gated centered ruins chest, Willow bank Finn, Pinewood campsite seal kit and persistent living snake retreat without quest credit")
	quit(1 if failures else 0)
