extends RefCounted

# Small session records only. Opening the journal never loads other areas.
const CREATURE = preload("res://environment/ambient_creature.gd")
var game: Node
var mines: Dictionary = {}
var cleared_kinds: Dictionary = {}
var fruit_used := false

func observe_area() -> void:
	if game.world == 0 and game.underground and not game.earth_transition and game.flight == 0:
		mines[game.earth_region] = true

func cleared(kind: int) -> void:
	if game.world == 0 and kind in [CREATURE.Kind.RAT,CREATURE.Kind.BAT]: cleared_kinds[kind] = true

func entries() -> Array[Dictionary]:
	return [
		{"id":"drill","title":"Build the hand drill","detail":"Collect 5 copper along Earth's trails. Build at the camp workbench to mine blue crystal.","progress":"Built" if game.upgraded else "%d / 5 copper" % mini(game.ore,5),"done":game.upgraded},
		{"id":"sword","title":"Craft the copper sword","detail":"Gather 3 copper and 2 fallen wood. Craft at camp; select 2 or tap the sword, then jab.","progress":"Crafted" if game.trial.sword_owned else "%d/3 copper · %d/2 wood" % [mini(game.ore,3),mini(game.trial.wood,2)],"done":game.trial.sword_owned},
		{"id":"crystal","title":"Discover blue crystal","detail":"Use the hand drill in an Earth mine. Move, switch tools or take a hit to pause. Return to the same deposit to resume.","progress":"%d / 1 blue crystal" % mini(game.blue_crystals,1),"done":game.blue_crystals > 0},
		{"id":"trails","title":"Explore Earth's trails","detail":"Follow wooden trail signs to Landing Meadow, Pinewood Trail, Willow Marsh, Sunstone Ridge and Old Quarry.","progress":"%d / 5 districts" % game.earth_visited.size(),"done":game.earth_visited.size() == 5},
		{"id":"mines","title":"Scout the three mines","detail":"Walk into Moss Mine, Copper Hollow and Crystal Depths. Walk back to the entrance to leave.","progress":"%d / 3 mines" % mines.size(),"done":mines.size() == 3},
		{"id":"snake","title":"Stand up to a snake","detail":"Watch for the warning, step away from its bite and jab. The pick also works, but does less damage. Defeat one snake.","progress":"%d / 1 snake" % mini(game.trial.defeated,1),"done":game.trial.defeated > 0},
		{"id":"caves","title":"Clear a bat and a rat","detail":"Use your sword in the mines, or bring Buddy to scare them away. Each creature disappears in a puff of smoke.","progress":"%d / 2 creature types" % cleared_kinds.size(),"done":cleared_kinds.size() == 2},
		{"id":"buddy","title":"Find your trail buddy","detail":"Look for the little dog in one of Earth's outer districts. Walk close to befriend him; he will follow you into the mines.","progress":"Buddy found" if game.companion.recruited else "Search beyond Landing Meadow","done":game.companion.recruited},
		{"id":"food","title":"Find a healing snack","detail":"When hurt, walk close to a berry bush for one heart or an apple tree for two. Food stays on the plant when your hearts are full.","progress":"Snack found" if fruit_used else "Optional · heal using Earth fruit","done":fruit_used,"optional":true},
	]

func next_hint() -> String:
	for entry in entries().slice(2):
		if not entry.done and not entry.get("optional",false): return entry.title
	return "Earth missions complete!"

func completed() -> int:
	var count := 0
	for entry in entries():
		if entry.done and not entry.get("optional",false): count += 1
	return count
