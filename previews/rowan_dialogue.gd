extends Node2D

# An isolated R04 review scene. The normal startup, game and quest state are
# unchanged. The world is a frozen backdrop, with no mission acceptance yet.
const BUBBLE = preload("res://ui/character_bubble.gd")
const STYLE = preload("res://ui/expedition_style.gd")
const PEOPLE: Texture2D = preload("res://assets/npcs/earth_people_concept.png")
const PAGES: Array[String] = [
	"Let's get you ready for the trail. Find 3 copper and 2 fallen wood.",
	"Bring them to this workbench to craft a sword. It'll help with the snakes along the trails.",
]
var game: Node2D
var bubble: BUBBLE
var rowan: Sprite2D
var marker: Marker2D
var status_label: Label
var preview_buttons: Array[Button] = []
var position_index := 0
var rowan_height := 0.0
var scout_height := 0.0
var source_bounds: Rect2i
var normal_foot := Vector2(650,454)

func _ready() -> void:
	game = load("res://main.tscn").instantiate()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(game)
	game.hud.notice.hide()
	game.hud.mission_panel.hide()
	game.hud.context_button.hide()
	game.hud.help_button.hide()
	game.hud.objective.hide()
	game.hud.attack_button.hide()
	game.camera.position_smoothing_enabled = false
	game.camera.reset_smoothing()
	# Use the source atlas without resizing/editing its PNG. Measure actual
	# alpha bounds of both figures so transparent margins cannot inflate Rowan.
	var scout_art: Texture2D = game.scout.sprite_frames.get_frame_texture(game.scout.animation,game.scout.frame)
	var scout_bounds := visible_bounds(scout_art.get_image())
	scout_height = scout_bounds.size.y*game.scout.scale.y
	var left := PEOPLE.get_image().get_region(Rect2i(0,0,768,1024))
	source_bounds = visible_bounds(left)
	var atlas := AtlasTexture.new()
	atlas.atlas = PEOPLE
	atlas.region = Rect2(source_bounds)
	rowan = Sprite2D.new()
	rowan.name = "RowanScalePreview"
	rowan.texture = atlas
	rowan.centered = false
	rowan.offset = Vector2(-source_bounds.size.x*0.5,-source_bounds.size.y)
	rowan.scale = Vector2.ONE*(scout_height/source_bounds.size.y)
	rowan_height = source_bounds.size.y*rowan.scale.y
	rowan.position = normal_foot
	game.add_child(rowan)
	marker = Marker2D.new()
	marker.position = rowan.position
	game.add_child(marker)
	game.fog.observe(game.area_id(),rowan.position)
	var controls := CanvasLayer.new()
	controls.layer = 3
	add_child(controls)
	var title := STYLE.panel(controls,Vector2(310,18),Vector2(440,56))
	var label := STYLE.label(title,"Rowan · speech bubble preview",Vector2(12,10),Vector2(416,32),19,true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label = STYLE.label(controls,"",Vector2(260,610),Vector2(760,26),15)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var names := ["Talk to Rowan","Show a hint","Next position","Touch buttons"]
	var positions := [Vector2(22,650),Vector2(22,718),Vector2(1048,650),Vector2(1048,718)]
	var callbacks := [talk,show_hint,next_position,toggle_touch]
	for i in 4:
		var button := STYLE.button(controls,names[i],positions[i],Vector2(210,56),16)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(callbacks[i])
		preview_buttons.append(button)
	bubble = BUBBLE.new()
	add_child(bubble)
	bubble.closed.connect(conversation_closed)
	bubble.page_changed.connect(func(_index: int): report_state())
	status_label.text = "E / Enter · Next     Esc / × · Close"
	talk()
	if OS.has_feature("web"):
		# The standard loader waits for this event before revealing the canvas.
		JavaScriptBridge.eval("window.dispatchEvent(new Event('scout-startup-ready'))")
	report_state()

static func visible_bounds(image: Image) -> Rect2i:
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	var low := Vector2i(image.get_width(),image.get_height())
	var high := Vector2i(-1,-1)
	for y in image.get_height():
		for x in image.get_width():
			if data[(y*image.get_width()+x)*4+3] < 32: continue
			low.x = mini(low.x,x)
			low.y = mini(low.y,y)
			high.x = maxi(high.x,x)
			high.y = maxi(high.y,y)
	return Rect2i(low,high-low+Vector2i.ONE)

func talk() -> void:
	status_label.text = "E / Enter · Next     Esc / × · Close"
	bubble.show_dialogue("Rowan",PAGES,marker,Vector2(0,-rowan_height),"Done")
	report_state()

func show_hint() -> void:
	status_label.text = "Hints disappear after a few seconds. Conversations stay until you close them."
	bubble.show_hint("Press E to gather fallen wood.",marker,Vector2(0,-rowan_height))
	report_state()

func conversation_closed(completed: bool) -> void:
	status_label.text = "Dialogue finished. Try a hint or another position." if completed else "Dialogue closed. Try a hint or another position."
	report_state()

func next_position() -> void:
	position_index = (position_index+1)%5
	var screens := [Vector2(650,454),Vector2(70,235),Vector2(1210,235),Vector2(70,585),Vector2(1210,585)]
	rowan.position = game.get_viewport().get_canvas_transform().affine_inverse()*screens[position_index]
	marker.position = rowan.position
	if position_index == 0:
		rowan.position = normal_foot
		marker.position = normal_foot
	game.fog.observe(game.area_id(),rowan.position)
	talk()

func toggle_touch() -> void:
	bubble.set_touch_mode(not bubble.touch_mode)
	preview_buttons[3].text = "Desktop buttons" if bubble.touch_mode else "Touch buttons"
	talk()

func report_state() -> void:
	# State for browser verification of this dedicated review scene only.
	if not OS.has_feature("web"): return
	JavaScriptBridge.eval("window.rowanPreview="+JSON.stringify({
		"open":bubble.is_dialogue_open(),"page":bubble.page_index,
		"touch":bubble.touch_mode,"position":position_index,
		"rowan_height":rowan_height,"scout_height":scout_height,
		"panel":[bubble.panel.position.x,bubble.panel.position.y,bubble.panel.size.x,bubble.panel.size.y],
		"next":[bubble.next_button.global_position.x,bubble.next_button.global_position.y,bubble.next_button.size.x,bubble.next_button.size.y],
		"close":[bubble.close_button.global_position.x,bubble.close_button.global_position.y,bubble.close_button.size.x,bubble.close_button.size.y],
		"body_lines":bubble.body_label.get_line_count(),"body_height":bubble.body_label.size.y,
	}),true)
