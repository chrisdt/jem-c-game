extends CanvasLayer

signal confirmed

const STYLE = preload("res://ui/expedition_style.gd")
var no_button: Button
var yes_button: Button
var previous_focus: Control
var previous_pause := false
var owns_pause := false

func _ready() -> void:
	layer = 10
	# The world, wildlife and other menus pause; this modal stays interactive.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015,0.03,0.025,0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	var panel := STYLE.panel(self,Vector2(370,264),Vector2(540,272))
	var heading := STYLE.label(panel,"Reset game?",Vector2(24,26),Vector2(492,42),30,true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var detail := STYLE.label(panel,"Start a new adventure?\nYour current progress will be lost.",Vector2(32,88),Vector2(476,66),19)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_button = STYLE.button(panel,"No",Vector2(60,184),Vector2(196,60),21)
	yes_button = STYLE.button(panel,"Yes",Vector2(284,184),Vector2(196,60),21)
	no_button.pressed.connect(dismiss)
	yes_button.pressed.connect(accept_reset)
	# Keep keyboard focus inside the modal, starting with the safe choice.
	for button in [no_button,yes_button]:
		var other: Button = yes_button if button == no_button else no_button
		button.focus_neighbor_left = button.get_path_to(other)
		button.focus_neighbor_right = button.get_path_to(other)
		button.focus_neighbor_top = button.get_path_to(other)
		button.focus_neighbor_bottom = button.get_path_to(other)
		button.focus_next = button.get_path_to(other)
		button.focus_previous = button.get_path_to(other)
	hide()

func open() -> void:
	if owns_pause:
		return
	previous_focus = get_viewport().gui_get_focus_owner()
	previous_pause = get_tree().paused
	owns_pause = true
	get_tree().paused = true
	show()
	no_button.grab_focus()

func close_prompt(restore_focus: bool) -> void:
	hide()
	no_button.release_touch()
	yes_button.release_touch()
	get_viewport().gui_release_focus()
	get_tree().paused = previous_pause
	owns_pause = false
	if restore_focus and is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
	previous_focus = null

func dismiss() -> void:
	if not owns_pause:
		return
	close_prompt(true)

func accept_reset() -> void:
	if not owns_pause:
		return
	close_prompt(false)
	confirmed.emit()

func _input(event: InputEvent) -> void:
	if not owns_pause or not event is InputEventKey:
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo:
			dismiss()
	elif event.keycode == KEY_R:
		# Holding or pressing R again must never confirm the reset.
		get_viewport().set_input_as_handled()

func _unhandled_key_input(_event: InputEvent) -> void:
	if owns_pause:
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = previous_pause
