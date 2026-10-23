extends CanvasLayer

signal recovered
const STYLE = preload("res://ui/expedition_style.gd")
var game: Node
var session: Node
var recovery_mode := false
var owns_pause := false
var previous_pause := false
var code_field: LineEdit
var detail: Label
var status_label: Label
var primary: Button
var copy_button: Button
var close_button: Button

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	session = get_node("/root/AdventureSave")
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01,0.025,0.03,0.78)
	add_child(shade)
	var panel := STYLE.panel(self,Vector2(290,160),Vector2(700,480))
	STYLE.label(panel,"EXPLORE CHECKPOINTS",Vector2(30,24),Vector2(600,24),16,true).add_theme_color_override("font_color",STYLE.GOLD)
	STYLE.label(panel,"Your adventure",Vector2(30,57),Vector2(580,48),31,true)
	var close := STYLE.button(panel,"X",Vector2(622,22),Vector2(48,38),18)
	close_button = close
	close.pressed.connect(dismiss)
	detail = STYLE.label(panel,"",Vector2(32,115),Vector2(636,66),17)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	code_field = LineEdit.new()
	code_field.position = Vector2(32,192)
	code_field.size = Vector2(636,48)
	code_field.add_theme_font_override("font",STYLE.BODY)
	code_field.add_theme_font_size_override("font_size",20)
	code_field.max_length = 80
	code_field.placeholder_text = "xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx"
	panel.add_child(code_field)
	STYLE.label(panel,"Keep this recovery code to continue on another device.",Vector2(32,250),Vector2(636,26),15)
	status_label = STYLE.label(panel,"",Vector2(32,288),Vector2(636,76),16)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	primary = STYLE.button(panel,"",Vector2(32,390),Vector2(300,54),19)
	primary.pressed.connect(perform)
	copy_button = STYLE.button(panel,"Copy code",Vector2(352,390),Vector2(316,54),19)
	copy_button.pressed.connect(copy_code)
	session.changed.connect(present)
	hide()

func open(for_recovery := false) -> void:
	if owns_pause: return
	if is_instance_valid(game) and game.run_session.timed: return
	recovery_mode = for_recovery
	previous_pause = get_tree().paused
	owns_pause = true
	get_tree().paused = true
	if is_instance_valid(game): game.clear_touch_gestures()
	code_field.editable = recovery_mode
	code_field.text = "" if recovery_mode else session.recovery_code()
	show()
	present()
	if recovery_mode: code_field.grab_focus()
	else: primary.grab_focus()

func present() -> void:
	if not visible: return
	status_label.text = session.status
	close_button.disabled = session.busy
	code_field.editable = recovery_mode and not session.busy
	copy_button.visible = not recovery_mode
	copy_button.disabled = not session.has_save() or session.code.is_empty()
	if recovery_mode:
		detail.text = "Enter your private recovery code to continue an Explore adventure saved online."
		primary.text = "Finding adventure…" if session.busy else "Find my adventure"
		primary.disabled = session.busy
	else:
		detail.text = "Walk close to a glowing save totem to keep a checkpoint. There are two on each world. Speedruns do not use checkpoints."
		code_field.text = session.recovery_code() if not session.code.is_empty() else "No checkpoint yet in this adventure"
		var near: bool = is_instance_valid(game) and game.save_totem.can_save()
		primary.text = "Saving checkpoint…" if session.busy else ("Continue online save" if session.conflict else ("Save and quit" if near else "Return to game"))
		primary.disabled = session.busy
		if not near: status_label.text += "\nReturn to a totem when you want to save and quit."

func perform() -> void:
	if session.busy: return
	if recovery_mode:
		if await session.recover(code_field.text):
			dismiss()
			recovered.emit()
	elif session.conflict:
		if await session.continue_adventure():
			dismiss()
			get_tree().change_scene_to_file("res://main.tscn")
	elif is_instance_valid(game) and game.save_totem.can_save():
		if await session.checkpoint(game):
			dismiss()
			get_tree().change_scene_to_file("res://startup.tscn")
	else: dismiss()

func copy_code() -> void:
	code_field.grab_focus()
	code_field.select_all()
	DisplayServer.clipboard_set(code_field.text)
	copy_button.text = "Code selected · copy"

func dismiss() -> void:
	if not owns_pause: return
	if session.busy: return
	hide()
	get_tree().paused = previous_pause
	owns_pause = false
	get_viewport().gui_release_focus()
	for button in [primary,copy_button]: button.release_touch()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()

func _exit_tree() -> void:
	if owns_pause: get_tree().paused = previous_pause
