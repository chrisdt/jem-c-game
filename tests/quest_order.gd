extends SceneTree
const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func place(game, point: Vector2) -> void:
	game.player = point
	game.scout.position = point
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()
func hand_in(story, role: String) -> void:
	story.begin(role)
	story.finish(role,true)
func talk(game, role: String, cancel := false) -> void:
	var person = game.frost_story.npcs.filter(func(n): return n.role == role)[0]
	place(game,person.position+Vector2(0,35))
	game.talk_to_npc(person)
	check(game.dialogue_open(),"Cannot open " + role + " before Pip")
	if cancel: game.character_bubble.dismiss()
	else:
		for page in 8:
			if not game.dialogue_open(): break
			game.character_bubble.advance()
func permutations(values: Array) -> Array:
	if values.is_empty(): return [[]]
	var result := []
	for value in values:
		var rest := values.duplicate()
		rest.erase(value)
		for suffix in permutations(rest): result.append([value]+suffix)
	return result
func run() -> void:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	for story in [game.story,game.frost_story,game.ember_story]: story.set_process(false)
	for person in game.npcs+game.frost_story.npcs+game.ember_story.npcs: person.set_process(false)
	game.trial.invulnerable = 10000
	for role in ["rowan","bea","otis","mara","iris","finn"]:
		check(game.story.available(role),"Earth quest has an order lock: "+role)
	check(not game.story.available("nova"),"Paused rocket quest was re-enabled")
	for story in [game.frost_story,game.ember_story]:
		for role in story.ORDER: check(story.available(role),"Off-world quest has an order lock: "+role)
	# Pickaxe users can return a genuinely recovered box without Rowan/sword.
	game.story.cache_held = true
	hand_in(game.story,"bea")
	check(game.story.done("bea") and not game.trial.sword_owned and not game.story.done("rowan"),"Bea still waits for Rowan or sword ownership")
	game.story.quarry_open = true
	hand_in(game.story,"otis")
	check(game.story.done("otis") and not game.story.done("rowan"),"Otis still waits for Rowan")
	# Shared quest evidence survives a consuming handoff in the opposite order.
	game.story.locker_recovered = true
	game.story.damaged_suit = true
	game.story.navigation_part = true
	game.story.seal_kit = true
	game.trial.wood = 2
	hand_in(game.story,"finn")
	check(game.story.done("finn") and not game.story.done("iris") and not game.story.damaged_suit,"Finn cannot repair before Iris reports")
	hand_in(game.story,"iris")
	check(game.story.done("iris") and game.trial.wood == 0,"Suit repair stranded Iris's discovery report")
	# Reproduce Nix: all minerals, Pip incomplete, unique item/sword missing.
	game.frost_ore = 4
	game.amethysts = 1
	game.travel_to_other_planet(1)
	game.advance_flight(10)
	await TRAVEL.enter(game,1,false)
	talk(game,"nix")
	check(game.frost_story.accepted.get("nix",false) and not game.frost_story.done("nix"),"Nix cannot be accepted independently")
	check("heart-crystal" in " ".join(game.frost_story.pages("nix")) and "Earth sword" in " ".join(game.frost_story.pages("nix")),"Nix hides actual missing requirements")
	check(not "Help Pip first" in game.frost_story.entries()[1].progress,"Journal still blocks Nix on Pip")
	# The pedestal remains solid; walk up to it and pick up from the front.
	await TRAVEL.enter(game,2,false)
	var crystal = game.frost_story.props.heart_crystal
	check(crystal.position == Vector2(1693,267),"Heart-crystal drifted off Prism Pass's central pedestal")
	check(not game.regions().can_walk(2,false,crystal.position),"Pedestal collision was removed just to place the item")
	place(game,crystal.position+Vector2(0,160))
	for step in 7: game.move_player(Vector2.UP,0.05)
	game.update_exploration()
	check(game.player.distance_to(crystal.position) < 100 and game.trial.floor_at(game.player),"Cannot approach central heart-crystal on real walking ground")
	game.space_action()
	check(game.frost_story.collected.has("heart_crystal") and not crystal.visible,"Space cannot recover the landmark heart-crystal")
	game.travel_to_other_planet(0)
	game.advance_flight(10)
	place(game,game.CAMP)
	game.ore = 8
	game.trial.wood = 2
	game.camp_menu.open()
	game.camp_menu.craft("sword")
	game.camp_menu.craft("drill")
	game.camp_menu.dismiss()
	game.travel_to_other_planet(1)
	game.advance_flight(10)
	await TRAVEL.enter(game,1,false)
	check(game.frost_story.entries()[1].progress == "Ready · return to Nix","Ready Nix recipe still looks incomplete")
	talk(game,"nix",true)
	check(game.frost_ore == 4 and game.amethysts == 1 and not game.frost_story.frostfang,"Cancelled independent upgrade spent materials")
	talk(game,"nix")
	check(game.frost_story.done("nix") and not game.frost_story.done("pip") and game.frost_ore == 0 and game.amethysts == 0,"Nix cannot forge before Pip despite all ingredients")
	# Larger fragments stay concealed, fade in on discovery and vanish on pickup.
	await TRAVEL.enter(game,3,false)
	var fragment = game.frost_story.props.beacon_aurora
	check(fragment.has_node("SnowContrast") and is_equal_approx(fragment.texture.get_width()*fragment.scale.x,46.0),"Snow collectible lacks its fitted contrast/size")
	check(is_zero_approx(fragment.modulate.a),"Beacon fragment visible before exploration")
	place(game,fragment.position)
	game.frost_story._process(0.375)
	check(fragment.modulate.a > 0 and fragment.modulate.a < 1,"Beacon did not fade in smoothly")
	game.space_action()
	check(game.frost_story.collected.has("beacon_aurora") and not fragment.visible,"Highlighted fragment was not collectible")
	game.frost_story.collected.beacon_west = true
	game.frost_story.collected.beacon_east = true
	hand_in(game.frost_story,"pip")
	game.frost_story.sync_area()
	var beacon = game.frost_story.props.trail_aurora
	place(game,beacon.position)
	game.interact()
	check(game.character_bubble.mode == game.character_bubble.Mode.HINT and game.message.contains("restored"),"Restored beacon has no inspect response")
	game.character_bubble.dismiss()
	game.trial.selected_tool = 1
	game.trial.jab_cooldown = 0
	game.space_action()
	check(game.trial.jab_time >= 0,"Decorative beacon stole Space from combat")
	game.trial.advance(0.6)
	# Every Frost handoff order works with earned ingredients/evidence prepared.
	for order in permutations(["pip","nix","tavi","eira"]):
		game.frost_story.complete.clear()
		game.frost_story.accepted.clear()
		game.frost_story.collected = {"beacon_west":true,"beacon_east":true,"beacon_aurora":true,"heart_crystal":true,"coupling":true}
		game.frost_story.cache_open = true
		game.frost_story.frostfang = false
		game.frost_story.crystal_drill = false
		game.frost_ore = 9
		game.amethysts = 3
		for role in order: hand_in(game.frost_story,role)
		check(game.frost_story.complete.size() == 4 and game.frost_ore == 0 and game.amethysts == 0,"A frozen handoff order failed: "+str(order))
	# Simultaneous offers must recheck shared materials instead of overspending.
	game.frost_story.complete.clear()
	game.frost_ore = 6
	game.amethysts = 2
	game.frost_story.begin("nix")
	hand_in(game.frost_story,"tavi")
	game.frost_story.finish("nix",true)
	check(not game.frost_story.done("nix") and game.frost_ore == 1 and game.amethysts == 0,"Overlapping recipes spent unavailable materials")
	game.ember_story.collected = {"plant_oasis":true,"plant_arch":true,"flask":true,"core":true}
	hand_in(game.ember_story,"luma")
	check(game.ember_story.done("luma") and not game.ember_story.done("sol"),"Luma still waits for Sol")
	game.ember_story.magma_drill = true
	game.ember_story.observatory_open = true
	hand_in(game.ember_story,"orin")
	check(game.ember_story.done("orin") and not game.ember_story.done("brasa"),"Orin still waits for both Brasa upgrades")
	game.gold_ore = 3
	game.rubies = 1
	hand_in(game.ember_story,"brasa")
	check(game.ember_story.done("brasa") and game.gold_ore == 0 and game.rubies == 0,"Brasa still waits for Sol or repeats the built drill")
	game.frost_story.crystal_drill = false
	game.frost_story.complete.erase("tavi")
	game.frost_story.cache_open = false
	await TRAVEL.enter(game,4,false)
	for yeti in game.frost_story.yetis: yeti.health = 0
	place(game,game.frost_story.props.cache.position)
	game.trial.selected_tool = 0
	game.space_action()
	game.frost_story._process(2.1)
	check(game.frost_story.cache_open and not game.frost_story.done("tavi"),"Stronger Magma Drill cannot open frozen cache before Tavi")
	game.story.drill_improved = false
	game.story.sword_improved = false
	check(game.story.locker_tools_ready(),"Stronger imported tools still wait for Mara's mission")
	if failures == 0: print("PASS: independent story handoffs, Nix before Pip with actual landmark pickup/cancel/crafting, 24 Frost orders, shared-item consumption, recipe races, snow reveal/collection, restored-beacon inspection and Space combat")
	quit(1 if failures else 0)
