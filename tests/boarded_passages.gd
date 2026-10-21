extends SceneTree

const BOARDS = preload("res://environment/boarded_passages.gd")
const EARTH = preload("res://earth_regions.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func run() -> void:
	# Check the actual imported texture, not just the doorway rectangles. An
	# original-size crop on the size-limited sign previously rendered fragments.
	var plank: AtlasTexture = BOARDS.plank_texture()
	check(Rect2(Vector2.ZERO,BOARDS.WOOD.get_size()).encloses(plank.region),"Board crop lies outside the imported wood texture")
	var wood := BOARDS.WOOD.get_image()
	for row in 5:
		for col in 21:
			var sample: Vector2 = plank.region.position+plank.region.size*Vector2((col+0.5)/21.0,(row+0.5)/5.0)
			check(wood.get_pixelv(Vector2i(sample)).a > 0.95,"Door plank contains missing or transparent wood")
	# Each reviewed decorative opening is closed without changing floor data or
	# accidentally covering the real, light-filled route back to the surface.
	for region in [0,1,4]:
		var doors := BOARDS.doors_for(0,region,true)
		check(doors.size() == {0:10,1:13,4:9}[region],"A reviewed decorative mine doorway is missing boarding")
		var exit: Vector2 = EARTH.MINE_EXITS[region]/EARTH.SIZE*EARTH.ART_SIZE
		var bright_exit: Rect2 = {0:Rect2(15,335,170,150),1:Rect2(660,810,180,145),4:Rect2(65,750,170,175)}[region]
		for opening: Rect2 in doors:
			check(Rect2(Vector2.ZERO,EARTH.ART_SIZE).encloses(opening),"Door boarding lies outside its painting")
			check(not opening.grow(55).has_point(exit),"Boarding covers a functional surface exit")
			check(not opening.intersects(bright_exit),"Boarding covers part of the bright exit illustration")
		check(BOARDS.doors_for(0,region,false).is_empty(),"Boarding appears across an exterior mine entrance")
		var rubble := BOARDS.rubble_for(0,region,true)
		check(rubble.size() == (5 if region == 0 else 0),"A natural rail working is missing its rubble closure")
		for opening: Rect2 in rubble:
			check(Rect2(Vector2.ZERO,EARTH.ART_SIZE).encloses(opening),"Rubble is outside its mine painting")
			check(not opening.grow(55).has_point(exit) and not opening.intersects(bright_exit),"Rubble covers the functional surface exit")
		check(BOARDS.rubble_for(0,region,false).is_empty(),"Rubble covers an exterior mine entrance")
		for world in [1,2]: check(BOARDS.doors_for(world,region,true).is_empty(),"Earth boarding leaked onto another planet")
		for world in [1,2]: check(BOARDS.rubble_for(world,region,true).is_empty(),"Earth rubble leaked onto another planet")
	var rocks: AtlasTexture = BOARDS.rubble_texture()
	check(Rect2(Vector2.ZERO,BOARDS.ROCKS.get_size()).encloses(rocks.region),"Rubble crop escapes its imported texture")
	var foot := Vector2i(rocks.region.position+rocks.region.size*Vector2(0.5,0.88))
	check(BOARDS.ROCKS.get_image().get_pixelv(foot).a > 0.5,"Rubble floats above its contact point")
	for region in [2,3]: check(BOARDS.doors_for(0,region,true).is_empty(),"Boarding was placed in a district without a mine")
	if failures == 0: print("PASS: resized board crop is opaque across 105 samples, 32 decorative Earth mine doors boarded, five natural rail workings closed with grounded rubble, all three real surface exits and exterior entrances clear, no off-world closures")
	quit(1 if failures else 0)
