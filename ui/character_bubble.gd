extends CanvasLayer

# The caller owns world/input pausing. Connect opened/closed when integrating
# a conversation; hints never acquire focus or block gameplay.
signal opened
signal closed(completed: bool)
signal page_changed(index: int)

const STYLE = preload("res://ui/expedition_style.gd")
const TOUCH = preload("res://ui/touch_controls.gd")
const INK := Color("183e3c")
enum Mode { CLOSED, HINT, DIALOGUE }

var mode := Mode.CLOSED
var page_index := 0
var touch_mode := false
# Left, top, right, bottom; callers can reserve their HUD and touch controls.
var safe_insets := Vector4(18,124,18,164)
var panel: Panel
var body_label: Label
var speaker_label: Label
var page_label: Label
var next_button: Button
var close_button: Button
var shield: Control
var tail: Polygon2D
var tail_border: Line2D
var anchor: Node2D
var head_offset := Vector2(0,-92)
var pages: Array[String] = []
var final_action := "Close"
var remaining := 0.0
var previous_focus: Control
var last_view_size := Vector2.ZERO

func _ready() -> void:
	layer = 5
	shield = Control.new()
	shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shield)
	tail = Polygon2D.new()
	tail.color = STYLE.CREAM
	shield.add_child(tail)
	tail_border = Line2D.new()
	tail_border.width = 2
	tail_border.default_color = STYLE.GOLD
	tail_border.antialiased = true
	shield.add_child(tail_border)
	panel = Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = STYLE.CREAM
	box.border_color = STYLE.GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(12)
	box.shadow_color = Color(0.025,0.07,0.055,0.22)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0,3)
	panel.add_theme_stylebox_override("panel",box)
	shield.add_child(panel)
	speaker_label = make_label(true,15)
	body_label = make_label(false,18)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_constant_override("line_spacing",3)
	page_label = make_label(false,13)
	next_button = STYLE.button(panel,"",Vector2.ZERO,Vector2(130,44),16)
	close_button = STYLE.button(panel,"×",Vector2.ZERO,Vector2(44,44),22)
	close_button.tooltip_text = "Close conversation (Escape)"
	next_button.pressed.connect(advance)
	close_button.pressed.connect(dismiss)
	# Trap keyboard focus between the two conversation controls.
	for button in [next_button,close_button]:
		var other: Button = close_button if button == next_button else next_button
		button.focus_next = button.get_path_to(other)
		button.focus_previous = button.get_path_to(other)
		for direction in ["left","right","top","bottom"]:
			button.set("focus_neighbor_"+direction,button.get_path_to(other))
	get_viewport().size_changed.connect(on_resize)
	touch_mode = TOUCH.device_uses_touch()
	hide()

func make_label(heading: bool, font_size: int) -> Label:
	var label := STYLE.label(panel,"",Vector2.ZERO,Vector2.ZERO,font_size,heading)
	label.add_theme_color_override("font_color",INK)
	label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	return label

func is_dialogue_open() -> bool:
	return mode == Mode.DIALOGUE

func show_dialogue(speaker: String, text_pages: Array[String], target: Node2D, offset := Vector2(0,-92), last_action := "Close") -> bool:
	if mode == Mode.DIALOGUE or not valid_target(target,offset) or text_pages.is_empty(): return false
	var clean: Array[String] = []
	for text in text_pages:
		if not text.strip_edges().is_empty(): clean.append(text.strip_edges())
	if clean.is_empty(): return false
	previous_focus = get_viewport().gui_get_focus_owner()
	anchor = target
	head_offset = offset
	pages = clean
	page_index = 0
	final_action = last_action
	speaker_label.text = speaker.to_upper()
	mode = Mode.DIALOGUE
	shield.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	update_page()
	opened.emit()
	next_button.grab_focus()
	return true

func show_hint(text: String, target: Node2D, offset := Vector2(0,-92), seconds := 4.5) -> bool:
	# A bark/tutorial/notification must never interrupt a conversation.
	if mode == Mode.DIALOGUE or not valid_target(target,offset) or text.strip_edges().is_empty(): return false
	anchor = target
	head_offset = offset
	pages = [text.strip_edges()]
	page_index = 0
	remaining = maxf(0.1,seconds)
	mode = Mode.HINT
	shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show()
	update_page()
	return true

func set_touch_mode(value: bool) -> void:
	if touch_mode == value: return
	touch_mode = value
	release_buttons()
	if mode != Mode.CLOSED: update_page()

