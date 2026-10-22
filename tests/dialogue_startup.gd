extends SceneTree

# Do not preload the game, bubble or icon catalog here: exercise the normal
# startup loader and its script dependencies from a fresh process.
var failures := 0
func _initialize() -> void:
	create_timer(30).timeout.connect(func():
		check(false,"Startup dialogue timed out; check earlier script compilation errors")
		quit(1))
	call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if ok: return
	failures += 1
	push_error(detail)
func run() -> void:
	change_scene_to_file("res://startup.tscn")
	await scene_changed
	await process_frame
	current_scene.start_exploring(false)
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.player = game.rowan.position+Vector2(0,28)
	game.scout.position = game.player
	game.camera.position = game.player
	game.camera.position_smoothing_enabled = false
	game.camera.force_update_scroll()
	game.update_exploration()
	game.refresh_ui()
	game.rowan.show()
	game.talk_to_npc(game.rowan)
	var bubble = game.character_bubble
	check(bubble.is_dialogue_open(),"Rowan dialogue failed after normal startup")
	check(bubble.ITEM_ICONS.has_method("fill"),"The icon renderer failed to compile for this Godot version")
	var text: String = bubble.body_label.get_parsed_text()
	check(text.contains("3 copper") and text.contains("2 fallen wood") and text.count("(") == 2,"Requested item icons and quantities did not render after startup")
	check(bubble.body_label.get_content_height() <= bubble.body_label.size.y,"Inline icons overflow the startup dialogue")
	bubble.advance()
	check(bubble.page_index == 1 and bubble.body_label.get_parsed_text().contains("sword"),"The second mission page did not render")
	bubble.dismiss()
	check(game.rowan.mission == game.rowan.Mission.NOT_STARTED,"Cancelling the dialogue accepted Rowan's mission")
	# Release the loaded world before shutting down the test process.
	change_scene_to_file("res://startup.tscn")
	await scene_changed
	await process_frame
	if failures == 0: print("PASS: cold startup, compiled icon renderer, inline mission items, paging and cancellation on Godot "+Engine.get_version_info().string)
	quit(1 if failures else 0)
