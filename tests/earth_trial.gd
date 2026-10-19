extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform()*point
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func combat_floor(trial: Node) -> Vector2:
	for y in range(560,800,24):
		for x in range(750,1150,24):
			var point := Vector2(x,y)
			var fits := true
			for offset in [Vector2.ZERO,Vector2.LEFT*90,Vector2.RIGHT*90,Vector2.UP*90,Vector2.DOWN*90]:
				if not trial.floor_at(point+offset): fits = false
			if fits: return point
	return Vector2.INF

func prepare(game: Node, snake: Node, origin: Vector2, direction: Vector2) -> void:
	var trial: Node = game.trial
	trial.jab_time = -1
	trial.jab_cooldown = 0
	trial.invulnerable = 0
	game.player = origin
	game.face_direction(direction)
	game.scout.position = origin
	game.restore_walk_visual()
	snake.position = origin+direction*57
	snake.home = snake.position
	snake.target = snake.position
	snake.seen = true
	snake.fade = 1
	snake.state = "recover"
	snake.clock = 0
	snake.health = 9
	snake.last_jab = -1
	snake.show()
	game.fog.observe(0,snake.position)
	snake.update_pose()

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var trial: Node = game.trial
	check(trial.health == 10 and trial.selected_tool == 0,"Trial must start with five hearts and mining tool")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),"Game playback is not silent")
	check(trial.snakes.size() == 3 and game.gardens.plants.size() == 1,"Landing Meadow lost its bounded trial actors")
	check(trial.is_active() and game.hud.health_panel.visible and game.hud.equip_slots[1].visible,"First-screen HUD is missing")
	check(not game.hud.objective.visible and not game.hud.equipment.visible,"Old overlays duplicate the trial HUD")
	check(game.gardens.plants.all(func(p): return not p.apple),"Landing Meadow contains a fruit tree")
	for plant in game.gardens.plants:
		check(trial.floor_at(plant.position),"Healing plant is outside safe grass")
		var uv: Vector4 = plant.leaves.get_shader_parameter("frame_region")
		check(uv.z < 0.5 and uv.w < 0.7,"Plant mesh displays the full atlas instead of its own artwork")
		for rock in game.rocks:
			check(rock.cave or rock.pos.distance_to(plant.position) >= 100,"Healing plant overlaps a mineral")
	for snake in trial.snakes:
		check(snake.can_stand(snake.position),"Snake started on blocked floor or a landmark")
	check(game.hud.attack_button.visible,"Mining tool has no touch attack")
	trial.equip(1)
	check(trial.sword_equipped() and not game.scout.has_node("CarriedSword"),"Idle sword should be hidden")
	game.upgraded = true
	trial.equip(0)
	check(game.scout.sprite_frames == game.DRILL_VISUAL.WALK[0],"Selecting mining tool lost the drill")
	trial.equip(1)
	check(game.upgraded and game.scout.sprite_frames == game.MINER_FRAMES,"Sword removed drill ownership or left drill hand artwork fitted")
	var origin := combat_floor(trial)
	check(origin.is_finite(),"No clear test floor for the directional jab")
	var snake: Node = trial.snakes[0]
	for other in trial.snakes.slice(1):
		other.health = 0
		other.state = "gone"
		other.hide()
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
		prepare(game,snake,origin,direction)
		check(trial.start_jab(),"A ready sword could not jab")
		check(not trial.start_jab(),"Repeated input bypassed the jab cooldown")
		trial.advance(0.12)
		check(snake.health == 6,"A forward jab did not register one hit: %s" % direction)
		check(game.scout.animation == StringName("jab_"+str(game.facing)),"Jab uses the wrong directional pose")
		check(game.scout.flip_h == (direction == Vector2.LEFT),"Left jab is not mirrored correctly")
		check(not game.scout.has_node("CarriedSword"),"Floating weapon draws over the illustrated jab")
		var row: int = {&"side":0,&"down":1,&"up":2}[game.facing]
		var anchor: Vector2 = trial.ART.ANCHORS.JAB_ANCHORS[row][game.scout.frame]
		var texture: Texture2D = game.scout.sprite_frames.get_frame_texture(game.scout.animation,game.scout.frame)
		var foot: float = (anchor.y-texture.get_height()*0.5+game.scout.offset.y)*game.scout.scale.y
		check(absf(foot-20) < 0.1,"Jab boots jump off the ground")
		trial.advance(0.06)
		check(snake.health == 6,"One thrust applied multiple hits")
		trial.advance(0.4)
		check(trial.jab_time < 0 and game.scout.sprite_frames == game.MINER_FRAMES,"Sword remains visible after its attack")
		# A target behind the player must remain untouched.
		prepare(game,snake,origin,-direction)
		game.face_direction(direction)
		trial.start_jab()
		trial.advance(0.45)
		check(snake.health == 9,"Sword jab hit behind Scout")
	# The starter pick and fitted drill can defend Scout, but remove only one
	# health unit where the sword removes three. All four swings stay grounded.
	for fitted in [false,true]:
		game.upgraded = fitted
		trial.equip(0)
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
			prepare(game,snake,origin,direction)
			check(trial.start_jab(),"Mining tool could not attack")
			trial.advance(0.12)
			check(snake.health == 8,"Pick/drill did not deal exactly one-third sword damage")
			check(game.mining_target == -1 and game.scout.animation == StringName("mine_"+str(game.facing)),"Tool attack started mining or used sword artwork")
			var frames: SpriteFrames = game.DRILL_VISUAL.MINING[0] if fitted else game.MINER_MINE_FRAMES
			check(game.scout.sprite_frames == frames,"Tool attack lost its fitted pick/drill")
			game.start_mining(0)
			check(game.mining_target == -1,"An E/mining action interrupted an attack")
			if not fitted:
				var pose: int = game.scout.frame
				var size: Vector2 = frames.get_frame_texture(game.scout.animation,pose).get_size()
				var foot: float = (game.MINE_ANCHORS[game.facing][pose].y-size.y*0.5+game.scout.offset.y)*game.scout.scale.y
				check(absf(foot-20) < 0.1,"Pick swing lifted Scout's boots")
			trial.advance(0.06)
			check(snake.health == 8,"One pick swing hit multiple times")
			trial.advance(0.5)
	# Nine pick hits defeat a full-health snake; mixed/overkill hits clamp at 0.
	prepare(game,snake,origin,Vector2.RIGHT)
	for hit in 9:
		game.player = snake.position-Vector2.RIGHT*57
		trial.jab_cooldown = 0
		check(trial.start_jab(),"Pick combo failed to start")
		trial.advance(0.18)
		check(snake.health == 8-hit,"Pick kill threshold differs from nine hits")
		trial.advance(0.5)
	check(snake.state == "puff" or snake.state == "gone","Final pick strike did not produce smoke")
	trial.equip(1)
	# A defeated snake poofs once and stays gone through area/planet changes.
	prepare(game,snake,origin,Vector2.RIGHT)
	var before_defeated: int = trial.defeated
	for attack in 3:
		game.player = snake.position-Vector2.RIGHT*57
		game.face_direction(Vector2.RIGHT)
		trial.jab_cooldown = 0
		trial.start_jab()
		trial.advance(0.18)
		check(snake.health == 6-attack*3,"Successive jabs did not remove one snake health each")
		if attack < 2: trial.advance(0.4)
	check(snake.state == "puff" and trial.defeated == before_defeated+1,"Defeated snake did not enter smoke exactly once")
	trial.advance(1.0)
	check(snake.state == "gone" and not snake.visible,"Smoke did not finish and hide the snake")
	# The actual enemy gives a warning, then a single gentle bite.
	prepare(game,snake,origin,Vector2.RIGHT)
	snake.state = "roam"
	trial.health = 10
	trial.invulnerable = 0
	trial.advance(0.30)
	check(snake.state == "warn" and trial.health == 10,"Snake bit without a readable warning")
	trial.advance(0.35)
	check(trial.health == 9,"The warned bite did not deal exactly half a heart")
	trial.advance(0.3)
	check(trial.health == 9,"One bite or contact applied repeated damage")
	snake.health = 0
	snake.state = "gone"
	snake.hide()
	# Half-heart damage is gentle and has a real recovery window.
	trial.health = 10
	trial.invulnerable = 0
	check(trial.hurt_player(1) and trial.health == 9,"Snake bite is not half a heart")
	check(not trial.hurt_player(1) and trial.health == 9,"Contact damage bypassed invulnerability")
	game.refresh_ui()
	check(game.hud.health_hearts[4].texture == trial.ART.icon(2),"Half-heart HUD icon is wrong")
	# Empty health returns safely, retaining the earned materials and tool.
	trial.health = 1
	trial.invulnerable = 0
	game.ore = 4
	trial.hurt_player(1)
	check(trial.health == 10 and game.player == Vector2(560,550) and game.ore == 4 and game.upgraded,"Camp recovery lost inventory or left Scout defeated")
	trial.invulnerable = 0
	check(not trial.hurt_player(1),"The camp's safe area still permits a bite")
	# Menu/help/loading pause the encounter. The prototype is only home surface.
	game.planet_menu.open(0)
	var clock_before: float = trial.seconds
	check(not trial.start_jab(),"Sword attacked while a menu was open")
	trial.advance(1)
	check(trial.seconds == clock_before,"Trial advanced behind a menu")
	game.planet_menu.dismiss()
	for area in [[0,0,true],[0,1,false],[1,0,false],[2,0,false]]:
		game.world = area[0]
		game.earth_region = area[1]
		game.underground = area[2]
		trial.advance(1)
		game.refresh_ui()
		check(not trial.is_active() and not trial.visible and not game.scout.has_node("CarriedSword"),"First-screen content leaked to another area")
		check(not game.hud.equip_slots[0].visible,"Trial HUD leaked to another area")
	game.world = 0
	game.earth_region = 0
	game.underground = false
	trial.advance(0)
	check(snake.state == "gone" and trial.defeated == before_defeated+1,"Revisiting respawned a defeated snake")
	# Long movement stays on floor; direction changes use genuinely different art.
	var living: Node = trial.snakes[1]
	living.health = 9
	living.state = "roam"
	living.seen = true
	living.fade = 1
	living.show()
	game.player = Vector2(560,550)
	for i in 3600:
		living.advance(1.0/60.0)
		check(living.can_stand(living.position),"Slithering crossed blocked terrain")
	var views := {}
	for facing in [Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		living.facing = facing
		living.update_pose()
		views[living.pictures[0].texture.region] = true
	check(views.size() == 3,"Snake has no distinct front/rear/side artwork")
	for direction in [Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		living.facing = direction
		for frame in 6:
			living.phase = float(frame)/6.0
			living.update_pose()
			var picture: Sprite2D = living.pictures[0]
			var bounds := picture.texture.get_image().get_used_rect()
			var visible_size: Vector2 = Vector2(bounds.size)*picture.scale
			check(visible_size.x < 60 and visible_size.y < 60,"A snake view is too large for a small ground animal")
	var positions: Array[Vector2] = []
	for fps in [30,144]:
		living.position = origin
		living.home = origin
		living.state = "chase"
		living.clock = 0
		game.player = origin+Vector2(130,0)
		trial.invulnerable = 0
		var time := 0.0
		while time < 0.35-0.00001:
			var step := minf(1.0/fps,0.35-time)
			living.advance(step)
			time += step
		positions.append(living.position)
	check(positions[0].distance_to(positions[1]) < 0.1,"Slither speed depends on the frame rate")
	# Actual independent touch fingers can equip and jab while walking.
	living.state = "gone"
	living.health = 0
	game.player = Vector2(560,550)
	trial.jab_time = -1
	trial.jab_cooldown = 0
	trial.selected_tool = 0
	game.hud.set_touch_mode(true)
	game.refresh_ui()
	var pad: Node = game.hud.touch_controls
	await touch(0,pad.position+pad.CENTER+Vector2(50,0),true)
	var slot: Control = game.hud.equip_slots[1]
	var slot_at := slot.get_global_rect().get_center()
	await touch(1,slot_at,true)
	await touch(1,slot_at,false)
	check(trial.selected_tool == 1 and pad.finger == 0 and pad.direction == Vector2.RIGHT,"Equipping on touch cancelled the held movement finger")
	game.refresh_ui()
	var attack_at: Vector2 = game.hud.attack_button.get_global_rect().get_center()
	await touch(2,attack_at,true)
	check(trial.jab_time < 0,"Touch attack activated before finger release")
	await touch(2,attack_at,false)
	check(trial.jab_time >= 0 and pad.finger == 0 and pad.direction == Vector2.RIGHT,"A second finger could not jab independently")
	await touch(0,pad.position+pad.CENTER,false)
	check(pad.finger == -1 and pad.direction.is_zero_approx(),"Movement finger remained held after release")
	trial.advance(0.5)
	game.refresh_ui()
	var tool_at: Vector2 = game.hud.equip_slots[0].get_global_rect().get_center()
	await touch(1,tool_at,true)
	await touch(1,tool_at,false)
	check(trial.selected_tool == 0 and game.scout.sprite_frames == game.DRILL_VISUAL.WALK[0],"Touching the first slot failed to restore the drill")
	trial.jab_cooldown = 0
	game.refresh_ui()
	check(game.hud.attack_button.visible,"Pick/drill attack button is hidden")
	await touch(2,game.hud.attack_button.get_global_rect().get_center(),true)
	await touch(2,game.hud.attack_button.get_global_rect().get_center(),false)
	check(trial.jab_time >= 0 and game.scout.sprite_frames == game.DRILL_VISUAL.MINING[0],"Touch Attack did not animate the mining tool")
	trial.advance(0.5)
	check(game.gardens.effects.size() <= 4,"Healing effects accumulated")
	game.queue_free()
	await process_frame
	await process_frame
	# Different random ore layouts must leave the single starting berry bush on
	# safe grass; fallback sites handle a deposit occupying a preferred spot.
	for run_index in 10:
		var fresh = load("res://main.tscn").instantiate()
		root.add_child(fresh)
		fresh.set_process(false)
		check(fresh.gardens.plants.size() == 1 and fresh.trial.snakes.size() == 3,"A new layout omitted trial actors")
		for plant in fresh.gardens.plants:
			check(fresh.trial.floor_at(plant.position),"Fresh-layout healing plant is not on clear ground")
			for rock in fresh.rocks:
				check(rock.cave or rock.pos.distance_to(plant.position) >= 100,"Fresh-layout healing plant overlaps ore")
		check(fresh.trial.health == 10 and fresh.trial.defeated == 0 and fresh.gardens.plants.all(func(p): return not p.picked),"Fresh game inherited trial progress")
		fresh.queue_free()
		await process_frame
		await process_frame
	if failures == 0:
		print("PASS: first-screen trial, hidden idle sword, grounded four-direction sword/pick/drill attacks, 3:1 damage and three-sword/nine-tool thresholds, one-hit/cooldown/front-only strikes, small directional snakes, smoke memory, safe 30/144fps slithering, half-heart protection/recovery, HUD/tool ownership, independent touch fingers, menus/travel scope and silent playback")
	quit(1 if failures else 0)
