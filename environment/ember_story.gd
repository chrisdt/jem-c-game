extends Node2D
const ART = preload("res://environment/ember_art.gd")
const NPC = preload("res://environment/ember_npc.gd")
const SCORPION = preload("res://environment/ember_scorpion.gd")
const ORDER := ["sol","luma","brasa","orin"]
const TITLES := ["A Cool Welcome","A Cure from the Oasis","Fire up the Sunforge","The Buried Observatory"]
const PEOPLE := {
	"sol":{"region":0,"foot":Vector2(1230,1130)},
	"luma":{"region":2,"foot":Vector2(1060,900)},
	"brasa":{"region":1,"foot":Vector2(1050,810)},
	"orin":{"region":3,"foot":Vector2(1000,720)},
}
const PROPS := {
	"cooler_dune":{"region":1,"cave":false,"foot":Vector2(650,750),"cell":2,"width":32.0},
	"cooler_oasis":{"region":2,"cave":false,"foot":Vector2(850,800),"cell":2,"width":32.0},
	"cooler_arch":{"region":3,"cave":false,"foot":Vector2(780,690),"cell":2,"width":32.0},
	"station_camp":{"region":0,"cave":false,"foot":Vector2(1380,1140),"cell":2,"width":58.0},
	"plant_oasis":{"region":2,"cave":false,"foot":Vector2(1300,690),"cell":3,"width":33.0},
	"plant_arch":{"region":3,"cave":false,"foot":Vector2(1350,730),"cell":3,"width":33.0},
	"flask":{"region":0,"cave":true,"foot":Vector2(1100,650),"cell":4,"width":24.0},
	"core":{"region":1,"cave":true,"foot":Vector2(1120,650),"cell":5,"width":34.0},
	"observatory":{"region":4,"cave":false,"foot":Vector2(1500,760),"cell":6,"width":94.0},
}
const SCORPION_HOMES := {1:Vector2(1200,1050),2:Vector2(1330,900),4:Vector2(1410,750)}
var game: Node
var npcs: Array = []
var accepted: Dictionary = {}
var complete: Dictionary = {}
var offered: Dictionary = {}
var collected: Dictionary = {}
var positions: Dictionary = {}
var props: Dictionary = {}
var fades: Dictionary = {}
var scorpions: Array = []
var records: Dictionary = {}
var active_area := -1
var sunfang := false
var magma_drill := false
var observatory_open := false
var antidote_owned := false
var antidote_doses := 0
var station_clock := 0.0
var job := ""
var work := 0.0
func _ready() -> void:
	name = "SunforgeExpedition"
	y_sort_enabled = true
	for role in ORDER:
		var person := NPC.new()
		person.game = game
		person.role = role
		game.add_child(person)
		npcs.append(person)
func floor_at(point: Vector2, region: int, cave: bool) -> bool:
	if region == 0: return game.DESERT_LAYOUT.can_walk(point,cave)
	return game.world_regions[2].can_walk(region,cave,point)
func fit_floor(preferred: Vector2, region: int, cave: bool) -> Vector2:
	for ring in 24:
		for ray in 24:
			var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*10
			if not floor_at(point,region,cave): continue
			var clear := true
			if game.world == 2 and game.current_region() == region and game.underground == cave:
				for rock in game.rocks:
					if rock.cave == cave and point.distance_to(rock.pos) < 105: clear = false
			for person in npcs:
				if person.home_region == region and not cave and point.distance_to(person.position) < 95: clear = false
			if clear: return point
	return Vector2.INF
func done(role: String) -> bool: return complete.get(role,false)
func available(role: String) -> bool:
	return role in ORDER
func fragments() -> int:
	return int(collected.has("cooler_dune"))+int(collected.has("cooler_oasis"))+int(collected.has("cooler_arch"))
func action(role: String) -> String:
	if done(role) or not available(role): return "Done"
	match role:
		"sol":
			if fragments() == 3: return "Repair cooling station"
		"luma":
			if collected.has("plant_oasis") and collected.has("plant_arch") and collected.has("flask"): return "Make antidote canteen"
		"brasa":
			if collected.has("core"):
				if not sunfang and game.trial.sword_owned and game.gold_ore >= 3 and game.rubies >= 1: return "Forge Sunfang Sword"
				if not magma_drill and game.upgraded and game.gold_ore >= 4 and game.rubies >= 1: return "Build Magma Drill"
		"orin":
			if observatory_open: return "Return the star map"
	return "Accept quest" if not accepted.get(role,false) else "Done"
