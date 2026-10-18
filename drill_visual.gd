extends RefCounted

const ANCHORS = preload("res://assets/drill/anchors.gd")
const WALK := [preload("res://assets/drill/miner_walk.tres"), preload("res://assets/drill/scout_walk.tres")]
const MINING := [preload("res://assets/drill/miner_mining.tres"), preload("res://assets/drill/scout_mining.tres")]
const WALK_ANCHORS := [ANCHORS.MINER_WALK_ANCHORS, ANCHORS.SCOUT_WALK_ANCHORS]
const WALK_SCALES := [ANCHORS.MINER_WALK_SCALES, ANCHORS.SCOUT_WALK_SCALES]
const MINE_ANCHORS := [ANCHORS.MINER_MINING_ANCHORS, ANCHORS.SCOUT_MINING_ANCHORS]
const MINE_SCALES := [ANCHORS.MINER_MINING_SCALES, ANCHORS.SCOUT_MINING_SCALES]

static func fit(sprite: AnimatedSprite2D, space_suit: bool, mining: bool, direction: StringName) -> void:
	var outfit := int(space_suit)
	var scale: float = (MINE_SCALES if mining else WALK_SCALES)[outfit][direction]
	var frame := 1 if str(sprite.animation).begins_with("idle_") else sprite.frame
	var anchor: Vector2 = (MINE_ANCHORS if mining else WALK_ANCHORS)[outfit][direction][frame]
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	sprite.scale = Vector2.ONE * scale
	sprite.offset = texture.get_size() * 0.5 - anchor + Vector2(0,20.0 / scale)
	if sprite.flip_h:
		sprite.offset.x = -sprite.offset.x
