extends CanvasLayer

const STYLE = preload("res://ui/expedition_style.gd")
const CATALOG = preload("res://ui/world_catalog.gd")
const ART = preload("res://environment/trial_art.gd")
var game: Node
var material_label: Label
var buttons: Array[Button] = []
var close_button: Button
var notes: Array[Label] = []
var cards: Array[Panel] = []
var finished_label: Label

func _ready() -> void:
	layer = 4
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015,0.03,0.025,0.72)
	add_child(backdrop)
	var panel := STYLE.panel(self,Vector2(264,184),Vector2(752,432))
	var title := STYLE.label(panel,"Camp workbench",Vector2(28,20),Vector2(696,38),28,true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	material_label = STYLE.label(panel,"",Vector2(28,61),Vector2(696,26),17)
	material_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in 2:
		var card := STYLE.panel(panel,Vector2(22+i*364,105),Vector2(344,242))
		cards.append(card)
		var heading := STYLE.label(card,"Hand drill" if i == 0 else "Copper sword",Vector2(16,12),Vector2(312,30),21,true)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		STYLE.icon(card,CATALOG.tool_icon(true) if i == 0 else ART.icon(0),Vector2(137,45),Vector2(70,70))
		var cost := STYLE.label(card,"5 copper" if i == 0 else "3 copper + 2 wood",Vector2(15,119),Vector2(314,24),18,true)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var note := STYLE.label(card,"",Vector2(15,146),Vector2(314,24),13)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notes.append(note)
		var button := STYLE.button(card,"",Vector2(22,178),Vector2(300,56),18)
		button.pressed.connect(craft.bind("drill" if i == 0 else "sword"))
		buttons.append(button)
	finished_label = STYLE.label(panel,"All starter equipment is built!",Vector2(70,188),Vector2(612,48),23,true)
	finished_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_button = STYLE.button(panel,"Back to exploring",Vector2(250,366),Vector2(252,56),17)
	close_button.pressed.connect(dismiss)
	hide()

func open() -> void:
	if game.world != 0 or not game.at_workbench(): return
	game.clear_touch_gestures()
	game.walking = false
	game.restore_walk_visual()
	show()
	present()
	close_button.grab_focus()
	game.refresh_ui()

func present() -> void:
	material_label.text = "Your materials: %d copper    ·    %d wood" % [game.ore,game.trial.wood]
	var remaining := int(not game.upgraded)+int(not game.trial.sword_owned)
	finished_label.visible = remaining == 0
	for i in 2:
		var owned: bool = game.upgraded if i == 0 else game.trial.sword_owned
		cards[i].visible = not owned and game.world == 0
		cards[i].position.x = 204 if remaining == 1 else 22+i*364
		var earth_only: bool = i == 1 and game.world != 0
		var available: bool = game.ore >= (5 if i == 0 else 3) and (i == 0 or game.trial.wood >= 2)
		buttons[i].disabled = owned or earth_only or not available
		buttons[i].text = "Built" if owned else ("Craft at Earth camp" if earth_only else ("Build hand drill" if i == 0 else "Craft sword"))
		notes[i].text = "Ready for adventure" if owned else ("Find materials along Earth's trails" if not available else ("Mine rare minerals" if i == 0 else "Stronger attacks against Earth foes"))

func craft(recipe: String) -> void:
	if not visible: return
	game.craft_item(recipe)
	present()
	game.refresh_ui()

func dismiss() -> void:
	hide()
	for button in buttons: button.release_touch()
	close_button.release_touch()
	get_viewport().gui_release_focus()
	game.refresh_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or event.keycode == KEY_R: return
	get_viewport().set_input_as_handled()
	if event.is_pressed() and not event.is_echo() and event.keycode in [KEY_E,KEY_ESCAPE]: dismiss()
