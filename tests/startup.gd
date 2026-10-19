extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://startup.tscn")
	var scene = load("res://startup.tscn")
	var original_aspect := root.content_scale_aspect
	for control in ["touch","keyboard"]:
		change_scene_to_packed(scene)
		await scene_changed
		var welcome = current_scene
		await process_frame
		assert(welcome.stage == welcome.Stage.GUIDE)
		assert(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND)
		assert(welcome.logo.texture.region.size.x / welcome.logo.texture.region.size.y > 3.5,"The wordmark should be a single wide line")
		var original_size := root.size
		for window_size in [Vector2i(1920,1080),Vector2i(1024,768),Vector2i(768,1024)]:
			root.size = window_size
			await process_frame
			await process_frame
			var screen := root.get_visible_rect()
			assert(welcome.backdrop.get_global_rect().encloses(screen),"Welcome artwork leaves a viewport border")
			assert(screen.encloses(welcome.start_button.get_global_rect()),"Start button is clipped after resizing")
		root.size = original_size
		await process_frame
		assert(not root.has_node("GreenPlanet"),"The world started before the player chose to explore")
		assert(welcome.walk_text.text.contains("WASD") and welcome.mine_text.text.contains("5 copper"))
		await key(KEY_D,true)
		await key(KEY_D,false)
		assert(current_scene == welcome and welcome.stage == welcome.Stage.GUIDE,"Walking skipped the guide")
		if control == "touch":
			welcome.set_touch_mode(true)
			assert(welcome.walk_text.text.contains("Drag") and welcome.mine_text.text.contains("Tap"))
			assert(welcome.start_button.size.y >= 60)
			var point: Vector2 = welcome.start_button.get_global_transform_with_canvas() * (welcome.start_button.size*0.5)
			# Releasing off the start button leaves the guide in place.
			await touch(3,point,true)
			await touch(3,point-Vector2(0,200),false)
			assert(welcome.stage == welcome.Stage.GUIDE)
			await touch(3,point,true)
			await touch(4,point,true)
			await touch(4,point,false)
			assert(welcome.stage == welcome.Stage.GUIDE,"Another finger activated the held button")
			await touch(3,point,false)
		else:
			await key(KEY_ENTER,true)
			await key(KEY_ENTER,false)
		assert(welcome.stage != welcome.Stage.GUIDE and welcome.start_button.disabled)
		# Duplicate starts while resources load must not request another world.
		welcome.start_exploring()
		var deadline := Time.get_ticks_msec()+12000
		while is_instance_valid(welcome) and current_scene == welcome and Time.get_ticks_msec() < deadline:
			await process_frame
		assert(current_scene != welcome,"The world never finished loading")
		var game = current_scene
		assert(root.content_scale_aspect == original_aspect,"Welcome resizing changed the gameplay camera aspect")
		assert(game.world == 0 and not game.underground)
		assert(game.player.is_equal_approx(Vector2(560,550)) and game.mining_target == -1)
		assert(game.scout.sprite_frames == game.MINER_FRAMES)
		assert(game.rocks.all(func(rock): return not rock.discovered),"Starting the game immediately revealed minerals")
	print("PASS: full-window welcome artwork, wide/tablet/portrait resize, single-line logo, guide before Earth, keyboard/touch starts without visible minerals, one load and restored gameplay aspect")
	quit()
