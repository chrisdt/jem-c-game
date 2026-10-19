extends Node2D

const EARTH = preload("res://earth_regions.gd")
const ANIMAL = preload("res://environment/pasture_animal.gd")
const ART = preload("res://environment/earth_animal_art.gd")
const HOMES := {
	1:[Vector3(650,340,ART.Species.SHEEP),Vector3(1020,650,ART.Species.SHEEP)],
	2:[Vector3(650,330,ART.Species.COW),Vector3(1260,755,ART.Species.COW)],
	3:[Vector3(500,400,ART.Species.SHEEP),Vector3(960,650,ART.Species.SHEEP),Vector3(750,700,ART.Species.SHEEP),Vector3(1050,470,ART.Species.COW)],
}
var grass: Image
var region := 1
var creatures: Array[Node2D] = []

static func add_to(parent: Node2D, district: int, painting: Texture2D, game: Node) -> Node2D:
	if not HOMES.has(district): return null
	var habitat := new()
	habitat.name = "EarthPastures"
	habitat.region = district
	habitat.grass = painting.get_image()
	if habitat.grass.is_compressed(): habitat.grass.decompress()
	# Area averaging suppresses tiny painted highlights before classifying grass.
	habitat.grass.resize(128,90,Image.INTERPOLATE_TRILINEAR)
	parent.add_child(habitat)
	habitat.y_sort_enabled = true
	var landmarks: Array[Vector2] = []
	for link in EARTH.LINKS[district]: landmarks.append(EARTH.portal(district,link.side))
	if EARTH.has_mine(district): landmarks.append(EARTH.MINE_ENTRANCES[district])
	for home in HOMES[district]:
		var animal := ANIMAL.new()
		animal.species = int(home.z)
		animal.name = ("Sheep" if animal.species == ART.Species.SHEEP else "Cow")+str(habitat.creatures.size()+1)
		animal.position = EARTH.from_art(Vector2(home.x,home.y))
		animal.game = game
		animal.wander_radius = 125
		animal.landmarks = landmarks
		animal.terrain = habitat.grass_at
		habitat.add_child(animal)
		habitat.creatures.append(animal)
		animal.advance(0)
	return habitat

func grass_at(point: Vector2) -> bool:
	if not EARTH.floor_contains(region,false,point): return false
	for tree in EARTH.TREES[region]:
		if point.distance_to(EARTH.from_art(Vector2(tree.x,tree.y))) < 65: return false
	var pixel := Vector2i(point/EARTH.SIZE*Vector2(grass.get_size())).clamp(Vector2i.ZERO,grass.get_size()-Vector2i.ONE)
	# Small painted flowers and dry flecks belong to the same grassy patch;
	# a majority footprint keeps them from trapping an animal on one pixel.
	var green := 0
	for offset in [Vector2i.ZERO,Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		var colour := grass.get_pixelv((pixel+offset).clamp(Vector2i.ZERO,grass.get_size()-Vector2i.ONE))
		if colour.g > colour.r+0.035 and colour.g > colour.b*1.25: green += 1
	return green >= 3
