extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)
func place(game, point: Vector2) -> void:
	game.player = point
	game.scout.position = point
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()
func conversation(game, role: String, cancel := false) -> void:
	var person = game.ember_story.npcs.filter(func(n): return n.role == role)[0]
	place(game,person.position+Vector2(0,30))
	game.interact()
	check(game.dialogue_open(),"Cannot talk to "+role)
	if cancel:
		game.character_bubble.dismiss()
		return
	for page in 8:
		if not game.dialogue_open(): break
		game.character_bubble.advance()
	check(not game.dialogue_open(),"Dialogue did not finish for "+role)
func pickup(game, id: String) -> void:
	var spec: Dictionary = game.ember_story.PROPS[id]
	await TRAVEL.enter(game,spec.region,spec.cave)
	game.refresh_ui()
	check(game.ember_story.props.has(id),"Missing Sunforge quest item: "+id)
	if not game.ember_story.props.has(id): return
	place(game,game.ember_story.props[id].position)
	game.space_action()
	check(game.ember_story.collected.has(id),"Space did not collect "+id)
func gather(game) -> void:
	game.trial.selected_tool = 0
	for i in game.rocks.size():
		var rock: Dictionary = game.rocks[i]
		if rock.cave != game.underground or rock.hp <= 0: continue
		place(game,rock.pos)
		game.start_mining(i)
		check(game.mining_target == i,"Could not mine desert material")
		game.advance_mining(20)
		check(rock.hp == 0,"Frozen material did not finish")
func approach(game, yeti, distance: float) -> Vector2:
	for ray in 24:
		var point: Vector2 = yeti.position+Vector2.from_angle(ray*TAU/24)*distance
		if game.trial.floor_at(point) and not game.trial.safe_at(point) and game.trial.clear_line(point,yeti.position): return point
	return Vector2.INF
func equipment(game) -> void:
	check(game.trial.sword_damage() == 10 and not game.trial.weapon_is_frost(),"Sunfang was downgraded or inherits Frostfang chill")
	check(game.hud.equip_slots.all(func(b): return b.visible),"Earned antidote/equipment disappears between worlds")
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
		game.face_direction(direction)
		game.trial.selected_tool = 1
		game.trial.jab_cooldown = 0
		check(game.trial.start_jab(),"Sunfang cannot jab")
		game.trial.advance(0.12)
		check(game.scout.material != null and game.scout.material.shader == game.EMBER_ART.SHADER,"Sunfang lost its ruby blade in outfit/world "+str(game.world))
		var texture: Texture2D = game.scout.sprite_frames.get_frame_texture(game.scout.animation,game.scout.frame)
		var bottom: float = (texture.get_height()*0.5+game.scout.offset.y)*game.scout.scale.y
		check(absf(bottom-20) < 0.1,"Sunfang jab floats away from boot anchor")
		game.trial.advance(0.5)
		check(not str(game.scout.animation).begins_with("jab"),"Sword stays visible after jab")
		game.trial.equip(0)
		game.face_direction(direction)
		game.restore_walk_visual()
		check(game.scout.material != null and game.scout.material.shader == game.EMBER_ART.SHADER,"Magma Drill lost ruby tip")
		game.set_mining_pose(1)
		check(game.scout.material != null and game.mining_rate() > 2.2,"Magma Drill lost mining art or speed")
		game.restore_walk_visual()
