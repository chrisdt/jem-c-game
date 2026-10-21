extends Node2D

const EARTH = preload("res://earth_regions.gd")
const NPC = preload("res://environment/earth_story_npc.gd")
const TITLES := {"rowan":"Ready for the Trail","bea":"Woodland Supplies","otis":"Clear the Way","mara":"Better Tools","iris":"The Old Expedition","finn":"Ready for Space","nova":"Beyond Earth"}
const ORDER := ["rowan","bea","otis","mara","iris","finn","nova"]
# All coordinates are feet on the existing paintings, not blocking collisions.
const PEOPLE := {
	"otis":{"region":1,"foot":Vector2(1660,790)},
	"mara":{"region":4,"foot":Vector2(1040,550)},
	"iris":{"region":3,"foot":Vector2(1370,600)},
	"finn":{"region":2,"foot":Vector2(1187,853)},
	"nova":{"region":0,"foot":Vector2(195,470)},
}
const PROPS := {
	"supplies":{"region":1,"cave":false,"foot":Vector2(1480,847),"cell":0,"width":58.0},
	"rockfall":{"region":1,"cave":false,"foot":Vector2(1975,740),"cell":1,"width":540.0},
	"locker":{"region":3,"cave":false,"foot":Vector2(1600,345),"cell":2,"width":68.0},
	"seals":{"region":1,"cave":false,"foot":Vector2(410,278),"cell":3,"width":36.0,"ground_depth":0.68},
	"engine":{"region":4,"cave":true,"foot":Vector2(1230,440),"cell":4,"width":44.0,"ground_depth":0.80},
}
const ROCKFALL_BARRIER := Rect2(1720,545,280,285)
# Keep the full repair chain available for a later update. Travel availability
# does not grant any quest rewards, equipment or completion flags.
var rocket_repair_required: bool = ProjectSettings.get_setting("gameplay/rocket_repair_required",false)
var game: Node
var accepted: Dictionary = {}
var complete: Dictionary = {}
var acknowledged: Dictionary = {}
var offered: Dictionary = {}
var cache_held := false
var quarry_open := false
var drill_improved := false
var sword_improved := false
var damaged_suit := false
var navigation_part := false
var seal_kit := false
var suit_ready := false
var regulator := false
var engine_part := false
var rocket_repaired := false
var prop_positions: Dictionary = {}
var prop_seen: Dictionary = {}
var prop_fades: Dictionary = {}
var props: Dictionary = {}
var dust: Array[Dictionary] = []
var active_area := -1
var prop_art: Dictionary = {}
var job := ""
var job_progress: Dictionary = {}

func _ready() -> void:
	name = "EarthStory"
	y_sort_enabled = true
	for role in PEOPLE:
		var person := NPC.new()
		person.game = game
		person.role = role
		game.add_child(person)
		game.npcs.append(person)
	sync_area()

func done(role: String) -> bool:
	if role == "rowan": return game.rowan.mission == game.ROWAN.Mission.COMPLETE
	return complete.get(role,false)

func available(role: String) -> bool:
	if role == "nova" and not rocket_repair_required: return false
	if role == "bea": return game.trial.sword_owned
	var index := ORDER.find(role)
	return index <= 0 or done(ORDER[index-1])

func launch_ready() -> bool:
	return not rocket_repair_required or (rocket_repaired and drill_improved and sword_improved and suit_ready)

func snake_cleared(region: int, slot: int) -> bool:
	var id := "%d/%d" % [region,slot]
	if game.world == 0 and game.earth_region == region and not game.underground:
		for snake in game.trial.snakes:
			if snake.spawn_id == id: return snake.health <= 0
	for record in game.trial.records.get(EARTH.SURFACE_IDS[region],[]):
		if record.get("spawn_id","") == id: return record.health <= 0
	return false

