extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec()+15000
	while not predicate.call() and Time.get_ticks_msec() < deadline: await process_frame
	check(predicate.call(),"Online scoreboard request did not settle")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var session = root.get_node("RunSession")
	session.endpoint_override = args[0]
	session.choose(true)
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.ember_story.set_process(false)
	game.frost_story.set_process(false)
	await settle(func(): return not session.start_pending)
	check(session.token.length() == 48,"Godot did not register a server run: "+session.notice)
	if session.token.is_empty():
		quit(1)
		return
	# Only this isolated test fixture backdates its private server record. It
	# exercises a real HTTP finish without waiting through a two-minute game.
	var path: String = args[1]
	var source := FileAccess.get_file_as_string(path)
	var guard := source.substr(0,source.find("\n")+1)
	var state: Dictionary = JSON.parse_string(source.trim_prefix(guard))
	state.runs[session.token].started_ms -= 120000
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(guard+JSON.stringify(state))
	file.close()
	game.rowan.mission = game.ROWAN.Mission.COMPLETE
	for role in ["bea","otis","mara","iris","finn"]: game.story.complete[role] = true
	for role in game.frost_story.ORDER: game.frost_story.complete[role] = true
	for role in game.ember_story.ORDER: game.ember_story.complete[role] = true
	session.record_enemy()
	game.refresh_ui()
	await settle(func(): return session.verified)
	check(session.finished and session.duration_ms >= 120000,"Server finish did not supply official time")
	check(game.score_panel.visible and paused,"Online finish did not open paused results")
	game.score_panel.nickname.text = "JeremyTest"
	game.score_panel.post_button.pressed.emit()
	await settle(func(): return session.submitted)
	check(session.rank == 1 and session.nickname == "JeremyTest","Posted time did not return rank")
	game.score_panel.open_board()
	await settle(func(): return not game.score_panel.fetching)
	check(game.score_panel.board_rows[0].get_meta("cells")[1].text == "JeremyTest","Latest posted score missing in popup")
	game.score_panel.dismiss()
	var token: String = session.token
	game.reset_confirmation.open()
	game.reset_confirmation.accept_reset()
	await scene_changed
	await settle(func(): return not session.start_pending)
	check(session.token != token and not session.finished and session.completed_ids.is_empty(),"Reset reused server run")
	var board: Dictionary = await session.api("board")
	check(board.has("scores") and board.scores.size() == 1,"Reset removed or duplicated shared score")
	if failures == 0: print("PASS: real Godot→PHP registration/finish/post/rank, server-clock result, paused completion, refreshed leaderboard and independent reset with persistent scores")
	quit(1 if failures else 0)