func update_page() -> void:
	body_label.text = pages[page_index]
	speaker_label.visible = mode == Mode.DIALOGUE
	page_label.visible = mode == Mode.DIALOGUE
	next_button.visible = mode == Mode.DIALOGUE
	close_button.visible = mode == Mode.DIALOGUE
	page_label.text = "%d / %d" % [page_index+1,pages.size()]
	var action := "Next" if page_index < pages.size()-1 else final_action
	next_button.text = action if touch_mode else "E  "+action
	last_view_size = get_viewport().get_visible_rect().size
	var width := minf(360,last_view_size.x-safe_insets.x-safe_insets.z)
	panel.size.x = width
	var body_top := (57.0 if touch_mode else 45.0) if mode == Mode.DIALOGUE else 16.0
	var body_width := width-36
	var text_size := STYLE.BODY.get_multiline_string_size(body_label.text,HORIZONTAL_ALIGNMENT_LEFT,body_width,18)
	var text_height := maxf(28,text_size.y+body_label.text.count("\n")*3+6)
	body_label.position = Vector2(18,body_top)
	body_label.size = Vector2(body_width,text_height)
	speaker_label.position = Vector2(18,15)
	speaker_label.size = Vector2(width-84,24)
	var footer_top := body_top+text_height+10
	var button_height := 56.0 if touch_mode else 44.0
	var button_width := maxf(130,STYLE.HEADING.get_string_size(next_button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+32)
	next_button.position = Vector2(width-button_width-16,footer_top)
	next_button.size = Vector2(button_width,button_height)
	close_button.size = Vector2.ONE*(56 if touch_mode else 44)
	close_button.position = Vector2(width-close_button.size.x-3,2)
	page_label.position = Vector2(18,footer_top+(button_height-22)*0.5)
	page_label.size = Vector2(70,22)
	panel.size.y = footer_top+button_height+14 if mode == Mode.DIALOGUE else body_top+text_height+12
	position_bubble()

func advance() -> void:
	if mode != Mode.DIALOGUE: return
	release_buttons()
	if page_index+1 == pages.size():
		finish(true)
	else:
		page_index += 1
		update_page()
		page_changed.emit(page_index)

func dismiss() -> void:
	finish(false)

func finish(completed: bool) -> void:
	var was_dialogue := mode == Mode.DIALOGUE
	mode = Mode.CLOSED
	release_buttons()
	hide()
	anchor = null
	pages.clear()
	if not was_dialogue: return
	get_viewport().gui_release_focus()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	previous_focus = null
	closed.emit(completed)

func release_buttons() -> void:
	next_button.release_touch()
	close_button.release_touch()

func safe_rect() -> Rect2:
	var view := get_viewport().get_visible_rect()
	return Rect2(Vector2(safe_insets.x,safe_insets.y),view.size-Vector2(safe_insets.x+safe_insets.z,safe_insets.y+safe_insets.w))

func valid_target(target: Node2D, offset: Vector2) -> bool:
	if not is_instance_valid(target) or not target.is_visible_in_tree(): return false
	var head := target.get_canvas_transform()*(target.global_position+offset)
	return get_viewport().get_visible_rect().grow(24).has_point(head)

func position_bubble() -> void:
	if not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		dismiss()
		return
	# Offset is measured in world units, independent of the sprite's art scale.
	var head := anchor.get_canvas_transform()*(anchor.global_position+head_offset)
	var view := get_viewport().get_visible_rect()
	if not view.grow(24).has_point(head):
		dismiss()
		return
	place_at(head,safe_rect())

func place_at(head: Vector2, area: Rect2) -> void:
	var at := Vector2(clampf(head.x-panel.size.x*0.5,area.position.x,area.end.x-panel.size.x),head.y-panel.size.y-14)
	var points: PackedVector2Array
	if at.y >= area.position.y:
		at.y = minf(at.y,area.end.y-panel.size.y)
		var x := clampf(head.x,at.x+20,at.x+panel.size.x-20)
		points = PackedVector2Array([Vector2(x-8,at.y+panel.size.y-1),head-Vector2(0,4),Vector2(x+8,at.y+panel.size.y-1)])
	else:
		# At the top edge, move beside the speaker instead of covering a face.
		var right := head.x+44+panel.size.x <= area.end.x
		at.x = head.x+44 if right else head.x-panel.size.x-44
		at.x = clampf(at.x,area.position.x,area.end.x-panel.size.x)
		at.y = clampf(head.y-24,area.position.y,area.end.y-panel.size.y)
		var x := at.x+1 if right else at.x+panel.size.x-1
		var y := clampf(head.y+8,at.y+20,at.y+panel.size.y-20)
		points = PackedVector2Array([Vector2(x,y-8),head+Vector2(20 if right else -20,8),Vector2(x,y+8)])
	panel.position = at
	tail.polygon = points
	tail_border.points = PackedVector2Array([points[0],points[1],points[2]])

func on_resize() -> void:
	release_buttons()
	if mode != Mode.CLOSED: update_page()

func _process(delta: float) -> void:
	if mode == Mode.CLOSED: return
	if mode == Mode.HINT:
		remaining -= delta
		if remaining <= 0:
			dismiss()
			return
	if last_view_size != get_viewport().get_visible_rect().size: update_page()
	else: position_bubble()

func _input(event: InputEvent) -> void:
	if mode == Mode.CLOSED: return
	if event is InputEventScreenTouch and event.pressed: set_touch_mode(true)
	if mode != Mode.DIALOGUE: return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if not event.pressed or event.echo: return
		if event.keycode == KEY_E: advance()
		elif event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
			if close_button.has_focus(): dismiss()
			else: advance()
		elif event.keycode == KEY_ESCAPE: dismiss()
		elif event.keycode == KEY_TAB:
			if next_button.has_focus(): close_button.grab_focus()
			else: next_button.grab_focus()
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		# Buttons handle their own fingers first; consume remaining touches so
		# they cannot start walking or attacking beneath a conversation.
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if is_instance_valid(next_button) and what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]: release_buttons()

func _exit_tree() -> void:
	if mode == Mode.DIALOGUE: closed.emit(false)