func action(role: String) -> String:
	if done(role): return "Done"
	if not available(role): return "Done"
	match role:
		"bea":
			if not game.trial.sword_owned: return "Done"
			if cache_held: return "Return supplies"
		"otis":
			if quarry_open: return "Complete mission"
		"mara":
			if game.upgraded and game.trial.sword_owned and game.ore >= 4 and game.blue_crystals >= 2: return "Upgrade both tools"
		"iris":
			if damaged_suit and navigation_part: return "Report discovery"
		"finn":
			if damaged_suit and seal_kit and game.trial.wood >= 2: return "Repair spacesuit"
		"nova":
			if drill_improved and sword_improved and suit_ready and navigation_part and regulator and engine_part: return "Repair and check rocket"
	return "Accept mission" if not accepted.get(role,false) else "Done"

func pages(role: String) -> Array[String]:
	if done(role):
		return [closing(role)]
	if not available(role):
		var prior: String = ORDER[ORDER.find(role)-1]
		if role == "nova": return ["I'd love to explore other planets with you. This rocket needs repairs first.","Help our Earth neighbours prepare your tools and spacesuit. I'll be here when you're ready."]
		return ["Let's finish %s's job first: %s. Then I can help with the next step." % [prior.capitalize(),TITLES[prior]]]
	match role:
		"bea":
			if not game.trial.sword_owned: return ["There's a snake near my supply box. Rowan at camp can help you prepare a copper sword."]
			if cache_held: return ["You found my supplies! Shall we put them back to work on the woodland trail?"]
			if snake_cleared(1,1): return ["The snake near the fallen tree is gone. Recover my tied wooden box just northwest of here, then bring it to me."]
			return ["A snake is guarding my supply box beside the fallen tree.","Deal with that snake, recover the tied box and bring it back. Watch its warning before you jab."]
		"otis":
			if quarry_open: return ["The quarry trail is open! Mara is beside the rails and mine cart in Old Quarry."]
			return ["That rockfall blocks the quarry trail. A starter pick won't shift it.","Build the hand drill at camp for 5 copper, then use it on the rocks. There's enough copper on this side of the quarry."]
		"mara":
			return ["Hard rock calls for better tools. I'll reinforce your drill and copper sword.","Bring 4 copper and 2 blue crystals in total: 2 copper and 1 crystal for each upgrade. Your drill will be faster and your sword stronger.","You have %d/4 copper and %d/2 blue crystals. Find crystal in Earth's three mines." % [mini(game.ore,4),mini(game.blue_crystals,2)]]
		"iris":
			if damaged_suit and navigation_part: return ["An old spacesuit and a navigation unit! Finn can repair the suit beside Willow Marsh's bridge."]
			return ["There's an expedition locker at the circular ruins. A snake has made its home nearby.","With Mara's upgraded tools, deal with the ruins snake and drill open the locker. Bring me news of what you find."]
		"finn":
			return ["Let's make that old spacesuit safe for the journey.","Find my seal kit beside the campsite tent on Pinewood Trail. Bring it, the damaged suit and 2 fallen wood for the repair frame.",("You have %d/2 wood. I'll seal the suit and give you the recovered fuel regulator." if rocket_repair_required else "You have %d/2 wood. I'll seal the suit for your next adventure.") % mini(game.trial.wood,2)]
		"nova":
			return ["We've nearly got a space explorer! The last engine component is in Crystal Depths.","Recover it with the upgraded drill. Bring the navigation unit from Iris and fuel regulator from Finn.","Then we'll fit the parts, check both upgraded tools and your sealed spacesuit, and repair the rocket together."]
	return []

func closing(role: String) -> String:
	match role:
		"bea": return "Thank you! Otis needs help with a rockfall on the east quarry trail. Build a hand drill at camp for 5 copper if you haven't already."
		"otis": return "The way is clear. Find Mara by the quarry rails and mine cart for better tools."
		"mara": return "Your crystal drill is faster and your reinforced sword hits harder! Iris is researching the circular ruins at Sunstone Ridge."
		"iris": return "Finn at Willow Marsh's stream and bridge can seal that spacesuit."+(" Keep the navigation unit safe for Nova." if rocket_repair_required else "")
		"finn": return "Your spacesuit is sealed and ready!"+(" Take this fuel regulator to Nova beside the rocket at camp." if rocket_repair_required else " Thanks for helping our Earth neighbours. The camp rocket is ready whenever you want to explore another world.")
		"nova": return "Launch checks complete! The rocket, both upgraded tools and your spacesuit are ready. Choose a world at the rocket when you're ready."
	return "Thanks for your help!"

