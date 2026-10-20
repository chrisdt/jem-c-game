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
	var result: Array[Dictionary] = game.story.entries()
	result.append({"id":"trails","title":"Explore Earth's trails","detail":"Optional: follow wooden signs to all five Earth districts.","progress":"%d / 5 districts" % game.earth_visited.size(),"done":game.earth_visited.size() == 5,"optional":true})
	result.append({"id":"mines","title":"Scout the three mines","detail":"Optional: visit Moss Mine, Copper Hollow and Crystal Depths.","progress":"%d / 3 mines" % mines.size(),"done":mines.size() == 3,"optional":true})
	result.append({"id":"buddy","title":"Find your trail buddy","detail":"Optional: find the little dog beyond Landing Meadow. Walk close to befriend him; he will follow and scare mine creatures.","progress":"Buddy found" if game.companion.recruited else "Search Earth's outer districts","done":game.companion.recruited,"optional":true})
	result.append({"id":"food","title":"Find a healing snack","detail":"Optional: when hurt, walk near berries for one heart or apples for two. Fruit stays available at full health.","progress":"Snack found" if fruit_used else "Heal using Earth's fruit","done":fruit_used,"optional":true})
	return result

func next_hint() -> String:
	for entry in entries():
		if not entry.done and not entry.get("optional",false): return entry.title
	return "Earth missions complete!"

func completed() -> int:
	var count := 0
	for entry in entries():
		if entry.done and not entry.get("optional",false): count += 1
	return count
