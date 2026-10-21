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
		for world in [1,2]: check(BOARDS.doors_for(world,region,true).is_empty(),"Earth boarding leaked onto another planet")
	for region in [2,3]: check(BOARDS.doors_for(0,region,true).is_empty(),"Boarding was placed in a district without a mine")
	if failures == 0: print("PASS: 32 decorative Earth mine doors boarded; all three real surface exits and every exterior entrance remain clear; no off-world boarding")
	quit(1 if failures else 0)
