extends SceneTree
const TRAVEL = preload("res://tests/support/area_travel.gd")
const GRID := 20.0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)
func reachable(game) -> Array[Vector2]:
	var first := Vector2i((game.player/GRID).round())
	var queue: Array[Vector2i] = [first]
	var visited := {first:true}
	var points: Array[Vector2] = []
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		points.append(Vector2(cell)*GRID)
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+offset
			if visited.has(next): continue
			var point := Vector2(next)*GRID
			if not Rect2(70,150,1860,1160).has_point(point): continue
			if game.trial.floor_at(point):
				visited[next] = true
				queue.append(next)
	return points
func near(points: Array[Vector2], target: Vector2) -> bool:
	return points.any(func(p): return p.distance_to(target) < 85)
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.ember_story.set_process(false)
	game.travel_to_other_planet(2)
	game.advance_flight(10)
	var samples := 0
	for region in 5:
		for cave in [false,true]:
			if cave and not game.regions().has_mine(region): continue
			await TRAVEL.enter(game,region,cave)
			var points := reachable(game)
			samples += points.size()
			for person in game.ember_story.npcs:
				if cave or person.home_region != region: continue
				check(person.position.is_finite() and near(points,person.position),"Unreachable Sunstone Folk: "+str(person.name))
			for id in game.ember_story.props:
				check(near(points,game.ember_story.props[id].position),"Unreachable Sunforge quest object: "+id)
			for scorpion in game.ember_story.scorpions:
				check(near(points,scorpion.position),"Yeti has no accessible ground approach")
			check(game.earth_stream.textures.size() <= game.earth_stream.MAX_TEXTURES,"Sunforge story bypasses bounded scenery cache")
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: four Sunstone Folk, all Sunforge quest props and scorpion approaches reachable across five surfaces and three mines (%d floor samples), bounded scenery cache" % samples)
	quit(1 if failures else 0)
