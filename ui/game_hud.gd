extends CanvasLayer

signal action_requested
signal equipment_requested(index: int)
signal attack_requested
signal missions_requested

const STYLE = preload("res://ui/expedition_style.gd")
const CATALOG = preload("res://ui/world_catalog.gd")
const TOUCH_CONTROLS = preload("res://ui/touch_controls.gd")
const TRIAL_ART = preload("res://environment/trial_art.gd")
var touch_controls: TOUCH_CONTROLS
var touch_mode := false
var touch_blocked := false
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
var help_button: Button
var help: Panel
var help_text: Label
var trial_active := false
var health_panel: Panel
var health_hearts: Array[TextureRect] = []
var mission_panel: Panel
var equip_slots: Array[Button] = []
var equip_icons: Array[TextureRect] = []
var equip_marks: Array[Panel] = []
var equip_labels: Array[Label] = []
var equipped_label: Label
var attack_button: Button
var missions_button: Button

func _ready() -> void:
	location_panel = STYLE.panel(self, Vector2(18,18), Vector2(242,58))
	planet = STYLE.icon(location_panel, CATALOG.planet_icon(0), Vector2(4,1), Vector2(58,56))
	location_title = STYLE.label(location_panel, "EARTH", Vector2(66,7), Vector2(164,24), 18, true)
	location_subtitle = STYLE.label(location_panel, "Surface", Vector2(66,31), Vector2(162,20), 14)
	resource_panel = STYLE.panel(self, Vector2(888,18), Vector2(374,58))
	for i in 3:
		var x := 12 + i * 148
		material_icons.append(STYLE.icon(resource_panel, CATALOG.ORES[0][i] if i < 2 else TRIAL_ART.wood(), Vector2(x,8), Vector2(40,42)))
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
	help_button = STYLE.button(self, "?", Vector2(1230,746), Vector2(32,34), 17)
	help_button.focus_mode = Control.FOCUS_NONE
	help_button.tooltip_text = "Controls"
	help_button.pressed.connect(func(): help.visible = not help.visible)
	help = STYLE.panel(self, Vector2(922,574), Vector2(340,158))
	STYLE.label(help,"EXPLORER'S GUIDE",Vector2(18,12),Vector2(300,24),16,true)
	help_text = STYLE.label(help,"",Vector2(18,43),Vector2(306,104),14)
	help.visible = false
	touch_controls = TOUCH_CONTROLS.new()
	add_child(touch_controls)
	touch_controls.touch_detected.connect(func(): set_touch_mode(true))
	set_touch_mode(TOUCH_CONTROLS.device_uses_touch())
	make_trial_hud()
	set_touch_mode(touch_mode)

func make_trial_hud() -> void:
	health_panel = STYLE.panel(self,Vector2(18,84),Vector2(198,34))
	for i in 5:
		health_hearts.append(STYLE.icon(health_panel,TRIAL_ART.icon(1),Vector2(10+i*36,4),Vector2(31,26)))
	mission_panel = Panel.new()
	mission_panel.position = Vector2(18,124)
	mission_panel.size = Vector2(144,44)
	mission_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	add_child(mission_panel)
	missions_button = STYLE.button(mission_panel,"Quests · J",Vector2.ZERO,Vector2(144,44),17)
	missions_button.focus_mode = Control.FOCUS_NONE
	missions_button.pressed.connect(func(): missions_requested.emit())
	for i in 2:
		var button := STYLE.button(self,"",Vector2(560+i*80,708),Vector2(72,72),12)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): equipment_requested.emit(i))
		equip_slots.append(button)
		equip_icons.append(STYLE.icon(button,CATALOG.tool_icon(false) if i == 0 else TRIAL_ART.icon(0),Vector2(10,6),Vector2(52,48)))
		equip_labels.append(STYLE.label(button,"",Vector2(4,53),Vector2(64,16),11))
		equip_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var selected := Panel.new()
		selected.position = Vector2(1,1)
		selected.size = Vector2(70,70)
		selected.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color.TRANSPARENT
		frame.border_color = Color("ffe19a")
		frame.set_border_width_all(3)
		frame.set_corner_radius_all(10)
		frame.shadow_color = Color(1,0.78,0.24,0.35)
		frame.shadow_size = 4
		selected.add_theme_stylebox_override("panel",frame)
		button.add_child(selected)
		equip_marks.append(selected)
	equipped_label = STYLE.label(self,"",Vector2(545,682),Vector2(180,22),14,true)
	equipped_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_button = STYLE.button(self,"Space · Jab",Vector2(1110,688),Vector2(112,62),14)
	attack_button.focus_mode = Control.FOCUS_NONE
	attack_button.pressed.connect(func(): attack_requested.emit())
	# No extra HUD is shown until present() identifies Earth.
	set_trial_visibility(false)

