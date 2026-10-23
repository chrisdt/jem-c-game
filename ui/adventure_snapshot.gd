extends RefCounted

# Explicit state only: no Nodes, scripts, resources, executable Variant data or
# speedrun tokens. Dictionary keys retain their integer/string identity in JSON.
const FIELDS := {
	"game":["world","earth_region","outer_region","player","underground","ore","blue_crystals","frost_ore","amethysts","gold_ore","rubies","total_mined","upgraded","won","ice_won","desert_won","earth_rocks","outer_rocks","earth_visited","outer_visited","scared_wildlife","elapsed"],
	"story":["accepted","complete","acknowledged","cache_held","quarry_open","drill_improved","sword_improved","damaged_suit","locker_recovered","navigation_part","seal_kit","suit_ready","regulator","engine_part","rocket_repaired","prop_positions","prop_seen","prop_fades","job_progress"],
	"frost_story":["accepted","complete","collected","positions","fades","records","frostfang","crystal_drill","cache_open"],
	"ember_story":["accepted","complete","collected","positions","fades","records","sunfang","magma_drill","observatory_open","antidote_owned","antidote_doses"],
	"trial":["health","selected_tool","sword_owned","wood","defeated","records","mine_health","mine_defeated","encounter_areas","encounter_count","poison_remaining"],
	"rowan":["mission","completion_seen"],
	"missions":["mines","cleared_kinds","fruit_used"],
	"companion":["recruited","discovery_region","discovery_home"],
	"gardens":["records"],
	"wood_supplies":["records"],
}
var valid := true
var count := 0

static func capture(game: Node) -> Dictionary:
	game.district_rocks()[game.current_region()] = game.rocks
	# Flush current enemies/plants as well as records of previously left maps.
	game.trial.records[game.trial.active_area] = []
	for snake in game.trial.snakes:
		game.trial.records[game.trial.active_area].append({"spawn_id":snake.spawn_id,"home":snake.home,"position":snake.position,"health":snake.health,"seen":snake.seen,"fade":snake.fade,"phase":snake.phase,"fear_seconds":snake.fear_seconds,"scare_cooldown":snake.scare_cooldown,"target":snake.target})
	for yeti in game.frost_story.yetis: game.frost_story.records[yeti.spawn_id] = yeti.record()
	for scorpion in game.ember_story.scorpions: game.ember_story.records[scorpion.spawn_id] = scorpion.record()
	game.gardens.records[game.gardens.active_area] = []
	for plant in game.gardens.plants:
		game.gardens.records[game.gardens.active_area].append({"position":plant.position,"apple":plant.apple,"wild_kind":plant.wild_kind,"picked":plant.picked,"discovered":plant.discovered,"fade":plant.fade})
	game.wood_supplies.records[game.wood_supplies.active_area] = game.wood_supplies.piles
	var data := {}
	for part in FIELDS:
		var object: Object = game if part == "game" else game.get(part)
		data[part] = {}
		for key in FIELDS[part]: data[part][key] = object.get(key)
	data["people"] = []
	for npc in game.npcs:
		data.people.append({"introduced":npc.introduced,"greeted":npc.greeted,"departed":npc.departed,"has_waved":npc.has_waved})
	data["fog"] = {}
	for area in game.fog.maps:
		data.fog[area] = Marshalls.raw_to_base64(game.fog.maps[area].pixels.compress(FileAccess.COMPRESSION_DEFLATE))
	return {"version":1,"mode":"explore","state":encode(data)}

static func encode(value: Variant) -> Variant:
	if value is Vector2:
		return {"v":[value.x,value.y]} if value.is_finite() else {"v":"inf"}
	if value is Dictionary:
		var pairs := []
		for key in value: pairs.append([encode(key),encode(value[key])])
		return {"map":pairs}
	if value is Array:
		var values := []
		for item in value: values.append(encode(item))
		return values
	return str(value) if value is StringName else value

