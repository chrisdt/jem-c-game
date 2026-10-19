extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		if failures < 25: push_error(description)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.trial.invulnerable = 10000
	check(not game.trial.sword_owned and game.trial.selected_tool == 0,"The sword is still granted for free")
	game.trial.equip(1)
	check(game.trial.selected_tool == 0 and game.hud.equip_slots[1].disabled,"Uncrafted sword can be equipped")
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	check(game.camp_menu.visible and not game.upgraded,"Camp should open the workbench without buying automatically")
	check(not game.craft_item("sword") and game.ore == 0 and game.trial.wood == 0,"Crafting without ingredients spent resources or unlocked a sword")
	game.camp_menu.dismiss()
	var wood_found := 0
	for region in 5:
		if region != game.earth_region: await TRAVEL.enter(game,region,false)
		game.refresh_ui()
		check(game.trial.snakes.size() == (3 if region == 0 else 2),"Surface district %d has missing or excessive snakes" % region)
		check(game.hud.health_panel.visible and game.hud.equip_slots[0].visible,"Earth combat HUD is missing outside Landing Meadow")
		check(game.wood_supplies.piles.size() == (2 if region == 1 else 1),"District %d is missing a reachable wood supply" % region)
		for snake in game.trial.snakes: check(snake.can_stand(snake.position),"A district snake starts on blocked ground or a doorway")
		for pile in game.wood_supplies.piles:
			check(game.gardens.clear_floor(pile.position),"Wood overlaps ore, rocks or a doorway")
			var painting: Texture2D = game.green_surface.get_node("Ground").texture if region == 0 else game.earth_stream.textures[game.EARTH.key(region,false)]
			var grass = load("res://environment/flower_placement.gd").new(painting,game.EARTH.SIZE,game.gardens.clear_floor)
			check(grass.fits(pile.position,0.12),"Fallen wood is on a path or rock instead of grass")
			if region == 0: check(not game.ORE_SPAWNS.starting_view(game.EARTH_START).grow(45).has_point(pile.position),"Wood starts inside the opening camera view")
			game.player = pile.position
			game.update_exploration()
			game.wood_supplies._process(0.75)
			game.cooldown = 0
			var before: int = game.trial.wood
			game.interact()
			check(pile.collected and game.trial.wood == before+1,"Wood was not collected through the normal interaction")
			wood_found += 1
			check(not game.wood_supplies.collect_nearby(),"The same wood pile could be collected twice")
		for index in game.rocks.size():
			if game.rocks[index].cave or game.ore >= 8: continue
			game.player = game.rocks[index].pos
			game.update_exploration()
			game.start_mining(index)
			game.advance_mining(2)
	check(game.ore == 8 and wood_found == 6,"Earth supply mismatch: %d copper, %d wood" % [game.ore,wood_found])
	check(game.trial.wood == wood_found,"Wood inventory does not match collected piles")
	await TRAVEL.enter(game,0,false)
	check(game.wood_supplies.piles.all(func(p): return p.collected),"Returning respawned collected wood")
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	check(game.camp_menu.buttons.all(func(b): return not b.disabled),"Recipes are locked despite having both ingredient sets")
	game.camp_menu.craft("sword")
	check(game.trial.sword_owned and game.ore == 5 and game.trial.wood == wood_found-2,"Sword recipe did not consume exactly 3 copper + 2 wood")
	game.camp_menu.craft("sword")
	check(game.ore == 5 and game.trial.wood == wood_found-2,"Crafting an owned sword spent ingredients twice")
	game.camp_menu.craft("drill")
	check(game.upgraded and game.ore == 0 and game.trial.sword_owned,"Drill craft removed sword ownership or used the wrong copper cost")
	game.camp_menu.craft("drill")
	check(game.ore == 0 and game.camp_menu.buttons.all(func(b): return b.disabled),"Completed craft can be bought again")
	game.camp_menu.dismiss()
	check(game.hud.mission_checks[0].visible and game.hud.mission_checks[1].visible,"Spending ingredients undid completed missions")
	check(game.hud.counts[2].text == str(wood_found-2),"Wood is missing from the compact inventory")
	game.trial.equip(0)
	check(game.scout.sprite_frames == game.DRILL_VISUAL.WALK[0],"Crafted drill is not visibly equipped")
	# Partial damage, positions and defeat persist when district actors unload.
	await TRAVEL.enter(game,1,false)
	var snake = game.trial.snakes[0]
	game.fog.observe(game.area_id(),snake.position)
	snake.seen = true
	check(snake.take_hit(900,game.player,3) and snake.health == 6,"A later-district snake cannot take sword damage")
	var remembered: Vector2 = snake.position
	await TRAVEL.enter(game,2,false)
	await TRAVEL.enter(game,1,false)
	snake = game.trial.snakes[0]
	check(snake.health == 6 and snake.position == remembered,"District reload reset snake damage or position")
	snake.take_hit(901,game.player,3)
	snake.take_hit(902,game.player,3)
	check(snake.health == 0 and game.trial.defeated == 1,"Defeating a later-district snake was not counted once")
	await TRAVEL.enter(game,1,true)
	check(game.trial.is_active() and game.hud.equip_slots[1].visible and game.trial.snakes.is_empty(),"Mine combat is disabled or surface snakes leaked inside")
	await TRAVEL.enter(game,1,false)
	check(game.trial.snakes[0].health == 0 and game.trial.snakes[0].state == "gone","A defeated snake returned after a mine trip")
	await TRAVEL.enter(game,0,false)
	for world in [1,2]:
		game.travel_to_other_planet(world)
		game.advance_flight(10)
		for region in 5:
			if region != game.current_region(): await TRAVEL.enter(game,region,false)
			game.refresh_ui()
			check(not game.trial.is_active() and game.trial.snakes.is_empty(),"Snakes/combat leaked to another planet")
			check(game.gardens.plants.is_empty() and not game.gardens.visible,"Earth fruit/berry plants are still on another planet")
			check(game.wood_supplies.piles.is_empty() and not game.wood_supplies.visible,"Earth wood is on another planet")
			check(game.trial.sword_owned and game.upgraded,"Rocket travel lost completed crafts")
		await TRAVEL.enter(game,0,false)
	game.travel_to_other_planet(0)
	game.advance_flight(10)
	check(game.trial.is_active() and game.trial.sword_owned and game.upgraded,"Return to Earth lost equipment or combat controls")
	check(game.wood_supplies.piles.all(func(p): return p.collected),"Rocket trip respawned collected wood")
	game.queue_free()
	await process_frame
	await process_frame
	# Ore is randomized, so its clearance can move a wood pile's preferred home.
	# Every fresh layout must still provide the full, sparse crafting supply.
	for layout in 6:
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.set_process(false)
		for region in 5:
			if region > 0: await TRAVEL.enter(game,region,false)
			check(game.wood_supplies.piles.size() == (2 if region == 1 else 1),"Fresh layout %d, district %d lost a wood supply to ore clearance" % [layout,region])
		game.queue_free()
		await process_frame
		await process_frame
	if failures == 0: print("PASS: Earth-wide snakes/HUD, locked starting sword, real wood/copper gathering, both exact recipes and one-time purchases, lasting missions, sparse stateful pickups, damaged/defeated snake memory, mine scope and no Earth combat/food/wood on any off-world district")
	quit(1 if failures else 0)
