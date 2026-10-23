extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle(session: Node) -> void:
	var deadline := Time.get_ticks_msec()+20000
	while session.busy and Time.get_ticks_msec()<deadline: await process_frame
	check(not session.busy,"Adventure request timed out")
func freeze(game: Node) -> void:
	game.set_process(false)
	for object in [game.story,game.frost_story,game.ember_story,game.gardens,game.wood_supplies,game.companion,game.save_totem]: object.set_process(false)
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var session := root.get_node("AdventureSave")
	session.endpoint_override = args[0]
	session.storage_path = args[1]+".first"
	session.saved = {}
	session.new_adventure()
	root.get_node("RunSession").choose(false)
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game := current_scene
	freeze(game)
	game.save_totem.refresh_area()
	game.player = game.save_totem.position+Vector2(-40,0)
	for snake in game.trial.snakes: snake.health = 0
	game.ore = 12
	game.trial.sword_owned = true
	game.update_exploration()
	game.save_totem.refresh_area()
	game.save_totem._process(0.01)
	await settle(session)
	check(session.has_save() and not session.saved.pending and session.revision==1,"Approaching totem did not save online: "+session.status)
	check(game.save_totem.flare>0 and game.save_totem.caption.text=="Adventure saved","Online totem did not light up")
	if not session.has_save():
		quit(1)
		return
	var code: String = session.recovery_code()
	# Recover into an empty device, using the actual WordPress API. Changing
	# nickname or starting a speedrun is never a way to read another save.
	session.storage_path = args[1]+".second"
	session.saved = {}
	session.code = ""
	check(await session.recover(code.to_upper()),"Private cross-device recovery failed")
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	game = current_scene
	freeze(game)
	check(game.ore==12 and game.trial.sword_owned and session.saved.revision==1,"Recovered game state wrong")
	game.save_totem.refresh_area()
	game.ore = 10
	check(await session.checkpoint(game),"Recovered game could not save its next checkpoint")
	check(session.revision==2 and not session.saved.pending,"Recovered game did not advance revision")
	# Original device's Continue must fetch the newer revision instead of
	# silently reverting progress to its own older copy.
	session.storage_path = args[1]+".first"
	session.saved = {}
	session.load_device()
	check(int(session.saved.revision)==1,"Original device fixture not retained")
	check(await session.continue_adventure(),"Original device couldn't Continue")
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	game = current_scene
	freeze(game)
	check(game.ore==10 and int(session.saved.revision)==2,"Continue ignored newer online progress")
	# Touch the real save-and-quit button while the game is paused.
	game.save_totem.refresh_area()
	game.adventure_panel.open()
	check(paused and not game.adventure_panel.primary.disabled,"Save-and-quit unavailable while paused")
	var point: Vector2 = game.adventure_panel.primary.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.index = 0
		event.pressed = pressed
		root.push_input(event,true)
		await process_frame
	var deadline := Time.get_ticks_msec()+25000
	while current_scene==game and Time.get_ticks_msec()<deadline: await process_frame
	check(current_scene!=game and not paused,"Touch Save and quit didn't return to the guide")
	check(session.revision==3,"Save and quit lost the final checkpoint")
	# Simulate a server commit whose success response was lost. The next
	# approach can rebase over its OWN uncertain write, not another device's.
	var uncertain: Dictionary = session.saved.duplicate(true)
	uncertain.checkpoint = Crypto.new().generate_random_bytes(12).hex_encode()
	uncertain.pending = true
	var committed: Dictionary = await session.api({"action":"save","code":uncertain.code,"revision":int(uncertain.revision),"checkpoint":uncertain.checkpoint,"snapshot":uncertain.snapshot})
	check(int(committed.get("revision",0))==4,"Lost-response fixture did not commit")
	session.persist(uncertain)
	check(await session.continue_adventure(),"Couldn't resolve a lost response on Continue")
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	game = current_scene
	freeze(game)
	check(session.revision==4 and not session.saved.pending,"Continue didn't acknowledge its successful uncertain checkpoint")
	# A delayed earlier checkpoint is now on the server, while local progress
	# advanced again before that response arrived.
	uncertain = session.saved.duplicate(true)
	uncertain.checkpoint = Crypto.new().generate_random_bytes(12).hex_encode()
	uncertain.pending = true
	committed = await session.api({"action":"save","code":uncertain.code,"revision":int(uncertain.revision),"checkpoint":uncertain.checkpoint,"snapshot":uncertain.snapshot})
	check(int(committed.get("revision",0))==5,"Earlier-write fixture did not commit")
	session.persist(uncertain)
	game.save_totem.refresh_area()
	check(await session.checkpoint(game) and session.revision==6 and not session.conflict,"Own lost-response checkpoint failed to rebase safely")
	# A genuinely different device must conflict and must never be overwritten.
	var other := Crypto.new().generate_random_bytes(12).hex_encode()
	committed = await session.api({"action":"save","code":session.code,"revision":session.revision,"checkpoint":other,"snapshot":session.saved.snapshot})
	check(int(committed.get("revision",0))==7,"Other-device fixture did not commit")
	await session.checkpoint(game)
	check(session.conflict and session.saved.pending,"Stale device silently overwrote someone else's progress")
	game.adventure_panel.open()
	check(game.adventure_panel.primary.text=="Continue online save","Conflict has no usable recovery action in-game")
	game.adventure_panel.primary.pressed.emit()
	deadline = Time.get_ticks_msec()+25000
	while current_scene==game and Time.get_ticks_msec()<deadline: await process_frame
	check(current_scene!=game and not paused,"In-game conflict action didn't continue the online checkpoint")
	await process_frame
	check(session.revision==7 and session.saved.checkpoint==other,"Continue didn't resolve conflict using latest online progress")
	for suffix in [".first",".second"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(args[1]+suffix))
	change_scene_to_file("res://startup.tscn")
	await scene_changed
	await create_timer(0.5).timeout
	if failures==0: print("PASS: actual totem approach/save pulse, WordPress database save, private new-device recovery, newer-online Continue, paused touch Save and quit, lost-response retries and cross-device conflicts")
	quit(1 if failures else 0)
