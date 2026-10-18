extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.ore == 0 and not game.upgraded)
	# Two hits per deposit; moving between deposits also allows cooldown to expire.
	for i in range(5):
		game.player = game.rocks[i].pos
		for hit in range(2):
			game.cooldown = 0
			game.interact()
	assert(game.ore == 5)
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	assert(game.upgraded and game.ore == 0)
	game.player = game.CAVE
	game.cooldown = 0
	game.interact()
	assert(game.underground)
	game.player = Vector2(1180, 450)
	for hit in range(2):
		game.cooldown = 0
		game.interact()
	assert(game.won)
	game.player = Vector2(350, 700)
	game.cooldown = 0
	game.interact()
	assert(not game.underground)
	print("PASS: mining, inventory, upgrade, mine entry, crystal mission and exit")
	quit()
