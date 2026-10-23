extends Node2D

const ART = preload("res://environment/trial_art.gd")
const WILD = preload("res://environment/wild_food_art.gd")
const MESH = preload("res://environment/wind_mesh.gd")
const WIND: Shader = preload("res://shaders/trial_leaves.gdshader")
var garden: Node
var apple := false
var wild_kind := -1
var picked := false
var discovered := false
var fade := 0.0
var rustle := 0.0
var illustration: MeshInstance2D
var leaves: ShaderMaterial

func _ready() -> void:
	illustration = MeshInstance2D.new()
	illustration.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaves = ShaderMaterial.new()
	leaves.shader = WIND
	leaves.set_shader_parameter("phase",position.x*0.01)
	illustration.material = leaves
	add_child(illustration)
	update_art()
	modulate.a = 0

func hearts() -> int:
	return WILD.HEARTS[wild_kind] if wild_kind >= 0 else (2 if apple else 1)

func collect_radius() -> float:
	return 65.0 if hearts() == 2 else 48.0

func update_art() -> void:
	var texture: AtlasTexture = WILD.frame(wild_kind,picked) if wild_kind >= 0 else ART.plant(apple,picked)
	var atlas: Texture2D = WILD.SHEET if wild_kind >= 0 else ART.PLANTS
	var scale_factor: float = WILD.HEIGHTS[wild_kind]/(texture.get_height()*0.875) if wild_kind >= 0 else (0.31 if apple else 0.20)
	var anchor: Vector2 = WILD.anchor() if wild_kind >= 0 else ART.plant_anchor(apple,picked)
	# MeshInstance2D samples the source sheet directly; remap grid UVs to the
	# atlas cell. Both food rows use the same ground contact and gentle wind.
	illustration.texture = atlas
	var bounds := texture.region
	var sheet_size := atlas.get_size()
	leaves.set_shader_parameter("frame_region",Vector4(bounds.position.x/sheet_size.x,bounds.position.y/sheet_size.y,bounds.size.x/sheet_size.x,bounds.size.y/sheet_size.y))
	illustration.mesh = MESH.make(texture.get_size())
	illustration.scale = Vector2.ONE*scale_factor
	illustration.position = -anchor*scale_factor+Vector2(0,20)
	queue_redraw()

func _draw() -> void:
	if wild_kind < 0: return
	# A light contact shadow seats the foliage on snow or sand without a tile.
	draw_set_transform(Vector2(0,20),0,Vector2(1,0.25))
	draw_circle(Vector2.ZERO,WILD.HEIGHTS[wild_kind]*0.30,Color(0.08,0.22,0.32,0.12) if wild_kind < 2 else Color(0.30,0.16,0.04,0.14))
	draw_set_transform(Vector2.ZERO)

func advance(delta: float, seconds: float) -> void:
	if not discovered:
		discovered = garden.game.fog.is_revealed(garden.active_area,position)
	if discovered:
		fade = minf(1,fade+delta/0.75)
	modulate.a = smoothstep(0,1,fade)
	rustle = maxf(0,rustle-delta)
	leaves.set_shader_parameter("seconds",seconds)
	leaves.set_shader_parameter("strength",2.0+rustle*14.0)
	if discovered and not picked and garden.game.trial.health < garden.game.trial.MAX_HEALTH and garden.game.player.distance_to(position) < collect_radius():
		collect()

func collect() -> bool:
	var trial: Node = garden.game.trial
	if picked or not discovered or garden.blocked() or trial.health >= trial.MAX_HEALTH:
		return false
	if garden.game.player.distance_to(position) >= collect_radius(): return false
	var amount := hearts()*2
	if trial.heal(amount) <= 0: return false
	picked = true
	if garden.game.world == 0 and is_instance_valid(garden.game.missions): garden.game.missions.fruit_used = true
	rustle = 0.5
	update_art()
	garden.add_heal_effect(position,hearts())
	garden.game.message = WILD.MESSAGES[wild_kind] if wild_kind >= 0 else ("Apples restore two hearts." if apple else "Berries restore one heart.")
	garden.game.refresh_ui()
	return true