func pages(role: String) -> Array[String]:
	if done(role): return [closing(role)]
	if not available(role): return []
	match role:
		"sol": return ["I'm Sol. Welcome to Ember Dunes, home of the Sunstone Folk! Our camp cooling station needs three parts.","Find them in Dune Sea, Sunken Oasis and Redrock Arches. Bring them here and we'll make a safe place to rest.","Watch for alien scorpions! A raised tail warns of a venom sting. Dodge while it aims. Camp shade clears venom; the repaired cooler also restores hearts."]
		"luma": return ["I'm Luma. Oasis glowleaf can stop scorpion venom!","Find two glowleaf plants: one in Sunken Oasis, one in Redrock Arches. Bring the empty flask from Lava Mine below Mesa Camp.","I'll make an antidote canteen with three doses. Press 3 or tap its icon while poisoned. Refill it at Sol's repaired cooling station."]
		"brasa":
			var recipes: Array[String] = ["I'm Brasa, the Sunforge smith. Recover the power core from Sunfire Cavern beneath Dune Sea."]
			if not sunfang: recipes.append("Sunfang Sword: bring an owned Earth sword, 3 gold and 1 fire ruby.")
			if not magma_drill: recipes.append("Magma Drill: bring a hand drill, 4 gold and 1 fire ruby.")
			recipes.append("Both upgrades work with both outfits on every world. Return for each unfinished tool; completed recipes disappear. Frost equipment helps but isn't required.")
			return recipes
		"orin": return ["I'm Orin. An ancient observatory lies beneath cooled lava in Obsidian Rise.","Use Brasa's Magma Drill, defeat the guardian scorpion and uncover the star map. The guardian's lifted tail gives you time to dodge!","Bring the map back here to Redrock Arches and we'll chart the old explorers' journey."]
	return []
func closing(role: String) -> String:
	return {"sol":"The cooling station works! Rest beside it to recover. Luma in Sunken Oasis knows a cure for venom.","luma":"Your antidote canteen is ready! Use 3 or tap its icon when poisoned. Brasa in Dune Sea can forge new tools.","brasa":"Sunfang Sword and Magma Drill are ready! Orin in Redrock Arches knows an ancient secret.","orin":"The star map is recovered! The old observatory's story can shine again. Thank you, Sunny Scout!"}[role]