func decode(value: Variant, depth := 0) -> Variant:
	count += 1
	if depth > 48 or count > 100000:
		valid = false
		return null
	if value is Dictionary:
		if value.size() != 1:
			valid = false
			return null
		if value.has("v"):
			if value.v is String and value.v == "inf": return Vector2.INF
			if value.v is Array and value.v.size() == 2 and number(value.v[0]) and number(value.v[1]): return Vector2(value.v[0],value.v[1])
		elif value.get("map") is Array:
			var result := {}
			for pair in value.map:
				if not pair is Array or pair.size() != 2:
					valid = false
					return null
				var key = decode(pair[0],depth+1)
				if not key is String and not key is int:
					valid = false
					return null
				result[key] = decode(pair[1],depth+1)
			return result
		valid = false
		return null
	if value is Array:
		var result := []
		for item in value: result.append(decode(item,depth+1))
		return result
	if value is float:
		if not is_finite(value): valid = false
		return int(value) if value == floor(value) else value
	if not value is String and not value is int and not value is bool and value != null: valid = false
	return value

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

func unpack(snapshot: Dictionary, game: Node) -> Dictionary:
	valid = true
	count = 0
	if snapshot.get("version",0) != 1 or snapshot.get("mode","") != "explore": return {}
	var data = decode(snapshot.get("state"))
	if not valid or not data is Dictionary: return {}
	for part in FIELDS:
		if not data.get(part) is Dictionary: return {}
		var object: Object = game if part == "game" else game.get(part)
		for key in FIELDS[part]:
			if not data[part].has(key): return {}
			var before = object.get(key)
			var after = data[part][key]
			if typeof(before) != typeof(after) and not (number(before) and number(after)): return {}
	var state: Dictionary = data.game
	if state.world not in [0,1,2] or state.earth_region not in range(5) or state.underground or not state.player.is_finite() or not Rect2(0,0,2000,1400).has_point(state.player): return {}
	for world in [1,2]:
		if state.outer_region.get(world,-1) not in range(5) or not state.outer_rocks.get(world) is Dictionary or not state.outer_visited.get(world) is Dictionary: return {}
	for districts in [state.earth_rocks,state.outer_rocks[1],state.outer_rocks[2]]:
		for region in districts:
			if region not in range(5) or not districts[region] is Array or districts[region].size() > 250: return {}
			for rock in districts[region]:
				if not rock is Dictionary or not vector(rock.get("pos")) or not rock.get("cave") is bool: return {}
				if not rock.get("hard") is bool or not rock.get("discovered") is bool: return {}
				if not bounded_number(rock.get("hp"),-10,10) or not bounded_number(rock.get("seconds"),0.1,120): return {}
				if not bounded_number(rock.get("work",0),0,rock.seconds): return {}
				if rock.has("revealed_at") and not bounded_number(rock.revealed_at,0,1000000000): return {}
	for key in ["ore","blue_crystals","frost_ore","amethysts","gold_ore","rubies","total_mined","elapsed"]:
		if not bounded_number(state[key],0,1000000000): return {}
	var region: int = state.earth_region if state.world == 0 else state.outer_region[state.world]
	var floor_ok: bool
	if region > 0: floor_ok = game.world_regions[state.world].can_walk(region,false,state.player)
	elif state.world == 0: floor_ok = game.LANDING_LAYOUT.can_walk(state.player)
	elif state.world == 1: floor_ok = game.FROST_LAYOUT.can_walk(state.player,false)
	else: floor_ok = game.DESERT_LAYOUT.can_walk(state.player,false)
	if not floor_ok: return {}
	for part in ["story","frost_story","ember_story"]:
		for key in ["accepted","complete"]:
			for value in data[part][key].values():
				if not value is bool: return {}
	for fields in [[data.story,["prop_positions"]],[data.frost_story,["positions"]],[data.ember_story,["positions"]]]:
		for key in fields[1]:
			for value in fields[0][key].values():
				if not value is Vector2: return {}
	if not record_map(data.trial.records,{"spawn_id":"string","home":"vector","position":"vector","health":"number","seen":"bool","fade":"number","phase":"number","target":"vector"},true): return {}
	for part in ["frost_story","ember_story"]:
		if not record_map(data[part].records,{"health":"number","position":"vector","seen":"bool","fade":"number"},false): return {}
	if not record_map(data.gardens.records,{"position":"vector","apple":"bool","wild_kind":"number","picked":"bool","discovered":"bool","fade":"number"},true): return {}
	if not record_map(data.wood_supplies.records,{"position":"vector","collected":"bool","seen":"bool","fade":"number"},true): return {}
	if data.trial.health < 1 or data.trial.health > 10 or data.trial.selected_tool not in [0,1]: return {}
	if not data.get("people") is Array or data.people.size() != game.npcs.size() or not data.get("fog") is Dictionary or data.fog.size() > 24: return {}
	for person in data.people:
		if not person is Dictionary: return {}
		for key in ["introduced","greeted","departed","has_waved"]:
			if not person.get(key) is bool: return {}
	for area in data.fog:
		if area not in range(24) or not data.fog[area] is String or data.fog[area].length() > 60000: return {}
		var pixels := Marshalls.base64_to_raw(data.fog[area]).decompress(43750,FileAccess.COMPRESSION_DEFLATE)
		if pixels.size() != 43750: return {}
		data.fog[area] = pixels
	return data

