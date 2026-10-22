extends Node2D

const ART = preload("res://environment/frost_art.gd")
const NPC = preload("res://environment/frost_npc.gd")
const YETI = preload("res://environment/frost_yeti.gd")
const ORDER := ["pip","nix","tavi","eira"]
const TITLES := ["Light the Aurora Trail","Forge the Frostfang","A Crystal Cutting Edge","The Lost Expedition"]
const PEOPLE := {
	"pip":{"region":0,"foot":Vector2(705,1060)},
	"nix":{"region":1,"foot":Vector2(1040,750)},
	"tavi":{"region":2,"foot":Vector2(1160,850)},
	"eira":{"region":3,"foot":Vector2(1110,620)},
}
const PROPS := {
	"beacon_west":{"region":1,"cave":false,"foot":Vector2(650,740),"cell":2,"width":42.0},
	"beacon_east":{"region":2,"cave":false,"foot":Vector2(820,850),"cell":2,"width":42.0},
	"beacon_aurora":{"region":3,"cave":false,"foot":Vector2(650,660),"cell":2,"width":42.0},
	"trail_west":{"region":1,"cave":false,"foot":Vector2(650,740),"cell":6,"width":50.0},
	"trail_east":{"region":2,"cave":false,"foot":Vector2(820,850),"cell":6,"width":50.0},
	"trail_aurora":{"region":3,"cave":false,"foot":Vector2(650,660),"cell":6,"width":50.0},
	"heart_crystal":{"region":2,"cave":false,"foot":Vector2(1693,267),"cell":3,"width":60.0,"landmark":true},
	"coupling":{"region":4,"cave":true,"foot":Vector2(825,755),"cell":4,"width":38.0},
	"cache":{"region":4,"cave":false,"foot":Vector2(1550,750),"cell":7,"width":108.0},
}
const YETI_HOMES := {1:Vector2(1150,1010),2:Vector2(1240,680),4:Vector2(1430,730)}
var game: Node
var npcs: Array = []
var accepted: Dictionary = {}
var complete: Dictionary = {}
var offered: Dictionary = {}
var collected: Dictionary = {}
var positions: Dictionary = {}
var props: Dictionary = {}
var fades: Dictionary = {}
var yetis: Array = []
var records: Dictionary = {}
var active_area := -1
var frostfang := false
var crystal_drill := false
var cache_open := false
var job := ""
var work := 0.0
var glint_clock := 0.0

func _ready() -> void:
	name = "FrozenExpedition"
	y_sort_enabled = true
	for role in ORDER:
		var person := NPC.new()
		person.game = game
		person.role = role
		game.add_child(person)
		npcs.append(person)

func floor_at(point: Vector2, region: int, cave: bool) -> bool:
	if region == 0: return game.FROST_LAYOUT.can_walk(point,cave)
	return game.world_regions[1].can_walk(region,cave,point)

func fit_floor(preferred: Vector2, region: int, cave: bool) -> Vector2:
	for ring in 24:
		for ray in 24:
			var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*10
			if not floor_at(point,region,cave): continue
			var clear := true
			if game.world == 1 and game.current_region() == region and game.underground == cave:
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
	return int(collected.has("beacon_west"))+int(collected.has("beacon_east"))+int(collected.has("beacon_aurora"))
func cache_drill_ready() -> bool: return crystal_drill or game.ember_story.magma_drill
func action(role: String) -> String:
	if done(role) or not available(role): return "Done"
	match role:
		"pip":
			if fragments() == 3: return "Restore the beacons"
		"nix":
			if game.trial.sword_owned and collected.has("heart_crystal") and game.frost_ore >= 4 and game.amethysts >= 1: return "Forge Frostfang Sword"
		"tavi":
			if game.upgraded and collected.has("coupling") and game.frost_ore >= 5 and game.amethysts >= 2: return "Build Crystal Drill"
		"eira":
			if cache_open: return "Return the keepsake"
	return "Accept quest" if not accepted.get(role,false) else "Done"