func begin(role: String) -> void: offered[role] = action(role)
func finish(role: String, confirmed: bool) -> void:
	var offer: String = offered.get(role,"")
	offered.erase(role)
	if not confirmed or done(role) or not available(role) or offer != action(role): return
	accepted[role] = true
	if offer == "Accept quest":
		game.message = "Quest started: "+TITLES[ORDER.find(role)]
		return
	if offer == "Done": return
	match role:
		"luma":
			antidote_owned = true
			antidote_doses = 3
		"brasa":
			if offer == "Forge Sunfang Sword":
				game.gold_ore -= 3
				game.rubies -= 1
				sunfang = true
			else:
				game.gold_ore -= 4
				game.rubies -= 1
				magma_drill = true
	complete[role] = role != "brasa" or (sunfang and magma_drill)
	game.restore_walk_visual()
	game.message = closing(role) if done(role) else "Upgrade ready! Speak to Brasa again when you have the materials for the other tool."
	game.refresh_ui()
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var details := ["Sol at Mesa Camp: recover cooling parts from Dune Sea, Sunken Oasis and Redrock Arches. The repaired station heals and refills antidote.","Luma in Sunken Oasis: find glowleaf in Sunken Oasis and Redrock Arches, plus the flask in Mesa Camp's Lava Mine. Reward: three-dose antidote canteen.","Brasa in Dune Sea: find the core in Sunfire Cavern. Sword upgrade: owned sword + 3 gold + 1 fire ruby. Drill upgrade: hand drill + 4 gold + 1 fire ruby. Speak to Brasa once for each tool.","Orin in Redrock Arches: use the Magma Drill to uncover Obsidian Rise's observatory. Defeat its guardian scorpion and return the star map."]
	if sunfang and not magma_drill: details[2] = "Brasa in Dune Sea: Sunfang built. Remaining upgrade: hand drill + 4 gold + 1 fire ruby for the Magma Drill."
	elif magma_drill and not sunfang: details[2] = "Brasa in Dune Sea: Magma Drill built. Remaining upgrade: owned sword + 3 gold + 1 fire ruby for Sunfang."
	for i in ORDER.size():
		var role: String = ORDER[i]
		var progress: String = ["%d / 3 cooling parts" % fragments(),"%d / 2 glowleaf · %s" % [int(collected.has("plant_oasis"))+int(collected.has("plant_arch")),"flask found" if collected.has("flask") else "find flask"],"%s · %s · %d gold / %d fire rubies" % ["Sunfang built" if sunfang else "Sunfang pending","Magma Drill built" if magma_drill else "Magma Drill pending",game.gold_ore,game.rubies],"Return the star map" if observatory_open else "Magma Drill · guardian · cooled lava"][i]
		if not done(role) and action(role) not in ["Done","Accept quest"]: progress = "Ready · return to "+role.capitalize()
		result.append({"id":"ember_"+role,"title":role.capitalize()+" · "+TITLES[i],"detail":closing(role) if done(role) else details[i],"progress":progress,"done":done(role)})
	return result
func prop_exists(id: String) -> bool:
	if id == "station_camp": return done("sol")
	return not observatory_open if id == "observatory" else not collected.has(id)
func use_antidote() -> bool:
	if game.trial.blocked() or game.trial.jab_time >= 0 or not antidote_owned: return false
	if game.trial.poison_remaining <= 0:
		game.message = "No venom to cure. Your antidote is saved for a sting."
		return false
	if antidote_doses <= 0:
		game.message = "Antidote empty. Refill at Mesa Camp's cooling station, or rest in camp shade to clear venom."
		return false
	antidote_doses -= 1
	game.trial.clear_poison()
	game.message = "Venom cured! %d antidote doses left." % antidote_doses
	game.refresh_ui()
	return true
func refill_at_station(delta: float) -> void:
	if game.current_region() != 0 or game.underground or not done("sol") or game.player.distance_to(game.camp_position()) >= 175:
		station_clock = 0
		return
	if antidote_owned: antidote_doses = 3
	game.trial.clear_poison()
	station_clock += delta
	if station_clock >= 1.5:
		game.trial.heal(1)
		station_clock = 0
func sync_area() -> void:
	visible = game.world == 2 and game.flight == 0 and not game.earth_transition
	for person in npcs: person.sync_area()
	if game.flight != 0 or game.earth_transition:
		cancel_work()
		return
	var area: int = game.area_id()
	if area != active_area:
		cancel_work()
		for scorpion in scorpions: records[scorpion.spawn_id] = scorpion.record()
		for scorpion in scorpions: scorpion.free()
		scorpions.clear()
		for prop in props.values(): prop.free()
		props.clear()
		active_area = area
		if game.world == 2 and not game.underground and SCORPION_HOMES.has(game.current_region()):
			var id := str(game.current_region())+"/0"
			var scorpion := SCORPION.new()
			scorpion.expedition = self
			scorpion.guardian = game.current_region() == 4
			scorpion.health = 30 if scorpion.guardian else 22
			scorpion.spawn_id = id
			scorpion.home = fit_floor(SCORPION_HOMES[game.current_region()],game.current_region(),false)
			if scorpion.home.is_finite():
				scorpion.position = scorpion.home
				add_child(scorpion)
				if records.has(id): scorpion.restore(records[id])
				scorpions.append(scorpion)
			else: scorpion.free()
	if not visible: return
	for id in PROPS:
		var spec: Dictionary = PROPS[id]
		if spec.region != game.current_region() or spec.cave != game.underground: continue
		if props.has(id):
			props[id].visible = prop_exists(id)
			continue
		if not prop_exists(id): continue
		if not positions.has(id): positions[id] = fit_floor(spec.foot,spec.region,spec.cave)
		var point: Vector2 = positions[id]
		if not point.is_finite(): continue
		var prop := Sprite2D.new()
		prop.texture = ART.item(spec.cell)
		prop.position = point
		prop.centered = false
		prop.offset = Vector2(-prop.texture.get_width()*0.5,-prop.texture.get_height()*0.85)
		prop.scale = Vector2(spec.width/prop.texture.get_width(),spec.width/prop.texture.get_width()*0.72)
		prop.modulate.a = fades.get(id,0.0)
		add_child(prop)
		props[id] = prop

