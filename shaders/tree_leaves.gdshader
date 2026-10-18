shader_type canvas_item;

// The mesh bends real canopy edges; the texture itself never ripples.
// Trunks and shadows use separate, unanimated draw calls.
uniform vec2 atlas_origin = vec2(0.0);
uniform vec2 atlas_size = vec2(0.333333333, 0.5);
uniform float wind_strength : hint_range(0.0, 8.0) = 3.5;
uniform float wind_speed : hint_range(0.1, 3.0) = 1.0;
uniform float wind_phase = 0.0;
varying vec4 tree_tint;

void vertex() {
	tree_tint = COLOR;
	float time = TIME * wind_speed;
	// Canopy base stays attached to the branches. Soft spatial waves give
	// neighbouring leaf clusters slightly different motion within one crown.
	float flexible = 1.0 - smoothstep(0.30, 0.90, UV.y);
	float breeze = sin(time * 1.05 + wind_phase);
	float clusters = sin(UV.x * 16.0 + UV.y * 9.0 + wind_phase + time * 1.7);
	float flutter = sin(UV.x * 31.0 - UV.y * 23.0 + time * 2.8 + wind_phase);
	VERTEX.x += wind_strength * flexible * (breeze + 0.35 * clusters + 0.12 * flutter);
	VERTEX.y += wind_strength * flexible * 0.22 * sin(time * 1.4 + UV.x * 18.0 + wind_phase);
}

void fragment() {
	COLOR = tree_tint * texture(TEXTURE, atlas_origin + UV * atlas_size);
}
