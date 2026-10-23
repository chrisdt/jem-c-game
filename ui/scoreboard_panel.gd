extends CanvasLayer
var run_session: Node
const STYLE = preload("res://ui/expedition_style.gd")
var game: Node
var panel: Panel
var title: Label
var subtitle: Label
var notice: Label
var time_label: Label
var stats: Label
var name_label: Label
var nickname: LineEdit
var post_button: Button
var back_button: Button
var again_button: Button
var board_button: Button
var board_rows: Array[Control] = []
var board_heading: Control
var board_mode := true
var board_local := false
var fetching := false
var previous_pause := false
var owns_pause := false
var previous_focus: Control
var request_generation := 0

func _ready() -> void:
	run_session = get_node("/root/RunSession")
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015,0.03,0.025,0.8)
	add_child(shade)
	panel = STYLE.panel(self,Vector2(196,80),Vector2(888,640))
	title = STYLE.label(panel,"Best adventure times",Vector2(32,24),Vector2(824,43),30,true)
	subtitle = STYLE.label(panel,"",Vector2(32,75),Vector2(824,36),17)
	notice = STYLE.label(panel,"",Vector2(32,115),Vector2(824,58),15)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_color",STYLE.GOLD)
	board_heading = Control.new()
	board_heading.position = Vector2(42,181)
	panel.add_child(board_heading)
	for spec in [["Rank",0,64],["Explorer",70,390],["Time",500,145],["Defeated",650,110]]:
		STYLE.label(board_heading,spec[0],Vector2(spec[1],0),Vector2(spec[2],28),14,true)
	for i in 10:
		var row := Control.new()
		row.position = Vector2(42,218+i*31)
		row.size = Vector2(800,30)
		panel.add_child(row)
		var cells := []
		for spec in [[0,64],[70,390],[500,145],[650,110]]:
			cells.append(STYLE.label(row,"",Vector2(spec[0],0),Vector2(spec[1],30),17))
		row.set_meta("cells",cells)
		board_rows.append(row)
	time_label = STYLE.label(panel,"",Vector2(32,184),Vector2(824,74),52,true)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_color_override("font_color",STYLE.GOLD)
	stats = STYLE.label(panel,"",Vector2(32,271),Vector2(824,40),20)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label = STYLE.label(panel,"Nickname (no real name needed)",Vector2(48,332),Vector2(480,32),18,true)
	nickname = LineEdit.new()
	nickname.position = Vector2(48,375)
	nickname.size = Vector2(360,56)
	nickname.max_length = 16
	nickname.add_theme_font_override("font",STYLE.BODY)
	nickname.add_theme_font_size_override("font_size",21)
	panel.add_child(nickname)
	post_button = STYLE.button(panel,"Post my time",Vector2(440,375),Vector2(400,56),20)
	post_button.pressed.connect(func(): run_session.submit(nickname.text))
	nickname.text_submitted.connect(func(_value):
		if not post_button.disabled: run_session.submit(nickname.text))
	var small := STYLE.label(panel,"Best time per nickname · Three worlds · 14 story quests",Vector2(32,490),Vector2(824,28),15)
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_button = STYLE.button(panel,"Leaderboard",Vector2(32,554),Vector2(230,56),18)
	board_button.pressed.connect(func(): open_board(not board_local) if board_mode else open_board())
	back_button = STYLE.button(panel,"Back",Vector2(288,554),Vector2(280,56),18)
	back_button.pressed.connect(func():
		if board_mode and game != null and run_session.finished: open_results()
		else: dismiss())
	again_button = STYLE.button(panel,"New adventure",Vector2(594,554),Vector2(262,56),18)
	again_button.pressed.connect(func():
		if game == null and board_mode:
			if run_session.restore_result(): open_results()
		else:
			dismiss()
			get_tree().change_scene_to_file("res://startup.tscn"))
	run_session.changed.connect(present)
	get_viewport().size_changed.connect(layout)
	layout()
	hide()
func layout() -> void:
	if is_inside_tree() and get_viewport() != null: panel.position = (get_viewport().get_visible_rect().size-panel.size)*0.5
func show_modal() -> void:
	if not visible:
		previous_focus = get_viewport().gui_get_focus_owner()
		if game != null:
			game.clear_touch_gestures()
			game.walking = false
			if game.mining_target >= 0: game.cancel_mining()
			game.story.cancel_work()
			game.frost_story.cancel_work()
			game.ember_story.cancel_work()
			game.restore_walk_visual()
			previous_pause = get_tree().paused
			owns_pause = true
			get_tree().paused = true
	show()
	back_button.grab_focus()
