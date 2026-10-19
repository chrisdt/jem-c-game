extends Node2D

const PLANT = preload("res://environment/healing_plant.gd")
const GRASS = preload("res://environment/flower_placement.gd")
const ART = preload("res://environment/trial_art.gd")
const STYLE = preload("res://ui/expedition_style.gd")
# Exactly two fruit trees and two berry bushes per planet, across districts.
# x/y use painting coordinates; z = 1 for a tree, 0 for a bush.
# Landing Meadow has one bush and no fruit trees.
const SITES := {
	0:{0:Vector3(555,500,0),1:Vector3(510,755,1),2:Vector3(1190,770,0),3:Vector3(520,515,1)},
	1:{1:Vector3(620,650,1),2:Vector3(1020,580,0),3:Vector3(390,650,1),4:Vector3(1020,680,0)},
	2:{1:Vector3(610,540,0),2:Vector3(1010,470,1),3:Vector3(750,530,1),4:Vector3(1000,400,0)},
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
	return not is_active() or game.get_tree().paused or game.planet_menu.visible or game.hud.help.visible

func clear_area() -> void:
	if active_area >= 0:
		records[active_area] = []
		for plant in plants:
			records[active_area].append({"position":plant.position,"apple":plant.apple,"picked":plant.picked,"discovered":plant.discovered,"fade":plant.fade})
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
		var point := find_site(Vector2(site.x,site.y),bool(site.z))
		if point.is_finite():
			records[area].append({"position":point,"apple":bool(site.z),"picked":false,"discovered":false,"fade":0.0})
	for record in records[area]:
		var plant := PLANT.new()
		plant.garden = self
		plant.position = record.position
		plant.apple = record.apple
		plant.picked = record.picked
		plant.discovered = record.discovered
		plant.fade = record.fade
		plant.modulate = [Color.WHITE,Color(0.83,0.94,1.0),Color(1.0,0.91,0.78)][game.world]
		add_child(plant)
		plants.append(plant)

func clear_floor(point: Vector2) -> bool:
	var district: int = game.current_region()
	var catalog = game.regions()
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
	return true

func find_site(preferred_art: Vector2, apple: bool) -> Vector2:
	var catalog = game.regions()
	var preferred: Vector2 = catalog.from_art(preferred_art)
	var plant_scale := 0.24 if apple else 0.16
	if game.world == 0:
		var painting: Texture2D = game.green_surface.get_node("Ground").texture if game.current_region() == 0 else game.earth_stream.textures[catalog.key(game.current_region(),false)]
		var placement := GRASS.new(painting,catalog.SIZE,clear_floor)
		for offset in [Vector2.ZERO,Vector2(-160,0),Vector2(160,0),Vector2(0,-150),Vector2(0,150)]:
			var point := placement.place(preferred+offset,plant_scale)
			if point.is_finite(): return point
	else:
		# Snow and sand do not pass Earth's green-grass mask. Check a complete
		# root footprint against their own cliff, rock and lava floor boundaries.
		for ring in 24:
			for ray in 24:
				var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*12
				var fits := true
				for offset in [Vector2.ZERO,Vector2.LEFT*45,Vector2.RIGHT*45,Vector2.UP*28,Vector2.DOWN*28]:
					if not clear_floor(point+offset):
						fits = false
						break
				if fits: return point
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
