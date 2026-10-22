extends SceneTree
const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)
func balance(game) -> Vector2i:
	return Vector2i(game.frost_ore,game.amethysts) if game.world == 1 else Vector2i(game.gold_ore,game.rubies)
func place(game, point: Vector2) -> void:
	game.player = point
	game.scout.position = point
	game.cooldown = 0
	game.trial.jab_time = -1
	game.update_exploration()
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.companion.set_process(false)
	game.frost_story.set_process(false)
	game.ember_story.set_process(false)
	for world in [1,2]:
		game.travel_to_other_planet(world)
		game.advance_flight(10)
		for region in [0,1,4]:
			await TRAVEL.enter(game,region,true)
			for hard in [false,true]:
				var index: int = game.rocks.find_custom(func(r): return r.cave and r.hard == hard)
				var rock: Dictionary = game.rocks[index]
				check(rock.seconds == (5.0 if hard else 3.0),"Wrong off-world mining duration")
				place(game,rock.pos)
				game.upgraded = false
				if hard:
					game.start_mining(index)
					check(game.mining_target == -1,"Rare material bypassed hand drill")
				game.upgraded = true
				game.trial.selected_tool = 0
				game.start_mining(index)
				game.advance_mining(0.75)
				game.interact()
				check(game.mining_target == -1 and is_equal_approx(rock.work,0.75),"E pause lost deposit work")
				game.start_mining(index)
				check(is_equal_approx(game.mining_elapsed,0.75),"Resume restarted paused mining")
				game.advance_mining(0.25)
				game.move_player(Vector2.LEFT,0.01)
				check(game.mining_target == -1 and is_equal_approx(rock.work,1.0),"Walking lost work")
				place(game,rock.pos)
				game.start_mining(index)
				game.advance_mining(0.25)
				game.trial.invulnerable = 0
				game.trial.health = 10
				check(game.trial.hurt_player(1),"Deposit is missing unsafe damage fixture")
				check(game.mining_target == -1 and is_equal_approx(rock.work,1.25),"Enemy interruption lost work")
				var before := balance(game)
				await TRAVEL.enter(game,region,false)
				await TRAVEL.enter(game,region,true)
				check(game.rocks[index] == rock and is_equal_approx(rock.work,1.25),"Area return reset partial mining")
				place(game,rock.pos)
				game.start_mining(index)
				check(is_equal_approx(game.mining_elapsed,1.25),"Area return did not resume remaining work")
				game.advance_mining(rock.seconds-1.26)
				check(balance(game) == before and rock.hp > 0,"Resumed material awarded early")
				game.advance_mining(0.02)
				var reward := Vector2i(0,1) if hard else Vector2i(1,0)
				check(balance(game) == before+reward and rock.hp == 0,"Resumed material did not award once")
				game.start_mining(index)
				game.advance_mining(10)
				check(balance(game) == before+reward,"Mined deposit awarded twice")
				for other in game.rocks:
					if other != rock and other.hp > 0: check(other.get("work",0.0) == 0.0,"Progress leaked to a different deposit")
		await TRAVEL.enter(game,0,false)
	# Drill tiers still shorten the five-second rare job.
	game.frost_story.crystal_drill = true
	check(is_equal_approx(5.0/game.mining_rate(),3.0),"Crystal Drill speed bonus changed")
	game.ember_story.magma_drill = true
	check(is_equal_approx(5.0/game.mining_rate(),2.25),"Magma Drill speed bonus changed")
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: 12 Frost/Ember deposits resume after E, movement, damage and area reload; five-second rares, tool gates, isolated work and one-time rewards")
	quit(1 if failures else 0)