func open_results() -> void:
	if not run_session.finished: return
	board_mode = false
	nickname.text = run_session.nickname
	show_modal()
	present()
func open_board(local := false) -> void:
	request_generation += 1
	board_mode = true
	board_local = local
	show_modal()
	present()
	fetch_board()
func present() -> void:
	if not is_instance_valid(title): return
	for item in [time_label,stats,name_label,nickname,post_button]: item.visible = not board_mode
	board_heading.visible = board_mode
	for row in board_rows: row.visible = board_mode
	board_button.visible = true
	board_button.text = ("Shared times" if board_local else "This device times") if board_mode else "Leaderboard"
	again_button.visible = (game != null and run_session.finished) or (game == null and not run_session.last_result.is_empty())
	again_button.text = "Last result" if game == null and board_mode else "New adventure"
	if board_mode:
		title.text = "Times on this device" if board_local else "Best adventure times"
		subtitle.text = "Fastest first · All 14 story quests · Optional challenges stay optional"
		back_button.text = "Back to results" if game != null and run_session.finished else "Back"
	else:
		title.text = "Adventure complete!"
		subtitle.text = "Earth, Frost Canyon and Ember Dunes · 14 / 14 story quests"
		time_label.text = run_session.format_time(run_session.duration_ms,true)
		stats.text = "Enemies defeated: %d · Recoveries: %d" % [run_session.enemies,run_session.recoveries]
		notice.text = run_session.notice if run_session.timed else "A wonderful adventure! Choose Speedrun on the welcome screen to post a time."
		name_label.visible = run_session.timed
		nickname.visible = run_session.timed
		post_button.visible = run_session.timed
		post_button.disabled = run_session.verifying or run_session.submitting or run_session.submitted
		nickname.editable = not run_session.submitting and not run_session.verifying and not run_session.submitted
		if run_session.submitted: post_button.text = "Posted!"
		elif run_session.verifying: post_button.text = "Checking time…"
		elif run_session.submitting: post_button.text = "Posting…"
		elif run_session.token.is_empty(): post_button.text = "Save on this device"
		elif not run_session.verified: post_button.text = "Retry and post"
		else: post_button.text = "Post my time"
		back_button.text = "Keep exploring" if game != null else "Back to welcome"
func fetch_board() -> void:
	if fetching: return
	fetching = true
	request_generation += 1
	var id := request_generation
	notice.text = "Reading shared times…"
	for row in board_rows:
		for cell in row.get_meta("cells"): cell.text = ""
	var local := board_local
	var reply: Dictionary = {"scores":run_session.local_scores.duplicate(true)} if local else await run_session.api("board")
	fetching = false
	if id != request_generation or not visible or not board_mode:
		if visible and board_mode: fetch_board()
		return
	if not reply.has("scores"):
		board_local = true
		present()
		notice.text = str(reply.get("error","Shared times couldn't open."))+" Showing times saved on this device."
		render_scores(run_session.local_scores.duplicate(true))
		return
	if reply.get("campaign",run_session.CAMPAIGN) != run_session.CAMPAIGN:
		notice.text = "These times belong to a different adventure version. Please refresh."
		return
	if local:
		notice.text = "Times saved in this browser or Godot device · Shared ranking is separate"
	else: notice.text = "No times yet. Finish a speedrun to set the first record!" if reply.scores.is_empty() else "Top 10 explorers · One best time per nickname"
	render_scores(reply.scores)
func render_scores(scores: Array) -> void:
	scores.sort_custom(func(a,b): return int(a.get("duration_ms",0)) < int(b.get("duration_ms",0)))
	for i in mini(10,scores.size()):
		var row: Dictionary = scores[i]
		var cells: Array = board_rows[i].get_meta("cells")
		cells[0].text = str(i+1)
		cells[1].text = str(row.get("nickname","Scout")).substr(0,16)
		cells[2].text = run_session.format_time(int(row.get("duration_ms",0)),true)
		cells[3].text = str(int(row.get("enemies",0)))
func dismiss() -> void:
	request_generation += 1
	hide()
	for button in [post_button,back_button,board_button,again_button]: button.release_touch()
	if owns_pause:
		get_tree().paused = previous_pause
		owns_pause = false
	get_viewport().gui_release_focus()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	if game != null: game.refresh_ui()
func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
func _unhandled_key_input(_event: InputEvent) -> void:
	if visible: get_viewport().set_input_as_handled()
func _exit_tree() -> void:
	if owns_pause: get_tree().paused = previous_pause