func begin(role: String) -> void:
	offered[role] = action(role)

func finish(role: String, completed: bool) -> void:
	var offer: String = offered.get(role,"")
	offered.erase(role)
	if not completed: return
	if done(role):
		acknowledged[role] = true
		return
	if not available(role) or offer != action(role): return
	if offer == "Accept mission":
		accepted[role] = true
		game.message = "Mission started: "+TITLES[role]
		return
	if offer == "Done": return
	match role:
		"bea": cache_held = false
		"mara":
			game.ore -= 4
			game.blue_crystals -= 2
			drill_improved = true
			sword_improved = true
		"finn":
			game.trial.wood -= 2
			seal_kit = false
			damaged_suit = false
			suit_ready = true
			regulator = rocket_repair_required
		"nova":
			navigation_part = false
			regulator = false
			engine_part = false
			rocket_repaired = true
	accepted[role] = true
	complete[role] = true
	game.restore_walk_visual()
	game.message = closing(role)
	sync_area()

func progress_text(role: String) -> String:
	if done(role): return "Complete"
	if not available(role): return "Help "+ORDER[ORDER.find(role)-1].capitalize()+" first"
	match role:
		"bea": return "Return supplies to Bea" if cache_held else ("Recover the supply box" if snake_cleared(1,1) else "Snake · supplies · return")
		"otis": return "Report to Otis" if quarry_open else ("Clear the rockfall" if game.upgraded else "Build hand drill · 5 copper")
		"mara": return "%d/4 copper · %d/2 crystals" % [mini(game.ore,4),mini(game.blue_crystals,2)]
		"iris": return "Report to Iris" if damaged_suit else "Search the ruins locker"
		"finn": return "Seal kit · %d/2 wood" % mini(game.trial.wood,2)
		"nova": return "Engine · navigation · regulator"
	return "Talk to Rowan at camp"

func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var details := {
		"rowan":"Talk to Rowan beside camp. Gather 3 copper and 2 wood, then craft a sword at the workbench.",
		"bea":"Pinewood Trail: defeat the snake beside Bea's tied supply box, recover the box and return it to her.",
		"otis":"Pinewood's quarry trail: craft the 5-copper hand drill, drill away the rockfall, then report to Otis.",
		"mara":"Old Quarry, beside the rails: bring 4 copper and 2 blue crystals to upgrade both your drill and sword.",
		"iris":"Sunstone Ridge: use the upgraded tools, defeat the ruins snake and open the expedition locker. Report to Iris.",
		"finn":"Find Finn on the grassy bank below Willow Marsh's bridge. Bring the damaged spacesuit, seal kit from Pinewood Trail's campsite tent and 2 fallen wood.",
		"nova":"Camp rocket: recover the engine part in Crystal Depths. Bring it, the navigation unit and Finn's regulator for launch checks.",
	}
	for role in ORDER:
		if role == "nova" and not rocket_repair_required: continue
		var detail: String = closing(role) if done(role) else details[role]
		var progress: String = ("Sword ready · talk to Rowan" if game.trial.sword_owned and not done(role) else game.rowan.progress_text()) if role == "rowan" else progress_text(role)
		result.append({"id":role,"title":role.capitalize()+" · "+TITLES[role],"detail":detail,"progress":progress,"done":done(role)})
	return result

func prop_exists(id: String) -> bool:
	match id:
		"supplies": return not cache_held and not done("bea")
		"rockfall": return not quarry_open
		"locker": return drill_improved and sword_improved and not damaged_suit and not done("iris") and not suit_ready
		"seals": return not seal_kit and not suit_ready
		"engine": return rocket_repair_required and not engine_part and not rocket_repaired
	return false

func floor_at(point: Vector2, region: int, cave: bool) -> bool:
	if region > 0: return EARTH.can_walk(region,cave,point)
	return game.ORE_SPAWNS.can_walk(0,cave,point) and (cave or game.ORE_SPAWNS.green_ground(point))

