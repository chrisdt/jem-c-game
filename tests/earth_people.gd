extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const HUMAN = preload("res://environment/human_npc.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func new_game():
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.story.set_process(false)
	game.trial.set_process(false)
	game.companion.set_process(false)
	game.gardens.set_process(false)
	for npc in game.npcs: npc.set_process(false)
	return game

func approach(game, npc) -> void:
	game.player = npc.position+Vector2(0,30)
	game.scout.position = game.player
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()

func finish_pages(game) -> void:
	for page in 8:
		if not game.dialogue_open(): break
		game.character_bubble.advance()
	check(not game.dialogue_open(),"Quest dialogue did not finish")

func inventory(game) -> Array:
	return [game.ore,game.blue_crystals,game.trial.wood,game.trial.sword_owned,game.story.cache_held,game.story.damaged_suit,game.story.navigation_part,game.story.seal_kit,game.story.suit_ready,game.story.regulator,game.story.engine_part,game.story.rocket_repaired]

func ready_offer(game, role: String) -> void:
	# Only isolate each handoff's lifecycle here. The full earth_story test
	# earns these prerequisite flags through actual gathering and campaign play.
	game.story.complete.clear()
	for prior in game.story.ORDER.slice(1,game.story.ORDER.find(role)):
		game.story.complete[prior] = true
	game.upgraded = true
	game.ore = 4
	game.blue_crystals = 2
	game.trial.wood = 2
	game.story.quarry_open = true
	game.story.cache_held = role == "bea"
	game.story.drill_improved = role in ["iris","finn","nova"]
	game.story.sword_improved = game.story.drill_improved
	game.story.damaged_suit = role in ["iris","finn"]
	game.story.navigation_part = role in ["iris","finn","nova"]
	game.story.seal_kit = role == "finn"
	game.story.suit_ready = role == "nova"
	game.story.regulator = role == "nova"
	game.story.engine_part = role == "nova"
	game.story.rocket_repaired = false

func check_departure(game, npc) -> void:
	check(npc.quest_finished() and not npc.can_talk(),"Completed character can still be selected: "+str(npc.name))
	npc.advance_departure(0.1)
	check(npc.departing and not npc.departed and npc.visible,"Character did not start its smoke puff: "+str(npc.name))
	check(npc.illustration.modulate.a < 1 and npc.illustration.modulate.a > 0,"Departure does not fade the figure: "+str(npc.name))
	var before: float = npc.departure_time
	game.mission_journal.open()
	check(game.mission_journal.visible,"Could not open Quests during the departure fixture")
	npc.advance_departure(0.4)
	check(is_equal_approx(npc.departure_time,before),"Departure advanced behind Quests")
	game.mission_journal.dismiss()
	paused = true
	npc.advance_departure(0.4)
	check(is_equal_approx(npc.departure_time,before),"Departure advanced while the tree was paused")
	paused = false
	game.hud.help.show()
	npc.advance_departure(0.4)
	check(is_equal_approx(npc.departure_time,before),"Departure advanced behind the controls popup")
	game.hud.help.hide()
	npc.advance_departure(0.69)
	check(npc.departing and npc.visible and not npc.departed,"Smoke puff ended before 0.8 seconds")
	npc.advance_departure(0.02)
	check(npc.departed and not npc.departing and not npc.visible and not npc.can_talk(),"Completed character did not finish its smoke exit")
	var after: Array = inventory(game)
	npc.conversation_finished(true)
	npc.advance_departure(5)
	npc.sync_area()
	check(inventory(game) == after and not npc.visible,"A departed character repeated rewards or reappeared")

func run() -> void:
	var game = await new_game()
	check(game.npcs.size() == 7,"Earth does not contain all seven quest characters")
	var atlas_image: Image = HUMAN.PORTRAITS.get_image()
	var scout_height: float = HUMAN.visible_bounds(game.MINER_FRAMES.get_frame_texture(&"idle_down",0).get_image()).size.y*0.15
	check(is_equal_approx(scout_height,87.45),"Sunny's reference height unexpectedly changed")
	for npc in game.npcs:
		var role: String = str(npc.name).to_lower()
		var cell: Rect2i = HUMAN.PORTRAIT_CELLS[role]
		var art: AtlasTexture = npc.illustration.texture
		check(art.atlas == HUMAN.PORTRAITS,"Character still uses the old tall artwork: "+role)
		check(is_equal_approx(npc.height,scout_height) and is_equal_approx(art.region.size.y*npc.illustration.scale.y,scout_height),"Character's visible height does not match Sunny: "+role)
		check(Rect2(Vector2.ZERO,atlas_image.get_size()).encloses(Rect2(cell)) and Rect2(cell).encloses(art.region),"Portrait crop escapes its assigned source cell: "+role)
		var bounds: Rect2i = HUMAN.visible_bounds(atlas_image.get_region(cell))
		check(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < cell.size.x and bounds.end.y < cell.size.y,"A portrait is clipped by the source cell: "+role)
		for other in HUMAN.PORTRAIT_CELLS:
			if other != role: check(not cell.intersects(HUMAN.PORTRAIT_CELLS[other]),"Portrait cells overlap: "+role+" / "+other)
		npc.advance_departure(2)
		check(not npc.departing and not npc.departed and npc.illustration.modulate.a == 1,"An unfinished neighbour disappeared: "+role)
	# Cancel the real Rowan offer before accepting, then use the actual recipe.
	var rowan = game.rowan
	approach(game,rowan)
	game.interact()
	check(game.dialogue_open(),"Rowan's real Talk action failed")
	game.character_bubble.dismiss()
	rowan.advance_departure(1)
	check(rowan.mission == rowan.Mission.NOT_STARTED and not rowan.departing,"Cancelling Rowan accepted her quest or started a puff")
	game.cooldown = 0
	game.interact()
	finish_pages(game)
	check(rowan.mission == rowan.Mission.ACTIVE,"Rowan's accepted quest did not begin")
	game.ore = 3
	game.trial.wood = 2
	game.player = game.CAMP
	game.scout.position = game.player
	game.cooldown = 0
	game.interact()
	check(game.camp_menu.visible,"Actual camp crafting menu did not open")
	game.camp_menu.craft("sword")
	check(game.trial.sword_owned and game.ore == 0 and game.trial.wood == 0 and rowan.mission == rowan.Mission.COMPLETE,"Actual sword recipe did not complete Rowan for exactly 3 copper + 2 wood")
	check(game.message.contains("Bea") and game.message.contains("Pinewood"),"Rowan's automatic completion lacks the next quest destination")
	rowan.advance_departure(1)
	check(not rowan.departing and not rowan.departed and rowan.visible,"Rowan disappeared while the craft menu was still open")
	game.camp_menu.dismiss()
	approach(game,rowan)
	check_departure(game,rowan)
	# Every other final action may be cancelled without spending or departure.
	for role in ["bea","otis","mara","iris","finn","nova"]:
		ready_offer(game,role)
		var npc = game.npcs.filter(func(n): return str(n.name).to_lower() == role)[0]
		if game.earth_region != npc.home_region: await TRAVEL.enter(game,npc.home_region,false)
		approach(game,npc)
		var before: Array = inventory(game)
		game.interact()
		check(game.dialogue_open() and game.dialogue_npc == npc,"Final handoff does not select its unfinished character: "+role)
		game.character_bubble.dismiss()
		npc.advance_departure(1)
		check(not game.story.done(role) and not npc.departing and not npc.departed and inventory(game) == before,"Cancelled handoff spent rewards, completed or departed: "+role)
		game.cooldown = 0
		game.interact()
		finish_pages(game)
		check(game.story.done(role),"The confirmed final action failed to complete: "+role)
		check_departure(game,npc)
		var home: int = npc.home_region
		await TRAVEL.enter(game,1 if home == 0 else 0,false)
		await TRAVEL.enter(game,home,false)
		approach(game,npc)
		check(npc.departed and not npc.visible and not npc.can_talk(),"Returning to a district resurrected its completed character: "+role)
	# Full planet travel also retains departures, while a new game resets them.
	await TRAVEL.enter(game,0,false)
	TRAVEL.depart(game,1)
	game.advance_flight(10)
	TRAVEL.depart(game,0)
	game.advance_flight(10)
	check(game.npcs.all(func(n): return n.departed and not n.visible),"Planet travel resurrected a completed character")
	game = await new_game()
	check(game.npcs.all(func(n): return not n.departed and not n.departing and n.departure_time == 0 and n.illustration.modulate.a == 1),"Fresh scene inherited departure state")
	check(game.rowan.mission == game.rowan.Mission.NOT_STARTED and game.story.complete.is_empty(),"Fresh scene inherited completed quests")
	# Leaving during a puff must retain its elapsed time and disabled Talk,
	# rather than rebuilding a fresh copy of the quest character on return.
	var mara = game.npcs.filter(func(n): return n.name == "Mara")[0]
	game.story.complete.mara = true
	await TRAVEL.enter(game,4,false)
	approach(game,mara)
	mara.advance_departure(0.1)
	var puff_time: float = mara.departure_time
	var puff_alpha: float = mara.illustration.modulate.a
	await TRAVEL.enter(game,0,false)
	await TRAVEL.enter(game,4,false)
	approach(game,mara)
	check(mara.departing and not mara.can_talk() and is_equal_approx(mara.departure_time,puff_time) and is_equal_approx(mara.illustration.modulate.a,puff_alpha),"Area loading restarted a completed character's in-progress puff")
	mara.advance_departure(0.8)
	check(mara.departed and not mara.visible,"An interrupted departure never finished")
	await TRAVEL.enter(game,0,false)
	var iris = game.npcs.filter(func(n): return n.name == "Iris")[0]
	game.story.complete.iris = true
	iris.advance_departure(0.1)
	await TRAVEL.enter(game,3,false)
	approach(game,iris)
	check(iris.departed and not iris.visible and not iris.can_talk(),"A quest completed off-screen spawned a new character on arrival")
	if failures == 0: print("PASS: seven complete compact portraits at Sunny's 87.45 height, distinct unclipped atlas cells, cancelled handoffs, real Rowan recipe and next-step message, menu/pause-safe 0.8-second puff exits, one-time rewards, district/planet departure memory and fresh-scene reset")
	quit(1 if failures else 0)
