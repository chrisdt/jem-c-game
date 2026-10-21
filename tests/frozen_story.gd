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
	var person = game.frost_story.npcs.filter(func(n): return n.role == role)[0]
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
	var spec: Dictionary = game.frost_story.PROPS[id]
	await TRAVEL.enter(game,spec.region,spec.cave)
	game.refresh_ui()
	check(game.frost_story.props.has(id),"Missing frozen quest item: "+id)
	if not game.frost_story.props.has(id): return
	place(game,game.frost_story.props[id].position)
	game.space_action()
	check(game.frost_story.collected.has(id),"Space did not collect "+id)
func gather(game) -> void:
	game.trial.selected_tool = 0
	for i in game.rocks.size():
		var rock: Dictionary = game.rocks[i]
		if rock.cave != game.underground or rock.hp <= 0: continue
		place(game,rock.pos)
		game.start_mining(i)
		check(game.mining_target == i,"Could not mine frozen material")
		game.advance_mining(20)
		check(rock.hp == 0,"Frozen material did not finish")
func approach(game, yeti, distance: float) -> Vector2:
	for ray in 24:
		var point: Vector2 = yeti.position+Vector2.from_angle(ray*TAU/24)*distance
		if game.trial.floor_at(point) and not game.trial.safe_at(point) and game.trial.clear_line(point,yeti.position): return point
	return Vector2.INF
func check_equipment(game) -> void:
	check(game.hud.equip_slots.all(func(b): return b.visible),"Equipment bar disappeared on another planet")
	check(game.hud.material_icons.size() == 7 and game.hud.material_icons.all(func(i): return i.visible),"Collected material types disappeared")
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
		game.face_direction(direction)
		game.trial.selected_tool = 1
		game.trial.jab_cooldown = 0
		check(game.trial.start_jab(),"Frostfang cannot jab in outfit/world "+str(game.world))
		game.trial.advance(0.12)
		var texture: Texture2D = game.scout.sprite_frames.get_frame_texture(game.scout.animation,game.scout.frame)
		check(texture.atlas == (game.FROST_ART.MINER_JAB if game.world == 0 else game.FROST_ART.SPACE_JAB),"Wrong sword outfit")
		var bottom: float = (texture.get_height()*0.5+game.scout.offset.y)*game.scout.scale.y
		check(absf(bottom-20) < 0.1,"Sword jab floats off its boot anchor")
		game.trial.advance(0.5)
		check(not str(game.scout.animation).begins_with("jab"),"Sword stays visible after attack")
		game.trial.equip(0)
		game.face_direction(direction)
		game.restore_walk_visual()
		check(game.scout.material != null,"Crystal drill lost its crystal cutting head")
		game.set_mining_pose(1)
		check(game.scout.material != null and game.mining_rate() > 1.6,"Drill upgrade does not change art and mining speed")
		game.restore_walk_visual()
