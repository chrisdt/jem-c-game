extends Node2D

const PLANT = preload("res://environment/healing_plant.gd")
const GRASS = preload("res://environment/flower_placement.gd")
const ART = preload("res://environment/trial_art.gd")
const STYLE = preload("res://ui/expedition_style.gd")
# Exactly two fruit trees and two berry bushes across Earth's districts.
# x/y use painting coordinates. Earth: z = 1 tree, 0 bush. Other worlds:
# z = 1 two-heart plant, 0 one-heart plant; one native plant per outdoor map.
# Landing Meadow has one bush and no fruit trees.
const SITES := {
	0:{0:Vector3(555,500,0),1:Vector3(510,755,1),2:Vector3(1190,770,0),3:Vector3(520,515,1)},
	1:{0:Vector3(360,610,0),1:Vector3(430,600,0),2:Vector3(450,600,0),3:Vector3(540,510,1),4:Vector3(1050,540,1)},
	2:{0:Vector3(395,630,0),1:Vector3(980,460,0),2:Vector3(1050,560,1),3:Vector3(700,720,1),4:Vector3(710,690,0)},
}
var game: Node
var plants: Array[Node2D] = []
var records: Dictionary = {}
var active_area := -1
var seconds := 0.0
var effects: Array[Dictionary] = []
var feedback: Node2D

func _ready() -> void:
	name = "HealingGardens"
	y_sort_enabled = true
	feedback = Node2D.new()
	feedback.z_index = 4
	feedback.draw.connect(draw_heal_effects)
	add_child(feedback)
	sync_area()

func is_active() -> bool:
	return active_area == game.area_id() and not game.underground and game.flight == 0 and not game.earth_transition

func blocked() -> bool:
	return not is_active() or game.trial.blocked()

func clear_area() -> void:
	if active_area >= 0:
		records[active_area] = []
		for plant in plants:
			records[active_area].append({"position":plant.position,"apple":plant.apple,"wild_kind":plant.wild_kind,"picked":plant.picked,"discovered":plant.discovered,"fade":plant.fade})
	for plant in plants:
		remove_child(plant)
		plant.free()
	plants.clear()
	effects.clear()
	feedback.queue_redraw()

func sync_area() -> void:
	visible = game.flight == 0 and not game.earth_transition and not game.underground
	if game.flight != 0 or game.earth_transition: return
	var area: int = game.area_id()
	if active_area == area: return
	if not game.underground and game.current_region() > 0 and not game.earth_stream.textures.has(game.regions().key(game.current_region(),false)):
		# Wait for the district's normal loader; gardens never fetch scenery.
		visible = false
		return
	clear_area()
	active_area = area
	if game.underground: return
	if not records.has(area):
		records[area] = []
		var district: int = game.current_region()
		if not SITES[game.world].has(district): return
		var site: Vector3 = SITES[game.world][district]
		var preferred := Vector2(site.x,site.y)
		var offset := Vector2(game.ore_rng.randf_range(-95,95),game.ore_rng.randf_range(-75,75))
		var point := find_site(preferred+offset,bool(site.z))
		if not point.is_finite(): point = find_site(preferred,bool(site.z))
		if point.is_finite():
			records[area].append({"position":point,"apple":game.world == 0 and bool(site.z),"wild_kind":-1 if game.world == 0 else (game.world-1)*2+int(site.z),"picked":false,"discovered":false,"fade":0.0})
	for record in records[area]:
		var plant := PLANT.new()
		plant.garden = self
		plant.position = record.position
		plant.apple = record.apple
		plant.wild_kind = record.wild_kind
		plant.picked = record.picked
		plant.discovered = record.discovered
		plant.fade = record.fade
		add_child(plant)
		plants.append(plant)