func pages(role: String) -> Array[String]:
	if done(role): return [closing(role)]
	if not available(role): return []
	match role:
		"pip": return ["Welcome to Frost Canyon! I'm Pip, an aurora trail scout.","Find three brass-and-crystal beacon fragments in Frozen Basin, Prism Pass and Aurora Shelf. Look for golden glints on the snow, then bring them here.","Warm up beside the Canyon Camp shelter to recover hearts. The rocket is ready whenever you want to visit another world."]
		"nix":
			if action(role) == "Forge Frostfang Sword": return ["You have everything! I'll forge your Frostfang here for 4 frost ore and 1 amethyst, using your sword and heart-crystal. It works on every planet."]
			return ["I'm Nix, the crystal smith. Bring your Earth sword, 4 frost ore, 1 amethyst and the heart-crystal from the centre of Prism Pass's ruined stone circle.","Still needed: "+", ".join(missing_upgrade(role))+". Return to me in Frozen Basin to forge the sword. Earth's camp builds the starter sword and hand drill."]
		"tavi":
			if action(role) == "Build Crystal Drill": return ["Everything's ready! I'll build your Crystal Drill here for 5 frost ore and 2 amethysts, using your hand drill and power coupling. It mines faster on every world."]
			return ["I'm Tavi. Bring your hand drill, the power coupling from Deep Prism Mine, 5 frost ore and 2 amethysts.","Still needed: "+", ".join(missing_upgrade(role))+". Return to me in Prism Pass to build the Crystal Drill."]
		"eira": return ["An expedition lost a keepsake behind frozen rock in Glacier Crown.","Use a Crystal Drill or Magma Drill to open it. A yeti patrols nearby: watch its raised-paw warning, dodge, then jab!","Clear the guardian and recover the keepsake. Bring it back and we'll honour the old explorers together."]
	return []

func missing_upgrade(role: String) -> PackedStringArray:
	var missing := PackedStringArray()
	if role == "nix":
		if not game.trial.sword_owned: missing.append("Earth sword (craft at Earth's camp)")
		if not collected.has("heart_crystal"): missing.append("heart-crystal from Prism Pass's ruined stone circle")
		if game.frost_ore < 4: missing.append("%d more frost ore" % (4-game.frost_ore))
		if game.amethysts < 1: missing.append("1 amethyst (mine with a hand drill)")
	elif role == "tavi":
		if not game.upgraded: missing.append("hand drill (build at Earth's camp)")
		if not collected.has("coupling"): missing.append("power coupling from Deep Prism Mine")
		if game.frost_ore < 5: missing.append("%d more frost ore" % (5-game.frost_ore))
		if game.amethysts < 2: missing.append("%d more amethysts" % (2-game.amethysts))
	return missing

func closing(role: String) -> String:
	return {"pip":"The aurora trail shines again! The restored beacons stay on the trails to guide explorers. You can inspect each light.","nix":"Frostfang is ready! Its stronger, chilling strikes work on every planet.","tavi":"Your Crystal Drill is ready! It mines faster on every planet and opens Glacier Crown's frozen cache.","eira":"You found the keepsake! Our lost expedition is remembered. Thank you, Sunny Scout."}[role]
func begin(role: String) -> void: offered[role] = action(role)
func finish(role: String, confirmed: bool) -> void:
	var offer: String = offered.get(role,"")
	offered.erase(role)
	if not confirmed or done(role) or not available(role) or offer != action(role): return
	if offer == "Accept quest":
		accepted[role] = true
		game.message = "Quest started: "+TITLES[ORDER.find(role)]
		return
	if offer == "Done": return
	if role == "nix":
		game.frost_ore -= 4
		game.amethysts -= 1
		frostfang = true
	elif role == "tavi":
		game.frost_ore -= 5
		game.amethysts -= 2
		crystal_drill = true
	complete[role] = true
	accepted[role] = true
	game.restore_walk_visual()
	game.message = closing(role)
	game.refresh_ui()

