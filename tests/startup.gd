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
	for control in ["touch","keyboard"]:
		change_scene_to_packed(scene)
		await scene_changed
		var welcome = current_scene
		await process_frame
		assert(welcome.stage == welcome.Stage.GUIDE)
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
		assert(game.world == 0 and not game.underground)
		assert(game.player.is_equal_approx(Vector2(560,550)) and game.mining_target == -1)
		assert(game.scout.sprite_frames == game.MINER_FRAMES)
	print("PASS: guide before Earth, keyboard and touch instructions, cancelled/multiple-finger taps, one start request, keyboard start and loaded Earth")
	quit()
