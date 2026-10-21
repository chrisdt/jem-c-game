extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const ART = preload("res://environment/trial_art.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func arrive(game, point: Vector2) -> void:
	game.player = point
	game.scout.position = point
	game.cooldown = 0
	game.update_exploration()
	game.refresh_ui()
	game.story._process(0.8)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.story.set_process(false)
	game.companion.set_process(false)
	game.gardens.set_process(false)
	game.trial.invulnerable = 10000
	var wood: Texture2D = ART.wood()
	check(game.hud.material_icons[2].texture == wood,"Wood inventory and pickup use different illustrations")
	var footprint: Rect2 = game.wood_supplies.pickup_rect()
	check(footprint.size.x <= 40 and footprint.size.y <= 22,"Wood pickup is still an oversized upright icon")
	check(footprint.has_point(Vector2.ZERO) and footprint.end.y < 6,"Wood's contact point is separated from the log")
	var wood_image := wood.get_image()
	var contact := Vector2i(Vector2(wood_image.get_size())*Vector2(0.5,0.78))
	check(wood_image.get_pixelv(contact).a > 0.5,"The wood illustration is transparent at its ground contact")
	var found := 0
	for region in 5:
		await TRAVEL.enter(game,region,false)
		check(game.hud.material_icons[2].texture == wood,"Changing Earth districts changes the wood icon")
		for pile in game.wood_supplies.piles:
			arrive(game,pile.position)
			game.wood_supplies._process(0.8)
			var before: int = game.trial.wood
			check(game.wood_supplies.collect_nearby() and game.trial.wood == before+1,"Smaller wood cannot be collected at ground level")
			check(not game.wood_supplies.collect_nearby(),"Grounded wood can be collected twice")
			found += 1
	check(found == 6,"The visual wood change removed story crafting supplies")
	game.story.quarry_open = false
	await TRAVEL.enter(game,1,false)
	check(game.story.props.has("seals"),"Seal kit is absent from Pinewood's campsite")
	if game.story.props.has("seals"):
		var kit: Sprite2D = game.story.props.seals
		check(kit.position.distance_to(Vector2(410,278)) < 1,"Seal kit is not beside the requested tent")
		check(kit.get_rect().has_point(Vector2.ZERO) and kit.get_rect().size.y*kit.scale.y < 25,"Seal kit is still an upright floating illustration")
		arrive(game,kit.position+Vector2(45,0))
		game.interact()
		check(game.story.seal_kit and not game.story.props.seals.visible,"Campsite kit cannot be recovered through the normal action")
	# The opaque body of the cropped rockfall must cover the entire arrow sign.
	var spec: Dictionary = game.story.PROPS.rockfall
	var rockfall: Sprite2D = game.story.props.rockfall
	var image := rockfall.texture.get_image()
	check(spec.foot.x+spec.width*0.5 > game.EARTH.SIZE.x,"Rockfall is not cropped at the map edge")
	for y in range(570,635,6):
		for x in range(1800,1980,6):
			var local: Vector2 = (Vector2(x,y)-rockfall.position)/rockfall.scale-rockfall.offset
			var pixel := Vector2i(local)
			check(Rect2i(Vector2i.ZERO,image.get_size()).has_point(pixel) and image.get_pixelv(pixel).a > 0.5,"The quarry sign protrudes around the rockfall")
	var approach: Vector2 = game.story.interaction_position("rockfall")+Vector2(-60,-30)
	arrive(game,approach)
	check(not game.story.ROCKFALL_BARRIER.has_point(approach) and game.story.floor_at(approach,1,false),"Rockfall requires standing inside blocked rock to drill")
	check(game.story.nearest_prop() == "rockfall" and game.nearest_npc() == null,"Otis or another prop steals the clear-side drilling prompt")
	check(game.story.prop_reach("rockfall") <= 105 and approach.distance_to(game.story.interaction_position("rockfall")) < 105,"Rockfall uses an oversized invisible interaction halo")
	game.upgraded = true
	game.interact()
	game.story.advance_actions(2.1)
	check(game.story.quarry_open,"Cropped rockfall cannot be drilled from clear ground")
	await TRAVEL.enter(game,0,true)
	check(not game.story.props.has("seals"),"Seal kit still appears in Moss Mine")
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: one shared wood illustration, small ground-contact pickups, six normally collectible supplies, reachable Pinewood campsite seal kit, low-profile gear, fully obscured quarry sign and cropped rockfall drillable from clear ground")
	quit(1 if failures else 0)
