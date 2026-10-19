extends Node2D

const SPEED := 235.0
const CAMP := Vector2(470, 400)
const CAVE := Vector2(1480, 340)
const MINE_EXIT := Vector2(150, 610)
const MINE_SPAWN := Vector2(420, 620)
const MINE_LAYOUT = preload("res://mine_layout.gd")
const MINE_ART: Texture2D = preload("res://assets/moss_mine.png")
const SHIP := Vector2(240, 400)
const FROST_LAYOUT = preload("res://frost_layout.gd")
const DESERT_LAYOUT = preload("res://desert_layout.gd")
const PLANET_MENU = preload("res://planet_menu.gd")
const CATALOG = preload("res://ui/world_catalog.gd")
const UI_STYLE = preload("res://ui/expedition_style.gd")
const WORLD_SIGNS = preload("res://environment/world_signs.gd")
const GAME_HUD = preload("res://ui/game_hud.gd")
const RESET_CONFIRMATION = preload("res://ui/reset_confirmation.gd")
var reset_confirmation: RESET_CONFIRMATION
const DRILL_VISUAL = preload("res://drill_visual.gd")
const EARTH_TRIAL = preload("res://environment/earth_trial.gd")
var trial: Node2D
const HEALING_GARDENS = preload("res://environment/healing_gardens.gd")
var gardens: Node2D
const WOOD_SUPPLIES = preload("res://environment/wood_supplies.gd")
var wood_supplies: Node2D
const CAMP_MENU = preload("res://ui/camp_workbench.gd")
var camp_menu: CAMP_MENU
const PLANET_NAMES := CATALOG.NAMES
const LAVA_ENVIRONMENT: PackedScene = preload("res://environment/lava_mine.tscn")
const DESERT_ART: Texture2D = preload("res://assets/desert_planet.png")
const GOLD_ART: Texture2D = preload("res://assets/gold_ore.png")
const RUBY_ART: Texture2D = preload("res://assets/ruby_ore.png")
const ORE_SPAWNS = preload("res://ore_spawns.gd")
const EXPLORATION_FOG = preload("res://exploration_fog.gd")
const ROCKET = preload("res://environment/rocket.gd")
enum Flight { IDLE, IGNITION, ASCENT, DESCENT, TOUCHDOWN }
const FLIGHT_DURATIONS := {Flight.IGNITION:0.75, Flight.ASCENT:1.85, Flight.DESCENT:2.6, Flight.TOUCHDOWN:0.5}
const FLIGHT_HEIGHT := 920.0
var flight: Flight = Flight.IDLE
var flight_elapsed := 0.0
var flight_camera_smoothing := true
var flight_destination := 1
var planet_menu: PLANET_MENU
var lava_environment: Node2D
var rocket: ROCKET
var travel_fade: ColorRect
const ICE_ART: Texture2D = preload("res://assets/ice_planet.png")
const FROST_MINE_ART: Texture2D = preload("res://assets/frost_mine.png")
const AMETHYST_ART: Texture2D = preload("res://assets/amethyst_ore.png")
const ICE_CAMP := Vector2(570, 1060)
const ICE_SHIP := Vector2(260, 1070)
const ICE_CAVE := Vector2(1620, 280)
const ICE_EXIT := Vector2(968, 1230)
const ICE_SPAWN := Vector2(968, 1115)
const MINE_TRIGGER_RADIUS := 65.0
var mine_transition_cooldown := 0.0
var world := 0
var planet_rocks: Dictionary = {}
var frost_ore := 0
var amethysts := 0
var ice_won := false
var gold_ore := 0
var rubies := 0
var desert_won := false
var player := Vector2(560, 550)
const EARTH = preload("res://earth_regions.gd")
const OUTER = preload("res://outer_regions.gd")
var world_regions := [EARTH,OUTER.new(1),OUTER.new(2)]
var outer_region := {1:0,2:0}
var outer_rocks := {1:{},2:{}}
var outer_visited := {1:{},2:{}}
const EARTH_STREAM = preload("res://environment/earth_stream.gd")
var earth_region := 0
var earth_rocks: Dictionary = {}
var earth_visited := {0:true}
var earth_stream: EARTH_STREAM
var earth_transition := false
var earth_transition_stage := 0
var earth_transition_elapsed := 0.0
var earth_wait_elapsed := 0.0
var earth_target_region := 0
var earth_target_cave := false
var earth_target_player := Vector2.ZERO
var earth_return_player := Vector2.ZERO
var earth_trail_cooldown := 0.0
const GREEN_ENVIRONMENT: PackedScene = preload("res://environment/green_planet.tscn")
const EARTH_WATER = preload("res://environment/earth_water.gd")
const AMBIENT_LIFE = preload("res://environment/ambient_life.gd")
const DOG_COMPANION = preload("res://environment/dog_companion.gd")
var companion: Node2D
var scared_wildlife: Dictionary = {}
var green_surface: Node2D
var moss_water: Node2D
var local_life: Node2D
const COPPER_ART: Texture2D = preload("res://assets/copper_ore.png")
const BLUE_ORE_ART: Texture2D = preload("res://assets/blue_ore.png")
const SCOUT_FRAMES: SpriteFrames = preload("res://assets/scout_frames.tres")
const MINE_FRAMES: SpriteFrames = preload("res://assets/scout_mining_frames.tres")
const MINER_FRAMES: SpriteFrames = preload("res://assets/miner_frames.tres")
const MINER_MINE_FRAMES: SpriteFrames = preload("res://assets/miner_mining_frames.tres")
const COPPER_SECONDS := 2.0
const CRYSTAL_SECONDS := 9.0
const ORE_REVEAL_SECONDS := 0.75
const STRIKE_SECONDS := 0.66
const IMPACT_PHASE := 0.22
# Pixel anchors keep boots planted across the painted poses.
const MINE_ANCHORS := {
	&"down": [Vector2(270, 425), Vector2(208, 430), Vector2(164, 426)],
	&"side": [Vector2(275, 393), Vector2(212, 356), Vector2(174, 361)],
	&"up": [Vector2(270, 395), Vector2(208, 394), Vector2(164, 394)],
}
var mining_target := -1
var mining_elapsed := 0.0
var next_strike := IMPACT_PHASE
var impact_flash := 0.0
var particles: Array[Dictionary] = []
var mining_fx: Node2D
const WALK_FRAME_DISTANCE := 28.0
var walk_distance := 0.0
var scout: AnimatedSprite2D
var walking := false
var facing_left := false
var facing: StringName = &"down"
var underground := false
var ore := 0
var total_mined := 0
var upgraded := false:
	set(value):
		upgraded = value
		if is_instance_valid(scout):
			if mining_target >= 0:
				update_mining_visual()
			else:
				restore_walk_visual()
