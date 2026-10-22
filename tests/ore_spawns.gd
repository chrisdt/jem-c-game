extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func reachable(layout, entry: Vector2, frost: bool, cave: bool) -> Dictionary:
	var first := Vector2i((entry / 16.0).round())
	var cells := {first:true}
	var queue: Array[Vector2i] = [first]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + direction
			if cells.has(next): continue
			var point := Vector2(next) * 16
			if point.x < 0 or point.y < 0 or point.x > 2000 or point.y > 1400: continue
			if layout.can_walk(point,cave) if frost else layout.can_walk(point):
				cells[next] = true
				queue.append(next)
	return cells

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var connected := {
		1:reachable(game.MINE_LAYOUT,game.MINE_SPAWN,false,true),
		2:reachable(game.FROST_LAYOUT,Vector2(390,1120),true,false),
		3:reachable(game.FROST_LAYOUT,game.ICE_SPAWN,true,true),
		4:reachable(game.DESERT_LAYOUT,game.DESERT_LAYOUT.ARRIVAL,true,false),
		5:reachable(game.DESERT_LAYOUT,game.DESERT_LAYOUT.MINE_SPAWN,true,true)
	}
	var seen := {}
	for painted_rock in [Vector2(430,575),Vector2(555,890),Vector2(1250,295)]:
		check(not game.ORE_SPAWNS.footprint_fits(1,false,game.FROST_LAYOUT.from_art(painted_rock)),"Frost ore can overlap a painted rock outcrop")
	check(not game.ORE_SPAWNS.clear_of_landmarks(1,false,game.FROST_LAYOUT.from_art(Vector2(290,690)),game.tree_cover()),"Frost ore can overlap the camp dome roof")
	for world in 3:
		game.world = world
		game.player = [game.EARTH_START,Vector2(390,1120),game.DESERT_LAYOUT.ARRIVAL][world]
		game.camera.position = game.player
		game.camera.reset_smoothing()
		game.camera.force_update_scroll()
		await process_frame
		# Measure the actual camera, including its shift against the map edges.
		var opening_view: Rect2 = game.get_canvas_transform().affine_inverse() * game.get_viewport_rect()
		check(opening_view.has_point(game.player),"Opening camera lost the landing position")
		for trial in 50:
			game.ore_rng.seed = trial * 1009 + 17
			game.reset_rocks()
			check(game.rocks.size() == 4,"Landing district should contain two surface and two mine deposits")
			var signature := str(game.rocks.map(func(rock): return rock.pos))
			check(not seen.has(signature),"Different seeds produced the same layout")
			seen[signature] = true
			var surface_count := 0
			var hard_count := 0
			for i in game.rocks.size():
				var rock: Dictionary = game.rocks[i]
				check(not rock.discovered,"Random generation pre-discovered ore")
				check(rock.seconds == ((5.0 if rock.hard else 3.0) if world > 0 else (5.0 if rock.hard else 2.0)),"Random generation changed mining times")
				surface_count += 0 if rock.cave else 1
				hard_count += 1 if rock.hard else 0
				var area: int = world * 2 + int(rock.cave)
				if not rock.cave:
					var artwork := Rect2(rock.pos + Vector2(-50,-52),Vector2(100,86))
					check(not opening_view.grow(32).intersects(artwork),"Deposit artwork overlaps the opening view: world=%d seed=%d at %s" % [world,trial,rock.pos])
				if area != 0:
					var cell := Vector2i((rock.pos / 16).round())
					check(connected[area].has(cell),"Ore spawned outside connected walkable floor: %s" % rock.pos)
				else:
					check(((rock.pos - Vector2(1270,960)) / Vector2(215,150)).length() > 1,"Copper spawned in the pond or its rocky rim")
					for cover in game.tree_cover():
						check(not cover.has_point(rock.pos),"Copper spawned under a tree canopy")
				for j in i:
					if game.rocks[j].cave == rock.cave:
						check(game.rocks[j].pos.distance_to(rock.pos) >= 149.9,"Ore deposits overlap")
			check(surface_count == 2 and hard_count == 1,"Sparse layout should have two common surface deposits and one common/one rare mine deposit")
	# The landing district cannot fund the drill by itself, while every planet
	# retains enough reachable starter-tool supplies to finish its objective.
	for world in 3:
		game.world = world
		game.reset_rocks()
		var total: Array[Dictionary] = game.rocks.duplicate()
		var home_common := total.filter(func(rock): return not rock.hard).size()
		check(home_common == 3 and home_common < 5,"The first district alone can fund the Earth drill")
		var surface_common := total.filter(func(rock): return not rock.cave).size()
		for region in range(1,5):
			var deposits: Array[Dictionary] = game.regions().generate(region,game.ore_rng)
			total.append_array(deposits)
			surface_common += deposits.filter(func(rock): return not rock.cave).size()
		check(total.size() == 16,"A planet no longer has the intended sparse supply budget")
		check(surface_common == 10 and surface_common >= 5,"Surface exploration cannot fund the starter drill")
		check(total.filter(func(rock): return rock.hard).size() == 3,"A planet lost its three rare mine deposits")
	if failures == 0:
		print("PASS: 150 distinct seeded layouts across all three planets, full artwork outside the opening camera view, connected reachable ore, sparse supplies, mining times and separated deposits clear of pond/tree cover")
	quit(1 if failures else 0)