func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var details := ["Pip at Canyon Camp: recover the three brass-and-crystal beacon fragments from Frozen Basin, Prism Pass and Aurora Shelf. Look for their golden glints on the snow.","Nix in Frozen Basin: bring a sword, 4 frost ore, 1 amethyst and the heart-crystal from the centre of Prism Pass's ruined stone circle.","Tavi in Prism Pass: bring a hand drill, 5 frost ore, 2 amethysts and the coupling from Deep Prism Mine.","Eira on Aurora Shelf: open Glacier Crown's frozen cache with a Crystal Drill or Magma Drill, defeat its guardian yeti and return the keepsake."]
	for i in ORDER.size():
		var role: String = ORDER[i]
		var progress: String = ["%d / 3 beacon fragments" % fragments(),"%d/4 frost ore · %d/1 amethyst" % [mini(game.frost_ore,4),mini(game.amethysts,1)],"%d/5 frost ore · %d/2 amethysts" % [mini(game.frost_ore,5),mini(game.amethysts,2)],"Return the keepsake" if cache_open else "Crystal Drill · guardian · frozen cache"][i]
		if role == "nix": progress += " · sword "+("ready" if game.trial.sword_owned else "needed")+" · heart-crystal "+("found" if collected.has("heart_crystal") else "needed")
		elif role == "tavi": progress += " · drill "+("ready" if game.upgraded else "needed")+" · coupling "+("found" if collected.has("coupling") else "needed")
		if not done(role) and action(role) not in ["Done","Accept quest"]: progress = "Ready · return to "+role.capitalize()
		result.append({"id":"frost_"+role,"title":role.capitalize()+" · "+TITLES[i],"detail":closing(role) if done(role) else details[i],"progress":progress,"done":done(role)})
	return result

func prop_exists(id: String) -> bool:
	if id.begins_with("trail_"): return done("pip")
	return not cache_open if id == "cache" else not collected.has(id)
func sync_area() -> void:
	visible = game.world == 1 and game.flight == 0 and not game.earth_transition
	for person in npcs: person.sync_area()
	if game.flight != 0 or game.earth_transition:
		cancel_work()
		return
	var area: int = game.area_id()
	if area != active_area:
		cancel_work()
		for yeti in yetis: records[yeti.spawn_id] = yeti.record()
		for yeti in yetis: yeti.free()
		yetis.clear()
		for prop in props.values(): prop.free()
		props.clear()
		active_area = area
		if game.world == 1 and not game.underground and YETI_HOMES.has(game.current_region()):
			var id := str(game.current_region())+"/0"
			var yeti := YETI.new()
			yeti.expedition = self
			yeti.spawn_id = id
			yeti.home = fit_floor(YETI_HOMES[game.current_region()],game.current_region(),false)
			if yeti.home.is_finite():
				yeti.position = yeti.home
				add_child(yeti)
				if records.has(id): yeti.restore(records[id])
				yetis.append(yeti)
			else: yeti.free()
	if not visible: return
	for id in PROPS:
		var spec: Dictionary = PROPS[id]
		if spec.region != game.current_region() or spec.cave != game.underground: continue
		if props.has(id):
			props[id].visible = prop_exists(id)
			continue
		if not prop_exists(id): continue
		# This crystal belongs on the pedestal, with a reachable approach in
		# front. Floor fitting would slide it off the centre of the landmark.
		if not positions.has(id): positions[id] = spec.foot if spec.get("landmark",false) else fit_floor(spec.foot,spec.region,spec.cave)
		var point: Vector2 = positions[id]
		if not point.is_finite(): continue
		var prop := Sprite2D.new()
		prop.texture = ART.item(spec.cell)
		prop.position = point
		prop.centered = false
		prop.offset = Vector2(-prop.texture.get_width()*0.5,-prop.texture.get_height()*0.85)
		prop.scale = Vector2(spec.width/prop.texture.get_width(),spec.width/prop.texture.get_width()*0.72)
		if id.begins_with("beacon_") or id == "heart_crystal":
			prop.scale.y = prop.scale.x if id.begins_with("beacon_") else prop.scale.x*0.85
			prop.offset.y = -prop.texture.get_height()
		if id == "heart_crystal":
			# A dark silhouette separates the brass/crystal outline from snow.
			# It inherits the collectible's fog fade and disappears with it.
			var outline := Sprite2D.new()
			outline.name = "SnowContrast"
			outline.texture = prop.texture
			outline.centered = false
			outline.offset = prop.offset
			outline.scale = Vector2.ONE*1.10
			outline.self_modulate = Color(0.025,0.09,0.15,0.9)
			outline.show_behind_parent = true
			prop.add_child(outline)
		prop.modulate.a = fades.get(id,0.0)
		add_child(prop)
		props[id] = prop

func nearest_prop() -> String:
	if not visible: return ""
	var best := ""
	var distance := 100.0
	for id in props:
		if not prop_exists(id) or not game.fog.is_revealed(game.area_id(),props[id].position): continue
		var gap: float = game.player.distance_to(props[id].position)
		if gap < distance:
			best = id
			distance = gap
	return best
