extends CanvasLayer

const STYLE = preload("res://ui/expedition_style.gd")
var game: Node
var close_button: Button
var summary: Label
var titles: Array[Label] = []
var descriptions: Array[Label] = []
var progress: Array[Label] = []
var marks: Array[Node2D] = []
var scroll: ScrollContainer
var up_button: Button
var down_button: Button

func _ready() -> void:
	layer = 4
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015,0.03,0.025,0.78)
	add_child(backdrop)
	var panel := STYLE.panel(self,Vector2(196,80),Vector2(888,640))
	STYLE.label(panel,"Earth expedition",Vector2(30,23),Vector2(550,40),30,true)
	summary = STYLE.label(panel,"",Vector2(30,66),Vector2(820,28),16)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(24,106)
	scroll.size = Vector2(840,438)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",8)
	scroll.add_child(rows)
	for entry in game.missions.entries():
		var row := Panel.new()
		row.custom_minimum_size = Vector2(810,108)
		var background := StyleBoxFlat.new()
		background.bg_color = Color(0.025,0.08,0.07,0.6)
		background.set_corner_radius_all(8)
		row.add_theme_stylebox_override("panel",background)
		rows.add_child(row)
		var mark := Node2D.new()
		mark.position = Vector2(25,25)
		mark.draw.connect(func():
			mark.draw_circle(Vector2.ZERO,9,STYLE.GOLD,false,1.5,true)
			if mark.get_meta("done",false):
				mark.draw_line(Vector2(-5,0),Vector2(-1,4),STYLE.GOLD,2,true)
				mark.draw_line(Vector2(-1,4),Vector2(6,-5),STYLE.GOLD,2,true))
		row.add_child(mark)
		marks.append(mark)
		titles.append(STYLE.label(row,entry.title,Vector2(48,10),Vector2(490,29),19,true))
		var detail := STYLE.label(row,"",Vector2(48,43),Vector2(724,58),15)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size = Vector2(724,58)
		detail.clip_text = true
		detail.text = entry.detail
		descriptions.append(detail)
		var status := STYLE.label(row,"",Vector2(526,13),Vector2(250,24),13)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress.append(status)
	close_button = STYLE.button(panel,"Back to exploring",Vector2(304,563),Vector2(280,56),18)
	close_button.pressed.connect(dismiss)
	up_button = STYLE.button(panel,"Up",Vector2(30,563),Vector2(100,56),17)
	down_button = STYLE.button(panel,"Down",Vector2(758,563),Vector2(100,56),17)
	up_button.pressed.connect(func(): scroll.scroll_vertical = maxi(0,scroll.scroll_vertical-330))
	down_button.pressed.connect(func(): scroll.scroll_vertical += 330)
	hide()

func open() -> void:
	if game.world != 0 or game.flight != 0 or game.earth_transition or game.menu_open() or game.hud.help.visible or game.trial.jab_time >= 0: return
	if game.mining_target >= 0: game.cancel_mining()
	game.story.cancel_work()
	game.clear_touch_gestures()
	game.walking = false
	game.restore_walk_visual()
	present()
	show()
	close_button.grab_focus()
	game.refresh_ui()

func present() -> void:
	summary.text = "%d / 7 story missions complete · Optional exploration · Progress lasts while this game is open" % game.missions.completed()
	var entries: Array = game.missions.entries()
	for i in entries.size():
		marks[i].set_meta("done",entries[i].done)
		marks[i].queue_redraw()
		progress[i].text = "Complete" if entries[i].done else entries[i].progress
		descriptions[i].text = entries[i].detail

func dismiss() -> void:
	hide()
	close_button.release_touch()
	up_button.release_touch()
	down_button.release_touch()
	get_viewport().gui_release_focus()
	game.refresh_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or event.keycode == KEY_R: return
	get_viewport().set_input_as_handled()
	if event.is_pressed() and not event.is_echo() and event.keycode in [KEY_J,KEY_ESCAPE]: dismiss()
