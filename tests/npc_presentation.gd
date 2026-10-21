extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func run() -> void:
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.set_process(false)
	for npc in game.npcs: npc.set_process(false)
	var first = game.rowan
	first.reveal_time = 0
	first.modulate.a = 0
	first.has_waved = false
	game.player = first.position+Vector2(0,30)
	game.update_exploration()
	game.refresh_ui()
	check(first.visible and first.modulate.a == 0,"A newly revealed person flashes fully opaque")
	first.advance_presentation(0.1875)
	var early: float = first.modulate.a
	first.advance_presentation(0.1875)
	check(early > 0 and early < first.modulate.a and is_equal_approx(first.modulate.a,0.5),"NPC reveal is not a gradual 0.75-second fade")
	first.advance_presentation(0.375)
	check(is_equal_approx(first.modulate.a,1) and first.has_waved and first.greeting_wave.visible,"A revealed nearby character does not wave")
	check(first.greeting_wave.modulate.a > 0 and first.illustration.modulate.a < 1,"Greeting artwork never replaces the idle pose")
	var angle: float = first.greeting_wave.material.get_shader_parameter("wave_angle")
	first.advance_presentation(0.2)
	check(not is_equal_approx(angle,first.greeting_wave.material.get_shader_parameter("wave_angle")),"Raised forearm has no animated wave")
	var paused_at: float = first.wave_time
	game.mission_journal.open()
	first.advance_presentation(1)
	check(is_equal_approx(first.wave_time,paused_at),"Wave continued behind Quests")
	game.mission_journal.dismiss()
	game.hud.help.show()
	first.advance_presentation(1)
	check(is_equal_approx(first.wave_time,paused_at),"Wave continued behind the controls popup")
	game.hud.help.hide()
	paused = true
	first.advance_presentation(1)
	check(is_equal_approx(first.wave_time,paused_at),"Wave continued while the tree was paused")
	paused = false
	first.advance_presentation(3)
	check(first.wave_time < 0 and not first.greeting_wave.visible and first.illustration.modulate.a == 1,"Wave does not return cleanly to idle")
	first.advance_presentation(3)
	check(first.wave_time < 0,"A nearby character waves continuously")
	await TRAVEL.enter(game,1,false)
	first.advance_presentation(3)
	await TRAVEL.enter(game,0,false)
	game.player = first.position+Vector2(0,30)
	game.update_exploration()
	game.refresh_ui()
	check(first.modulate.a == 1 and first.has_waved and first.wave_time < 0,"Returning to an explored area restarts the reveal or wave")
	# All seven have their own complete waving artwork and preserve body size.
	for npc in game.npcs:
		var role: String = str(npc.name).to_lower()
		if npc.home_region != game.earth_region: await TRAVEL.enter(game,npc.home_region,false)
		if role == "nova": game.story.complete.finn = true
		game.player = npc.position+Vector2(0,260)
		game.fog.observe(game.area_id(),npc.position)
		game.refresh_ui()
		npc.reveal_time = 0
		npc.modulate.a = 0
		npc.has_waved = false
		npc.wave_time = -1
		npc.advance_presentation(0.75)
		check(npc.visible and npc.modulate.a == 1 and not npc.has_waved,"A distant revealed neighbour spends their greeting early: "+role)
		game.player = npc.position+Vector2(0,50)
		npc.advance_presentation(0.3)
		check(npc.has_waved and npc.greeting_wave.visible,"Missing greeting for "+role)
		var frame: Dictionary = npc.GREETING.frames[role]
		var region: Rect2 = frame.region
		check(is_equal_approx(region.size.y*npc.greeting_wave.scale.y,npc.height),"Greeting changes the character's height: "+role)
		check(frame.anchor > 0 and frame.anchor < region.size.x,"Greeting boots are outside their own frame: "+role)
		for other in npc.GREETING.frames:
			if other != role: check(not region.intersects(npc.GREETING.frames[other].region),"Greeting frames include another person: "+role)
		# A completed mission interrupts a wave, then retains the existing puff.
		if role == "rowan": npc.mission = npc.Mission.COMPLETE
		else: game.story.complete[role] = true
		npc.advance_departure(0.1)
		check(npc.departing and not npc.greeting_wave.visible and npc.illustration.modulate.a > 0,"Departure leaves a waving ghost: "+role)
		npc.advance_departure(0.71)
		check(npc.departed and not npc.visible,"Completed character remains after puff: "+role)
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: seven unique planted greeting poses, gradual shared character/shadow reveal, nearby one-time animated waves, pause/help/journal guards, retained reveal on revisits, correct height and clean completion-puff interruption")
	quit(1 if failures else 0)
