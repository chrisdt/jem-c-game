extends SceneTree

const BUBBLE = preload("res://ui/character_bubble.gd")
var failures := 0
var outcomes: Array[bool] = []

class InputProbe extends Node:
	var received: Array[int] = []
	func _unhandled_key_input(event: InputEvent) -> void:
		if event.is_pressed(): received.append(event.keycode)

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, detail: String) -> void:
	if condition: return
	failures += 1
	push_error(detail)

func key(code: Key, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	Input.parse_input_event(event)
	await process_frame

func touch(index: int, point: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform()*point
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	await process_frame

func tap(index: int, button: Button) -> void:
	var point: Vector2 = button.get_global_transform_with_canvas()*(button.size*0.5)
	await touch(index,point,true)
	await touch(index,point,false)

func run() -> void:
	var probe := InputProbe.new()
	root.add_child(probe)
	var anchor := Node2D.new()
	anchor.position = Vector2(640,450)
	root.add_child(anchor)
	var bubble := BUBBLE.new()
	root.add_child(bubble)
	bubble.closed.connect(func(completed: bool): outcomes.append(completed))
	var pages: Array[String] = ["Find 3 copper and 2 fallen wood.","Craft a sword at the camp workbench."]
	check(bubble.show_dialogue("Rowan",pages,anchor),"A valid conversation did not open")
	check(bubble.is_dialogue_open() and bubble.speaker_label.text == "ROWAN","Conversation has no speaker or modal state")
	check(bubble.next_button.text == "E  Next" and bubble.page_label.text == "1 / 2","First page controls are wrong")
	check(not bubble.show_hint("Woof!",anchor),"A lower-priority hint interrupted the NPC")
	check(not bubble.show_dialogue("Otis",pages,anchor),"Another NPC interrupted the active conversation")
	await key(KEY_SPACE)
	await key(KEY_R)
	await key(KEY_W)
	check(probe.received.is_empty() and bubble.page_index == 0,"Conversation keys leaked to gameplay or accidentally advanced")
	await key(KEY_E,true)
	check(bubble.page_index == 0,"A held key skipped a page")
	await key(KEY_E)
	check(bubble.page_index == 1 and bubble.next_button.text == "E  Close","A single E did not advance exactly once")
	bubble._process(30)
	check(bubble.is_dialogue_open(),"Dialogue disappeared on a timer")
	await key(KEY_ENTER)
	check(not bubble.is_dialogue_open() and outcomes == [true],"Finishing dialogue did not close with one completed event")
	check(pages.size() == 2,"Closing mutated the caller's dialogue pages")
	bubble.show_dialogue("Rowan",pages,anchor)
	await key(KEY_ESCAPE)
	check(outcomes == [true,false],"Escape did not cancel the conversation")
	bubble.show_dialogue("Rowan",pages,anchor)
	await key(KEY_TAB)
	check(bubble.close_button.has_focus(),"Keyboard focus escaped the bubble")
	await key(KEY_ENTER)
	check(outcomes.back() == false and not bubble.is_dialogue_open(),"Enter did not activate the focused Close button")
	# Hints do not capture gameplay keys, and a conversation replaces a hint.
	check(bubble.show_hint("Press E to gather fallen wood.",anchor,Vector2(0,-92),0.5),"Hint did not open")
	await key(KEY_W)
	check(probe.received == [KEY_W],"A non-modal hint blocked walking input")
	bubble._process(1)
	check(bubble.mode == bubble.Mode.CLOSED,"Hint did not expire")
	bubble.show_hint("Gather wood.",anchor)
	check(bubble.show_dialogue("Rowan",pages,anchor),"NPC dialogue could not replace a hint")
	bubble.set_touch_mode(true)
	check(bubble.next_button.size.y >= 56 and bubble.next_button.text == "Next","Touch buttons are too small or retain keyboard prefixes")
	var point: Vector2 = bubble.next_button.get_global_transform_with_canvas()*(bubble.next_button.size*0.5)
	await touch(3,point,true)
	await touch(4,point,true)
	await touch(4,point,false)
	check(bubble.page_index == 0,"A second finger hijacked the dialogue button")
	await touch(3,point,false)
	check(bubble.page_index == 1,"Touch release did not advance exactly one page")
	point = bubble.next_button.get_global_transform_with_canvas()*(bubble.next_button.size*0.5)
	await touch(3,point,true)
	await touch(3,point,false,true)
	check(bubble.is_dialogue_open(),"Cancelled touch finished the conversation")
	await tap(3,bubble.close_button)
	check(not bubble.is_dialogue_open() and bubble.next_button.finger == -1,"Touch Close left an active conversation or held gesture")
	# Fit above or beside the head while keeping the reserved HUD areas clear.
	bubble.show_dialogue("Rowan",pages,anchor)
	var area := bubble.safe_rect()
	for head in [Vector2(640,365),Vector2(25,130),Vector2(1255,130),Vector2(25,610),Vector2(1255,610)]:
		bubble.place_at(head,area)
		var rect := Rect2(bubble.panel.position,bubble.panel.size)
		check(area.encloses(rect),"Speech bubble left its safe area at %s: %s" % [head,rect])
		check(not rect.has_point(head+Vector2(0,10)),"Bubble covers its speaker's face at %s" % head)
	# Camera changes move the actual anchor instead of leaving screen-fixed UI.
	var before: Vector2 = bubble.panel.position
	anchor.position += Vector2(70,0)
	bubble.position_bubble()
	check(bubble.panel.position != before,"Moving the speaker did not move its bubble")
	anchor.hide()
	bubble._process(0)
	check(bubble.mode == bubble.Mode.CLOSED,"Hiding the speaker stranded a conversation")
	check(not bubble.show_dialogue("Rowan",pages,anchor),"A hidden speaker started a conversation")
	anchor.show()
	anchor.position = Vector2(-1000,-1000)
	check(not bubble.show_dialogue("Rowan",pages,anchor),"An offscreen speaker started a conversation")
	anchor.position = Vector2(640,450)
	bubble.show_dialogue("Rowan",pages,anchor)
	anchor.queue_free()
	await process_frame
	bubble._process(0)
	check(bubble.mode == bubble.Mode.CLOSED,"Freeing the speaker stranded a conversation")
	bubble.queue_free()
	probe.queue_free()
	await process_frame
	# The review scene must match the actual visible heights, not atlas sizes.
	var preview = load("res://previews/rowan_dialogue.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	check(preview.rowan_height > preview.scout_height and is_equal_approx(preview.rowan.head_width,30.0),"Preview lost the shared head size")
	check(preview.bubble.is_dialogue_open() and preview.game.process_mode == Node.PROCESS_MODE_DISABLED,"Preview is not isolated from gameplay")
	check(not preview.game.trial.sword_owned and preview.game.ore == 0,"Bubble preview granted mission progress or equipment")
	preview.queue_free()
	await process_frame
	if failures == 0: print("PASS: NPC paging, priority, key isolation, touch/cancellation, safe screen edges, speaker lifecycle and matching character scale")
	quit(1 if failures else 0)
