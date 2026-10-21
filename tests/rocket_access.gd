extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func unearned(game) -> void:
	check(game.ore == 0 and game.blue_crystals == 0 and game.trial.wood == 0,"Travel awarded resources")
	check(not game.upgraded and not game.trial.sword_owned and not game.story.drill_improved and not game.story.sword_improved and not game.story.suit_ready,"Travel awarded quest equipment")
	check(game.missions.completed() == 0 and not game.story.rocket_repaired,"Paused mission was marked complete")

func board(game, destination: int, touch_mode: bool) -> void:
	game.hud.set_touch_mode(touch_mode)
	game.player = game.ship_position()
	game.scout.position = game.player
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()
	if touch_mode:
		game.action_button.pressed.emit()
	else:
		game.interact()
	check(game.planet_menu.visible,"Fresh rocket did not open destination picker")
	check(not game.planet_menu.buttons[destination].disabled,"Destination remains locked")
	game.planet_menu.buttons[destination].pressed.emit()
	check(game.flight == game.Flight.IGNITION,"Destination selection did not start takeoff")
	game.advance_flight(10)
	check(game.world == destination and game.flight == game.Flight.IDLE and game.scout.visible,"Early flight did not finish with a playable landing")
	check(not game.rocket.damaged,"Early travel restored the broken rocket")
	unearned(game)

func run() -> void:
	check(not ProjectSettings.get_setting("gameplay/rocket_repair_required",true),"Production repair quest is enabled")
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.story.set_process(false)
	check(game.story.launch_ready() and not game.rocket.damaged,"Fresh rocket is broken or locked")
	game.rocket._process(2)
	check(game.rocket.smoke.is_empty(),"Working rocket emits damage smoke")
	unearned(game)
	var nova = game.npcs.filter(func(n): return n.name == "Nova")[0]
	game.story.complete.finn = true
	game.fog.observe(0,nova.position)
	game.refresh_ui()
	check(not nova.visible and not nova.can_talk() and not game.story.available("nova"),"Paused repair NPC becomes available")
	game.story.complete.clear()
	check(game.story.entries().size() == 6 and not game.story.entries().any(func(e): return e.id == "nova"),"Paused quest remains in journal")
	game.mission_journal.open()
	check(game.mission_journal.summary.text.begins_with("0 / 6") and game.mission_journal.rows.size() == 10,"Journal count or optional quests are incorrect")
	game.mission_journal.dismiss()
	check(not game.story.prop_exists("engine"),"Paused quest still spawns its engine part")
	check(not game.story.closing("iris").contains("Nova") and not game.story.closing("finn").contains("Nova"),"Other quests still direct players to the paused mission")
	for trip in [[1,false],[0,false],[2,true],[0,true]]:
		board(game,trip[0],trip[1])
	await TRAVEL.enter(game,4,true)
	check(not game.story.props.has("engine"),"Unused engine part appears in Crystal Depths")
	await TRAVEL.enter(game,0,false)
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await process_frame
	game = current_scene
	game.set_process(false)
	check(game.world == 0 and game.story.launch_ready() and not game.rocket.damaged,"Confirmed reset restores the travel gate")
	unearned(game)
	board(game,2,false)
	if failures == 0: print("PASS: fresh keyboard/touch rocket access, both planets and return flights without quest rewards, six-story journal with optional quests, hidden Nova/engine, no broken-rocket smoke and confirmed fresh reset")
	quit(1 if failures else 0)