var won := false
var blue_crystals := 0
var rocks: Array[Dictionary] = []
var ore_rng := RandomNumberGenerator.new()
var fog: EXPLORATION_FOG
var message := "WASD / arrows to walk. E to mine. Follow trails to find 5 copper, then build your hand drill at camp."
var cooldown := 0.0
var elapsed := 0.0
var camera: Camera2D
var action_button: Button
var hud_layer: CanvasLayer
var hud: GAME_HUD
var flight_caption_panel: Panel
var flight_caption: Label

func _ready() -> void:
	# This iteration is deliberately silent, including Buddy's existing bark.
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),true)
	y_sort_enabled = true
	green_surface = GREEN_ENVIRONMENT.instantiate()
	add_child(green_surface)
	moss_water = EARTH_WATER.add_to(self,"moss",MINE_ART,1)
	moss_water.hide()
	local_life = AMBIENT_LIFE.new()
	local_life.name = "LocalAmbientLife"
	add_child(local_life)
	earth_stream = EARTH_STREAM.new()
	earth_stream.y_sort_enabled = true
	add_child(earth_stream)
	lava_environment = LAVA_ENVIRONMENT.instantiate()
	add_child(lava_environment)
	lava_environment.visible = false
	rocket = ROCKET.new()
	add_child(rocket)
	rocket.reset_pad(ship_position(), world == 1)
	scout = AnimatedSprite2D.new()
	scout.name = "SunnyScout"
	scout.sprite_frames = MINER_FRAMES if world == 0 else SCOUT_FRAMES
	scout.animation = &"idle_down"
	scout.scale = Vector2.ONE * 0.15
	scout.offset = Vector2(0, -145)
	scout.position = player
	add_child(scout)
	mining_fx = Node2D.new()
	mining_fx.name = "MiningEffects"
	mining_fx.z_index = 1
	mining_fx.draw.connect(draw_mining_effects)
	add_child(mining_fx)
	ore_rng.randomize()
	reset_rocks()
	planet_rocks[world] = rocks
	camera = Camera2D.new()
	camera.position = player
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2000
	camera.limit_bottom = 1400
	add_child(camera)
	fog = EXPLORATION_FOG.new()
	add_child(fog)
	update_exploration()
	hud = GAME_HUD.new()
	add_child(hud)
	hud_layer = hud
	action_button = hud.context_button
	hud.action_requested.connect(interact)
	hud.equipment_requested.connect(func(index: int):
		if is_instance_valid(trial): trial.equip(index))
	hud.attack_requested.connect(func():
		if is_instance_valid(trial): trial.start_jab())
	if hud.touch_mode:
		message = "Drag the pad to walk. Tap action buttons to mine. Explore trails to find 5 copper for your drill."
	var travel_layer := CanvasLayer.new()
	travel_layer.layer = 2
	add_child(travel_layer)
	flight_caption_panel = UI_STYLE.panel(travel_layer,Vector2(335,714),Vector2(610,48))
	flight_caption_panel.z_index = 1
	flight_caption = UI_STYLE.label(flight_caption_panel,"",Vector2(14,7),Vector2(582,34),16,true)
	flight_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	travel_fade = ColorRect.new()
	travel_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	travel_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	travel_fade.color = Color(0.025, 0.045, 0.08, 0)
	travel_layer.add_child(travel_fade)
	planet_menu = PLANET_MENU.new()
	add_child(planet_menu)
	planet_menu.destination_selected.connect(travel_to_other_planet)
	planet_menu.closed.connect(refresh_ui)
	camp_menu = CAMP_MENU.new()
	camp_menu.game = self
	add_child(camp_menu)
	companion = DOG_COMPANION.new()
	companion.game = self
	add_child(companion)
	trial = EARTH_TRIAL.new()
	trial.game = self
	add_child(trial)
	gardens = HEALING_GARDENS.new()
	gardens.game = self
	add_child(gardens)
	wood_supplies = WOOD_SUPPLIES.new()
	wood_supplies.game = self
	add_child(wood_supplies)
	reset_confirmation = RESET_CONFIRMATION.new()
	add_child(reset_confirmation)
	reset_confirmation.confirmed.connect(func(): get_tree().reload_current_scene())
	message = "Earth missions: gather copper and fallen wood. Craft a sword and a hand drill at camp. E gathers; Space mines nearby ore or attacks."
	if hud.touch_mode:
		message = "Earth missions: find copper and fallen wood, then craft at camp. Tap the action to gather and Attack to defend yourself."
	refresh_ui()