func fitted_position(id: String) -> Vector2:
	if prop_positions.has(id): return prop_positions[id]
	var spec: Dictionary = PROPS[id]
	if id == "rockfall":
		prop_positions[id] = spec.foot
		return spec.foot
	for ring in 18:
		for ray in 24:
			var point: Vector2 = spec.foot+Vector2.from_angle(ray*TAU/24)*ring*12
			if not floor_at(point,spec.region,spec.cave): continue
			var clear := true
			for rock in game.rocks:
				if rock.cave == spec.cave and point.distance_to(rock.pos) < 105: clear = false
			for npc in game.npcs:
				if npc.home_region == spec.region and point.distance_to(npc.position) < 75: clear = false
			if clear:
				prop_positions[id] = point
				return point
	return Vector2.INF

func sync_area() -> void:
	visible = game.world == 0 and game.flight == 0 and not game.earth_transition
	if not visible: return
	var area: int = game.area_id()
	if active_area != area:
		for prop in props.values(): prop.free()
		props.clear()
		active_area = area
	for id in PROPS:
		var spec: Dictionary = PROPS[id]
		if spec.region != game.earth_region or spec.cave != game.underground: continue
		if not prop_exists(id):
			if props.has(id): props[id].hide()
			continue
		if props.has(id): continue
		var point := fitted_position(id)
		if not point.is_finite(): continue
		var prop := Sprite2D.new()
		if not prop_art.has(spec.cell):
			var atlas := AtlasTexture.new()
			atlas.atlas = load("res://assets/npcs/earth_quest_props.png")
			var region: Rect2i = [Rect2i(0,0,440,480),Rect2i(440,0,610,460),Rect2i(1050,0,486,460),Rect2i(0,480,515,544),Rect2i(520,480,510,544),Rect2i(1035,480,501,544)][spec.cell]
			var bounds: Rect2i = game.HUMAN_NPC.visible_bounds(atlas.atlas.get_image().get_region(region))
			atlas.region = Rect2(bounds.position+region.position,bounds.size)
			prop_art[spec.cell] = atlas
		prop.texture = prop_art[spec.cell]
		prop.position = point
		prop.centered = false
		prop.scale = Vector2.ONE*(spec.width/prop.texture.get_width())
		prop.offset = Vector2(-prop.texture.get_width()*0.5,-prop.texture.get_height())
		if spec.has("ground_depth"):
			prop.scale.y *= spec.ground_depth
			prop.offset.y = -prop.texture.get_height()*0.82
		prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		prop.modulate.a = prop_fades.get(id,0.0)
		add_child(prop)
		props[id] = prop

func _process(delta: float) -> void:
	sync_area()
	if not visible or game.trial.blocked(): return
	advance_actions(delta)
	for id in props:
		if not prop_exists(id): continue
		if game.fog.is_revealed(game.area_id(),interaction_position(id)): prop_seen[id] = true
		if prop_seen.get(id,false): prop_fades[id] = minf(1,prop_fades.get(id,0.0)+delta/0.75)
		props[id].modulate.a = smoothstep(0,1,prop_fades.get(id,0.0))
	for particle in dust:
		particle.time += delta
	dust = dust.filter(func(p): return p.time < 0.8)
	queue_redraw()

func nearest_prop() -> String:
	if not visible: return ""
	var best := ""
	var distance := 1.0
	for id in props:
		if not prop_exists(id) or not prop_seen.get(id,false): continue
		var d: float = game.player.distance_to(interaction_position(id))/prop_reach(id)
		if d < distance:
			best = id
			distance = d
	return best

func prop_reach(_id: String) -> float:
	return 105.0

func space_usable_prop() -> String:
	var id := nearest_prop()
	# Space remains an attack while a creature guards the object. E can still
	# explain the requirement; once safe, either key recovers the item.
	if id == "supplies" and not snake_cleared(1,1): return ""
	if id == "locker" and not snake_cleared(3,1): return ""
	if id in ["rockfall","locker","engine"] and game.trial.sword_equipped(): return ""
	return id

func interaction_position(id: String) -> Vector2:
	# The rockfall's illustrated center extends beyond the map. Work on its
	# visible west/front face, so Sunny never has to stand behind the boulders.
	if id == "rockfall": return Vector2(ROCKFALL_BARRIER.position.x+20,PROPS.rockfall.foot.y-20)
	return props[id].position

