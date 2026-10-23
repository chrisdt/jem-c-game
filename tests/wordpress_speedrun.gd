extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec()+30000
	while not predicate.call() and Time.get_ticks_msec()<deadline: await process_frame
	check(predicate.call(),"WordPress scoreboard request did not settle")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var session = root.get_node("RunSession")
	session.endpoint_override = args[0]
	session.storage_path = args[1]+".scores"
	session.load_scores()
	session.choose(true)
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.frost_story.set_process(false)
	game.ember_story.set_process(false)
	await settle(func(): return not session.start_pending)
	check(session.token.length()==48,"WordPress did not register the Godot run: "+session.notice)
	if session.token.is_empty():
		quit(1)
		return
	var file := FileAccess.open(args[1],FileAccess.WRITE)
	file.store_string(session.token)
	file.close()
	# The disposable test database is backdated outside the shipped plugin;
	# production has no shortcut for creating an instant verified time.
	await settle(func(): return FileAccess.file_exists(args[2]))
	game.rowan.mission = game.ROWAN.Mission.COMPLETE
	for role in ["bea","otis","mara","iris","finn"]: game.story.complete[role] = true
	for role in game.frost_story.ORDER: game.frost_story.complete[role] = true
	for role in game.ember_story.ORDER: game.ember_story.complete[role] = true
	game.refresh_ui()
	await settle(func(): return session.verified)
	check(session.finished and session.duration_ms>=120000,"WordPress did not verify the server-clock finish")
	check(game.score_panel.visible and paused and not game.score_panel.post_button.disabled,"WordPress completion cannot be posted while paused")
	game.score_panel.nickname.text = "GodotWPTest"
	var point: Vector2 = game.score_panel.post_button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.index = 0
		event.pressed = pressed
		root.push_input(event,true)
		await process_frame
	await settle(func(): return session.submitted)
	check(session.rank>0 and session.nickname=="GodotWPTest","Godot post did not return a WordPress rank")
	game.score_panel.open_board()
	await settle(func(): return not game.score_panel.fetching)
	var found := false
	for row in game.score_panel.board_rows:
		if row.get_meta("cells")[1].text=="GodotWPTest": found = true
	check(found,"Posted WordPress time missing from in-game board")
	game.score_panel.dismiss()
	change_scene_to_file("res://startup.tscn")
	await scene_changed
	await create_timer(0.5).timeout
	if failures==0: print("PASS: real Godot registration, 14-quest server finish, paused touch posting and leaderboard through WordPress database")
	quit(1 if failures else 0)
