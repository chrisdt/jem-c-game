extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var environment = game.green_surface
	var pond = environment.get_node("PondLife")
	var duck = environment.get_node("Duck")
	var goats: Array = []
	for child in environment.get_children():
		if str(child.name).begins_with("MountainGoat"):
			goats.append(child)
	check(goats.size() == 4,"First level does not have four mountain goats")
	for i in goats.size():
		goats[i].set_process(false)
		goats[i].rng.seed = 900 + i
	pond.set_process(false)
	duck.set_process(false)
	pond.rng.seed = 12345
	pond.phase = 0
	pond.next_jump_in = 6
	duck.rng.seed = 54321
	duck.choose_target()
	var jump_starts: Array[float] = []
	var last_count: int = pond.jump_count
	var saw_airborne := false
	var saw_swimming := false
	for i in 2400:
		pond.advance(0.05)
		duck.advance(0.05)
		for goat in goats:
			goat.advance(0.05)
			check(goat.position.distance_to(goat.home) <= goat.wander_radius + 0.01,"Goat left its grazing area")
			check(((goat.position - Vector2(1270,960)) / Vector2(173,117)).length() > 1,"Goat walked into the pond")
			for rock in game.rocks:
				if not rock.cave and rock.hp > 0:
					check(goat.position.distance_to(rock.pos) >= 80,"Goat walked through a mining deposit")
		check(pond.water_contains(pond.fish_position),"Fish left the water during swimming or landing")
		check(duck.WANDER_AREA.has_point(duck.position),"Duck left its grassy wandering area")
		check(((duck.position - Vector2(1270,960)) / Vector2(173,117)).length() > 1,"Duck walked into the pond")
		check(pond.ripples.size() <= 16 and pond.droplets.size() <= 12,"Pond effects accumulated without cleanup")
		if pond.jump_count != last_count:
			jump_starts.append(i * 0.05)
			last_count = pond.jump_count
		if pond.jump_time > 0.3 and pond.jump_time < 0.8:
			saw_airborne = true
			check(pond.jumper.visible and not pond.swimmer.visible,"Jump showed both fish sprites")
			check(pond.jumper.position.y < pond.fish_position.y - 20,"Fish did not rise out of the water")
		if pond.jump_time < 0:
			saw_swimming = true
			check(pond.swimmer.visible and not pond.jumper.visible,"Fish did not return to swimming after landing")
	check(saw_airborne and saw_swimming and jump_starts.size() >= 5,"Fish did not alternate between swimming and occasional jumps")
	var shortest := INF
	var longest := 0.0
	for i in range(1, jump_starts.size()):
		var interval := jump_starts[i] - jump_starts[i-1]
		shortest = minf(shortest, interval)
		longest = maxf(longest, interval)
		check(interval >= 9 and interval <= 19.5,"Fish jumped too frequently or stopped jumping")
	check(longest - shortest > 2,"Fish jump timing is repetitive rather than random")
	check(duck.peck_count >= 4 and duck.walk_distance > 200,"Duck did not wander and stop to peck")
	for goat in goats:
		check(goat.graze_count >= 4 and goat.walk_distance > 150,"A goat did not alternate between walking and grazing")
	# Leaving the surface pauses ambient actors instead of accumulating a burst
	# of unseen jumps and pecks to play when the player returns.
	environment.visible = false
	var phase_before: float = pond.phase
	var position_before: Vector2 = duck.position
	var goat_positions: Array = goats.map(func(goat): return goat.position)
	pond._process(5)
	duck._process(5)
	for i in goats.size():
		goats[i]._process(5)
		check(goats[i].position == goat_positions[i],"Hidden goat kept moving")
	check(pond.phase == phase_before and duck.position == position_before,"Hidden surface wildlife kept advancing")
	if failures == 0:
		print("PASS: fish swims/jumps/lands with bounded effects; duck wanders/pecks; four goats wander and graze away from water and deposits; hidden wildlife pauses")
	quit(1 if failures else 0)
