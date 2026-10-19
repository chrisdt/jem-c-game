extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func key(code: Key, pressed := true, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform()*point
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func center(button: Button) -> Vector2:
	return button.get_global_transform_with_canvas()*(button.size*0.5)

func click(button: Button) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = root.get_final_transform()*center(button)
		event.global_position = event.position
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func run() -> void:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	var prompt = game.reset_confirmation
	check(not prompt.visible and not paused,"New game starts paused or with a reset prompt")
	game.ore = 4
	game.blue_crystals = 2
	game.upgraded = true
	game.trial.health = 6
	game.trial.sword_owned = true
	game.trial.wood = 4
	game.trial.equip(1)
	game.gardens.plants[0].picked = true
	game.trial.snakes[0].health = 2
	await key(KEY_R)
	check(current_scene == game and prompt.visible and paused,"R reset the game instead of opening a paused confirmation")
	check(root.gui_get_focus_owner() == prompt.no_button,"No is not the default choice")
	var clock: float = game.elapsed
	var snake_position: Vector2 = game.trial.snakes[0].position
	var player: Vector2 = game.player
	var jab_id: int = game.trial.jab_id
	for code in [KEY_R,KEY_E,KEY_1,KEY_SPACE,KEY_D]:
		# Space activates the focused No button, so test gameplay keys with
		# focus temporarily released; confirmation itself is checked below.
		if code == KEY_SPACE: root.gui_release_focus()
		await key(code)
		await key(code,false)
	await key(KEY_R,true,true)
	await key(KEY_R,false)
	await create_timer(0.12).timeout
	check(current_scene == game and prompt.visible and paused,"Repeated/gameplay keys escaped the modal")
	check(game.elapsed == clock and game.player == player and game.trial.snakes[0].position == snake_position,"Gameplay or wildlife continued while choosing")
	check(game.trial.jab_id == jab_id and game.trial.selected_tool == 1,"Gameplay input changed equipment or attacked beneath the prompt")
	await click(prompt.no_button)
	check(not prompt.visible and not paused and current_scene == game,"Clicking No did not resume the same game")
	check(game.ore == 4 and game.blue_crystals == 2 and game.upgraded and game.trial.sword_owned and game.trial.wood == 4 and game.trial.health == 6,"No lost inventory, upgrade or health")
	check(game.gardens.plants[0].picked and game.trial.snakes[0].health == 2,"No lost harvested/enemy state")
	game.set_process(false)
	await key(KEY_R)
	await key(KEY_R,false)
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE,false)
	check(not prompt.visible and not paused and current_scene == game,"Escape did not cancel reset")
	await key(KEY_R)
	await key(KEY_R,false)
	await key(KEY_TAB)
	await key(KEY_TAB,false)
	check(root.gui_get_focus_owner() == prompt.yes_button,"Tab did not reach Yes")
	await key(KEY_TAB)
	await key(KEY_TAB,false)
	check(root.gui_get_focus_owner() == prompt.no_button,"Tab escaped the reset prompt")
	await key(KEY_ENTER)
	await key(KEY_ENTER,false)
	check(not prompt.visible and not paused and current_scene == game,"Enter on default No did not safely resume")
	# Cancellation preserves an in-progress mining attempt exactly.
	game.trial.equip(0)
	game.player = game.rocks[0].pos
	game.update_exploration()
	game.start_mining(0)
	game.advance_mining(0.5)
	var progress: float = game.mining_elapsed
	check(game.mining_target == 0 and progress > 0,"Mining fixture did not start")
	await key(KEY_R)
	await key(KEY_R,false)
	game.set_process(true)
	await create_timer(0.10).timeout
	check(game.mining_elapsed == progress,"Mining advanced while reset was pending")
	game.set_process(false)
	await click(prompt.no_button)
	check(game.mining_target == 0 and game.mining_elapsed == progress,"No discarded partial mining progress")
	game.cancel_mining()
	# A cancelled prompt also returns to the destination picker and its focus.
	game.planet_menu.open(game.world)
	var previous_focus: Control = root.gui_get_focus_owner()
	await key(KEY_R)
	await key(KEY_R,false)
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE,false)
	check(game.planet_menu.visible and root.gui_get_focus_owner() == previous_focus,"Cancel closed the destination picker or lost its keyboard focus")
	game.planet_menu.dismiss()
	game.refresh_ui()
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	check(game.camp_menu.visible,"Workbench fixture did not open")
	previous_focus = root.gui_get_focus_owner()
	await key(KEY_R)
	await key(KEY_R,false)
	await click(prompt.no_button)
	check(game.camp_menu.visible and root.gui_get_focus_owner() == previous_focus and game.trial.sword_owned and game.trial.wood == 4,"No lost workbench focus or crafted progress")
	game.camp_menu.dismiss()
	# Touch choices remain usable while paused, even with a walking thumb held.
	game.hud.set_touch_mode(true)
	game.refresh_ui()
	var pad: Control = game.hud.touch_controls
	var walk_point: Vector2 = pad.position+pad.CENTER+Vector2(60,0)
	await touch(0,walk_point,true)
	check(game.hud.touch_controls.direction.x > 0,"Touch fixture did not hold the walk pad")
	await key(KEY_R)
	await key(KEY_R,false)
	check(game.hud.touch_controls.direction == Vector2.ZERO and game.hud.touch_controls.finger == -1,"Opening reset left a held walking gesture active")
	await touch(1,center(prompt.no_button),true)
	await touch(1,center(prompt.no_button),false)
	check(not prompt.visible and not paused and current_scene == game,"Touch No failed while a second thumb was held")
	await touch(0,walk_point,false)
	# Confirming from a paused flight creates one fresh playable session.
	game.travel_to_other_planet(1)
	var stage: int = game.flight
	await key(KEY_R)
	await key(KEY_R,false)
	game.set_process(true)
	var flight_time: float = game.flight_elapsed
	await create_timer(0.10).timeout
	check(game.flight == stage and game.flight_elapsed == flight_time,"Flight continued beneath reset confirmation")
	await touch(2,center(prompt.yes_button),true)
	await touch(2,center(prompt.yes_button),false)
	var deadline := Time.get_ticks_msec()+10000
	while (current_scene == null or current_scene == game) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(current_scene != null and current_scene != game,"Yes did not create a fresh game")
	var fresh = current_scene
	check(not paused and not fresh.reset_confirmation.visible,"Confirmed reset left the new game paused")
	check(fresh.ore == 0 and fresh.blue_crystals == 0 and not fresh.upgraded and not fresh.trial.sword_owned and fresh.trial.wood == 0,"Yes kept old inventory or upgrade")
	check(fresh.trial.health == 10 and fresh.trial.snakes[0].health == 9 and not fresh.gardens.plants[0].picked,"Yes kept old health, enemies or harvested state")
	check(fresh.world == 0 and fresh.flight == fresh.Flight.IDLE and fresh.mining_target == -1,"Reset did not return to the initial playable world")
	# Standalone cleanup must restore the pause state it originally owned.
	paused = true
	fresh.reset_confirmation.open()
	fresh.reset_confirmation.dismiss()
	check(paused,"Closing the prompt overwrote an existing pause")
	paused = false
	fresh.reset_confirmation.open()
	fresh.queue_free()
	await process_frame
	await process_frame
	check(not paused,"Removing an open prompt left the tree paused")
	if failures == 0:
		print("PASS: R confirmation, default No, gameplay/wildlife/mining/flight pause, mouse No, Escape, menu focus, independent touch choices, preserved progress on cancel and fresh unpaused game on Yes")
	quit(1 if failures else 0)