# The Earth-named transition fields are retained for the existing editor/test
# API; the same bounded loader now serves all three planets.
func regions():
	return world_regions[world]

func current_region() -> int:
	return earth_region if world == 0 else outer_region[world]

func set_current_region(region: int) -> void:
	if world == 0: earth_region = region
	else: outer_region[world] = region

func district_rocks() -> Dictionary:
	return earth_rocks if world == 0 else outer_rocks[world]

func visited_regions() -> Dictionary:
	return earth_visited if world == 0 else outer_visited[world]

func reset_rocks() -> void:
	if current_region() > 0:
		rocks = regions().generate(current_region(),ore_rng)
	else:
		var entries: Array[Vector2] = [[Vector2(560,550),Vector2(390,1120),DESERT_LAYOUT.ARRIVAL][world],mine_spawn_position()]
		rocks = ORE_SPAWNS.generate(world,ore_rng,entries,tree_cover(),Vector2(COPPER_SECONDS,CRYSTAL_SECONDS))
	district_rocks()[current_region()] = rocks

func tree_cover() -> Array[Rect2]:
	var cover: Array[Rect2] = []
	for tree in green_surface.get_children():
		if str(tree.name).begins_with("Tree"):
			cover.append(Rect2(tree.position + Vector2(-256,-532) * tree.scale, Vector2(512,532) * tree.scale).grow(45))
	return cover

func area_id() -> int:
	return regions().MINE_IDS[current_region()] if underground else regions().SURFACE_IDS[current_region()]

func has_base() -> bool:
	return current_region() == 0

func menu_open() -> bool:
	return planet_menu.visible or (is_instance_valid(camp_menu) and camp_menu.visible)

func at_workbench() -> bool:
	return not underground and has_base() and player.distance_to(camp_position()) < 140 and flight == Flight.IDLE and not earth_transition

func craft_item(recipe: String) -> bool:
	if not camp_menu.visible or not at_workbench(): return false
	if recipe == "drill":
		if upgraded or ore < trial.DRILL_COPPER: return false
		ore -= trial.DRILL_COPPER
		upgraded = true
		message = "Mission complete: hand drill built! It can mine rare minerals."
	elif recipe == "sword":
		if world != 0 or trial.sword_owned or ore < trial.SWORD_COPPER or trial.wood < trial.SWORD_WOOD: return false
		ore -= trial.SWORD_COPPER
		trial.wood -= trial.SWORD_WOOD
		trial.sword_owned = true
		trial.selected_tool = 1
		restore_walk_visual()
		message = "Mission complete: copper sword crafted! Select 2 or tap Sword; Space or Jab attacks."
	else: return false
	return true

func clear_touch_gestures() -> void:
	hud.touch_controls.clear()
	var buttons: Array = hud.equip_slots + [hud.context_button,hud.attack_button,hud.help_button] + planet_menu.buttons + [planet_menu.close_button,planet_menu.cancel_button]
	if is_instance_valid(camp_menu): buttons += camp_menu.buttons + [camp_menu.close_button]
	for button in buttons: button.release_touch()

func update_exploration() -> void:
	if fog == null:
		return
	fog.observe(area_id(), player)
	for rock in rocks:
		if rock.cave == underground and not rock.discovered and fog.is_revealed(area_id(), rock.pos):
			rock.discovered = true
			# Remember the first discovery so revisiting an area cannot restart it.
			rock.revealed_at = elapsed

func camp_position() -> Vector2:
	return [CAMP, ICE_CAMP, DESERT_LAYOUT.CAMP][world]

func cave_position() -> Vector2:
	return regions().MINE_ENTRANCES[current_region()]

func exit_position() -> Vector2:
	return regions().MINE_EXITS[current_region()]

func ship_position() -> Vector2:
	return [SHIP, ICE_SHIP, DESERT_LAYOUT.SHIP][world]

func mine_spawn_position() -> Vector2:
	return regions().MINE_SPAWNS[current_region()]

func surface_arrival_position() -> Vector2:
	if current_region() > 0: return regions().arrival(current_region(),regions().LINKS[current_region()][0].side)
	return [Vector2(320,500), Vector2(390,1120), DESERT_LAYOUT.ARRIVAL][world]

func surface_exit_position() -> Vector2:
	if current_region() > 0: return cave_position()+Vector2(0,160)
	return [Vector2(1430,520), Vector2(1575,385), DESERT_LAYOUT.OUTSIDE][world]

func mine_name() -> String:
	return regions().MINE_NAMES[current_region()]

func material_name(rock: Dictionary) -> String:
	if world == 2:
		return "fire ruby" if rock.hard else "gold"
	if world == 1:
		return "amethyst" if rock.hard else "frost ore"
	return "blue crystal" if rock.hard else "copper"

func material_tint(rock: Dictionary) -> Color:
	return [[Color("ffc16f"),Color("92e8f4")],[Color("92e8f4"),Color("d4a5ff")],[Color("ffd659"),Color("ff6b81")]][world][int(rock.hard)]

func arrival_message() -> String:
	return ["Back on Earth! Follow the trails to explore five districts and three mines.",
		"Frost Canyon! Follow the snow trails to explore five districts and three mines.",
		"Ember Dunes! Follow the sand trails to explore five districts and three mines."][world]

func open_planet_menu() -> void:
	walking = false
	walk_distance = 0
	restore_walk_visual()
	scout.animation = StringName("idle_" + str(facing))
	planet_menu.open(world)
	refresh_ui()

