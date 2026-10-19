extends Node2D

const ART = preload("res://environment/earth_animal_art.gd")
const FACING = preload("res://environment/wildlife_facing.gd")
const GRID_MESH = preload("res://environment/wind_mesh.gd")
const TAIL = preload("res://shaders/dog_tail.gdshader")
const EARTH = preload("res://earth_regions.gd")
const MOSS = preload("res://mine_layout.gd")
const GROUND = preload("res://ore_spawns.gd")
const HOME := Vector2(610,400) / EARTH.ART_SIZE * EARTH.SIZE
const GRID := 24.0
const FOLLOW_DISTANCE := 76.0
const FIND_DISTANCE := 95.0
const SIT_DELAY := 0.65

var game: Node
var recruited := false
var area_key := ""
var facing := Vector2.DOWN
var state := "sit"
var elapsed := 0.0
var walk_distance := 0.0
var still_seconds := 0.0
var excitement := 0.0
var last_player := Vector2.INF
var planned_goal := Vector2.INF
var repath_seconds := 0.0
var path := PackedVector2Array()
var path_index := 0
var navigation: AStarGrid2D
var pivot: Node2D
var illustration: MeshInstance2D
var tail: ShaderMaterial
var current_frame := 0

func _ready() -> void:
	name = "Buddy"
	pivot = Node2D.new()
	add_child(pivot)
	illustration = MeshInstance2D.new()
	illustration.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pivot.add_child(illustration)
	tail = ShaderMaterial.new()
	tail.shader = TAIL
	illustration.material = tail
	update_pose()
	hide()

func sync_area() -> void:
	visible = game.world == 0 and game.flight == 0 and not game.earth_transition and (recruited or (game.earth_region == 1 and not game.underground))
	if game.world != 0:
		area_key = ""
		navigation = null
		path.clear()
	if not visible: return
	var key := "%d/%s" % [game.earth_region,game.underground]
	if key == area_key: return
	var point: Vector2 = HOME
	if recruited:
		var direction := Vector2.UP if game.facing == &"up" else (Vector2.DOWN if game.facing == &"down" else (Vector2.LEFT if game.facing_left else Vector2.RIGHT))
		point = game.player-direction*60
	point = nearest_clear(point)
	if not point.is_finite():
		hide()
		return
	area_key = key
	position = point
	facing = Vector2.DOWN
	last_player = game.player
	still_seconds = 0
	state = "idle" if recruited else "sit"
	navigation = null
	path.clear()
	path_index = 0
	planned_goal = Vector2.INF
	repath_seconds = 0
	update_pose()

func _process(delta: float) -> void:
	advance(delta)

func floor_at(point: Vector2) -> bool:
	if not Rect2(Vector2(12,12),EARTH.SIZE-Vector2(24,24)).has_point(point): return false
	if game.earth_region > 0: return EARTH.floor_contains(game.earth_region,game.underground,point)
	if game.underground: return MOSS.floor_contains(point)
	return GROUND.can_walk(0,false,point) and GROUND.green_ground(point)

