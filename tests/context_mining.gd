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

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.trial.invulnerable = 10000
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
		game.travel_to_other_planet(world)
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
	if failures == 0: print("PASS: real keyboard Space/E mining and cancellation, one-time rewards/timing, sword attacks near ore, mining-tool attacks away from ore, rare drill gate, fitted drill poses, help blocking and both off-world mining actions")
	quit(1 if failures else 0)