func prop_prompt(id: String) -> String:
	return {"supplies":"Recover Bea's supplies","rockfall":"Drill the rockfall","locker":"Open expedition locker","seals":"Recover seal kit","engine":"Recover engine component"}.get(id,"")

func working() -> bool:
	return not job.is_empty()

func cancel_work() -> void:
	if not working(): return
	job = ""
	game.restore_walk_visual()
	game.message = "Drilling paused. Return to finish the job."

func advance_actions(delta: float) -> void:
	if not working() or game.menu_open() or game.get_tree().paused or game.flight != 0 or game.earth_transition: return
	if not props.has(job) or game.player.distance_to(interaction_position(job)) >= prop_reach(job)+5:
		cancel_work()
		return
	job_progress[job] = minf(2,job_progress.get(job,0.0)+delta)
	game.set_mining_pose(int(job_progress[job]/0.09)%3)
	if job_progress[job] >= 2:
		var finished := job
		job = ""
		finish_prop(finished)
		game.restore_walk_visual()

func use_prop(id: String) -> bool:
	if id.is_empty() or id != nearest_prop() or game.menu_open(): return false
	var hint := ""
	match id:
		"supplies":
			if not snake_cleared(1,1): hint = "The snake beside the supply box is still there. Watch its warning, then jab."
			else: cache_held = true
		"rockfall":
			if not game.upgraded: hint = "The rockfall needs a hand drill. Craft one at camp for 5 copper."
		"locker":
			if not drill_improved or not sword_improved: hint = "Mara can upgrade both tools at Old Quarry before you open this locker."
			elif not snake_cleared(3,1): hint = "Deal with the snake at the ruins before opening the locker."
		"seals": seal_kit = true
		"engine":
			if not drill_improved: hint = "The engine housing needs Mara's upgraded drill."
	if not hint.is_empty():
		game.message = hint
		return true
	if id in ["rockfall","locker","engine"]:
		if game.trial.selected_tool != 0:
			game.message = "Select your mining tool first: press 1 or tap the drill."
			return true
		job = id
		game.face_direction(interaction_position(id)-game.player)
		game.walking = false
		game.set_mining_pose(0)
		game.message = "Drilling · move or tap Pause to stop. Your work is kept."
		return true
	finish_prop(id)
	return true

func finish_prop(id: String) -> void:
	match id:
		"rockfall": quarry_open = true
		"locker":
			damaged_suit = true
			navigation_part = true
		"engine": engine_part = true
	dust.append({"pos":interaction_position(id),"time":0.0})
	props[id].hide()
	game.message = "The quarry trail is open! Tell Otis." if id == "rockfall" else "Recovered: %s. Keep it safe for the expedition." % prop_prompt(id).trim_prefix("Recover ").trim_prefix("Open ")
	game.refresh_ui()

func _draw() -> void:
	for id in props:
		if id == "rockfall" or not prop_exists(id) or not props[id].visible: continue
		var alpha: float = props[id].modulate.a
		draw_set_transform(props[id].position+Vector2(0,-1),0,Vector2(1,0.20))
		draw_circle(Vector2.ZERO,PROPS[id].width*0.34,Color(0.08,0.11,0.05,alpha*0.18))
	draw_set_transform(Vector2.ZERO)
	if working() and props.has(job):
		# Keep the quarry bar left of the tall boulder art and above Sunny's
		# head; parent drawing behind the pile must not hide the work feedback.
		var at: Vector2 = interaction_position(job)+(Vector2(-96,-130) if job == "rockfall" else Vector2(-36,-55))
		draw_rect(Rect2(at,Vector2(72,7)),Color("143638"))
		draw_rect(Rect2(at+Vector2.ONE,Vector2(70*job_progress.get(job,0.0)/2,5)),Color("8de5e5"))
	for particle in dust:
		var t: float = particle.time/0.8
		for i in 9:
			var at: Vector2 = particle.pos+Vector2.from_angle(i*TAU/9)*(10+24*t)+Vector2(0,-20*t)
			draw_circle(at,8+6*t,Color(0.86,0.83,0.72,(1-t)*0.5))
