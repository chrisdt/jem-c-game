extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const ROWAN = preload("res://environment/rowan.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, detail: String) -> void:
	if condition: return
	failures += 1
	push_error(detail)

func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func tap(button: Button) -> void:
	var point: Vector2 = root.get_final_transform()*button.get_global_transform_with_canvas()*(button.size*0.5)
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index = 1
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func new_game():
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	current_scene.set_process(false)
	current_scene.trial.invulnerable = 10000
	return current_scene

func approach(game) -> void:
	game.player = game.rowan.position+Vector2(0,28)
	game.scout.position = game.player
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()

func talk(game) -> void:
	approach(game)
	game.interact()
	check(game.dialogue_open(),"Rowan's real Talk interaction did not open")

func gather_copper(game, count: int) -> void:
	var before: int = game.ore
	for index in game.rocks.size():
		var rock: Dictionary = game.rocks[index]
		if rock.cave or rock.hard or rock.hp <= 0: continue
		game.player = rock.pos
		game.scout.position = game.player
		game.update_exploration()
		game.start_mining(index)
		game.advance_mining(2)
		if game.ore-before == count: break
	game.refresh_ui()
	check(game.ore-before == count,"Real copper gathering did not supply the requested materials")

func gather_wood(game) -> void:
	var before: int = game.trial.wood
	for pile in game.wood_supplies.piles:
		if pile.collected: continue
		game.player = pile.position
		game.scout.position = game.player
		game.update_exploration()
		game.wood_supplies._process(0.75)
		game.cooldown = 0
		game.interact()
		check(pile.collected and game.trial.wood == before+1,"A real wood pickup did not update mission supplies")
		game.refresh_ui()
		return
	check(false,"No uncollected wood was available")

func craft(game, recipe: String) -> void:
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	check(game.camp_menu.visible,"Rowan's mission blocked the workbench")
	game.camp_menu.craft(recipe)
	game.camp_menu.dismiss()

func run() -> void:
	var game = await new_game()
	var rowan = game.rowan
	var bubble = game.character_bubble
	check(rowan.mission == rowan.Mission.NOT_STARTED,"Rowan's mission started from proximity alone")
	talk(game)
	await key(KEY_E)
	check(bubble.final_action == "Accept mission" and bubble.next_button.text.contains("Accept mission"),"The offer has no explicit Accept action")
	await key(KEY_ESCAPE)
	check(rowan.mission == rowan.Mission.NOT_STARTED and not rowan.introduced,"Closing the offer accepted the mission")
	game.hud.set_touch_mode(true)
	talk(game)
	await tap(bubble.next_button)
	check(rowan.mission == rowan.Mission.NOT_STARTED,"Reading the first page accepted the mission")
	check(Rect2(Vector2.ZERO,bubble.panel.size).encloses(Rect2(bubble.next_button.position,bubble.next_button.size)),"The touch Accept button overflows its bubble")
	await tap(bubble.next_button)
	check(rowan.mission == rowan.Mission.ACTIVE and not game.dialogue_open(),"Touch Accept did not start the mission and restore gameplay")
	check(game.story.entries()[0].title == "Rowan · Ready for the Trail" and rowan.progress_text() == "Copper 0/3 · Wood 0/2","Accepted mission has no named objective or live material counts")
	check(game.ore == 0 and game.trial.wood == 0 and not game.trial.sword_owned,"Accepting granted ingredients or a sword")
	gather_copper(game,2)
	check(rowan.progress_text() == "Copper 2/3 · Wood 0/2","Mining did not update mission progress")
	talk(game)
	check(bubble.body_label.get_parsed_text().contains("2 / 3 copper"),"A return visit did not explain the missing copper")
	await key(KEY_ESCAPE)
	gather_wood(game)
	await TRAVEL.enter(game,1,false)
	check(rowan.mission == rowan.Mission.ACTIVE,"Changing districts lost the accepted mission")
	gather_copper(game,2)
	check(rowan.pages()[0].contains("1 / 2 wood"),"The reminder did not switch to missing wood")
	gather_wood(game)
	check(rowan.progress_text().contains("craft at camp") and rowan.mission == rowan.Mission.ACTIVE,"Holding enough materials completed the quest before crafting")
	await TRAVEL.enter(game,2,false)
	gather_copper(game,1)
	await TRAVEL.enter(game,0,false)
	# Spending the first five copper on a drill must leave the mission active
	# with current inventory counts and enough reachable copper for the sword.
	craft(game,"drill")
	check(game.upgraded and game.ore == 0 and rowan.mission == rowan.Mission.ACTIVE,"Crafting the drill completed or reset the sword quest")
	check(rowan.progress_text() == "Copper 0/3 · Wood 2/2","Spending copper did not update the remaining sword requirements")
	await TRAVEL.enter(game,2,false)
	gather_copper(game,1)
	await TRAVEL.enter(game,3,false)
	gather_copper(game,2)
	await TRAVEL.enter(game,0,false)
	craft(game,"sword")
	check(game.trial.sword_owned and game.ore == 0 and game.trial.wood == 0,"The sword did not use exactly 3 copper and 2 wood")
	check(rowan.mission == rowan.Mission.COMPLETE and game.story.done("rowan"),"Crafting did not complete the accepted mission")
	check(rowan.progress_text() == "Copper sword crafted","Spending ingredients erased the completed objective")
	check(game.message.contains("Ready for the Trail complete!") and game.message.contains("Bea"),"Mission completion lost its next-step instructions")
	bubble._process(5)
	game.refresh_ui()
	check(not bubble.visible,"Completion feedback repeated after its hint expired")
	rowan.advance_departure(0.4)
	check(rowan.departing and not rowan.can_talk(),"Completed Rowan quest remains available during departure")
	rowan.advance_departure(0.5)
	check(rowan.departed and not rowan.visible and game.ore == 0 and game.trial.wood == 0,"Rowan did not puff away after completion or changed ingredients")
	game.trial.equip(0)
	await TRAVEL.enter(game,1,true)
	check(rowan.mission == rowan.Mission.COMPLETE and not rowan.visible,"A mine trip or equipping the drill undid quest completion")
	await TRAVEL.enter(game,0,false)
	TRAVEL.depart(game,1)
	game.advance_flight(10)
	TRAVEL.depart(game,0)
	game.advance_flight(10)
	check(rowan.mission == rowan.Mission.COMPLETE and rowan.departed and not rowan.visible,"Planet travel respawned the completed quest character")
	# Crafting before meeting Rowan uses the same real materials and remains
	# available. The later conversation recognizes it without a second charge.
	game = await new_game()
	rowan = game.rowan
	bubble = game.character_bubble
	gather_copper(game,2)
	gather_wood(game)
	await TRAVEL.enter(game,1,false)
	gather_copper(game,1)
	gather_wood(game)
	await TRAVEL.enter(game,0,false)
	craft(game,"sword")
	check(rowan.mission == rowan.Mission.NOT_STARTED,"Crafting silently accepted Rowan's offer")
	talk(game)
	check(bubble.body_label.get_parsed_text().contains("fine sword") and bubble.final_action == "Complete mission","An early sword was not recognized")
	await key(KEY_ESCAPE)
	check(rowan.mission == rowan.Mission.NOT_STARTED,"Cancelling an early-sword conversation accepted the mission")
	talk(game)
	await key(KEY_E)
	await key(KEY_E)
	check(rowan.mission == rowan.Mission.COMPLETE and rowan.completion_seen and game.ore == 0 and game.trial.wood == 0,"An early sword did not complete the mission once without extra costs")
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await process_frame
	check(current_scene.rowan.mission == ROWAN.Mission.NOT_STARTED and not current_scene.rowan.completion_seen and not current_scene.trial.sword_owned,"A confirmed reset kept Rowan's mission or reward")
	if failures == 0: print("PASS: explicit/cancelled keyboard and touch offers, real copper/wood gathering, live reminders, drill-first supply, exact sword craft, lasting completion, one-time ending, early crafting, area/planet memory and confirmed reset")
	quit(1 if failures else 0)