func travel_to_other_planet(destination: int = -1) -> void:
	if flight != Flight.IDLE or earth_transition or underground or mining_target >= 0:
		return
	if destination < 0:
		destination = 0 if world == 1 else 1
	if destination == world or destination >= PLANET_NAMES.size():
		return
	planet_menu.visible = false
	flight_destination = destination
	flight = Flight.IGNITION
	flight_elapsed = 0
	walking = false
	walk_distance = 0
	particles.clear()
	scout.visible = false
	rocket.reset_pad(ship_position(), world == 1)
	# Flight remains crisp above the mist without revealing an aerial trail.
	rocket.z_index = 1001
	flight_camera_smoothing = camera.position_smoothing_enabled
	camera.position_smoothing_enabled = false
	camera.position = ship_position() + Vector2(180, -60)
	camera.reset_smoothing()
	message = "All aboard! Warming up the boosters..."
	update_flight_visual()
	refresh_ui()
	queue_redraw()

func advance_flight(delta: float) -> void:
	# Consume phase boundaries even on a slow frame; switch planets once,
	# under the fade, after the ship has left the departure screen.
	while flight != Flight.IDLE and delta > 0:
		var duration: float = FLIGHT_DURATIONS[flight]
		var step := minf(delta, duration - flight_elapsed)
		flight_elapsed += step
		delta -= step
		update_flight_visual()
		if flight_elapsed >= duration:
			flight_elapsed = 0
			match flight:
				Flight.IGNITION:
					flight = Flight.ASCENT
					message = "Blastoff! Next stop: " + PLANET_NAMES[flight_destination] + "!"
				Flight.ASCENT:
					switch_planet()
					flight = Flight.DESCENT
					message = "Boosters on! Slowing down for a gentle landing..."
				Flight.DESCENT:
					flight = Flight.TOUCHDOWN
					message = "Touchdown! Welcome to " + PLANET_NAMES[world] + "."
				Flight.TOUCHDOWN:
					finish_flight()
			update_flight_visual()
	refresh_ui()
	queue_redraw()

func update_flight_visual() -> void:
	if flight == Flight.IDLE:
		rocket.set_flight(0, 0)
		travel_fade.color.a = 0
		return
	var t := clampf(flight_elapsed / float(FLIGHT_DURATIONS[flight]), 0, 1)
	match flight:
		Flight.IGNITION:
			rocket.set_flight(0, 0.15 + 0.65 * t)
		Flight.ASCENT:
			rocket.set_flight(FLIGHT_HEIGHT * t * t, 1)
			travel_fade.color.a = smoothstep(0.65, 1.0, t)
		Flight.DESCENT:
			rocket.set_flight(FLIGHT_HEIGHT * pow(1 - t, 2.3), 0.85 * (1 - smoothstep(0.87, 1, t)))
			travel_fade.color.a = 1 - smoothstep(0, 0.22, t)
		Flight.TOUCHDOWN:
			rocket.set_flight(0, 0)
			travel_fade.color.a = 0

func switch_planet() -> void:
	district_rocks()[current_region()] = rocks
	planet_rocks[world] = district_rocks()[0]
	earth_stream.deactivate()
	world = flight_destination
	set_current_region(0)
	earth_stream.REGIONS = regions()
	visited_regions()[0] = true
	if planet_rocks.has(world):
		rocks = planet_rocks[world]
	else:
		rocks = []
		reset_rocks()
		planet_rocks[world] = rocks
	particles.clear()
	player = surface_arrival_position()
	rocket.reset_pad(ship_position(), world == 1)
	camera.position = ship_position() + Vector2(180, -60)
	camera.reset_smoothing()
	update_exploration()

func finish_flight() -> void:
	flight = Flight.IDLE
	flight_elapsed = 0
	rocket.z_index = 2
	scout.visible = true
	restore_walk_visual()
	scout.animation = StringName("idle_" + str(facing))
	scout.position = player
	camera.position = player
	camera.position_smoothing_enabled = flight_camera_smoothing
	camera.reset_smoothing()
	cooldown = 0.3
	mine_transition_cooldown = 0.6
	message = arrival_message()
	update_exploration()
	refresh_ui()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	cooldown = maxf(0, cooldown - delta)
	update_particles(delta)
	mining_fx.queue_redraw()
	trial.advance(delta)
	if earth_transition:
		advance_earth_transition(delta)
		return
	earth_stream.prepare(current_region(),underground,player)
	if flight != Flight.IDLE:
		advance_flight(delta)
		return
	if menu_open():
		refresh_ui()
		queue_redraw()
		return
	if trial.is_active() and hud.help.visible:
		refresh_ui()
		queue_redraw()
		return
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	direction += hud.touch_controls.direction
	move_player(direction, delta)
	advance_mining(delta)
	camera.position = player
	refresh_ui()
	queue_redraw()

