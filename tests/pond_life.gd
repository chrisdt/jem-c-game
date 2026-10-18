extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var environment = load("res://environment/green_planet.tscn").instantiate()
	root.add_child(environment)
	await process_frame
	var pond = environment.get_node("PondLife")
	var duck = environment.get_node("Duck")
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
	# Leaving the surface pauses ambient actors instead of accumulating a burst
	# of unseen jumps and pecks to play when the player returns.
	environment.visible = false
	var phase_before: float = pond.phase
	var position_before: Vector2 = duck.position
	pond._process(5)
	duck._process(5)
	check(pond.phase == phase_before and duck.position == position_before,"Hidden surface wildlife kept advancing")
	if failures == 0:
		print("PASS: fish stays in water, jumps at varied intervals, lands and resumes swimming; bounded effects; duck wanders/pecks on land; hidden actors pause")
	quit(1 if failures else 0)