func prompt(id: String) -> String:
	if id.begins_with("trail_"): return "Inspect restored beacon"
	if id == "cache": return "Drill frozen cache" if cache_drill_ready() else "Crystal Drill needed for frozen cache"
	return "Pick up "+{"beacon_west":"beacon fragment","beacon_east":"beacon fragment","beacon_aurora":"beacon fragment","heart_crystal":"heart-crystal","coupling":"power coupling"}.get(id,id)
func guardian_cleared() -> bool:
	for yeti in yetis:
		if yeti.spawn_id == "4/0": return yeti.health <= 0
	return records.get("4/0",{}).get("health",16) <= 0
func use_prop(id: String) -> bool:
	if id.is_empty() or id != nearest_prop() or game.trial.blocked(): return false
	if id.begins_with("trail_"):
		game.message = "Aurora beacon restored! You repaired this trail light for Pip."
		game.character_bubble.show_hint(game.message,props[id],Vector2(0,-42))
		return true
	if id == "cache":
		if not cache_drill_ready():
			game.message = "Tavi's Crystal Drill can open this frozen rock."
		elif not guardian_cleared():
			game.message = "A yeti guards the cache. Watch its warning and dodge before attacking."
		elif game.trial.selected_tool != 0:
			game.message = "Select your Crystal Drill to open the frozen cache."
		else:
			job = id
			game.walking = false
			game.message = "Drilling through ancient ice..."
		return true
	collected[id] = true
	props[id].hide()
	game.message = "Collected "+prompt(id).trim_prefix("Pick up ")+"! Open Quests to see who needs it."
	return true
func cancel_work() -> void:
	if job.is_empty(): return
	job = ""
	game.restore_walk_visual()
func working() -> bool: return not job.is_empty()
func _process(delta: float) -> void:
	sync_area()
	if not visible or game.trial.blocked(): return
	glint_clock += delta
	for id in props:
		if not prop_exists(id): continue
		if game.fog.is_revealed(game.area_id(),props[id].position): fades[id] = minf(0.75,fades.get(id,0.0)+delta)
		props[id].modulate.a = smoothstep(0,0.75,fades.get(id,0.0))
	for yeti in yetis: yeti.advance(delta)
	if not job.is_empty():
		if nearest_prop() != job or game.trial.selected_tool != 0:
			cancel_work()
			return
		work = minf(2.0,work+delta)
		game.set_mining_pose(int(work/0.09)%3)
		if work >= 2:
			cache_open = true
			props.cache.texture = ART.item(5)
			props.cache.hide()
			cancel_work()
			game.message = "Expedition keepsake recovered! Return to Eira on Aurora Shelf."
	queue_redraw()
func _draw() -> void:
	for id in props:
		if not props[id].visible or not prop_exists(id): continue
		var alpha: float = props[id].modulate.a
		draw_set_transform(props[id].position,0,Vector2(1,0.3))
		var fragment: bool = id.begins_with("beacon_") or id == "heart_crystal"
		var beacon: bool = id.begins_with("beacon_")
		var radius := 17 if beacon or not fragment else 23
		var opacity := 0.18 if beacon else (0.32 if fragment else 0.15)
		draw_circle(Vector2.ZERO,radius,Color(0.02,0.07,0.12,alpha*opacity))
		if fragment:
			draw_set_transform(Vector2.ZERO)
			var sparkle: Vector2 = props[id].position+Vector2(0.42,-0.65)*PROPS[id].width
			var strength := 0.25+0.75*pow(maxf(0,sin(glint_clock*3.2+PROPS[id].region)),2)
			var gold := Color(1.0,0.68,0.16,alpha*strength)
			draw_line(sparkle-Vector2(0,5),sparkle+Vector2(0,5),gold,2,true)
			draw_line(sparkle-Vector2(4,0),sparkle+Vector2(4,0),gold,2,true)
	draw_set_transform(Vector2.ZERO)
	if not job.is_empty():
		draw_rect(Rect2(game.player+Vector2(-28,-100),Vector2(56,5)),Color(0.02,0.06,0.10,0.8))
		draw_rect(Rect2(game.player+Vector2(-28,-100),Vector2(56*work/2.0,5)),Color("87e7ff"))
