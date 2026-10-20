extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func fly(game, destination: int) -> void:
	game.underground = false
	game.player = game.ship_position()
	game.update_exploration()
	game.cooldown = 0
	game.interact()
	game.planet_menu.choose(destination)
	game.advance_flight(10)
	check(game.world == destination,"Travel did not reach the chosen world")

func check_pose(game, mining: bool) -> void:
	var atlas: AtlasTexture = game.scout.sprite_frames.get_frame_texture(game.scout.animation,game.scout.frame)
	var expected := "scout" if game.world > 0 else "miner"
	check(atlas.atlas.resource_path == "res://assets/drill/%s_%s.png" % [expected,"mining" if mining else "walk"],"Upgrade reverted to pick artwork or changed outfit")
	check(atlas.region.size.x > 100 and atlas.region.size.y > 250,"A drill pose is empty or clipped")
	# The lowest opaque boot stays on the common contact line, even when
	# switching outfits, facing, walking, drilling or cancelling.
	var bottom: float = (atlas.get_height() * 0.5 + game.scout.offset.y) * game.scout.scale.y
	check(absf(bottom - 20) < 0.1,"Drill boots lost their ground anchor")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	TRAVEL.arm_launch(game) # Campaign preconditions; full repair is tested in earth_story.gd.
	check(game.PLANET_NAMES[0] == "Earth" and game.hud.location_title.text == "EARTH" and game.planet_menu.NAMES[0] == "Earth","Earth name differs between gameplay and travel")
	check(game.hud.location_panel.size.y <= 60 and game.hud.resource_panel.size.y <= 60 and game.action_button.size.y <= 42,"HUD grew back into a large overlay")
	check(game.hud.planet.size.x <= 58 and game.hud.material_icons[0].size.x <= 40 and game.hud.equipment.size.x <= 48,"Imported icon dimensions leaked into the gameplay view")
	game.player = Vector2(800,600)
	game.update_exploration()
	game.ore = 3
	game.refresh_ui()
	check(game.hud.counts[0].text == "3" and game.hud.counts[1].text == "0","Earth inventory counters are incorrect")
	check(game.hud.material_icons[0].texture == game.COPPER_ART and game.hud.material_icons[1].texture == game.BLUE_ORE_ART,"HUD uses different ore artwork from the deposits")
	game.player = game.CAMP
	game.update_exploration()
	game.cooldown = 0
	game.interact()
	game.camp_menu.craft("drill")
	game.camp_menu.dismiss()
	check(not game.upgraded and game.ore == 3,"Workbench fitted a drill without its copper cost")
	game.ore = 5
	game.cooldown = 0
	game.interact()
	game.camp_menu.craft("drill")
	game.camp_menu.dismiss()
	check(game.upgraded and game.ore == 0 and game.scout.sprite_frames == game.DRILL_VISUAL.WALK[0],"Buying the upgrade did not immediately fit the miner's drill")
	check(game.hud.equipment.texture == game.CATALOG.tool_icon(true) and "drill" in game.hud.equipment.tooltip_text,"HUD equipment indicator did not upgrade")
	var worlds := [0,1,2,0]
	for destination in worlds:
		if game.world != destination:
			fly(game,destination)
		check(game.upgraded,"Rocket travel lost the drill upgrade")
		for cave in [false,true]:
			game.underground = cave
			game.player = game.mine_spawn_position() if cave else game.surface_arrival_position()
			game.mine_transition_cooldown = 999
			game.update_exploration()
			for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
				game.move_player(direction,0.03)
				check_pose(game,false)
				game.move_player(Vector2.ZERO,0.01)
				check_pose(game,false)
				check(game.scout.animation == StringName("idle_"+str(game.facing)),"Drill idle pose lost its facing")
			for i in game.rocks.size():
				if game.rocks[i].cave == cave and game.rocks[i].hp > 0:
					for offset in [Vector2(-70,0),Vector2(70,0),Vector2(0,70),Vector2(0,-70)]:
						game.player = game.rocks[i].pos + offset
						game.update_exploration()
						game.start_mining(i)
						check(game.mining_target == i,"Fitted drill could not begin mining")
						check_pose(game,true)
						var first: Texture2D = game.scout.sprite_frames.get_frame_texture(game.scout.animation,game.scout.frame)
						game.advance_mining(0.1)
						check(game.scout.sprite_frames.get_frame_texture(game.scout.animation,game.scout.frame) != first,"Powered drill animation did not advance")
						check_pose(game,true)
						game.cancel_mining()
						check_pose(game,false)
					break
		game.refresh_ui()
		check(game.hud.location_subtitle.text == game.mine_name(),"Mine name is missing from the compact location badge")
	# Collect more than one crystal: the icon counter tracks the actual total,
	# rather than turning the old mission-complete boolean into a fake count.
	for region in [0,1]:
		if region > 0:
			await TRAVEL.enter(game,region,true)
		var i: int = game.rocks.find_custom(func(rock): return rock.hard)
		game.player = game.rocks[i].pos
		game.update_exploration()
		var remaining: float = (game.rocks[i].seconds-game.rocks[i].get("work",0.0))/(1.333333 if game.world == 0 and game.story.drill_improved else 1.0)
		game.start_mining(i)
		game.advance_mining(remaining-0.01)
		check(game.rocks[i].hp > 0,"Drill changed the full rare-material mining duration")
		game.advance_mining(0.02)
	game.refresh_ui()
	check(game.blue_crystals == 2 and game.hud.counts[1].text == "2","Blue crystal counter lost collected materials")
	await TRAVEL.enter(game,0,false)
	game.underground = false
	game.player = game.SHIP
	game.update_exploration()
	game.cooldown = 0
	game.interact()
	check(game.planet_menu.thumbnails.size() == 3 and game.planet_menu.buttons[0].disabled,"Destination cards are missing thumbnails or current-world state")
	for thumbnail in game.planet_menu.thumbnails:
		check(thumbnail.size.x <= 100 and thumbnail.size.y <= 92,"World thumbnail overflowed its travel card")
	check(game.planet_menu.panel.size.x <= 720 and game.planet_menu.panel.size.y <= 360,"Travel menu grew beyond the compact layout")
	check(not game.action_button.visible and not game.hud.objective.visible,"Gameplay prompts obscure the destination picker")
	game.planet_menu.dismiss()
	check(not game.planet_menu.visible and game.action_button.visible,"Closing travel menu did not restore rocket controls")
	game.message = "Ready for another adventure."
	game.refresh_ui()
	check(game.character_bubble.anchor == game.scout,"Notifications are not anchored to Scout")
	game.character_bubble._process(5)
	check(not game.character_bubble.visible,"Notifications remained as a permanent overlay")
	var fresh = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	check(not fresh.upgraded and fresh.blue_crystals == 0 and fresh.scout.sprite_frames == fresh.MINER_FRAMES,"Fresh game inherited the upgraded drill or inventory")
	if failures == 0:
		print("PASS: compact illustrated HUD, Earth naming, matching mineral icons/counts, real drill purchase, all directional walk/idle/drilling outfits on six maps, travel/cancellation persistence, grounded boots, crystal totals and fresh-game reset")
	quit(1 if failures else 0)
