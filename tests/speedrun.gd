extends SceneTree
const RUN = preload("res://ui/run_session.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var session = root.get_node("RunSession")
	session.endpoint_override = "http://127.0.0.1:1/api/leaderboard.php"
	session.storage_path = "user://speedrun-test-%d.json" % OS.get_process_id()
	session.load_scores()
	change_scene_to_file("res://startup.tscn")
	await scene_changed
	await process_frame
	var welcome = current_scene
	check(not session.running and welcome.board_button.visible and welcome.relax_button.visible,"Welcome started timer or omitted mode/board buttons")
	welcome.score_panel.open_board()
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_SPACE
	welcome._input(event)
	check(welcome.stage == welcome.Stage.GUIDE and not root.has_node("GreenPlanet"),"Leaderboard loaded the world or Space started behind it")
	while welcome.score_panel.fetching: await process_frame
	check(welcome.score_panel.board_local and welcome.score_panel.notice.text.contains("device"),"Offline scoreboard lacks saved device times")
	welcome.score_panel.dismiss()
	welcome.start_exploring(false)
	while is_instance_valid(welcome) and current_scene == welcome: await process_frame
	var game = current_scene
	game.set_process(false)
	game.frost_story.set_process(false)
	game.ember_story.set_process(false)
	check(session.running and not session.timed and session.completed_ids.is_empty(),"Relaxed play didn't start cleanly")
	# Time uses the monotonic clock, not frame delta, and all menus count.
	session.choose(true)
	session.begin_world()
	session.started_ms = Time.get_ticks_msec()-123450
	game.mission_journal.open()
	check(session.elapsed_ms() >= 123450 and not session.finished,"Quest popup stopped the speedrun")
	game.mission_journal.dismiss()
	game.hud.help.show()
	check(session.elapsed_ms() >= 123450,"Help stopped the speedrun")
	game.hud.help.hide()
	game.reset_confirmation.open()
	check(session.elapsed_ms() >= 123450,"Reset prompt stopped the speedrun")
	game.reset_confirmation.dismiss()
	session.record_enemy()
	var snake = game.trial.snakes[0]
	snake.seen = true
	snake.health = 1
	check(snake.take_hit(9876,game.player,1),"Real enemy defeat failed")
	check(not snake.take_hit(9876,game.player,1),"One jab counted a defeated enemy twice")
	session.record_recovery()
	game.rowan.mission = game.ROWAN.Mission.COMPLETE
	for role in ["bea","otis","mara","iris","finn"]: game.story.complete[role] = true
	for role in game.frost_story.ORDER: game.frost_story.complete[role] = true
	for role in ["sol","luma","brasa"]: game.ember_story.complete[role] = true
	session.observe(game)
	check(session.running and session.completed_ids.size() == 13,"Run finished before final story quest")
	check(not game.companion.recruited and not game.missions.fruit_used,"Fixture unexpectedly completed optional Earth challenges")
	game.ember_story.complete.orin = true
	session.observe(game)
	await process_frame
	check(session.finished and not session.running and session.completed_ids.size() == 14,"All three worlds did not finish the run")
	check(game.score_panel.visible and paused,"Finish popup didn't pause the world")
	check(game.score_panel.stats.text.contains("Enemies defeated: 2") and game.score_panel.stats.text.contains("Recoveries: 1"),"Finish statistics wrong")
	while session.verifying: await process_frame
	check(not session.verified and not game.score_panel.post_button.disabled and game.score_panel.post_button.text == "Save on this device","Offline result has no usable save button")
	check(session.local_saved and FileAccess.file_exists(session.storage_path),"Offline finish wasn't automatically saved")
	await session.submit("Offline-Scout")
	check(not session.submitted and session.local_scores.size() == 1 and session.local_scores[0].nickname == "Offline-Scout","Local save posted an unverified time or duplicated the run")
	game.score_panel.open_board(true)
	check(game.score_panel.board_rows[0].get_meta("cells")[1].text == "Offline-Scout","Local saved result missing from device times")
	game.score_panel.open_results()
	var stopped: int = session.duration_ms
	session.record_enemy()
	session.record_recovery()
	session.observe(game)
	check(session.duration_ms == stopped and session.enemies == 2 and session.recoveries == 1,"Finished run kept changing")
	game.score_panel.dismiss()
	check(not paused,"Closing finish popup left the world paused")
	game.score_panel.open_board()
	check(paused,"In-game leaderboard doesn't pause combat")
	game.score_panel.dismiss()
	check(not paused,"Closing leaderboard left the world paused")
	session.choose(false)
	session.begin_world()
	session.observe(game)
	await process_frame
	check(game.score_panel.visible and not game.score_panel.post_button.visible,"Relaxed completion offers a ranked post")
	game.score_panel.dismiss()
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await process_frame
	check(session.running and not session.finished and session.enemies == 0 and session.completed_ids.is_empty(),"Confirmed reset reused previous run")
	check(RUN.format_time(123450,true) == "2:03.45" and RUN.format_time(3661000) == "1:01:01","Run time formatting is wrong")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.storage_path))
	if failures == 0: print("PASS: welcome modes/leaderboard, no early world/timer, monotonic menu-counting clock, exactly 14 story quests without optional tasks, once-only completion/stats, modal pause, offline finish, reset and time formatting")
	quit(1 if failures else 0)