func nearest_prop() -> String:
	if not visible: return ""
	var best := ""
	var distance := 100.0
	for id in props:
		if id.begins_with("station_"): continue
		if not prop_exists(id) or not game.fog.is_revealed(game.area_id(),props[id].position): continue
		var gap: float = game.player.distance_to(props[id].position)
		if gap < distance:
			best = id
			distance = gap
	return best
func prompt(id: String) -> String:
	if id == "observatory": return "Drill cooled lava" if magma_drill else "Magma Drill needed for cooled lava"
	return "Pick up "+{"cooler_dune":"cooling part","cooler_oasis":"cooling part","cooler_arch":"cooling part","plant_oasis":"glowleaf","plant_arch":"glowleaf","flask":"empty flask","core":"Sunforge core"}.get(id,id)
func guardian_cleared() -> bool:
	for scorpion in scorpions:
		if scorpion.spawn_id == "4/0": return scorpion.health <= 0
	return records.get("4/0",{}).get("health",30) <= 0
func use_prop(id: String) -> bool:
	if id.is_empty() or id != nearest_prop() or game.trial.blocked(): return false
	if id == "observatory":
		if not magma_drill:
			game.message = "Brasa's Magma Drill can break this cooled lava."
		elif not guardian_cleared():
			game.message = "A scorpion guards the observatory. Dodge its raised-tail warning, then jab."
		elif game.trial.selected_tool != 0:
			game.message = "Select your Magma Drill to uncover the observatory."
		else:
			work = 0
			job = id
			game.walking = false
			game.message = "Breaking the cooled lava crust..."
		return true
	collected[id] = true
	props[id].hide()
	game.message = "Collected "+prompt(id).trim_prefix("Pick up ")+"! Open Quests to see who needs it."
	return true
func cancel_work() -> void:
	if job.is_empty(): return
	job = ""
	work = 0
	game.restore_walk_visual()
func working() -> bool: return not job.is_empty()
func _process(delta: float) -> void:
	sync_area()
	if not visible or game.trial.blocked(): return
	refill_at_station(delta)
	for id in props:
		if not prop_exists(id): continue
		if game.fog.is_revealed(game.area_id(),props[id].position): fades[id] = minf(0.75,fades.get(id,0.0)+delta)
		props[id].modulate.a = smoothstep(0,0.75,fades.get(id,0.0))
	for scorpion in scorpions: scorpion.advance(delta)
	if not job.is_empty():
		if nearest_prop() != job or game.trial.selected_tool != 0:
			cancel_work()
			return
		work = minf(2.0,work+delta)
		game.set_mining_pose(int(work/0.09)%3)
		if work >= 2:
			observatory_open = true
			props.observatory.texture = ART.item(7)
			props.observatory.hide()
			cancel_work()
			game.message = "Ancient star map recovered! Return to Orin in Redrock Arches."
	queue_redraw()
func _draw() -> void:
	for id in props:
		if not props[id].visible: continue
		var alpha: float = props[id].modulate.a
		draw_set_transform(props[id].position,0,Vector2(1,0.3))
		draw_circle(Vector2.ZERO,17,Color(0.02,0.07,0.12,alpha*0.15))
	draw_set_transform(Vector2.ZERO)
	if not job.is_empty():
		draw_rect(Rect2(game.player+Vector2(-28,-100),Vector2(56,5)),Color(0.02,0.06,0.10,0.8))
		draw_rect(Rect2(game.player+Vector2(-28,-100),Vector2(56*work/2.0,5)),Color("ffb85b"))
