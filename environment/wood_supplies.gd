extends Node2D

const ART = preload("res://environment/trial_art.gd")
const GRASS = preload("res://environment/flower_placement.gd")
const HOMES := {
	0:[Vector2(1120,600)],1:[Vector2(650,650),Vector2(1050,410)],
	2:[Vector2(720,350)],3:[Vector2(1000,520)],4:[Vector2(580,430)],
}
var game: Node
var piles: Array[Dictionary] = []
var records: Dictionary = {}
var active_area := -1

func _ready() -> void:
	name = "FallenWood"
	z_index = -1
	sync_area()

func sync_area() -> void:
	visible = game.world == 0 and not game.underground and game.flight == 0 and not game.earth_transition
	if game.flight != 0 or game.earth_transition: return
	var area: int = game.area_id()
	if area == active_area: return
	if game.world == 0 and game.current_region() > 0 and not game.underground and not game.earth_stream.textures.has(game.regions().key(game.current_region(),false)): return
	if active_area >= 0: records[active_area] = piles
	piles = []
	active_area = area
	if not visible:
		queue_redraw()
		return
	if records.has(area):
		piles = records[area]
	else:
		var painting: Texture2D = game.green_surface.get_node("Ground").texture if game.earth_region == 0 else game.earth_stream.textures[game.EARTH.key(game.earth_region,false)]
		var placement := GRASS.new(painting,game.EARTH.SIZE,clear_floor)
		for home in HOMES[game.earth_region]:
			var preferred: Vector2 = game.EARTH.from_art(home)
			var point := Vector2.INF
			for offset in [Vector2.ZERO,Vector2(-180,0),Vector2(180,0),Vector2(0,-180),Vector2(0,180),Vector2(-300,-160),Vector2(300,160)]:
				point = placement.place(preferred+offset,0.12)
				if point.is_finite(): break
			if point.is_finite(): piles.append({"position":point,"pose":(game.earth_region+piles.size())%3,"collected":false,"seen":false,"fade":0.0})
	queue_redraw()

func clear_floor(point: Vector2) -> bool:
	if not game.gardens.clear_floor(point): return false
	if game.earth_region == 0 and game.ORE_SPAWNS.starting_view(Vector2(560,550)).grow(45).has_point(point): return false
	for plant in game.gardens.plants:
		if point.distance_to(plant.position) < 115: return false
	for pile in piles:
		if point.distance_to(pile.position) < 120: return false
	return true

func nearest() -> int:
	if not visible or active_area != game.area_id(): return -1
	var best := -1
	var distance := 85.0
	for i in piles.size():
		if piles[i].collected or not piles[i].seen: continue
		var d: float = game.player.distance_to(piles[i].position)
		if d < distance:
			distance = d
			best = i
	return best

func collect_nearby() -> bool:
	if game.trial.blocked(): return false
	var i := nearest()
	if i < 0: return false
	piles[i].collected = true
	game.trial.wood += 1
	game.message = "Wood collected! Sword recipe: 3 copper + 2 wood. Craft it at Earth camp."
	queue_redraw()
	return true

func _process(delta: float) -> void:
	if not visible or game.trial.blocked(): return
	for pile in piles:
		if not pile.seen: pile.seen = game.fog.is_revealed(active_area,pile.position)
		if pile.seen: pile.fade = minf(1,pile.fade+delta/0.75)
	queue_redraw()

func _draw() -> void:
	for pile in piles:
		if pile.collected or not pile.seen: continue
		var texture: Texture2D = ART.wood(pile.pose)
		var size := texture.get_size()*64.0/texture.get_width()
		var alpha := smoothstep(0,1,float(pile.fade))
		draw_set_transform(pile.position+Vector2(0,18),0,Vector2(1,0.3))
		draw_circle(Vector2.ZERO,27,Color(0.1,0.1,0.03,0.14*alpha))
		draw_set_transform(pile.position)
		draw_texture_rect(texture,Rect2(Vector2(-size.x*0.5,20-size.y),size),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)
