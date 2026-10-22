extends Control
var run_session: Node

const STYLE = preload("res://ui/expedition_style.gd")
const CATALOG = preload("res://ui/world_catalog.gd")
const TOUCH = preload("res://ui/touch_controls.gd")
const STARTUP_ART = preload("res://ui/startup_art.gd")
const TRIAL_ART = preload("res://environment/trial_art.gd")
const ART: Texture2D = preload("res://assets/ui/title_landscape.png")
const WORLD_SCENE := "res://main.tscn"
enum Stage { GUIDE, LOADING, ENTERING }
var stage := Stage.GUIDE
var touch_mode := false
const SCORE_PANEL = preload("res://ui/scoreboard_panel.gd")
var score_panel: SCORE_PANEL
var board_button: Button
var relax_button: Button
var start_button: Button
var walk_text: Label
var mine_text: Label
var combat_text: Label
var menu_text: Label
var footer: Label
var load_status: Label
var progress: ProgressBar
var request_started := false
var backdrop: TextureRect
var content: Control
var logo: TextureRect
var window: Window
var previous_aspect := Window.CONTENT_SCALE_ASPECT_KEEP

func _ready() -> void:
	run_session = get_node("/root/RunSession")
	run_session.menu()
	window = get_window()
	previous_aspect = window.content_scale_aspect
	# Fill the window during the welcome scene. The game restores its usual
	# camera/HUD aspect when this scene leaves the tree.
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	backdrop = TextureRect.new()
	backdrop.texture = ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	content = Control.new()
	content.name = "WelcomeContent"
	content.size = Vector2(1280,800)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	logo = STYLE.icon(content,STARTUP_ART.logo_texture(),Vector2(76,86),Vector2(530,156))
	var panel := STYLE.panel(content,Vector2(676,62),Vector2(544,680))
	var eyebrow := STYLE.label(panel,"YOUR EXPLORER'S GUIDE",Vector2(32,22),Vector2(480,24),14,true)
	eyebrow.add_theme_color_override("font_color",STYLE.GOLD)
	STYLE.label(panel,"How to play",Vector2(32,49),Vector2(480,42),30,true)
	STYLE.label(panel,"The controls for your three-world adventure.",Vector2(32,95),Vector2(480,28),15)
	walk_text = guide_row(panel,132,CATALOG.planet_icon(0),"1. Move and explore","")
	mine_text = guide_row(panel,224,CATALOG.ORES[0][0],"2. Talk, use and mine","")
	combat_text = guide_row(panel,316,TRIAL_ART.icon(0),"3. Tools and combat","")
	menu_text = guide_row(panel,408,CATALOG.planet_icon(1),"4. Quests and help","")
	start_button = STYLE.button(panel,"Start speedrun",Vector2(32,506),Vector2(480,60),22)
	start_button.pressed.connect(start_exploring)
	board_button = STYLE.button(panel,"Best times",Vector2(32,578),Vector2(232,46),18)
	board_button.pressed.connect(func(): score_panel.open_board())
	relax_button = STYLE.button(panel,"Explore for fun",Vector2(280,578),Vector2(232,46),18)
	relax_button.pressed.connect(func(): start_exploring(false))
	score_panel = SCORE_PANEL.new()
	add_child(score_panel)
	footer = STYLE.label(panel,"",Vector2(32,638),Vector2(480,32),12)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_status = STYLE.label(panel,"",Vector2(32,586),Vector2(480,22),14)
	load_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_status.hide()
	progress = ProgressBar.new()
	progress.position = Vector2(42,617)
	progress.size = Vector2(460,8)
	progress.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("0a2327")
	track.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = STYLE.GOLD
	fill.set_corner_radius_all(4)
	progress.add_theme_stylebox_override("background",track)
	progress.add_theme_stylebox_override("fill",fill)
	panel.add_child(progress)
	progress.hide()
	set_touch_mode(TOUCH.device_uses_touch())
	start_button.grab_focus()
	get_viewport().size_changed.connect(layout_content)
	resized.connect(layout_content)
	layout_content()
	if OS.has_feature("web"):
		# Let the HTML loader cover engine initialization, then reveal this
		# finished guide instead of exposing an empty first frame.
		await get_tree().process_frame
		JavaScriptBridge.eval("window.dispatchEvent(new Event('scout-startup-ready'))")

func layout_content() -> void:
	content.position = (get_viewport_rect().size - content.size) * 0.5

func _exit_tree() -> void:
	window.content_scale_aspect = previous_aspect

func guide_row(panel: Control, y: float, icon: Texture2D, title: String, text: String) -> Label:
	STYLE.icon(panel,icon,Vector2(29,y+5),Vector2(64,64))
	STYLE.label(panel,title,Vector2(112,y),Vector2(400,27),18,true)
	var detail := STYLE.label(panel,text,Vector2(112,y+30),Vector2(400,54),15)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return detail

func set_touch_mode(value: bool) -> void:
	touch_mode = value
	walk_text.text = "Drag the left pad · Walk\nWalk into mine doors and signed trails." if value else "WASD / arrow keys · Walk\nWalk into mine doors and signed trails."
	mine_text.text = "Tap action · Talk / use / gather / mine\nMove away to pause mining." if value else "E · Talk / use / open camp or rocket\nE / Space · Gather / mine. Move to pause."
	combat_text.text = "Tap tool / sword slots · Choose equipment\nTap Attack / Jab · Fight   Tap antidote · Cure" if value else "1 · Mining tool   2 · Sword   Space · Attack\n3 · Use antidote (once earned)"
	menu_text.text = "Tap Quests · Missions   Tap ? · Controls\nUse Close / X buttons to leave menus." if value else "J · Quests   ? button · Controls\nR · Restart (asks first)   Esc · Close panels"
	footer.text = "Speedrun: finish 14 story quests (extras optional).\nMenus + travel count · No mid-run saves · Use a nickname"

func start_exploring(timed := true) -> void:
	if score_panel.visible or stage != Stage.GUIDE:
		return
	run_session.choose(timed)
	stage = Stage.LOADING
	board_button.hide()
	relax_button.hide()
	start_button.disabled = true
	start_button.text = "Landing on Earth…"
	footer.hide()
	load_status.text = "Packing your pickaxe and preparing the meadow…"
	load_status.show()
	progress.value = 0
	progress.show()
	# Paint the feedback before requesting the world. Single-threaded Web
	# builds may do some resource preparation on their next main-thread frame.
	await get_tree().process_frame
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(WORLD_SCENE,"PackedScene")
	if error != OK:
		load_failed()
		return
	request_started = true

func _process(_delta: float) -> void:
	if stage != Stage.LOADING or not request_started:
		return
	var amount: Array = []
	var status := ResourceLoader.load_threaded_get_status(WORLD_SCENE,amount)
	if not amount.is_empty():
		progress.value = float(amount[0]) * 100
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		stage = Stage.ENTERING
		var scene := ResourceLoader.load_threaded_get(WORLD_SCENE) as PackedScene
		if scene == null or get_tree().change_scene_to_packed(scene) != OK:
			load_failed()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		load_failed()

func load_failed() -> void:
	stage = Stage.GUIDE
	request_started = false
	start_button.disabled = false
	start_button.text = "Try again"
	board_button.show()
	relax_button.show()
	load_status.text = "Earth couldn't open. Please try again."
	progress.hide()
	start_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not touch_mode:
		set_touch_mode(true)
	if score_panel.visible: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		start_exploring()
		get_viewport().set_input_as_handled()