func run() -> void:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.frost_story.set_process(false)
	for person in game.frost_story.npcs: person.set_process(false)
	check(game.story.launch_ready() and game.frost_story.entries().size() == 4,"Fresh rocket or frozen quest list is wrong")
	# Earn starter crafts through the existing workbench API. Earth gathering
	# and exact initial costs are covered separately by earth_story.gd.
	game.ore = 8
	game.trial.wood = 2
	place(game,game.CAMP)
	game.interact()
	game.camp_menu.craft("sword")
	check(not game.camp_menu.cards[1].visible and game.camp_menu.cards[0].visible,"Owned sword recipe is still shown")
	game.camp_menu.craft("drill")
	check(game.camp_menu.cards.all(func(c): return not c.visible) and game.camp_menu.finished_label.visible,"Owned starter recipes remain visible")
	game.camp_menu.dismiss()
	game.travel_to_other_planet(1)
	game.advance_flight(10)
	check(game.world == 1 and game.trial.sword_owned and game.upgraded,"Starter equipment was lost during travel")
	place(game,game.ICE_CAMP)
	game.camp_menu.open()
	check(not game.camp_menu.visible and not game.at_workbench() and not game.craft_item("drill"),"Earth recipes are available at the frozen camp")
	game.mission_journal.open()
	check(game.mission_journal.rows.size() == 4 and game.mission_journal.summary.text.begins_with("0 / 4"),"Frozen quests were not substituted for Earth quests")
	game.mission_journal.dismiss()
	for id in ["beacon_west","beacon_east","beacon_aurora"]: await pickup(game,id)
	await TRAVEL.enter(game,0,false)
	conversation(game,"pip")
	check(game.frost_story.done("pip"),"Pip did not recognize early recovered fragments")
	# All five surfaces and three mines contain enough real resources for both
	# upgrades: 13 common and 3 rare, requiring 9 common and all 3 rare.
	for region in 5:
		await TRAVEL.enter(game,region,false)
		gather(game)
		if game.regions().has_mine(region):
			await TRAVEL.enter(game,region,true)
			gather(game)
	check(game.frost_ore == 13 and game.amethysts == 3,"Frozen resource budget is not achievable")
	await pickup(game,"heart_crystal")
	await TRAVEL.enter(game,1,false)
	var before := Vector2i(game.frost_ore,game.amethysts)
	conversation(game,"nix",true)
	check(not game.frost_story.frostfang and before == Vector2i(game.frost_ore,game.amethysts),"Cancelled sword upgrade spent resources")
	conversation(game,"nix")
	check(game.frost_story.frostfang and game.frost_ore == 9 and game.amethysts == 2,"Frostfang did not cost exactly 4 frost ore and 1 amethyst")
	await pickup(game,"coupling")
	await TRAVEL.enter(game,2,false)
	conversation(game,"tavi")
	check(game.frost_story.crystal_drill and game.frost_ore == 4 and game.amethysts == 0,"Crystal Drill did not cost exactly 5 frost ore and 2 amethysts")
	game.frost_story.begin("tavi")
	game.frost_story.finish("tavi",true)
	check(game.frost_ore == 4 and game.amethysts == 0,"Completed upgrade charged twice")
	check_equipment(game)
	await TRAVEL.enter(game,4,false)
	var yeti = game.frost_story.yetis[0]
	var spot := approach(game,yeti,65)
	check(spot.is_finite(),"Guardian yeti has no reachable attack approach")
	place(game,spot)
	yeti.seen = true
	yeti.fade = 0.75
	game.trial.invulnerable = 0
	game.trial.health = 10
	yeti.advance(0.1)
	check(yeti.state == "warn" and game.trial.health == 10,"Yeti skipped its warning")
	yeti.advance(0.65)
	check(game.trial.health == 10,"Yeti attacked before its warning ended")
	yeti.advance(0.3)
	check(game.trial.health == 7,"Yeti did not deal exactly one and a half hearts")
	yeti.advance(0.2)
	check(game.trial.health == 7,"Yeti repeated contact damage")
	game.trial.invulnerable = 0
	yeti.state = "warn"
	yeti.clock = 0
	yeti.target = game.player
	var dodge := approach(game,yeti,165)
	check(dodge.is_finite(),"No safe dodge destination near the yeti")
	place(game,dodge)
	yeti.advance(0.9)
	check(game.trial.health == 7,"Dodging the yeti's locked warning aim still caused damage")
	place(game,spot)
	game.trial.selected_tool = 1
	game.face_direction((yeti.position-game.player).normalized())
	game.trial.jab_cooldown = 0
	game.trial.start_jab()
	game.trial.advance(0.12)
	check(yeti.health == 9 and yeti.slow > 0,"Frostfang does not deal seven damage and chill the yeti")
	game.trial.advance(0.5)
	for strike in 2:
		game.trial.jab_cooldown = 0
		game.trial.start_jab()
		game.trial.advance(0.5)
	check(yeti.health == 0 and yeti.state == "puff","Yeti did not defeat into a snowy puff")
	yeti.advance(0.8)
	check(not yeti.visible,"Defeated yeti did not disappear")
	place(game,game.frost_story.props.cache.position)
	game.trial.equip(0)
	game.space_action()
	game.frost_story._process(0.9)
	game.mission_journal.open()
	check(not game.frost_story.working() and is_equal_approx(game.frost_story.work,0.9),"Quest popup did not pause cache drilling")
	game.mission_journal.dismiss()
	game.cooldown = 0
	game.space_action()
	game.frost_story._process(1.2)
	check(game.frost_story.cache_open,"Crystal Drill did not open the frozen cache")
	await TRAVEL.enter(game,3,false)
	conversation(game,"eira")
	check(game.frost_story.entries().all(func(e): return e.done),"Frozen expedition did not finish all four missions")
	game.travel_to_other_planet(0)
	game.advance_flight(10)
	check_equipment(game)
	# Imported upgrades affect real Earth combat and mining, not only HUD art.
	var snake = game.trial.snakes[0]
	var earth_approach := approach(game,snake,60)
	check(earth_approach.is_finite(),"No Earth combat approach for the imported sword")
	place(game,earth_approach)
	snake.seen = true
	game.trial.selected_tool = 1
	game.face_direction((snake.position-game.player).normalized())
	game.trial.jab_cooldown = 0
	game.trial.start_jab()
	game.trial.advance(0.12)
	check(snake.health == 2 and snake.get_meta("frost_slow",0.0) > 0,"Frozen sword lost its stronger damage/chill on Earth")
	game.trial.advance(0.5)
	game.trial.equip(0)
	var deposit: int = game.rocks.find_custom(func(r): return not r.cave and not r.hard and r.hp > 0)
	place(game,game.rocks[deposit].pos)
	game.start_mining(deposit)
	game.advance_mining(1.19)
	check(game.rocks[deposit].hp > 0,"Crystal Drill awards before its real 1.2-second duration")
	game.advance_mining(0.02)
	check(game.rocks[deposit].hp == 0,"Crystal Drill does not shorten real Earth mining")
	check(game.frost_story.npcs.all(func(p): return not p.visible),"Snow Sprites appeared on Earth")
	game.mission_journal.open()
	check(game.mission_journal.rows.size() == 10 and game.mission_journal.summary.text.begins_with("0 / 6"),"Earth's independent quests were changed")
	game.mission_journal.dismiss()
	game.travel_to_other_planet(2)
	game.advance_flight(10)
	check_equipment(game)
	game.travel_to_other_planet(1)
	game.advance_flight(10)
	await TRAVEL.enter(game,4,false)
	check(game.frost_story.yetis[0].health == 0 and game.frost_story.cache_open,"Travel reset the guardian or frozen cache")
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await process_frame
	check(not current_scene.frost_story.frostfang and not current_scene.frost_story.crystal_drill and current_scene.frost_story.complete.is_empty() and current_scene.story.launch_ready(),"Fresh reset inherited frozen quest equipment or locked travel")
	if failures == 0: print("PASS: four Snow Sprite quests, real affordable gathering, cancellation/exact one-time recipes, global materials and equipment, Earth-only starter recipes and hidden built cards, both grounded outfits and all jab directions, stronger slowing sword, faster drill, warned 1.5-heart yeti/puff, retained cache drilling, independent journals, travel memory and reset")
	quit(1 if failures else 0)
