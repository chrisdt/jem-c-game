extends Button

# Handle each finger directly. Mouse emulation alone only follows the first
# finger, so it cannot operate menus/actions while a thumb holds the walk pad.
var finger := -1
var scroll_owner: ScrollContainer
var press_point := Vector2.ZERO
var dragged := false

func contains_touch(point: Vector2) -> bool:
	var local := get_global_transform_with_canvas().affine_inverse() * point
	if not Rect2(Vector2.ZERO,size).has_point(local): return false
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			var clipped: Vector2 = ancestor.get_global_transform_with_canvas().affine_inverse()*point
			if not Rect2(Vector2.ZERO,ancestor.size).has_point(clipped): return false
		ancestor = ancestor.get_parent()
	return true

func release_touch() -> void:
	finger = -1
	dragged = false
	modulate = Color.WHITE

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Consume the mouse copy of a touch, including the release after pressed
	# changes screens. Physical mouse clicks still use Button's normal handling.
	if event is InputEventMouse and event.device == -1:
		if finger >= 0 or contains_touch(event.position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if finger < 0 and not disabled and contains_touch(event.position):
				finger = event.index
				press_point = event.position
				dragged = false
				modulate = Color(0.8,0.87,0.85)
				get_viewport().set_input_as_handled()
		elif event.index == finger:
			var activate: bool = not event.canceled and not disabled and not dragged and contains_touch(event.position)
			release_touch()
			get_viewport().set_input_as_handled()
			if activate:
				pressed.emit()
	elif event is InputEventScreenDrag and event.index == finger:
		if is_instance_valid(scroll_owner) and (dragged or event.position.distance_to(press_point) > 10):
			dragged = true
			var local_motion := scroll_owner.get_global_transform_with_canvas().affine_inverse().basis_xform(event.relative)
			scroll_owner.scroll_vertical -= roundi(local_motion.y)
		modulate = Color(0.8,0.87,0.85) if contains_touch(event.position) else Color.WHITE
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_touch()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release_touch()

func _process(_delta: float) -> void:
	if finger >= 0 and disabled:
		release_touch()
