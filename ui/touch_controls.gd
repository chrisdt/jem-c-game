extends Control

signal touch_detected

const STYLE = preload("res://ui/expedition_style.gd")
const CENTER := Vector2(90,90)
const DEAD_ZONE := 14.0
const TRAVEL := 52.0
var direction := Vector2.ZERO
var finger := -1
var knob := Vector2.ZERO
var active := false
var detected := false
var pad_style: StyleBoxFlat
var knob_style: StyleBoxFlat

static func device_uses_touch() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0"))
	return DisplayServer.is_touchscreen_available()

func _ready() -> void:
	position = Vector2(36,590)
	size = Vector2(180,180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad_style = StyleBoxFlat.new()
	pad_style.bg_color = Color(0.07,0.21,0.21,0.72)
	pad_style.border_color = Color(0.84,0.68,0.35,0.8)
	pad_style.set_border_width_all(2)
	pad_style.set_corner_radius_all(34)
	knob_style = StyleBoxFlat.new()
	knob_style.bg_color = Color(0.16,0.36,0.34,0.95)
	knob_style.border_color = STYLE.GOLD
	knob_style.set_border_width_all(2)
	knob_style.set_corner_radius_all(24)
	get_viewport().size_changed.connect(clear)
	set_active(false)

func set_active(value: bool) -> void:
	active = value
	visible = value
	if not value:
		clear()

func clear() -> void:
	finger = -1
	direction = Vector2.ZERO
	knob = Vector2.ZERO
	queue_redraw()

func update_drag(point: Vector2) -> void:
	var offset := get_global_transform_with_canvas().affine_inverse() * point - CENTER
	knob = offset.limit_length(TRAVEL)
	direction = offset.normalized() if offset.length() > DEAD_ZONE else Vector2.ZERO
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not detected:
		detected = true
		touch_detected.emit()
	if not active:
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger < 0:
			var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			if Rect2(Vector2.ZERO,size).has_point(point):
				finger = event.index
				update_drag(event.position)
				get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			clear()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		update_drag(event.position)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		clear()

func _draw() -> void:
	if pad_style == null:
		return
	draw_style_box(pad_style,Rect2(Vector2.ZERO,size))
	for facing in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
		var tip: Vector2 = CENTER + facing*72
		var side: Vector2 = facing.orthogonal()*6
		draw_colored_polygon(PackedVector2Array([tip,tip-facing*9+side,tip-facing*9-side]),Color(1,0.94,0.8,0.55))
	draw_style_box(knob_style,Rect2(CENTER+knob-Vector2(25,25),Vector2(50,50)))
	draw_string(STYLE.BODY,Vector2(0,-10),"MOVE",HORIZONTAL_ALIGNMENT_CENTER,180,14,STYLE.CREAM)