func can_stand(point: Vector2, avoid_ore := true) -> bool:
	for offset in [Vector2.ZERO,Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		if not floor_at(point+offset*7): return false
	if avoid_ore:
		for rock in game.rocks:
			if rock.cave == game.underground and rock.hp > 0 and point.distance_to(rock.pos) < 62: return false
	return true

func clear_route(start: Vector2, finish: Vector2, avoid_ore := true) -> bool:
	var steps := maxi(1,ceili(start.distance_to(finish)/4.0))
	for i in range(1,steps+1):
		if not can_stand(start.lerp(finish,float(i)/steps),avoid_ore): return false
	return true

func nearest_clear(point: Vector2) -> Vector2:
	if can_stand(point): return point
	for ring in range(1,10):
		for ray in 16:
			var candidate := point+Vector2.from_angle(TAU*ray/16)*ring*12
			if can_stand(candidate): return candidate
	return Vector2.INF

func build_navigation() -> void:
	navigation = AStarGrid2D.new()
	navigation.region = Rect2i(0,0,ceili(EARTH.SIZE.x/GRID),ceili(EARTH.SIZE.y/GRID))
	navigation.cell_size = Vector2.ONE*GRID
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.update()
	for y in navigation.region.size.y:
		for x in navigation.region.size.x:
			var cell := Vector2i(x,y)
			navigation.set_point_solid(cell,not can_stand(Vector2(cell)*GRID))

func nearby_cell(point: Vector2) -> Vector2i:
	var centre := Vector2i((point/GRID).round())
	for ring in range(4):
		for y in range(-ring,ring+1):
			for x in range(-ring,ring+1):
				var cell := centre+Vector2i(x,y)
				if navigation.is_in_boundsv(cell) and not navigation.is_point_solid(cell) and clear_route(point,Vector2(cell)*GRID): return cell
	return Vector2i(-1,-1)

func plan_route(goal: Vector2) -> void:
	planned_goal = goal
	repath_seconds = 0.35
	path.clear()
	path_index = 0
	if clear_route(position,goal):
		path.append(goal)
		return
	if navigation == null: build_navigation()
	var first := nearby_cell(position)
	var last := nearby_cell(goal)
	if first.x < 0 or last.x < 0: return
	path = navigation.get_point_path(first,last)
	if not path.is_empty() and clear_route(path[-1],goal): path.append(goal)

func advance(delta: float) -> void:
	sync_area()
	if not is_visible_in_tree() or game.planet_menu.visible: return
	delta = maxf(0,delta)
	elapsed += delta
	excitement = maxf(0,excitement-delta)
	if not recruited:
		state = "sit"
		if position.distance_to(game.player) <= FIND_DISTANCE and clear_route(position,game.player,false) and game.fog.is_revealed(game.area_id(),position):
			recruited = true
			excitement = 3.0
			game.message = "You found Buddy! He'll follow you around Earth. Stop walking and he'll sit nearby."
		update_pose()
		queue_redraw()
		return
	var player_moved: bool = not last_player.is_finite() or last_player.distance_to(game.player) > 0.1
	still_seconds = 0.0 if player_moved else still_seconds+delta
	last_player = game.player
	repath_seconds = maxf(0,repath_seconds-delta)
	var goal := nearest_clear(game.player)
	var near: bool = goal.is_finite() and position.distance_to(game.player) <= FOLLOW_DISTANCE and clear_route(position,goal,false)
	var before := position
	if not near and goal.is_finite():
		if repath_seconds <= 0 and (path_index >= path.size() or planned_goal.distance_to(goal) > 18): plan_route(goal)
		var remaining: float = delta*game.SPEED*1.15
		while remaining > 0.001 and path_index < path.size():
			var next := position.move_toward(path[path_index],minf(remaining,4.0))
			if not clear_route(position,next):
				path.clear()
				path_index = 0
				repath_seconds = 0
				break
			var distance := position.distance_to(next)
			facing = FACING.from_movement(next-position,facing)
			position = next
			walk_distance += distance
			remaining -= distance
			if position.distance_to(path[path_index]) < 0.01: path_index += 1
			if position.distance_to(game.player) <= FOLLOW_DISTANCE and clear_route(position,goal,false): break
	var travelled := before.distance_to(position)
	state = "walk" if travelled > 0.001 else ("sit" if still_seconds >= SIT_DELAY else "idle")
	if near:
		path.clear()
		path_index = 0
	update_pose()
	queue_redraw()

func update_pose() -> void:
	var sitting := state == "sit"
	current_frame = int(elapsed*(9.0 if excitement > 0 else 5.0))%4 if sitting else (int(walk_distance/9.0)%4 if state == "walk" else 0)
	var art := ART.pose(ART.Species.DOG,facing,current_frame,sitting)
	var texture: AtlasTexture = art.texture
	var scale_factor: float = art.scale
	pivot.scale.x = -1 if facing.x < 0 else 1
	illustration.texture = texture.atlas
	illustration.mesh = GRID_MESH.make(texture.region.size)
	illustration.position = -(art.anchor-texture.region.position)*scale_factor
	illustration.scale = Vector2.ONE*scale_factor
	tail.set_shader_parameter("atlas_origin",texture.region.position/texture.atlas.get_size())
	tail.set_shader_parameter("atlas_size",texture.region.size/texture.atlas.get_size())
	tail.set_shader_parameter("tail_base",[Vector2(0.34,0.50),Vector2(0.50,0.30),Vector2(0.53,0.58)][art.row])
	tail.set_shader_parameter("tail_tip",[Vector2(0.15,0.20),Vector2(0.50,0.05),Vector2(0.78,0.43)][art.row])
	tail.set_shader_parameter("wag_phase",elapsed*(14.0 if excitement > 0 else 9.0))
	tail.set_shader_parameter("wag_amount",0.0 if sitting else 18.0)

func _draw() -> void:
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,17,Color(0.08,0.14,0.06,0.14))
	draw_set_transform(Vector2.ZERO)
	if excitement > 0:
		var lift := Vector2(0,-52-sin(elapsed*4)*2)
		var heart := PackedVector2Array([Vector2(0,5),Vector2(-7,-1),Vector2(-7,-5),Vector2(-3,-7),Vector2(0,-4),Vector2(3,-7),Vector2(7,-5),Vector2(7,-1)])
		for i in heart.size(): heart[i] += lift
		draw_colored_polygon(heart,Color(1.0,0.48,0.38,minf(excitement,1.0)))
