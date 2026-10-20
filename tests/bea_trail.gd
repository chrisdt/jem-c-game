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
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
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

func approach(game, npc, offset := Vector2(0,30)) -> void:
	game.player = npc.position+offset
	game.scout.position = game.player
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()

func run() -> void:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.trial.invulnerable = 10000
	var bea = game.bea
	var rowan = game.rowan
	var bubble = game.character_bubble
	check(not bea.visible and not bea.greeted,"Bea appeared or greeted in Landing Meadow")
	check(bea.position == Vector2(1632,1138) and absf(bea.head_width-rowan.head_width) < 0.01,"Bea lost the approved position or matching head size")
	check(absf(bea.illustration.texture.region.size.y*bea.illustration.scale.y-bea.height) < 0.01,"Bea's fitted sprite does not match her measured height")
	await TRAVEL.enter(game,1,false)
	check(not bea.visible and not bea.can_talk() and not bea.greeted,"An undiscovered Bea appeared through fog or offered Talk")
	approach(game,bea)
	if bubble.anchor != bea:
		bubble._process(5) # Let any remaining arrival notice finish first.
		game.refresh_ui()
	check(bea.visible and bea.greeted and bubble.anchor == bea and not game.menu_open(),"Discovery did not produce Bea's non-blocking greeting")
	bubble._process(5)
	game.refresh_ui()
	check(not bubble.visible,"Bea's greeting repeated while standing nearby")
	check(game.action_button.text.contains("Talk to Bea") and game.nearest_npc() == bea,"The Talk prompt does not select Bea")
	await key(KEY_E)
	check(game.dialogue_npc == bea and bubble.speaker_label.text == "BEA" and bubble.page_index == 0,"E opened the wrong speaker or skipped the first page")
	var before: Vector2 = game.player
	var trial_time: float = game.trial.seconds
	game.move_player(Vector2.RIGHT,1)
	game._process(0.5)
	await key(KEY_SPACE)
	await key(KEY_R)
	check(game.player == before and game.trial.seconds == trial_time and game.trial.jab_time < 0 and not game.reset_confirmation.visible,"Bea's dialogue leaked movement, combat or reset input")
	await key(KEY_ESCAPE)
	check(not bea.introduced and game.dialogue_npc == null,"Cancelling marked Bea introduced or retained her conversation")
	game.cooldown = 0
	await key(KEY_E)
	await key(KEY_E)
	check(bubble.body_label.text.contains("Rowan") and bubble.final_action == "Done","A player without a sword has no camp guidance")
	await key(KEY_E)
	check(bea.introduced and not rowan.introduced and rowan.mission == rowan.Mission.NOT_STARTED,"Completing Bea's conversation changed Rowan's mission")
	check(game.ore == 0 and game.trial.wood == 0 and not game.trial.sword_owned,"Bea's introduction granted resources or equipment")
	# The same context action supports touch and clears a thumb left on the pad.
	game.hud.set_touch_mode(true)
	approach(game,bea)
	var joy = game.hud.touch_controls
	var center: Vector2 = joy.get_global_transform_with_canvas()*joy.CENTER
	await touch(0,center+Vector2(65,0),true)
	game.refresh_ui()
	await tap(1,game.action_button)
	check(game.dialogue_npc == bea and bubble.touch_mode and bubble.next_button.size.y >= 56,"Touch Talk did not open Bea with usable buttons")
	check(joy.direction == Vector2.ZERO and joy.finger == -1 and not joy.visible,"Touch Talk retained a held movement gesture")
	await tap(2,bubble.close_button)
	await touch(0,center,false)
	check(not game.dialogue_open() and game.dialogue_npc == null and joy.visible,"Touch Close did not restore exploration")
	# Two nearby people must use the same nearest speaker for label and action.
	var rowan_home: Vector2 = rowan.position
	rowan.home_region = 1
	rowan.position = bea.position+Vector2(90,0)
	approach(game,bea,Vector2(5,0))
	check(game.nearest_npc() == bea and game.action_button.text.contains("Bea"),"A farther NPC stole Bea's prompt")
	approach(game,rowan,Vector2(0,25))
	check(game.nearest_npc() == rowan and game.action_button.text.contains("Rowan"),"The closest NPC did not get the Talk prompt")
	game.interact()
	check(game.dialogue_npc == rowan and bubble.speaker_label.text == "ROWAN","The actual interaction disagreed with the nearest prompt")
	await key(KEY_E)
	await key(KEY_E)
	check(rowan.mission == rowan.Mission.ACTIVE,"Rowan's own acceptance no longer works after talking to Bea")
	rowan.home_region = 0
	rowan.position = rowan_home
	game.refresh_ui()
	approach(game,bea)
	game.interact()
	await key(KEY_E)
	check(rowan.mission == rowan.Mission.ACTIVE and not rowan.completion_seen,"Bea changed Rowan's active mission or ending")
	# Use the real camp craft to check Bea's equipment-aware advice.
	await TRAVEL.enter(game,0,false)
	game.player = game.CAMP
	game.cooldown = 0
	game.ore = 3
	game.trial.wood = 2
	game.interact()
	game.camp_menu.craft("sword")
	game.camp_menu.dismiss()
	await TRAVEL.enter(game,1,false)
	approach(game,bea)
	game.interact()
	check(bubble.final_action == "Accept mission" and bubble.body_label.text.contains("supply box") and rowan.mission == rowan.Mission.COMPLETE,"Bea did not offer Woodland Supplies after the sword craft or Rowan lost completion")
	bubble.dismiss()
	await TRAVEL.enter(game,1,true)
	check(not bea.visible and not bea.can_talk(),"Bea appeared inside Copper Hollow")
	await TRAVEL.enter(game,0,false)
	TRAVEL.depart(game,1)
	game.advance_flight(10)
	check(not bea.visible and not bea.can_talk(),"Bea appeared on another planet")
	TRAVEL.depart(game,0)
	game.advance_flight(10)
	await TRAVEL.enter(game,1,false)
	check(bea.introduced and bea.greeted,"Area/planet travel lost Bea's conversation memory")
	approach(game,bea)
	game.interact()
	bea.queue_free()
	await process_frame
	bubble._process(0)
	check(not game.dialogue_open() and game.dialogue_npc == null,"Removing the speaker stranded a conversation")
	check(game.nearest_npc() == null and rowan.mission == rowan.Mission.COMPLETE,"A freed speaker stayed selectable or changed Rowan")
	# Randomized scenery must preserve a clear place for the approved actor.
	var rng := RandomNumberGenerator.new()
	for layout in 32:
		rng.seed = layout
		for rock in game.EARTH.generate(1,rng):
			if not rock.cave:
				check(rock.pos.distance_to(game.EARTH.BEA_FOOT-game.EARTH.FOOT_OFFSET) >= 120,"A randomized ore layout overlaps Bea")
	check(game.EARTH.can_walk(1,false,game.EARTH.BEA_FOOT-game.EARTH.FOOT_OFFSET),"The approved foot point is not walkable")
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await process_frame
	check(not current_scene.bea.introduced and not current_scene.bea.greeted and not current_scene.bea.visible,"A confirmed new game kept Bea's introduction or discovery")
	if failures == 0: print("PASS: approved Bea size/position, fog/greeting, keyboard/touch Talk, nearest-speaker ownership, Rowan isolation and acceptance, real crafting advice, area/planet scope, speaker cleanup, 32 ore layouts and reset")
	quit(1 if failures else 0)
