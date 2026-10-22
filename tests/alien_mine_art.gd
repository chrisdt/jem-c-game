extends SceneTree
const CREATURE = preload("res://environment/ambient_creature.gd")
const ART = preload("res://environment/alien_mine_art.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)
func run() -> void:
	var clips := 0
	for world in [1,2]:
		for kind in [CREATURE.Kind.RAT,CREATURE.Kind.BAT]:
			var actor := CREATURE.new()
			actor.kind = kind
			actor.mine_world = world
			root.add_child(actor)
			actor.set_process(false)
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				actor.facing = direction
				var seen := {}
				for pose in 4:
					# Explicit pose selection tests the complete approved sheet,
					# including vertical movement which used to switch to Earth art.
					ART.apply(actor.sprite,world,kind == CREATURE.Kind.BAT,direction,pose,1.0)
					check(actor.sprite.texture.atlas == ART.ATLAS,"Alien switched back to Earth's creature sheet")
					seen[actor.sprite.texture.region] = true
					var row: int = (world-1)*2+int(kind == CREATURE.Kind.BAT)
					var scale := ART.ATLAS.get_size()/ART.SOURCE_SIZE
					var anchor_y: float = (ART.ANCHORS[row][pose].y-ART.CROPS[row][pose].position.y)*scale.y
					check(absf(anchor_y-actor.sprite.texture.get_height()*0.5+actor.sprite.offset.y) < 0.1,"Animation pose moved away from its foot/body anchor")
					check(actor.sprite.flip_h == (direction.x < 0) if direction.x != 0 else true,"Alien facing flipped incorrectly")
					if actor.sprite.material != null: clips += 1
				check(seen.size() == 4,"Alien animation repeated a single static pose")
			actor.kind = kind
			actor.elapsed = 0
			actor.walk_distance = 0
			actor.state = "walk"
			actor.update_pose()
			var first: Rect2 = actor.sprite.texture.region
			actor.elapsed = 0.2
			actor.walk_distance = 10
			actor.update_pose()
			check(actor.sprite.texture.region != first,"Alien walk/flap cycle did not animate")
			actor.free()
	check(clips == 8,"Wing corner clips were not applied to all directions")
	if failures == 0: print("PASS: four distinct alien species, 16 cropped poses, stable anchors, left/right/up/down keep alien art, walk/flap animation and unclipped wing silhouettes")
	quit(1 if failures else 0)