static func vector(value: Variant) -> bool:
	return value is Vector2 and value.is_finite() and absf(value.x) < 10000 and absf(value.y) < 10000

static func bounded_number(value: Variant, low: float, high: float) -> bool:
	return number(value) and value >= low and value <= high

static func record_map(records: Dictionary, fields: Dictionary, lists: bool) -> bool:
	if records.size() > 200: return false
	for value in records.values():
		if lists and not value is Array: return false
		var entries: Array = value if lists else [value]
		if entries.size() > 250: return false
		for entry in entries:
			if not entry is Dictionary: return false
			for key in fields:
				var item = entry.get(key)
				match fields[key]:
					"vector":
						if not vector(item): return false
					"number":
						if not bounded_number(item,-1000,1000000): return false
					"bool":
						if not item is bool: return false
					"string":
						if not item is String or item.length() > 100: return false
	return true

static func apply(data: Dictionary, game: Node) -> void:
	# Discard freshly spawned live objects before restoring their saved records;
	# otherwise sync_area() could flush the new world's defaults over the save.
	for snake in game.trial.snakes: snake.free()
	game.trial.snakes.clear()
	for enemy in game.frost_story.yetis + game.ember_story.scorpions: enemy.free()
	game.frost_story.yetis.clear()
	game.ember_story.scorpions.clear()
	game.gardens.clear_area()
	for part in FIELDS:
		var object: Object = game if part == "game" else game.get(part)
		for key in FIELDS[part]:
			var old = object.get(key)
			var value = data[part][key]
			if old is Array: old.assign(value)
			else: object.set(key,int(value) if old is int else (float(value) if old is float else value))
	for i in game.npcs.size():
		for key in data.people[i]: game.npcs[i].set(key,data.people[i][key])
	for object in [game.story,game.frost_story,game.ember_story,game.trial,game.gardens,game.wood_supplies]: object.active_area = -1
	game.wood_supplies.piles.clear()
	# Godot's typed arrays must be rebuilt explicitly after plain JSON decode;
	# future district/wood switches assign these cached arrays directly.
	for districts in [game.earth_rocks,game.outer_rocks[1],game.outer_rocks[2],game.wood_supplies.records]:
		for key in districts:
			var records: Array[Dictionary] = []
			records.assign(districts[key])
			districts[key] = records
	game.companion.area_key = ""
	game.companion.waiting_position = Vector2.INF
	game.fog.maps.clear()
	game.fog.active_map = -1
	for area in data.fog:
		game.fog.observe(area,Vector2.ZERO)
		var pixels: PackedByteArray = data.fog[area]
		game.fog.maps[area].pixels = pixels
		game.fog.maps[area].image.set_data(250,175,false,Image.FORMAT_R8,pixels)
		game.fog.maps[area].texture.update(game.fog.maps[area].image)
		game.fog.maps[area].last_stamp = Vector2.INF
	game.planet_rocks.clear()
	for world in [0,1,2]:
		var districts: Dictionary = game.earth_rocks if world == 0 else game.outer_rocks[world]
		if districts.has(0): game.planet_rocks[world] = districts[0]
	game.rocks.assign(game.district_rocks().get(game.current_region(),[]))
	game.district_rocks()[game.current_region()] = game.rocks
	game.earth_stream.deactivate()
	game.earth_stream.REGIONS = game.regions()
	game.rocket.reset_pad(game.ship_position(),game.world == 1)
	game.scout.position = game.player
	game.restore_walk_visual()
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.update_exploration()
	if game.current_region() > 0:
		# Stream the saved painting through the normal bounded loader. Restore
		# never unlocks a story gate merely to get back to an earned checkpoint.
		var point: Vector2 = game.player
		game.begin_earth_transition(game.current_region(),false,point,point)
	game.message = "Adventure continued. Visit a glowing save totem to keep your next checkpoint."
	game.refresh_ui()
