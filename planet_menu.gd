extends CanvasLayer

signal destination_selected(planet: int)
signal closed

const STYLE = preload("res://ui/expedition_style.gd")
const CATALOG = preload("res://ui/world_catalog.gd")
const NAMES := CATALOG.NAMES
const DESCRIPTIONS := CATALOG.DESCRIPTIONS
var buttons: Array[Button] = []
var thumbnails: Array[TextureRect] = []
var panel: Panel

func _ready() -> void:
	layer = 3
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015,0.03,0.025,0.48)
	add_child(backdrop)
	panel = STYLE.panel(self,Vector2(280,220),Vector2(720,360))
	var heading := STYLE.label(panel,"Where shall we fly?",Vector2(58,14),Vector2(604,32),23,true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var detail := STYLE.label(panel,"Choose your next adventure",Vector2(60,46),Vector2(600,20),14)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_button := STYLE.button(panel,"×",Vector2(670,15),Vector2(32,32),20)
	close_button.pressed.connect(dismiss)
	for i in NAMES.size():
		var card := STYLE.panel(panel,Vector2(18+i*234,72),Vector2(216,224))
		var name_label := STYLE.label(card,NAMES[i],Vector2(10,8),Vector2(196,25),18,true)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		thumbnails.append(STYLE.icon(card,CATALOG.planet_icon(i),Vector2(58,34),Vector2(100,92)))
		var description := STYLE.label(card,DESCRIPTIONS[i],Vector2(6,126),Vector2(204,19),12)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for mineral in 2:
			STYLE.icon(card,CATALOG.ORES[i][mineral],Vector2(72+mineral*40,146),Vector2(32,28))
		var button := STYLE.button(card,"",Vector2(15,181),Vector2(186,32),15)
		button.pressed.connect(choose.bind(i))
		buttons.append(button)
	var cancel := STYLE.button(panel,"Esc   Stay here",Vector2(270,311),Vector2(180,34),15)
	cancel.pressed.connect(dismiss)
	visible = false

func open(current_world: int) -> void:
	for i in buttons.size():
		buttons[i].disabled = i == current_world
		buttons[i].text = "You are here" if i == current_world else "%d   Fly here" % (i+1)
	visible = true
	buttons[1 if current_world == 0 else 0].grab_focus()

func choose(planet: int) -> void:
	if not visible or planet < 0 or planet >= buttons.size() or buttons[planet].disabled:
		return
	visible = false
	destination_selected.emit(planet)

func dismiss() -> void:
	visible = false
	closed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
		dismiss()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_3:
		choose(event.keycode-KEY_1)
	else:
		return
	get_viewport().set_input_as_handled()
