extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, detail: String) -> void:
	if condition: return
	failures += 1
	push_error(detail)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	Input.parse_input_event(event)
	await process_frame

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform()*point
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func tap(index: int, button: Button) -> void:
	var point: Vector2 = button.get_global_transform_with_canvas()*(button.size*0.5)
	await touch(index,point,true)
	await touch(index,point,false)

func approach(game: Node) -> void:
	game.player = game.rowan.position+Vector2(0,28)
	game.scout.position = game.player
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()

func run() -> void:
	# Enter through F5's actual welcome scene, not a review scene.
	change_scene_to_file("res://startup.tscn")
	await scene_changed
	await process_frame
	current_scene.start_exploring()
	var deadline := Time.get_ticks_msec()+12000
	while not current_scene.scene_file_path.ends_with("main.tscn") and Time.get_ticks_msec() < deadline:
		await process_frame
	check(current_scene.scene_file_path.ends_with("main.tscn"),"Normal startup did not load the main game")
	var game = current_scene
	game.set_process(false)
	await process_frame
	var rowan = game.rowan
	var bubble = game.character_bubble
	check(rowan.visible and rowan.position == Vector2(590,454),"Rowan is missing from her approved camp position")
	var scout_bounds: Rect2i = rowan.visible_bounds(game.MINER_FRAMES.get_frame_texture(&"idle_down",0).get_image())
	check(is_equal_approx(rowan.height,scout_bounds.size.y*0.15),"Rowan exceeds Scout's visible height")
	check(absf(rowan.illustration.texture.region.size.y*rowan.illustration.scale.y-rowan.height) < 0.01,"Rowan's fitted art does not match the measured height")
	check(rowan.greeted and bubble.anchor == rowan and not game.menu_open(),"Camp greeting is missing or blocks gameplay")
	check(not game.trial.sword_owned and game.ore == 0 and game.trial.wood == 0,"Meeting Rowan granted ingredients or equipment")
	# The overlapping camp approach must still select the workbench at camp.
	game.player = game.CAMP
	game.cooldown = 0
	game.refresh_ui()
	check(game.action_button.text.contains("workbench"),"Rowan stole the workbench prompt")
	game.interact()
	check(game.camp_menu.visible and not game.dialogue_open(),"The workbench is inaccessible beside Rowan")
	game.camp_menu.dismiss()
	approach(game)
	check(game.action_button.text.contains("Talk to Rowan"),"Approaching Rowan does not offer Talk")
	await key(KEY_E)
	check(game.dialogue_open() and bubble.anchor == rowan and bubble.page_index == 0,"E did not open the first Rowan page exactly once")
	check(game.menu_open() and game.trial.blocked() and not game.action_button.visible,"Conversation did not block exploration/combat controls")
	var before: Vector2 = game.player
	game.move_player(Vector2.RIGHT,1)
	game.space_action()
	game.travel_to_other_planet(1)
	check(game.player == before and game.trial.jab_time < 0 and game.flight == 0,"Movement, attacks or travel continued beneath dialogue")
	await key(KEY_R)
	await key(KEY_SPACE)
	check(not game.reset_confirmation.visible and bubble.page_index == 0,"Dialogue leaked reset/attack keys")
	game.message = "A lower priority hint."
	game.refresh_ui()
	check(bubble.is_dialogue_open() and bubble.anchor == rowan,"A notification interrupted Rowan")
	await key(KEY_E)
	check(bubble.page_index == 1 and not rowan.introduced,"Advancing a page finished the conversation early")
	await key(KEY_E)
	check(not game.dialogue_open() and rowan.introduced and not game.camp_menu.visible,"Finishing the dialogue also opened another interaction")
	check(bubble.anchor == game.scout,"Deferred notification did not appear over Scout after dialogue")
	bubble._process(5)
	game.refresh_ui()
	check(not bubble.visible,"A completed greeting/notification immediately repeated")
	game.move_player(Vector2.RIGHT,0.1)
	check(game.player != before,"Walking did not resume after dialogue")
	# Touching Talk while a thumb rests on the pad must discard that gesture.
	game.hud.set_touch_mode(true)
	approach(game)
	var joy = game.hud.touch_controls
	var center: Vector2 = joy.get_global_transform_with_canvas()*joy.CENTER
	await touch(0,center+Vector2(65,0),true)
	game.refresh_ui() # The manually stepped game applies first-touch layout here.
	await tap(1,game.action_button)
	check(game.dialogue_open() and bubble.touch_mode and bubble.next_button.size.y >= 56,"Touch Talk did not open a usable conversation")
	check(joy.finger == -1 and joy.direction == Vector2.ZERO and not joy.visible,"Touch Talk kept a held walking gesture")
	await tap(2,bubble.close_button)
	check(not game.dialogue_open() and joy.visible and joy.direction == Vector2.ZERO,"Closing touch dialogue left movement blocked or held")
	await touch(0,center,false)
	# Real crafting retains its exact cost and gets a relevant Rowan response.
	game.player = game.CAMP
	game.cooldown = 0
	game.ore = 3
	game.trial.wood = 2
	game.interact()
	game.camp_menu.craft("sword")
	check(game.trial.sword_owned and game.ore == 0 and game.trial.wood == 0,"Rowan changed the sword recipe or spent ingredients twice")
	game.camp_menu.dismiss()
	rowan.advance_departure(1)
	approach(game)
	check(rowan.departed and not rowan.can_talk(),"Rowan did not leave after the completed sword quest")
	await TRAVEL.enter(game,1,false)
	check(not rowan.visible and not rowan.can_talk(),"Rowan followed Scout to another district")
	await TRAVEL.enter(game,0,true)
	check(not rowan.visible,"Rowan is visible inside a mine")
	await TRAVEL.enter(game,0,false)
	check(not rowan.visible and rowan.departed and rowan.introduced and rowan.greeted,"Returning to camp respawned the completed character or lost conversation memory")
	game.queue_free()
	await process_frame
	var fresh = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	check(not fresh.rowan.introduced and not fresh.trial.sword_owned,"A fresh game inherited Rowan or sword progress")
	fresh.queue_free()
	await process_frame
	if failures == 0: print("PASS: normal startup, approved Rowan position/scale, greeting, keyboard/touch Talk, input/combat pause, notice priority, workbench crafting, area scope and session reset")
	quit(1 if failures else 0)