func clear_floor(point: Vector2) -> bool:
	var district: int = game.current_region()
	var catalog = game.regions()
	if game.world == 0 and not game.EARTH.clear_of_people(district,point): return false
	if district == 0:
		if not game.trial.floor_at(point): return false
	elif not catalog.can_walk(district,false,point): return false
	for rock in game.rocks:
		if not rock.cave and rock.hp > 0 and point.distance_to(rock.pos) < 110: return false
	for link in catalog.LINKS[district]:
		if point.distance_to(catalog.portal(district,link.side)) < 150: return false
	if catalog.has_mine(district) and point.distance_to(catalog.MINE_ENTRANCES[district]) < 170: return false
	if district > 0:
		for tree in catalog.TREES[district]:
			if point.distance_to(catalog.from_art(Vector2(tree.x,tree.y))) < 100: return false
	if game.world > 0:
		if game.has_base() and (point.distance_to(game.camp_position()) < 155 or point.distance_to(game.ship_position()) < 155): return false
		var story = game.frost_story if game.world == 1 else game.ember_story
		for person in story.npcs:
			if person.home_region == district and point.distance_to(person.position) < 130: return false
		for prop in story.props.values():
			if point.distance_to(prop.position) < 130: return false
	return true

func find_site(preferred_art: Vector2, apple: bool) -> Vector2:
	if game.world > 0: return find_wild_site(preferred_art)
	var catalog = game.regions()
	var preferred: Vector2 = catalog.from_art(preferred_art)
	var plant_scale := 0.24 if apple else 0.16
	var painting: Texture2D = game.green_surface.get_node("Ground").texture if game.current_region() == 0 else game.earth_stream.textures[catalog.key(game.current_region(),false)]
	var placement := GRASS.new(painting,catalog.SIZE,clear_floor)
	for offset in [Vector2.ZERO,Vector2(-160,0),Vector2(160,0),Vector2(0,-150),Vector2(0,150)]:
		var point := placement.place(preferred+offset,plant_scale)
		if point.is_finite(): return point
	return Vector2.INF

func ground_painting() -> Texture2D:
	if game.current_region() > 0: return game.earth_stream.textures[game.regions().key(game.current_region(),false)]
	return game.ICE_ART if game.world == 1 else game.DESERT_ART

func wild_ground_fits(point: Vector2, painting: Image) -> bool:
	var size: Vector2 = game.regions().SIZE
	for offset in [Vector2.ZERO,Vector2(-35,0),Vector2(35,0),Vector2(0,-23),Vector2(0,23)]:
		var at: Vector2 = point+offset
		if not clear_floor(at) or not Rect2(Vector2.ZERO,size).has_point(at): return false
		var pixel := Vector2i(at/size*Vector2(painting.get_size())).clamp(Vector2i.ZERO,painting.get_size()-Vector2i.ONE)
		var colour := painting.get_pixelv(pixel)
		if game.world == 1:
			# Snow, not a dark rock, cyan ice face, pond or footprint track.
			if colour.r < 0.57 or colour.g < 0.62 or colour.b < 0.65: return false
		else:
			# Native warm sand, excluding molten lava and black basalt.
			if colour.r < 0.58 or colour.g < 0.30 or colour.b > 0.65 or colour.r < colour.g*1.12 or colour.g < colour.b*1.12: return false
	return true

func find_wild_site(preferred_art: Vector2) -> Vector2:
	var painting := ground_painting().get_image()
	if painting.is_compressed(): painting.decompress()
	painting.resize(384,269,Image.INTERPOLATE_TRILINEAR)
	var preferred: Vector2 = game.regions().from_art(preferred_art)
	for ring in 36:
		for ray in (1 if ring == 0 else 24):
			var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*12
			if wild_ground_fits(point,painting): return point
	return Vector2.INF

func _process(delta: float) -> void:
	if blocked(): return
	seconds += delta
	for plant in plants: plant.advance(delta,seconds)
	for effect in effects: effect.time += delta
	effects = effects.filter(func(effect): return effect.time < 1.2)
	feedback.queue_redraw()

func add_heal_effect(at: Vector2, hearts: int) -> void:
	effects.append({"position":at,"hearts":hearts,"time":0.0})
	feedback.queue_redraw()

func draw_heal_effects() -> void:
	for effect in effects:
		var alpha := 1-smoothstep(0.6,1.2,float(effect.time))
		var at: Vector2 = effect.position+Vector2(-15,-50-effect.time*38)
		feedback.draw_texture_rect(ART.icon(1),Rect2(at,Vector2(25,22)),false,Color(1,1,1,alpha))
		feedback.draw_string(STYLE.BODY,at+Vector2(27,17),"+%d" % effect.hearts,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(1,0.94,0.8,alpha))