func face_direction(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		# Diagonals use their stronger axis; ties face up/down consistently.
		if absf(direction.x) > absf(direction.y):
			facing = &"side"
			facing_left = direction.x < 0
		else:
			facing = &"up" if direction.y < 0 else &"down"
			facing_left = false

func restore_walk_visual() -> void:
	var carrying_sword: bool = is_instance_valid(trial) and trial.sword_equipped()
	scout.sprite_frames = DRILL_VISUAL.WALK[int(world > 0)] if upgraded and not carrying_sword else (MINER_FRAMES if world == 0 else SCOUT_FRAMES)
	scout.animation = StringName(("walk_" if walking else "idle_") + str(facing))
	scout.frame = int(walk_distance / WALK_FRAME_DISTANCE) % 4 if walking else 0
	scout.flip_h = facing_left
	scout.rotation = 0.0
	if upgraded and not carrying_sword:
		DRILL_VISUAL.fit(scout,world > 0,false,facing)
	else:
		scout.scale = Vector2.ONE * 0.15
		scout.offset = Vector2(0,-145)

func move_player(direction: Vector2, delta: float) -> void:
	if flight != Flight.IDLE or earth_transition or menu_open():
		return
	if is_instance_valid(trial) and trial.is_active():
		if trial.jab_time >= 0:
			trial.update_jab_pose()
			return
		if hud.help.visible: return
	mine_transition_cooldown = maxf(0, mine_transition_cooldown - delta)
	earth_trail_cooldown = maxf(0,earth_trail_cooldown-delta)
	var previous := player
	if mining_target >= 0:
		if direction.is_zero_approx():
			walking = false
			return
		cancel_mining()
	face_direction(direction)
	var next := player + direction.normalized() * SPEED * delta
	next = next.clamp(Vector2(90, 180), Vector2(1900, 1290))
	if current_region() > 0:
		next = regions().move_on_floor(current_region(),underground,player,direction.normalized()*SPEED*delta)
	elif world == 2:
		next = DESERT_LAYOUT.move_on_floor(player, direction.normalized() * SPEED * delta, underground)
	elif world == 1:
		next = FROST_LAYOUT.move_on_floor(player,direction.normalized() * SPEED * delta,underground)
	elif underground:
		next = MINE_LAYOUT.move_on_floor(player, direction.normalized() * SPEED * delta)
	elif ((next - Vector2(1270, 960)) / Vector2(173, 117)).length() < 1.0:
		next = player
	var travelled := player.distance_to(next)
	player = next
	walking = travelled > 0.001
	if walking:
		walk_distance += travelled
	else:
		walk_distance = 0.0
	restore_walk_visual()
	scout.position = player
	fog.reveal_motion(area_id(), previous, player)
	update_exploration()
	check_mine_transition(previous)
	check_earth_trail(previous)

func check_mine_transition(previous: Vector2) -> void:
	if mine_transition_cooldown > 0 or earth_transition:
		return
	if not regions().has_mine(current_region()):
		return
	var doorway := exit_position() if underground else cave_position()
	var closest := Geometry2D.get_closest_point_to_segment(doorway, previous, player)
	if closest.distance_to(doorway) >= MINE_TRIGGER_RADIUS:
		return
	if current_region() > 0:
		var entering := not underground
		begin_earth_transition(current_region(),entering,mine_spawn_position() if entering else surface_exit_position(),surface_exit_position() if entering else mine_spawn_position())
		return
	cancel_mining()
	particles.clear()
	underground = not underground
	player = mine_spawn_position() if underground else surface_exit_position()
	walking = false
	walk_distance = 0
	restore_walk_visual()
	scout.position = player
	camera.position = player
	camera.reset_smoothing()
	mine_transition_cooldown = 0.6
	message = ("Frost Mine: follow either branch to find amethyst. A hand drill is required." if world == 1 else "The Moss Mine. Follow the lanterns. Blue crystal needs a hand drill.") if underground else "Back outside. The rocket and workbench are at your landing camp."
	if world == 2 and underground:
		message = "The Lava Mine! Stay on the stone ledges and bridge. Fire ruby needs a hand drill."
	update_exploration()
	refresh_ui()
	queue_redraw()

func check_earth_trail(previous: Vector2) -> void:
	if underground or earth_transition or earth_trail_cooldown > 0:
		return
	for link in regions().LINKS[current_region()]:
		var point: Vector2 = regions().portal(current_region(),link.side)
		var closest := Geometry2D.get_closest_point_to_segment(point,previous,player)
		if closest.distance_to(point) < 55:
			begin_earth_transition(link.target,false,regions().arrival(link.target,link.arrival),regions().arrival(current_region(),link.side))
			return

func begin_earth_transition(region: int, cave: bool, arrival: Vector2, rollback: Vector2) -> void:
	if earth_transition or flight != Flight.IDLE or menu_open():
		return
	if mining_target >= 0: cancel_mining()
	district_rocks()[current_region()] = rocks
	earth_target_region = region
	earth_target_cave = cave
	earth_target_player = arrival
	earth_return_player = rollback
	earth_transition = true
	earth_transition_stage = 0
	earth_transition_elapsed = 0
	earth_wait_elapsed = 0
	walking = false
	walk_distance = 0
	restore_walk_visual()
	earth_stream.REGIONS = regions()
	earth_stream.pin_target(regions().key(region,cave))
	message = "Entering "+(regions().MINE_NAMES[region] if cave else regions().NAMES[region])+"..."
	refresh_ui()

func advance_earth_transition(delta: float) -> void:
	if not earth_transition: return
	earth_transition_elapsed += delta
	if earth_transition_stage == 0:
		travel_fade.color.a = smoothstep(0,0.15,earth_transition_elapsed)
		if earth_transition_elapsed >= 0.15:
			earth_transition_stage = 1
			earth_transition_elapsed = 0
	elif earth_transition_stage == 1:
		earth_wait_elapsed += delta
		var key: String = regions().key(earth_target_region,earth_target_cave)
		if earth_stream.is_ready(key):
			set_current_region(earth_target_region)
			underground = earth_target_cave
			if not district_rocks().has(current_region()):
				reset_rocks()
			else:
				rocks = district_rocks()[current_region()]
			visited_regions()[current_region()] = true
			earth_stream.show_area(current_region(),underground)
			player = earth_target_player
			message = (mine_name()+" — follow the lanterns to find "+CATALOG.MATERIALS[world][0].to_lower()+" and "+CATALOG.MATERIALS[world][1].to_lower()+".") if underground else (regions().NAMES[current_region()]+" — follow the trail signs to keep exploring.")
			finish_earth_switch()
		elif earth_stream.failures.has(key) or earth_wait_elapsed > 24:
			# Retain inventory, ore and discovery on the old map if a download
			# fails. Return to a safe spot so holding a key cannot loop the door.
			player = earth_return_player
			earth_stream.pinned = ""
			message = "That trail could not load. Try again in a moment."
			finish_earth_switch()
	else:
		travel_fade.color.a = 1-smoothstep(0,0.18,earth_transition_elapsed)
		if earth_transition_elapsed >= 0.18:
			earth_transition = false
			travel_fade.color.a = 0
	refresh_ui()
	queue_redraw()

func finish_earth_switch() -> void:
	earth_transition_stage = 2
	earth_transition_elapsed = 0
	particles.clear()
	mine_transition_cooldown = 0.8
	earth_trail_cooldown = 0.8
	scout.position = player
	restore_walk_visual()
	camera.position = player
	camera.reset_smoothing()
	update_exploration()
	earth_stream.prepare(current_region(),underground,player)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_R:
			# Discard held touch gestures before pausing their input handlers.
			clear_touch_gestures()
			reset_confirmation.open()
			get_viewport().set_input_as_handled()
		elif not earth_transition and not menu_open() and trial.is_active() and event.keycode in [KEY_1,KEY_2]:
			trial.equip(0 if event.keycode == KEY_1 else 1)
		elif event.keycode == KEY_SPACE and trial.is_active():
			space_action()
			get_viewport().set_input_as_handled()
		elif not earth_transition and not menu_open() and (event.keycode == KEY_E or event.keycode == KEY_SPACE):
			interact()

func space_action() -> void:
	if trial.blocked(): return
	if trial.sword_equipped():
		trial.start_jab()
	elif mining_target >= 0:
		interact()
	else:
		var rock := nearest_rock()
		if rock >= 0:
			start_mining(rock)
			refresh_ui()
		else: trial.start_jab()

func nearest_rock() -> int:
	var best := -1
	var distance := 100.0
	for i in rocks.size():
		if rocks[i].cave == underground and rocks[i].hp > 0 and rocks[i].discovered:
			var d := player.distance_to(rocks[i].pos)
			if d < distance:
				best = i
				distance = d
	return best

func interact() -> void:
	if flight != Flight.IDLE or earth_transition or menu_open():
		return
	if trial.is_active() and (hud.help.visible or trial.jab_time >= 0): return
	if mining_target >= 0:
		cancel_mining()
		refresh_ui()
		return
	if cooldown > 0:
		return
	cooldown = 0.3
	if not underground and has_base() and player.distance_to(ship_position()) < 95:
		open_planet_menu()
	elif not underground and has_base() and player.distance_to(camp_position()) < 140:
		camp_menu.open()
	elif is_instance_valid(wood_supplies) and wood_supplies.collect_nearby():
		pass
	else:
		var i := nearest_rock()
		if i >= 0:
			if rocks[i].hard and not upgraded:
				message = "Too tough! Bring 5 copper from Earth to a workbench for a hand drill."
			else:
				start_mining(i)
	refresh_ui()

func start_mining(index: int) -> void:
	if flight != Flight.IDLE or earth_transition or menu_open():
		return
	if is_instance_valid(trial) and trial.is_active() and trial.jab_time >= 0:
		return
	if is_instance_valid(trial) and trial.sword_equipped():
		message = "Select your mining tool first: press 1 or tap its equipment slot."
		return
	if index < 0 or index >= rocks.size():
		return
	var rock: Dictionary = rocks[index]
	if rock.hp <= 0 or rock.cave != underground or not rock.discovered or player.distance_to(rock.pos) >= 100:
		return
	if rock.hard and not upgraded:
		message = "Too tough! Bring 5 copper from Earth to a workbench for a hand drill."
		return
	mining_target = index
	mining_elapsed = 0.0
	next_strike = 0.08 if upgraded else IMPACT_PHASE
	walk_distance = 0.0
	walking = false
	face_direction(rock.pos - player)
	var cancel_hint := "Move or tap Cancel to stop." if hud.touch_mode else "Walk or press E / Space to cancel."
	message = "%s %s. %s" % ["Drilling" if upgraded else "Mining",material_name(rock),cancel_hint]
	update_mining_visual()

func cancel_mining() -> void:
	mining_target = -1
	mining_elapsed = 0.0
	impact_flash = 0.0
	walking = false
	walk_distance = 0
	restore_walk_visual()
	scout.animation = StringName("idle_" + str(facing))
	scout.flip_h = facing_left
	message = "Mining cancelled. You can start again whenever you're ready."

func update_mining_visual() -> void:
	var phase := fmod(mining_elapsed,STRIKE_SECONDS)
	var pose := int(mining_elapsed / 0.09) % 3 if upgraded else mini(2,int(phase / (STRIKE_SECONDS / 3.0)))
	set_mining_pose(pose)
	if upgraded:
		# A small motor tremor accompanies the braced three-pose drill loop.
		scout.offset.x += sin(mining_elapsed * 95) * 0.6 / scout.scale.x

func set_mining_pose(pose: int) -> void:
	scout.sprite_frames = DRILL_VISUAL.MINING[int(world > 0)] if upgraded else (MINER_MINE_FRAMES if world == 0 else MINE_FRAMES)
	scout.animation = StringName("mine_" + str(facing))
	scout.frame = pose
	scout.flip_h = facing_left
	scout.position = player
	scout.rotation = 0
	if upgraded:
		DRILL_VISUAL.fit(scout,world > 0,true,facing)
	else:
		scout.scale = Vector2.ONE * 0.22
		var texture_size := scout.sprite_frames.get_frame_texture(scout.animation,pose).get_size()
		var anchor: Vector2 = MINE_ANCHORS[facing][pose]
		scout.offset = texture_size * 0.5 - anchor + Vector2(0,20.0 / 0.22)
		if facing_left:
			scout.offset.x = -scout.offset.x

func advance_mining(delta: float) -> void:
	if mining_target < 0:
		return
	var rock: Dictionary = rocks[mining_target]
	if rock.hp <= 0 or rock.cave != underground or player.distance_to(rock.pos) >= 100:
		cancel_mining()
		return
	mining_elapsed = minf(mining_elapsed + delta, rock.seconds)
	while next_strike <= mining_elapsed:
		emit_impact(rock, false)
		impact_flash = 0.16
		next_strike += 0.12 if upgraded else STRIKE_SECONDS
	update_mining_visual()
	if mining_elapsed >= rock.seconds:
		rock.hp = 0
		emit_impact(rock, true)
		mining_target = -1
		mining_elapsed = 0.0
		impact_flash = 0.0
		restore_walk_visual()
		scout.animation = StringName("idle_" + str(facing))
		if world == 2:
			if rock.hard: rubies += 1
			else: gold_ore += 1
			desert_won = gold_ore >= 3 and rubies >= 1
			message = "DESERT MISSION COMPLETE! You found gold and fire ruby!" if desert_won else "Desert mission: %d / 3 gold, %d / 1 fire ruby." % [gold_ore,rubies]
		elif world == 1:
			if rock.hard: amethysts += 1
			else: frost_ore += 1
			ice_won = frost_ore >= 3 and amethysts >= 1
			message = "FROST MISSION COMPLETE! You found frost ore and amethyst!" if ice_won else "Frost mission: %d / 3 frost ore, %d / 1 amethyst." % [frost_ore,amethysts]
		elif rock.hard:
			blue_crystals += 1
			won = blue_crystals >= 1
			message = "MISSION COMPLETE! You discovered blue crystal! Visit the rocket to explore Frost Canyon."
		else:
			ore += 1
			total_mined += 1
			message = "Copper collected! %d / 5 for your upgrade." % ore if not upgraded else "More copper for your next adventure!"

func emit_impact(rock: Dictionary, finished: bool) -> void:
	var origin: Vector2 = rock.pos + (player - rock.pos).normalized() * 12 + Vector2(0, -25)
	for i in (18 if finished else (5 if upgraded else 9)):
		var spark := i % 3 == 0
		var life := randf_range(0.4, 0.8)
		var tint := material_tint(rock)
		particles.append({"pos": origin, "velocity": Vector2(randf_range(-65, 65), randf_range(-100, -30)), "life": life, "max_life": life, "spark": spark, "tint": tint if spark else Color("c8b79b"), "size": randf_range(2.5, 4.0)})
	while particles.size() > 96:
		particles.pop_front()

func update_particles(delta: float) -> void:
	impact_flash = maxf(0, impact_flash - delta)
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		particle.life -= delta
		if particle.life <= 0:
			particles.remove_at(i)
		else:
			particle.velocity.y += 150 * delta
			particle.pos += particle.velocity * delta

func refresh_ui() -> void:
	if is_instance_valid(gardens): gardens.sync_area()
	if is_instance_valid(wood_supplies): wood_supplies.sync_area()
	if is_instance_valid(companion): companion.sync_area()
	if current_region() == 0:
		local_life.populate(world,0,underground,regions(),self)
	else:
		local_life.clear()
	if is_instance_valid(trial): trial.sync_area()
	green_surface.visible = world == 0 and earth_region == 0 and not underground
	green_surface.process_mode = Node.PROCESS_MODE_INHERIT if green_surface.visible else Node.PROCESS_MODE_DISABLED
	moss_water.visible = world == 0 and earth_region == 0 and underground
	moss_water.process_mode = Node.PROCESS_MODE_INHERIT if moss_water.visible else Node.PROCESS_MODE_DISABLED
	earth_stream.visible = true
	lava_environment.visible = world == 2 and current_region() == 0 and underground
	rocket.visible = not underground and has_base()
	if hud == null:
		return
	planet_menu.set_touch_mode(hud.touch_mode)
	if camp_menu.visible: camp_menu.present()
	var flying := flight != Flight.IDLE or earth_transition
	hud_layer.visible = not flying
	flight_caption_panel.visible = flying
	flight_caption.text = message
	var inventory: Vector2i = [Vector2i(ore,blue_crystals),Vector2i(frost_ore,amethysts),Vector2i(gold_ore,rubies)][world]
	var objective := "Build hand drill: %d / 5 copper" % ore
	if upgraded:
		objective = ["Find blue crystal in an Earth mine","Collect 3 frost ore and 1 amethyst","Collect 3 gold and 1 fire ruby"][world]
		if [won,ice_won,desert_won][world]:
			objective = "%s trails: %d / 5 discovered" % [PLANET_NAMES[world],visited_regions().size()]
	var context := ""
	var actionable := true
	if mining_target >= 0:
		var rock: Dictionary = rocks[mining_target]
		context = "E / Space   Cancel %s · %.1fs" % ["drilling" if upgraded else "mining",maxf(0,rock.seconds-mining_elapsed)]
	elif not underground and has_base() and player.distance_to(ship_position()) < 95:
		context = "E   Choose a world"
	elif not underground and has_base() and player.distance_to(camp_position()) < 140:
		context = "E   Camp workbench"
	elif is_instance_valid(wood_supplies) and wood_supplies.nearest() >= 0:
		context = "E   Pick up wood"
	elif (not underground and regions().has_mine(current_region()) and player.distance_to(cave_position()) < 130) or (underground and player.distance_to(exit_position()) < 120):
		context = "Walk to the surface" if underground else "Walk into " + mine_name()
		actionable = false
	elif nearest_rock() >= 0:
		var rock: Dictionary = rocks[nearest_rock()]
		context = "E / Space   %s %s · %ds" % ["Drill" if upgraded else "Mine",material_name(rock),int(rock.seconds)]
		if rock.hard and not upgraded:
			context = "Hand drill needed · build at camp"
			actionable = false
	var trial_active: bool = is_instance_valid(trial) and trial.is_active()
	if trial_active and trial.sword_equipped() and nearest_rock() >= 0 and mining_target < 0 and wood_supplies.nearest() < 0 and player.distance_to(camp_position()) >= 140 and player.distance_to(ship_position()) >= 95:
		context = "Select mining tool to mine"
		actionable = false
	hud.present({"world":world,"place":mine_name() if underground else regions().NAMES[current_region()], "inventory":inventory,
		"upgraded":upgraded,"objective":objective,"context":context,"actionable":actionable,
		"flying":flying,"menu":menu_open(),"mining":mining_target >= 0,"message":message,
		"trial_active":trial_active,"health":trial.health if is_instance_valid(trial) else 10,
		"wood":trial.wood,"sword_owned":trial.sword_owned,"earth_explored":earth_visited.size(),
		"mining_reachable":mining_target >= 0 or nearest_rock() >= 0,
		"selected_tool":trial.selected_tool if trial_active else 0,"defeated":trial.defeated if trial_active else 0,
		"snake_count":trial.snakes.size() if trial_active else 0,"jabbing":trial.jab_time >= 0 if trial_active else false})

func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, color)

