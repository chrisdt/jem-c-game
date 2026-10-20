extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const WATER = preload("res://environment/earth_water.gd")
const GRID := 16.0
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func reachable(game) -> Array[Vector2]:
	var queue: Array[Vector2i] = [Vector2i((game.player/GRID).round())]
	var visited := {queue[0]:true}
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
			if not Rect2(90,180,1810,1110).has_point(point): continue
			if game.story.floor_at(point,game.earth_region,game.underground):
				visited[next] = true
				queue.append(next)
	return points

func near_route(points: Array[Vector2], target: Vector2) -> bool:
	for point in points:
		if point.distance_to(target) < 65: return true
	return false

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.story.set_process(false)
	game.story.drill_improved = true
	game.story.sword_improved = true
	for region in 5:
		await TRAVEL.enter(game,region,false)
		var points := reachable(game)
		for npc in game.npcs:
			if npc.home_region != region: continue
			check(near_route(points,npc.position),"NPC is disconnected from the arrival route: "+str(npc.name))
		for id in game.story.props:
			check(near_route(points,game.story.props[id].position),"Quest object is disconnected from its district route: "+id)
		if region == 2:
			var water: Image = WATER.mask_for("willow").image
			var finn = game.npcs.filter(func(n): return n.name == "Finn")[0]
			for point in [finn.position]:
				var pixel := Vector2i(point/game.EARTH.SIZE*Vector2(water.get_size()))
				check(water.get_pixelv(pixel).r < 0.5,"Finn or his seal kit is standing in painted water")
	await TRAVEL.enter(game,0,true)
	check(near_route(reachable(game),game.story.props.seals.position),"Seal kit is disconnected from Moss Mine arrival")
	await TRAVEL.enter(game,4,true)
	check(near_route(reachable(game),game.story.props.engine.position),"Engine part is disconnected from Crystal Depths arrival")
	check(game.earth_stream.textures.size() <= game.earth_stream.MAX_TEXTURES,"Story props bypassed the scenery cache")
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: seven NPCs and every surface quest prop connect to real arrival routes, Finn stays off painted water and the seal kit is reachable in Moss Mine, engine recovery is reachable in Crystal Depths and scenery cache remains bounded")
	quit(1 if failures else 0)
