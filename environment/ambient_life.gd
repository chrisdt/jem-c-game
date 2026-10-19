extends Node2D

const CREATURE = preload("res://environment/ambient_creature.gd")
const EARTH = preload("res://earth_regions.gd")
const MOSS = preload("res://mine_layout.gd")
const FROST = preload("res://frost_layout.gd")
const DESERT = preload("res://desert_layout.gd")
const SCALE := Vector2(2000.0/1500.0,1400.0/1050.0)
const SURFACE_HOMES := {
	1:[
		[Vector2(340,550),Vector2(500,720),Vector2(1090,400),Vector2(1160,620)],
		[Vector2(590,340),Vector2(750,450),Vector2(650,660),Vector2(1100,505)],
		[Vector2(430,510),Vector2(600,220),Vector2(800,500),Vector2(820,770)],
		[Vector2(390,300),Vector2(420,560),Vector2(760,520),Vector2(1100,520)],
		[Vector2(440,420),Vector2(750,380),Vector2(430,650),Vector2(1050,650)],
	],
	2:[
		[Vector2(260,400),Vector2(400,790),Vector2(1200,410),Vector2(1150,665)],
		[Vector2(450,340),Vector2(850,500),Vector2(650,700),Vector2(1100,430)],
		[Vector2(350,315),Vector2(830,310),Vector2(350,700),Vector2(1120,800)],
		[Vector2(800,350),Vector2(1050,480),Vector2(600,750),Vector2(1150,900)],
		[Vector2(300,430),Vector2(650,450),Vector2(550,800),Vector2(1250,630)],
	],
}
const ALIEN_MINE_HOMES := {
	1:{0:[Vector2(520,420),Vector2(1030,400)],1:[Vector2(420,460),Vector2(1050,580)],4:[Vector2(580,450),Vector2(950,490)]},
	2:{0:[Vector2(420,460),Vector2(1230,530)],1:[Vector2(300,500),Vector2(1200,420)],4:[Vector2(600,390),Vector2(1000,330)]},
}
const RAT_HOMES := {
	0:[Vector2(350,440),Vector2(650,850)],
	1:[Vector2(750,700),Vector2(300,590)],
	4:[Vector2(370,680),Vector2(930,550)],
}
const BAT_HOMES := {
	0:[Vector2(500,350),Vector2(820,210),Vector2(1270,470)],
	1:[Vector2(350,450),Vector2(750,130),Vector2(1270,585)],
	4:[Vector2(560,500),Vector2(820,310),Vector2(1200,270)],
}
# Keep the small Moss Mine rat on the dry gallery above the painted foreground
# ledge. The ledge's visible rock cap extends beyond the player floor outline.
const RAT_BOUNDS := {0:[Rect2(280,400,220,60),Rect2()]}
var area_key := ""
var creatures: Array[Node2D] = []
var spawn_slot := 0

static func floor_at(world: int, region: int, cave: bool, point: Vector2, catalog) -> bool:
	if region > 0: return catalog.floor_contains(region,cave,point)
	if world == 0: return cave and MOSS.floor_contains(point)
	if world == 1: return FROST.floor_contains(point,cave)
	return DESERT.floor_contains(point,cave) and DESERT.deposit_floor_clear(point,cave)

static func add_to(parent: Node2D, world: int, region: int, cave: bool, catalog, game: Node) -> Node2D:
	if world == 0 and not cave: return null
	var habitat := new()
	habitat.name = "AmbientLife"
	parent.add_child(habitat)
	habitat.populate(world,region,cave,catalog,game)
	return habitat

func clear() -> void:
	if area_key.is_empty(): return
	for child in get_children():
		remove_child(child)
		child.free()
	creatures.clear()
	spawn_slot = 0
	area_key = ""

func populate(world: int, region: int, cave: bool, catalog, game: Node) -> void:
	var key := "%d/%d/%s" % [world,region,cave]
	if key == area_key: return
	clear()
	area_key = key
	y_sort_enabled = true
	if world == 0 and not cave: return
	var landmarks: Array[Vector2] = []
	if cave:
		landmarks.append(catalog.MINE_EXITS[region])
	else:
		for link in catalog.LINKS[region]: landmarks.append(catalog.portal(region,link.side))
		if catalog.has_mine(region): landmarks.append(catalog.MINE_ENTRANCES[region])
		if region == 0:
			landmarks.append(Vector2(570,1060) if world == 1 else DESERT.CAMP)
			landmarks.append(Vector2(260,1070) if world == 1 else DESERT.SHIP)
	if world == 0:
		for home in RAT_HOMES[region]:
			add_creature(CREATURE.Kind.RAT,home,world,region,cave,catalog,game,landmarks)
		for home in BAT_HOMES[region]:
			add_creature(CREATURE.Kind.BAT,home,world,region,cave,catalog,game,landmarks)
	else:
		var homes: Array = ALIEN_MINE_HOMES[world][region] if cave else SURFACE_HOMES[world][region]
		for home in homes:
			add_creature(CREATURE.Kind.FROSTLING if world == 1 else CREATURE.Kind.DUNE_SPRITE,home,world,region,cave,catalog,game,landmarks)

func add_creature(kind: int, home: Vector2, world: int, region: int, cave: bool, catalog, game: Node, landmarks: Array[Vector2]) -> void:
	var slot := spawn_slot
	spawn_slot += 1
	var mine_id: int = catalog.MINE_IDS[region] if cave else -1
	if world == 0 and cave and is_instance_valid(game) and game.has_method("area_id"):
		if game.scared_wildlife.get(mine_id,{}).has(slot): return
	var creature := CREATURE.new()
	creature.name = "Creature%d" % creatures.size()
	creature.kind = kind
	creature.scare_id = slot
	creature.scare_area = mine_id
	creature.hostile = world == 0 and cave and is_instance_valid(game) and is_instance_valid(game.get("trial"))
	if creature.hostile:
		creature.health = game.trial.mine_health.get(mine_id,{}).get(slot,creature.max_health())
	creature.position = home*SCALE
	creature.cave = cave
	creature.game = game
	creature.wander_radius = 125.0 if cave else 175.0
	if kind == CREATURE.Kind.RAT and RAT_BOUNDS.has(region):
		var bounds: Rect2 = RAT_BOUNDS[region][RAT_HOMES[region].find(home)]
		creature.wander_bounds = Rect2(bounds.position*SCALE,bounds.size*SCALE)
	creature.landmarks = landmarks
	creature.terrain = func(point: Vector2) -> bool: return floor_at(world,region,cave,point,catalog)
	add_child(creature)
	creatures.append(creature)
