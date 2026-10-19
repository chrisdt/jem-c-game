extends SceneTree

const CREATURE = preload("res://environment/ambient_creature.gd")
const VERTICAL = preload("res://environment/wildlife_vertical.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var duck = game.green_surface.get_node("Duck")
	var goat = game.green_surface.get_node("MountainGoat01")
	var actors: Array = [duck,goat]
	for kind in 4:
		var creature = CREATURE.new()
		creature.kind = kind
		creature.terrain = func(_point: Vector2) -> bool: return true
		root.add_child(creature)
		actors.append(creature)
	for index in actors.size():
		var actor = actors[index]
		actor.set_process(false)
		actor.rng.seed = 8001 + index
		actor.advance(0)
		var origin: Vector2 = actor.position
		if index == 0:
			actor.wander_area = Rect2(origin - Vector2.ONE * 200,Vector2.ONE * 400)
		if index == 1:
			# Find a real grass patch clear in every tested direction.
			var found := false
			for ring in range(9):
				for ray in 24:
					var point: Vector2 = actor.home + Vector2.from_angle(ray * TAU / 24) * ring * 10
					var clear: bool = actor.can_stand(point)
					for axis in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
						clear = clear and actor.can_stand(point + axis * 8)
					if clear:
						origin = point
						found = true
						break
				if found: break
			check(found,"No grass fixture for goat turning")
		var views: Dictionary = {}
		for dt in [1.0/30,1.0/120]:
			for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(1,-2),Vector2(-1,2),Vector2(-1,-1)]:
				actor.position = origin
				actor.target = origin + direction.normalized() * 20
				actor.state = "walk"
				actor.state_time = 0
				actor.advance(dt)
				check(actor.position.distance_to(origin) > 0,"Creature did not move in direction test")
				game.face_direction(direction)
				var expected := Vector2.UP if game.facing == &"up" else (Vector2.DOWN if game.facing == &"down" else (Vector2.LEFT if game.facing_left else Vector2.RIGHT))
				check(actor.facing == expected,"Wildlife facing differs from Scout: species %d, direction %s" % [index,direction])
				check(actor.sprite.flip_h == (expected == Vector2.LEFT),"Vertical/side artwork mirrored incorrectly")
				if expected.y != 0:
					var texture: AtlasTexture = actor.sprite.texture
					check(texture != null and texture.atlas == VERTICAL.DATA[index].art,"Front/back artwork not displayed")
					views[expected] = texture.region
					var row: int = (2 if expected.y < 0 else 0) if index < 2 else int(expected.y < 0)
					var y: float = VERTICAL.DATA[index].rows[row].x
					check(texture.region.position.y == y,"Wrong front/back atlas row")
				# Idle and feeding/sniffing/hovering must retain the movement view.
				actor.state = "peck" if index == 0 else ("graze" if index == 1 else "rest")
				actor.state_time = 0
				actor.rest_seconds = 100
				for frame in 12:
					actor.advance(0.05)
					check(actor.facing == expected,"Paused/feeding creature forgot its facing")
					if expected.y != 0:
						var texture: AtlasTexture = actor.sprite.texture
						var row: int = (3 if expected.y < 0 else 1) if index < 2 else int(expected.y < 0)
						check(texture.region.position.y == VERTICAL.DATA[index].rows[row].x,"Feeding/idle reverted to a side view")
		check(views[Vector2.UP] != views[Vector2.DOWN],"Front and back reuse the same artwork")
		actor.position = origin
		actor.facing = Vector2.DOWN
		actor.target = origin
		actor.state = "walk"
		actor.advance(0.02)
		check(actor.position == origin and actor.facing == Vector2.DOWN,"Zero movement forgot the previous facing")
		# Blocked attempts may select another route, but must not turn in place.
		actor.position = origin
		actor.facing = Vector2.UP
		actor.target = origin + Vector2.RIGHT * 20
		actor.state = "walk"
		if index == 0: actor.shore_floor = func(_point: Vector2) -> bool: return false
		elif index == 1: actor.wander_radius = 0
		else: actor.terrain = func(_point: Vector2) -> bool: return false
		actor.advance(0.02)
		check(actor.position == origin and actor.facing == Vector2.UP,"Blocked movement changed position or facing")
		print("Directional wildlife check: species %d" % index)
	game.free()
	for actor in actors.slice(2): actor.free()
	if failures == 0:
		print("PASS: six species follow Scout's four directions at 30/120fps, show distinct front/back art, retain facing through feeding/idle/flaps, and do not turn on blocked movement")
	quit(1 if failures else 0)
