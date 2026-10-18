extends CanvasLayer

signal action_requested

const STYLE = preload("res://ui/expedition_style.gd")
const CATALOG = preload("res://ui/world_catalog.gd")
var location_panel: Panel
var resource_panel: Panel
var location_title: Label
var location_subtitle: Label
var planet: TextureRect
var material_icons: Array[TextureRect] = []
var material_labels: Array[Label] = []
var counts: Array[Label] = []
var equipment: TextureRect
var objective: Label
var context_button: Button
var notice: Panel
var notice_label: Label
var help_button: Button
var help: Panel
var last_message := ""
var notice_seconds := 0.0
var blocked := false

func _ready() -> void:
	location_panel = STYLE.panel(self, Vector2(18,18), Vector2(242,58))
	planet = STYLE.icon(location_panel, CATALOG.planet_icon(0), Vector2(4,1), Vector2(58,56))
	location_title = STYLE.label(location_panel, "EARTH", Vector2(66,7), Vector2(164,24), 18, true)
	location_subtitle = STYLE.label(location_panel, "Surface", Vector2(66,31), Vector2(162,20), 14)
	resource_panel = STYLE.panel(self, Vector2(888,18), Vector2(374,58))
	for i in 2:
		var x := 12 + i * 148
		material_icons.append(STYLE.icon(resource_panel, CATALOG.ORES[0][i], Vector2(x,8), Vector2(40,42)))
		material_labels.append(STYLE.label(resource_panel, "", Vector2(x+47,7), Vector2(94,18), 12))
		counts.append(STYLE.label(resource_panel, "0", Vector2(x+47,24), Vector2(90,29), 22, true))
		var divider := ColorRect.new()
		divider.color = Color("9e854d")
		divider.position = Vector2(x+141,14)
		divider.size = Vector2(1,30)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resource_panel.add_child(divider)
	equipment = STYLE.icon(resource_panel, CATALOG.tool_icon(false), Vector2(314,6), Vector2(48,46))
	equipment.mouse_filter = Control.MOUSE_FILTER_PASS
	objective = STYLE.label(self, "", Vector2(24,83), Vector2(550,24), 15, true)
	objective.add_theme_constant_override("shadow_offset_x", 1)
	context_button = STYLE.button(self, "", Vector2(450,742), Vector2(380,40))
	context_button.focus_mode = Control.FOCUS_NONE
	context_button.pressed.connect(func(): action_requested.emit())
	notice = STYLE.panel(self, Vector2(345,684), Vector2(590,46))
	notice_label = STYLE.label(notice, "", Vector2(15,5), Vector2(560,36), 13)
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice.visible = false
	help_button = STYLE.button(self, "?", Vector2(1230,746), Vector2(32,34), 17)
	help_button.focus_mode = Control.FOCUS_NONE
	help_button.tooltip_text = "Controls"
	help_button.pressed.connect(func(): help.visible = not help.visible)
	help = STYLE.panel(self, Vector2(922,574), Vector2(340,158))
	STYLE.label(help,"EXPLORER'S GUIDE",Vector2(18,12),Vector2(300,24),16,true)
	STYLE.label(help,"WASD / arrows   Walk\nE / Space   Mine, use or cancel\nWalk into mine doors to enter / leave\nR   Start a new game",Vector2(18,43),Vector2(306,104),14)
	help.visible = false

func present(state: Dictionary) -> void:
	var world: int = state.world
	location_title.text = CATALOG.NAMES[world].to_upper()
	location_subtitle.text = state.place
	planet.texture = CATALOG.planet_icon(world)
	for i in 2:
		material_icons[i].texture = CATALOG.ORES[world][i]
		material_labels[i].text = CATALOG.MATERIALS[world][i]
		counts[i].text = str(state.inventory[i])
	equipment.texture = CATALOG.tool_icon(state.upgraded)
	equipment.tooltip_text = "Hand drill fitted — ready for every mineral" if state.upgraded else "Starter pick — build a hand drill at camp for 5 copper"
	objective.text = state.objective
	objective.visible = not state.menu
	context_button.text = state.context
	context_button.disabled = state.flying or state.menu or not state.actionable
	# Keep the control logically enabled in open ground, while hiding it when
	# there is nothing nearby to interact with. Flight always locks input.
	if state.context.is_empty() and not state.flying and not state.menu:
		context_button.disabled = false
	var width := clampf(STYLE.HEADING.get_string_size(state.context,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x + 42,230,470)
	context_button.size.x = width
	context_button.position.x = (1280 - width) * 0.5
	context_button.visible = not state.flying and not state.menu and not state.context.is_empty()
	blocked = state.menu or state.mining or state.flying
	help_button.visible = not state.menu
	if state.menu:
		help.visible = false
	if state.message != last_message:
		last_message = state.message
		notice_label.text = state.message
		notice_seconds = 4.5
	notice.visible = notice_seconds > 0 and not blocked and not state.message.is_empty()

func _process(delta: float) -> void:
	notice_seconds = maxf(0, notice_seconds - delta)
	notice.visible = notice_seconds > 0 and not blocked and visible
