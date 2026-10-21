extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func press(code: Key) -> void:
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func arrive(game, point: Vector2) -> void:
	game.player = point
	game.scout.position = point
	game.cooldown = 0
	game.trial.advance(0.6)
	game.update_exploration()
	game.wood_supplies._process(0.8)
	game.story._process(0.8)
	game.refresh_ui()

func pickups(game) -> void:
	var pile: Dictionary = game.wood_supplies.piles[0]
	game.player = pile.position
	var before: int = game.trial.wood
	await press(KEY_SPACE)
	check(game.trial.wood == before,"Space collected undiscovered wood")
	game.cancel_mining()
	arrive(game,pile.position)
	check(game.hud.context_button.text.contains("E / Space"),"Wood prompt omits Space")
	await press(KEY_SPACE)
	check(pile.collected and game.trial.wood == before+1 and game.trial.jab_time < 0,"Space attacked instead of picking up wood")
	var repeated := InputEventKey.new()
	repeated.keycode = KEY_SPACE
	repeated.pressed = true
	repeated.echo = true
	Input.parse_input_event(repeated)
	await process_frame
	check(game.trial.wood == before+1 and game.trial.jab_time < 0,"Held Space repeated a pickup or started an unintended attack")
	await TRAVEL.enter(game,1,false)
	for i in 2:
		pile = game.wood_supplies.piles[i]
		arrive(game,pile.position)
		before = game.trial.wood
		if i == 1:
			game.trial.sword_owned = true
			game.trial.equip(1)
		await press(KEY_E if i == 0 else KEY_SPACE)
		check(pile.collected and game.trial.wood == before+1 and game.trial.jab_time < 0,"E/Space gathering failed with the pick or equipped sword")
	# The seal kit is a true pickup, independent of the equipped weapon.
	var kit: Vector2 = game.story.props.seals.position
	arrive(game,kit+Vector2(150,0))
	await press(KEY_SPACE)
	check(not game.story.seal_kit,"Space collected a quest object outside its range")
	arrive(game,kit)
	game.hud.help.show()
	await press(KEY_SPACE)
	check(not game.story.seal_kit,"Space collected an object behind help")
	game.hud.help.hide()
	game.mission_journal.open()
	await press(KEY_SPACE)
	check(not game.story.seal_kit,"Space collected an object behind Quests")
	game.mission_journal.dismiss()
	game.cooldown = 0
	game.refresh_ui()
	check(game.hud.context_button.text.contains("E / Space"),"Quest pickup prompt omits Space")
	await press(KEY_SPACE)
	check(game.story.seal_kit and not game.story.props.seals.visible and game.trial.jab_time < 0,"Space with the sword failed to collect the seal kit")
	# Protected objects must not swallow the combat key.
	arrive(game,game.story.props.supplies.position)
	await press(KEY_SPACE)
	check(game.trial.jab_time >= 0 and not game.story.cache_held,"A guarded supply box blocked the sword attack or bypassed its snake")
	game.trial.advance(0.6)
	for snake in game.trial.snakes:
		if snake.spawn_id == "1/1": snake.health = 0
	game.cooldown = 0
	await press(KEY_SPACE)
	check(game.story.cache_held and game.trial.jab_time < 0,"A safe supply box cannot be recovered with Space")
	# Quest objects needing drilling follow the same tool gate and pause key.
	arrive(game,game.story.interaction_position("rockfall")+Vector2(-60,-30))
	await press(KEY_SPACE)
	check(game.trial.jab_time >= 0 and not game.story.working(),"Sword Space started drilling a quest object")
	game.trial.advance(0.6)
	game.trial.equip(0)
	game.cooldown = 0
	await press(KEY_SPACE)
	check(not game.story.working() and not game.story.quarry_open and game.message.contains("hand drill"),"Space bypassed the rockfall's drill requirement")
	game.upgraded = true
	game.cooldown = 0
	await press(KEY_SPACE)
	check(game.story.job == "rockfall" and game.trial.jab_time < 0,"Space failed to start drilling the quest object")
	game.story.advance_actions(0.7)
	await press(KEY_SPACE)
	check(not game.story.working() and not game.story.quarry_open,"Space failed to pause quest-object drilling")
	game.cooldown = 0
	await press(KEY_SPACE)
	game.story.advance_actions(1.31)
	check(game.story.quarry_open,"Space failed to resume the quest object with retained work")
	await TRAVEL.enter(game,0,false)
	game.upgraded = false
	game.trial.sword_owned = false
	game.trial.selected_tool = 0
	game.cooldown = 0

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.trial.invulnerable = 10000
	await pickups(game)
	game.player = game.rocks[0].pos
	game.update_exploration()
	game.refresh_ui()
	check(game.hud.context_button.text.contains("E / Space"),"Mining prompt omits Space")
	await press(KEY_SPACE)
	check(game.mining_target == 0 and game.trial.jab_time < 0,"Space attacked instead of mining with the pick")
	game.advance_mining(0.8)
	await press(KEY_SPACE)
	check(game.mining_target == -1 and game.ore == 0,"Space did not cancel mining")
	await press(KEY_SPACE)
	game.advance_mining(2)
	check(game.ore == 1 and game.rocks[0].hp == 0,"Space mining did not award exactly one copper after its duration")
	game.player = game.CAMP
	await press(KEY_SPACE)
	check(game.trial.jab_time >= 0 and game.mining_target == -1,"Space no longer attacks away from ore")
	game.trial.advance(0.5)
	game.trial.sword_owned = true
	game.trial.equip(1)
	game.player = game.rocks[1].pos
	game.update_exploration()
	await press(KEY_SPACE)
	check(game.trial.jab_time >= 0 and game.mining_target == -1,"Sword Space did not remain an attack near ore")
	game.trial.advance(0.5)
	game.trial.equip(0)
	game.cooldown = 0
	await press(KEY_E)
	check(game.mining_target == 1,"E no longer starts the same mining action")
	await press(KEY_SPACE)
	check(game.mining_target == -1,"Space did not cancel an E-started job")
	game.cooldown = 0
	await press(KEY_SPACE)
	await press(KEY_E)
	check(game.mining_target == -1,"E did not cancel a Space-started job")
	await TRAVEL.enter(game,0,true)
	var rare: int = game.rocks.find_custom(func(rock): return rock.hard)
	game.player = game.rocks[rare].pos
	game.update_exploration()
	await press(KEY_SPACE)
	check(game.mining_target == -1 and game.trial.jab_time < 0 and game.message.contains("Too tough"),"Space bypassed the rare mineral's drill requirement")
	game.upgraded = true
	await press(KEY_SPACE)
	check(game.mining_target == rare and game.scout.sprite_frames == game.DRILL_VISUAL.MINING[0],"Space failed to use the fitted drill in a mine")
	await press(KEY_SPACE)
	game.hud.help.show()
	await press(KEY_SPACE)
	check(game.mining_target == -1 and game.trial.jab_time < 0,"Space mined beneath help")
	game.hud.help.hide()
	await TRAVEL.enter(game,0,false)
	for world in [1,2]:
		TRAVEL.depart(game,world)
		game.advance_flight(10)
		game.player = game.rocks[0].pos
		game.update_exploration()
		game.cooldown = 0
		await press(KEY_SPACE)
		check(game.mining_target == 0,"Off-world Space mining stopped working")
		game.advance_mining(3)
		check((game.frost_ore if world == 1 else game.gold_ore) == 1,"Off-world Space awarded the wrong material")
	game.queue_free()
	await process_frame
	await process_frame
	if failures == 0: print("PASS: real keyboard Space/E wood and quest pickups, range/discovery/help/journal/echo guards, both weapons, protected-box combat, quest drilling requirements and retained work, mining cancellation and exact rewards/timing, sword attacks near ore, rare drill gate, fitted drill poses and both off-world mining actions")
	quit(1 if failures else 0)