func run() -> void:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.frost_story.set_process(false)
	game.ember_story.set_process(false)
	for person in game.ember_story.npcs: person.set_process(false)
	check(game.story.launch_ready() and not game.hud.equip_slots[2].visible,"Rocket locked or unearned antidote shown")
	for person in game.ember_story.npcs:
		check(absf(person.height-87.45) < 0.1 and person.illustration.offset.y < 0,"Sunstone Folk height or foot anchor differs from Sunny")
	game.ore = 8
	game.trial.wood = 2
	place(game,game.CAMP)
	game.interact()
	game.camp_menu.craft("sword")
	game.camp_menu.craft("drill")
	game.camp_menu.dismiss()
	game.travel_to_other_planet(2)
	game.advance_flight(10)
	check(game.world == 2 and game.trial.sword_owned and game.upgraded,"Lost starter crafts in desert travel")
	place(game,game.camp_position())
	game.camp_menu.open()
	check(not game.camp_menu.visible and not game.at_workbench(),"Earth starter recipes available on desert")
	game.mission_journal.open()
	check(game.mission_journal.rows.size() == 4 and game.mission_journal.summary.text.begins_with("0 / 4"),"Missing desert journal")
	game.mission_journal.dismiss()
	for id in ["cooler_dune","cooler_oasis","cooler_arch"]: await pickup(game,id)
	await TRAVEL.enter(game,0,false)
	conversation(game,"sol",true)
	check(not game.ember_story.done("sol"),"Cancelled cooling quest completed")
	conversation(game,"sol")
	check(game.ember_story.done("sol") and game.ember_story.props.has("station_camp"),"Cooling station not repaired")
	for id in ["plant_oasis","plant_arch","flask"]: await pickup(game,id)
	await TRAVEL.enter(game,2,false)
	conversation(game,"luma")
	check(game.ember_story.antidote_owned and game.ember_story.antidote_doses == 3,"Luma did not award canteen")
	check(not game.ember_story.use_antidote() and game.ember_story.antidote_doses == 3,"Antidote wasted without venom")
	# Use actual limited desert deposits, not fabricated forge balances.
	for region in 5:
		await TRAVEL.enter(game,region,false)
		gather(game)
		if game.regions().has_mine(region):
			await TRAVEL.enter(game,region,true)
			gather(game)
	check(game.gold_ore == 13 and game.rubies == 3,"Desert resource budget cannot support both upgrades")
	await pickup(game,"core")
	await TRAVEL.enter(game,1,false)
	var before := Vector2i(game.gold_ore,game.rubies)
	conversation(game,"brasa",true)
	check(not game.ember_story.sunfang and before == Vector2i(game.gold_ore,game.rubies),"Cancelled forge spent materials")
	conversation(game,"brasa")
	check(game.ember_story.sunfang and not game.ember_story.magma_drill and not game.ember_story.done("brasa"),"First forge incorrectly completed both upgrades")
	check(game.gold_ore == 10 and game.rubies == 2 and game.ember_story.action("brasa") == "Build Magma Drill","Built sword recipe repeated or wrong costs")
	check(not "Sunfang Sword:" in " ".join(game.ember_story.pages("brasa")) and "Remaining upgrade:" in game.ember_story.entries()[2].detail,"Completed recipe is still offered in dialogue/journal")
	conversation(game,"brasa")
	check(game.ember_story.magma_drill and game.ember_story.done("brasa") and game.gold_ore == 6 and game.rubies == 1,"Magma Drill did not cost 4 gold and 1 ruby")
	game.ember_story.begin("brasa")
	game.ember_story.finish("brasa",true)
	check(game.gold_ore == 6 and game.rubies == 1,"Completed forge charged twice")
	equipment(game)
	await TRAVEL.enter(game,4,false)
	var scorpion = game.ember_story.scorpions[0]
	var spot := approach(game,scorpion,65)
	check(spot.is_finite(),"No reachable scorpion combat approach")
	place(game,spot)
	scorpion.seen = true
	scorpion.fade = 0.75
	game.trial.invulnerable = 0
	game.trial.health = 10
	scorpion.advance(0.1)
	check(scorpion.state == "warn" and game.trial.health == 10,"Scorpion skipped warning")
	scorpion.advance(0.70)
	check(game.trial.health == 10,"Sting landed before warning elapsed")
	scorpion.advance(0.3)
	check(game.trial.health == 7 and game.trial.poison_remaining == 3,"Sting failed 1.5 hearts plus venom")
	game.trial.advance(1)
	var poison: float = game.trial.poison_remaining
	game.trial.apply_poison()
	check(is_equal_approx(game.trial.poison_remaining,poison),"Venom stacks or refreshes")
	game.mission_journal.open()
	game.trial.advance(10)
	check(is_equal_approx(game.trial.poison_remaining,poison),"Venom timer continues through quest popup")
	check(not game.ember_story.use_antidote(),"Antidote used behind modal")
	game.mission_journal.dismiss()
	game.refresh_ui()
	check(game.hud.poison_label.visible and not game.hud.equip_slots[2].disabled,"Venom HUD/canteen unavailable")
	game.hud.equip_slots[2].pressed.emit()
	check(game.trial.poison_remaining == 0 and game.ember_story.antidote_doses == 2,"Touch antidote did not clear venom")
	game.trial.advance(4)
	check(game.trial.health == 7,"Cured poison still dealt damage")
	game.trial.apply_poison()
	game.trial.advance(2.99)
	check(game.trial.health == 7,"Venom ticked early")
	game.trial.advance(0.02)
	check(game.trial.health == 6 and game.trial.poison_remaining == 0,"Venom did not deal exactly half a heart once")
	game.trial.advance(5)
	check(game.trial.health == 6,"Venom repeats after expiry")
	game.trial.apply_poison()
	game.hud.help.show()
	game.trial.advance(10)
	check(game.trial.poison_remaining == 3,"Help does not pause venom")
	game.hud.help.hide()
	game.trial.clear_poison()
	# Claw is distinct from the sting and does not poison.
	game.trial.invulnerable = 0
	scorpion.state = "warn"
	scorpion.clock = 0
	scorpion.target = game.player
	scorpion.sting = false
	scorpion.advance(0.7)
	check(game.trial.health == 4 and game.trial.poison_remaining == 0,"Claw has wrong damage or applies poison")
	game.trial.invulnerable = 0
	scorpion.state = "warn"
	scorpion.clock = 0
	scorpion.target = game.player
	scorpion.sting = true
	var dodge := approach(game,scorpion,160)
	place(game,dodge)
	scorpion.advance(1)
	check(game.trial.health == 4 and game.trial.poison_remaining == 0,"Dodging locked sting aim still hurt")
	place(game,spot)
	game.trial.selected_tool = 1
	game.face_direction((scorpion.position-game.player).normalized())
	for strike in 3:
		game.trial.jab_cooldown = 0
		game.trial.start_jab()
		game.trial.advance(0.5)
	check(scorpion.health == 0 and scorpion.state == "puff","Sunfang did not defeat 30-health guardian in three jabs")
	# A fatal sting must not poison the newly recovered full-health player.
	game.trial.health = 2
	game.trial.invulnerable = 0
	scorpion.health = 30
	scorpion.state = "warn"
	scorpion.clock = 0
	scorpion.target = game.player
	scorpion.sting = true
	scorpion.advance(1)
	check(game.trial.health == 10 and game.trial.poison_remaining == 0,"Fatal sting poisoned recovery")
	scorpion.health = 0
	scorpion.change("puff")
	game.trial.health = 4
	scorpion.advance(0.8)
	check(not scorpion.visible,"Scorpion did not disappear in puff")
	place(game,game.ember_story.props.observatory.position)
	game.trial.equip(0)
	game.space_action()
	game.ember_story._process(0.9)
	game.mission_journal.open()
	check(not game.ember_story.working() and not game.ember_story.observatory_open,"Journal did not cancel observatory job")
	game.mission_journal.dismiss()
	game.cooldown = 0
	game.space_action()
	game.ember_story._process(2.1)
	check(game.ember_story.observatory_open,"Magma Drill failed to recover star map")
	await TRAVEL.enter(game,3,false)
	conversation(game,"orin")
	check(game.ember_story.entries().all(func(e): return e.done),"Desert quests did not all complete")
	await TRAVEL.enter(game,0,false)
	place(game,game.camp_position())
	game.trial.apply_poison()
	game.ember_story._process(1.6)
	check(game.trial.poison_remaining == 0 and game.ember_story.antidote_doses == 3 and game.trial.health == 5,"Cooler did not heal, cure and refill")
	game.travel_to_other_planet(0)
	game.advance_flight(10)
	# Lower tier story completions must never downgrade later equipment.
	game.frost_story.frostfang = true
	game.frost_story.crystal_drill = true
	game.story.sword_improved = true
	game.story.drill_improved = true
	game.refresh_ui()
	equipment(game)
	check(game.ember_story.npcs.all(func(p): return not p.visible),"Sunstone Folk leaked onto Earth")
	# Use the imported blade against a real Earth snake and the drill against
	# a real copper deposit, verifying the gameplay effect beyond icon state.
	var snake = game.trial.snakes[0]
	place(game,approach(game,snake,60))
	snake.seen = true
	game.trial.selected_tool = 1
	game.face_direction((snake.position-game.player).normalized())
	game.trial.jab_cooldown = 0
	game.trial.start_jab()
	game.trial.advance(0.12)
	check(snake.health == 0,"Sunfang lost ten-damage power on Earth")
	game.trial.advance(0.5)
	game.trial.equip(0)
	var deposit: int = game.rocks.find_custom(func(r): return not r.cave and not r.hard and r.hp > 0)
	place(game,game.rocks[deposit].pos)
	game.start_mining(deposit)
	game.advance_mining(0.89)
	check(game.rocks[deposit].hp > 0,"Magma Drill awards before 0.9-second duration")
	game.advance_mining(0.02)
	check(game.rocks[deposit].hp == 0,"Magma Drill failed to shorten real Earth mining")
	game.mission_journal.open()
	check(game.mission_journal.rows.size() == 10,"Earth journal replaced by desert quests")
	game.mission_journal.dismiss()
	game.travel_to_other_planet(1)
	game.advance_flight(10)
	equipment(game)
	check(game.quest_completed() == 0,"Desert quest completion leaked into Frost Canyon")
	game.travel_to_other_planet(2)
	game.advance_flight(10)
	await TRAVEL.enter(game,4,false)
	check(game.ember_story.scorpions[0].health == 0 and game.ember_story.observatory_open,"Travel reset scorpion or observatory")
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await process_frame
	check(not current_scene.ember_story.sunfang and not current_scene.ember_story.magma_drill and not current_scene.ember_story.antidote_owned and current_scene.trial.poison_remaining == 0 and current_scene.ember_story.complete.is_empty(),"Reset inherited desert quest/venom state")
	if failures == 0: print("PASS: four Sunstone quests, real affordable materials, separate one-time forge recipes/cancellation, both outfits/all directions/global upgrade priority, warned sting/claw/dodge, nonstacking paused one-tick venom, touch antidote/refill/shade, guardian puff/observatory, independent journals, travel memory/reset")
	quit(1 if failures else 0)
