extends CanvasLayer

signal destination_selected(planet: int)

const NAMES := ["Green Planet", "Frost Canyon", "Ember Dunes"]
const DESCRIPTIONS := ["Meadows & Moss Mine", "Snow & Frost Mine", "Desert & Lava Mine"]
var buttons: Array[Button] = []

func _ready() -> void:
	layer = 3
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.03, 0.05, 0.76)
	add_child(backdrop)
	var panel := Panel.new()
	panel.position = Vector2(245, 220)
	panel.size = Vector2(790, 360)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172b2d")
	style.border_color = Color("b9a475")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var heading := Label.new()
	heading.text = "WHERE SHALL WE FLY?"
	heading.position = Vector2(30, 24)
	heading.add_theme_font_size_override("font_size", 27)
	panel.add_child(heading)
	var detail := Label.new()
	detail.text = "Choose a planet. Your discoveries and materials stay with you."
	detail.position = Vector2(30, 70)
	detail.add_theme_font_size_override("font_size", 17)
	panel.add_child(detail)
	for i in NAMES.size():
		var button := Button.new()
		button.position = Vector2(30 + i * 245, 120)
		button.size = Vector2(235, 120)
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(choose.bind(i))
		panel.add_child(button)
		buttons.append(button)
	var cancel := Button.new()
	cancel.text = "Stay here  [Esc]"
	cancel.position = Vector2(280, 280)
	cancel.size = Vector2(230, 48)
	cancel.pressed.connect(dismiss)
	panel.add_child(cancel)
	visible = false

func open(current_world: int) -> void:
	for i in buttons.size():
		buttons[i].disabled = i == current_world
		buttons[i].text = NAMES[i] + "\n" + ("You are here" if i == current_world else "[%d]  %s" % [i + 1, DESCRIPTIONS[i]])
	visible = true
	buttons[1 if current_world == 0 else 0].grab_focus()

func choose(planet: int) -> void:
	if not visible or planet < 0 or planet >= buttons.size() or buttons[planet].disabled:
		return
	visible = false
	destination_selected.emit(planet)

func dismiss() -> void:
	visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
		dismiss()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_3:
		choose(event.keycode - KEY_1)
	else:
		return
	get_viewport().set_input_as_handled()
