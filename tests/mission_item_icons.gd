extends SceneTree

const ICONS = preload("res://ui/mission_item_icons.gd")
const BUBBLE = preload("res://ui/character_bubble.gd")
var failures := 0
var checked_pages := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)
func ids(text: String, world: int) -> Array:
	return ICONS.matches(text,world).map(func(item): return item.id)
func run() -> void:
	check(ids("3 copper and 2 fallen wood",0) == ["copper","wood"],"Rowan's material list does not identify both pickups")
	check(ids("Earth sword, 4 frost ore, 1 amethyst and the heart-crystal",1) == ["sword","frost","amethyst","heart"],"Frost recipe uses incorrect or overlapping icons")
	check(ids("hand drill, power coupling, 5 frost ore and 2 amethysts",1) == ["drill","coupling","frost","amethyst"],"Tavi's plural materials or coupling are missing")
	check(ids("Sunfang Sword: Earth sword, 3 gold and 1 fire ruby. Magma Drill.",2) == ["ember_sword","sword","gold","ruby","ember_drill"],"Ember recipe uses the wrong equipment or material icons")
	check(ids("three brass-and-crystal beacon fragments",1) == ["beacon"],"Beacon fragment was split into unrelated crystal icons")
	check(ids("two glowleaf plants and an empty flask; star map",2) == ["glowleaf","flask","map"],"Ember collection items are missing")
	check(ids("golden glints, crystal smith, Deep Prism Mine and swordfish",1).is_empty(),"Ordinary words or place names gained misleading icons")
	var label := RichTextLabel.new()
	root.add_child(label)
	label.size = Vector2(324,200)
	ICONS.fill(label,"Find 3 copper and 2 fallen wood. [b]literal[/b]",0)
	var rendered := label.get_parsed_text()
	check(rendered.contains("3 copper") and rendered.contains("2 fallen wood") and rendered.count("(") == 2 and rendered.count(")") == 2,"Inline icons lost quantities or their parentheses")
	check(rendered.contains("[b]literal[/b]"),"Dialogue was interpreted as markup")
	label.queue_free()
	change_scene_to_file("res://main.tscn")
	await scene_changed
	await process_frame
	var game = current_scene
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var anchor := Node2D.new()
	anchor.position = Vector2(640,450)
	root.add_child(anchor)
	var bubble := BUBBLE.new()
	root.add_child(bubble)
	var source_pages: Array[Array] = [game.rowan.pages()]
	var worlds: Array[int] = [0]
	for world in 3:
		var story = [game.story,game.frost_story,game.ember_story][world]
		for role in story.ORDER:
			source_pages.append(story.pages(role))
			worlds.append(world)
	# A second, ready-to-forge branch exercises the other Frost recipe text.
	game.trial.sword_owned = true
	game.upgraded = true
	game.frost_ore = 5
	game.amethysts = 2
	game.frost_story.collected = {"heart_crystal":true,"coupling":true}
	for role in ["nix","tavi"]:
		source_pages.append(game.frost_story.pages(role))
		worlds.append(1)
	for touch in [false,true]:
		bubble.set_touch_mode(touch)
		for i in source_pages.size():
			var pages: Array[String] = []
			pages.assign(source_pages[i])
			if pages.is_empty(): continue
			var original := pages.duplicate()
			check(bubble.show_dialogue("Mission",pages,anchor,Vector2(0,-92),"Accept quest",worlds[i]),"A mission conversation did not open")
			while bubble.is_dialogue_open():
				var page := pages[bubble.page_index]
				var body := bubble.body_label
				var count := ICONS.matches(page,worlds[i]).size()
				check(body.get_parsed_text().count("(") == page.count("(")+count,"Page retained stale icons or lost parentheses: "+page)
				check(body.size.y >= body.get_content_height(),"Inline images overflow the dialogue body")
				check(body.position.y+body.size.y < bubble.next_button.position.y,"A recipe overlaps the Next button")
				check(bubble.safe_rect().encloses(Rect2(bubble.panel.position,bubble.panel.size)),"A mission bubble left the reserved screen area: "+page)
				checked_pages += 1
				bubble.advance()
			check(pages == original,"Icon rendering changed the story's source pages")
	bubble.show_hint("Find copper and wood.",anchor)
	check(bubble.body_label.get_parsed_text() == "Find copper and wood.","Plain non-modal hints inherited mission icons")
	bubble.dismiss()
	bubble.queue_free()
	anchor.queue_free()
	await process_frame
	if failures == 0: print("PASS: item identity, longest-name and plural matching, literal text, page cleanup and %d actual mission pages fitting keyboard/touch bubbles" % checked_pages)
	quit(1 if failures else 0)