func set_trial_visibility(value: bool) -> void:
	health_panel.visible = value
	mission_panel.visible = value
	equipped_label.visible = value
	for button in equip_slots: button.visible = value
	attack_button.visible = value

func set_touch_mode(value: bool) -> void:
	touch_mode = value
	context_button.size.y = 64 if value else 40
	context_button.position.y = 704 if value else 742
	help_button.position = Vector2(1194,622) if value else Vector2(1230,746)
	help_button.size = Vector2(68,60) if value else Vector2(32,34)
	help.position = Vector2(922,454) if value else Vector2(922,574)
	update_help_copy()
	touch_controls.set_active(value and not touch_blocked)
	if is_instance_valid(missions_button):
		missions_button.text = "Quests" if value else "Quests · J"
		missions_button.size = Vector2(144,52) if value else Vector2(144,44)
		mission_panel.size = missions_button.size
		missions_button.position = Vector2.ZERO

func present(state: Dictionary) -> void:
	trial_active = state.get("trial_active",false)
	update_help_copy()
	var world: int = state.world
	location_title.text = CATALOG.NAMES[world].to_upper()
	location_subtitle.text = state.place
	planet.texture = CATALOG.planet_icon(world)
	for i in 3:
		var shown := i < 2 or world == 0
		material_icons[i].visible = shown
		material_labels[i].visible = shown
		counts[i].visible = shown
		material_icons[i].texture = CATALOG.ORES[world][i] if i < 2 else TRIAL_ART.wood()
		material_labels[i].text = CATALOG.MATERIALS[world][i] if i < 2 else "Wood"
		counts[i].text = str(state.inventory[i]) if i < 2 else str(state.get("wood",0))
	equipment.texture = CATALOG.tool_icon(state.upgraded)
	equipment.tooltip_text = "Hand drill fitted — ready for every mineral" if state.upgraded else "Starter pick — build a hand drill at camp for 5 copper"
	equipment.visible = not trial_active
	resource_panel.position.x = 804 if trial_active else 888
	resource_panel.size.x = 458 if trial_active else 374
	objective.text = state.objective
	objective.visible = not state.menu and not trial_active
	context_button.text = state.context.trim_prefix("E / Space   ").trim_prefix("E   ") if touch_mode else state.context
	context_button.disabled = state.flying or state.menu or not state.actionable
	# Keep the control logically enabled in open ground, while hiding it when
	# there is nothing nearby to interact with. Flight always locks input.
	if state.context.is_empty() and not state.flying and not state.menu:
		context_button.disabled = false
	var width := clampf(STYLE.HEADING.get_string_size(context_button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x + 42,230,320 if touch_mode else 470)
	context_button.size.x = width
	context_button.position.x = 1262-width if touch_mode else (1280-width)*0.5
	context_button.visible = not state.flying and not state.menu and not state.context.is_empty()
	context_button.position.y = (599 if touch_mode else 638) if trial_active else (704 if touch_mode else 742)
	touch_blocked = state.menu or state.flying
	touch_controls.set_active(touch_mode and not touch_blocked)
	help_button.visible = not state.menu
	if state.menu:
		help.visible = false
	if trial_active:
		present_trial(state)
	else:
		set_trial_visibility(false)
		# Keep remaining health readable while searching other districts for
		# scarce fruit, without adding combat controls outside the meadow trial.
		health_panel.visible = state.get("health",10) < 10 and not state.menu and not state.flying
		set_touch_layout_positions()
	present_health(state.get("health",10))
	objective.position.y = 123 if health_panel.visible else 83

func set_touch_layout_positions() -> void:
	help_button.position = Vector2(1194,622) if touch_mode else Vector2(1230,746)
	help.position = Vector2(922,454) if touch_mode else Vector2(922,574)

func update_help_copy() -> void:
	if trial_active:
		help_text.text = "Drag pad · walk\nTap action · gather / mine\nMove to pause; return to resume\nOpen Quests for your next step" if touch_mode else "WASD / arrows · walk\n1 tool · 2 sword · Space attack\nE / Space · gather / mine\nJ · Quests   E · talk / use"
	else:
		help_text.text = "Drag pad   Walk\nTap action   Mine, use or cancel\nWalk into doors and signed trails\nReload page   Start a new game" if touch_mode else "WASD / arrows   Walk\nE / Space   Mine, use or cancel\nWalk into mine doors to enter / leave\nR   Reset (asks first)"

func present_trial(state: Dictionary) -> void:
	set_trial_visibility(not state.menu and not state.flying)
	var owned: bool = state.get("sword_owned",false)
	missions_button.disabled = state.menu or state.flying or state.get("jabbing",false) or help.visible
	missions_button.tooltip_text = "Quests · expand a title for instructions and progress"
	equip_icons[0].texture = CATALOG.tool_icon(state.upgraded)
	var selected: int = state.get("selected_tool",0)
	for i in 2:
		equip_marks[i].visible = i == selected
		equip_slots[i].disabled = state.menu or state.flying or state.get("jabbing",false) or help.visible
		equip_labels[i].text = str(i+1)
	equip_slots[1].disabled = equip_slots[1].disabled or not owned
	equip_icons[1].modulate.a = 1.0 if owned else 0.35
	equip_slots[1].tooltip_text = "Copper sword" if owned else "Craft at Earth camp: 3 copper + 2 wood"
	equipped_label.text = ("Reinforced sword" if state.get("improved_sword",false) else "Sword") if selected == 1 else ("Crystal drill" if state.get("improved_drill",false) else ("Hand drill" if state.upgraded else "Mining pick"))
	equip_icons[0].modulate = Color(0.75,1.2,1.25) if state.get("improved_drill",false) else Color.WHITE
	equip_icons[1].modulate = Color(0.75,1.2,1.25,1 if owned else 0.35) if state.get("improved_sword",false) else Color(1,1,1,1 if owned else 0.35)
	attack_button.disabled = state.menu or state.flying or state.get("jabbing",false) or help.visible
	attack_button.text = ("Jab" if selected == 1 else "Attack") if touch_mode else ("Space · Jab" if selected == 1 else "Space · Hit")
	if not touch_mode and selected == 0 and state.get("mining_reachable",false): attack_button.text = "Attack"
	if not touch_mode and state.get("space_object",false): attack_button.text = "Jab" if selected == 1 else "Attack"
	attack_button.position = Vector2(1140,680) if touch_mode else Vector2(1110,688)
	attack_button.size = Vector2(122,98) if touch_mode else Vector2(112,62)
	if touch_mode:
		help_button.position = Vector2(1194,515)
		help.position = Vector2(922,343)
	else: set_touch_layout_positions()

func present_health(health: int) -> void:
	for i in 5:
		var units := clampi(health-i*2,0,2)
		health_hearts[i].texture = TRIAL_ART.icon(1 if units == 2 else (2 if units == 1 else 3))
	health_panel.tooltip_text = "%.1f / 5 hearts" % (health*0.5)