func _draw() -> void:
	if world != 2 and (underground or world == 1) and current_region() == 0:
		draw_rect(Rect2(0, 0, 2000, 1400), Color("182d2b") if underground else Color("719c58"))
	if underground:
		if world != 2 and current_region() == 0:
			draw_texture_rect(FROST_MINE_ART if world == 1 else MINE_ART, Rect2(Vector2.ZERO, MINE_LAYOUT.WORLD_SIZE), false)
		var lamps: PackedVector2Array = [MINE_LAYOUT.LAMPS, FROST_LAYOUT.LAMPS, DESERT_LAYOUT.LAMPS][world]
		if current_region() > 0:
			lamps = PackedVector2Array(regions().MINE_LAMPS[current_region()])
		for i in lamps.size():
			var lamp: Vector2 = regions().from_art(lamps[i]) if current_region() > 0 else (DESERT_LAYOUT.from_art(lamps[i]) if world == 2 else MINE_LAYOUT.from_art(lamps[i]))
			var flicker := 0.012 + sin(elapsed * 4.3 + i * 2.1) * 0.004
			for radius in [25, 40, 58]:
				draw_circle(lamp, radius, Color(1.0, 0.65, 0.22, flicker))
	else:
		if world == 1 and current_region() == 0:
			draw_texture_rect(ICE_ART, Rect2(0, 0, 2000, 1400), false)
		elif world == 2 and current_region() == 0:
			draw_texture_rect(DESERT_ART, Rect2(0, 0, 2000, 1400), false)
	WORLD_SIGNS.draw_map(self, world, current_region(), underground, regions())

	for rock_index in rocks.size():
		var rock: Dictionary = rocks[rock_index]
		if rock.cave != underground or rock.hp <= 0 or not rock.discovered:
			continue
		var reveal_alpha := smoothstep(0.0, ORE_REVEAL_SECONDS, elapsed - float(rock.get("revealed_at", -ORE_REVEAL_SECONDS)))
		var p: Vector2 = rock.pos
		if rock_index == mining_target and impact_flash > 0:
			p.x += sin(impact_flash * 110) * 2.5
		ellipse(p + Vector2(0, 13), Vector2(35, 20), Color(0, 0, 0, 0.16 * reveal_alpha))
		var ore_art: Texture2D = (AMETHYST_ART if rock.hard else BLUE_ORE_ART) if world == 1 else (BLUE_ORE_ART if rock.hard else COPPER_ART)
		if world == 2:
			ore_art = RUBY_ART if rock.hard else GOLD_ART
		draw_texture_rect(ore_art, Rect2(p + ORE_SPAWNS.ART_BOUNDS.position, ORE_SPAWNS.ART_BOUNDS.size), false, Color(1, 1, 1, reveal_alpha))
	if flight == Flight.IDLE:
		ellipse(player + Vector2(0, 20), Vector2(23, 9), Color(0, 0, 0, 0.25))
	if mining_target >= 0:
		var target: Dictionary = rocks[mining_target]
		var bar_pos: Vector2 = target.pos + Vector2(-48, -72)
		draw_rect(Rect2(bar_pos, Vector2(96, 10)), Color("182c2a"))
		draw_rect(Rect2(bar_pos + Vector2(2, 2), Vector2(92 * mining_elapsed / target.seconds, 6)), material_tint(target))

func draw_mining_effects() -> void:
	for particle in particles:
		var tint: Color = particle.tint
		tint.a = particle.life / particle.max_life
		if particle.spark:
			mining_fx.draw_line(particle.pos, particle.pos - particle.velocity.normalized() * 7, tint, 2)
		else:
			mining_fx.draw_circle(particle.pos, particle.size * (2.0 - tint.a), tint)
