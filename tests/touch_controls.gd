extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func touch(index: int, point: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = get_root().get_final_transform() * point
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	await process_frame

func drag(index: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = get_root().get_final_transform() * point
	Input.parse_input_event(event)
	await process_frame

func tap(index: int, button: Button) -> void:
	var point: Vector2 = button.get_global_transform_with_canvas() * (button.size*0.5)
	await touch(index,point,true)
	await touch(index,point,false)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	assert(not game.hud.touch_mode and not game.hud.touch_controls.visible)
	game.hud.set_touch_mode(true)
	game.refresh_ui()
	var joy = game.hud.touch_controls
	var center: Vector2 = joy.get_global_transform_with_canvas() * joy.CENTER
	game.player = Vector2(600,600)
	await touch(0,center+Vector2(65,0),true)
	assert(joy.direction.is_equal_approx(Vector2.RIGHT),"Touch direction %s, finger %s, viewport transform %s" % [joy.direction,joy.finger,get_root().get_final_transform()])
	var before: Vector2 = game.player
	game._process(0.1)
	assert(is_equal_approx(game.player.x-before.x,23.5) and game.walking)
	await touch(1,center+Vector2(-65,0),true)
	await drag(1,center+Vector2(0,-65))
	assert(joy.direction.is_equal_approx(Vector2.RIGHT),"A second finger hijacked the walk pad")
	await touch(1,center,false)
	await drag(0,center+Vector2(0,-65))
	assert(joy.direction.is_equal_approx(Vector2.UP))
	await drag(0,center)
	assert(joy.direction == Vector2.ZERO,"The walk pad has no dead zone")
	await touch(0,center,false,true)
	assert(joy.finger == -1 and joy.direction == Vector2.ZERO)
	await touch(0,center+Vector2(65,0),true)
	joy.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(joy.direction == Vector2.ZERO,"Losing browser focus kept walking")
	await touch(0,center,false)
	# A touch release outside the action button must not begin mining. A normal
	# tap starts once, and dragging the movement pad cancels the current attempt.
	game.player = game.rocks[0].pos
	game.update_exploration()
	game.refresh_ui()
	assert(not game.action_button.text.begins_with("E   ") and game.action_button.size.y == 64)
	var action: Vector2 = game.action_button.get_global_transform_with_canvas() * (game.action_button.size*0.5)
	await touch(1,action,true)
	await drag(1,action-Vector2(400,0))
	await touch(1,action-Vector2(400,0),false)
	assert(game.mining_target == -1)
	await tap(1,game.action_button)
	assert(game.mining_target == 0,"Touch started and immediately cancelled mining")
	game.advance_mining(1)
	await touch(0,center+Vector2(65,0),true)
	game._process(0.01)
	assert(game.mining_target == -1 and game.ore == 0)
	await touch(0,center,false)
	game.player = game.rocks[0].pos
	game.update_exploration()
	game.refresh_ui()
	game.cooldown = 0
	await tap(1,game.action_button)
	game.advance_mining(2)
	assert(game.ore == 1 and game.rocks[0].hp == 0)
	# The same touch action buys a real upgrade, then operates the rocket and
	# destination picker with another finger still resting on the walk pad.
	game.ore = 5
	game.player = game.CAMP
	game.cooldown = 0
	game.refresh_ui()
	await tap(1,game.action_button)
	assert(game.upgraded and game.ore == 0)
	game.player = game.SHIP
	game.cooldown = 0
	game.refresh_ui()
	await touch(0,center,true)
	await tap(1,game.action_button)
	assert(game.planet_menu.visible and not joy.visible and joy.direction == Vector2.ZERO)
	assert(game.planet_menu.buttons[1].size.y == 56 and game.planet_menu.cancel_button.size.y == 52)
	await tap(2,game.planet_menu.buttons[1])
	assert(game.flight != game.Flight.IDLE and not game.planet_menu.visible)
	game.advance_flight(10)
	assert(game.world == 1 and joy.visible and joy.direction == Vector2.ZERO)
	await touch(0,center,false)
	# Resizing/reorienting cannot leave a stale held direction behind.
	await touch(0,center+Vector2(65,0),true)
	get_root().size_changed.emit()
	assert(joy.direction == Vector2.ZERO)
	await touch(0,center,false)
	game.hud.set_touch_mode(false)
	game.refresh_ui()
	assert(not joy.visible and game.action_button.size.y == 40 and game.planet_menu.panel.size.y == 360)
	print("PASS: touch walking, dead zone, finger ownership, cancellation/focus/resize cleanup, mining, drill purchase, multitouch rocket/menu travel and desktop layout")
	quit()
