extends Node2D

const ART = preload("res://environment/trial_art.gd")
const MESH = preload("res://environment/wind_mesh.gd")
const WIND: Shader = preload("res://shaders/trial_leaves.gdshader")
var trial: Node
var apple := false
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

func update_art() -> void:
	var texture: AtlasTexture = ART.plant(apple,picked)
	var scale_factor := 0.31 if apple else 0.20
	# MeshInstance2D samples the source sheet directly; map its local grid UVs
	# to this atlas region instead of relying on Sprite2D's atlas handling.
	illustration.texture = ART.PLANTS
	var bounds := texture.region
	var sheet_size := ART.PLANTS.get_size()
	leaves.set_shader_parameter("frame_region",Vector4(bounds.position.x/sheet_size.x,bounds.position.y/sheet_size.y,bounds.size.x/sheet_size.x,bounds.size.y/sheet_size.y))
	illustration.mesh = MESH.make(texture.get_size())
	illustration.scale = Vector2.ONE*scale_factor
	illustration.position = -ART.plant_anchor(apple,picked)*scale_factor+Vector2(0,20)

func advance(delta: float, seconds: float) -> void:
	if not discovered:
		discovered = trial.game.fog.is_revealed(0,position)
	if discovered:
		fade = minf(1,fade+delta/0.75)
	modulate.a = smoothstep(0,1,fade)
	rustle = maxf(0,rustle-delta)
	leaves.set_shader_parameter("seconds",seconds)
	leaves.set_shader_parameter("strength",2.0+rustle*14.0)
	if discovered and not picked and trial.health < trial.MAX_HEALTH and trial.game.player.distance_to(position) < (65.0 if apple else 48.0):
		collect()

func collect() -> bool:
	if picked or not discovered or not trial.is_active() or trial.blocked() or trial.health >= trial.MAX_HEALTH:
		return false
	if trial.game.player.distance_to(position) >= (65.0 if apple else 48.0): return false
	var amount := 4 if apple else 2
	if trial.heal(amount) <= 0: return false
	picked = true
	rustle = 0.5
	update_art()
	trial.add_heal_effect(position,2 if apple else 1)
	trial.game.message = "Apples restore two hearts." if apple else "Berries restore one heart."
	return true
