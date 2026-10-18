shader_type canvas_item;

uniform vec2 atlas_origin = vec2(0.0);
uniform vec2 atlas_size = vec2(0.25, 0.5);
uniform float wind_strength : hint_range(0.0, 25.0) = 9.0;
uniform float wind_speed : hint_range(0.1, 3.0) = 1.0;
uniform float wind_phase = 0.0;
varying vec4 plant_tint;

void vertex() {
	plant_tint = COLOR;
	float height = clamp((0.90 - UV.y) / 0.72, 0.0, 1.0);
	float bend = pow(height, 1.5);
	float time = TIME * wind_speed;
	float breeze = sin(time * 1.1 + wind_phase);
	float tips = sin(time * 2.0 + UV.x * 15.0 + wind_phase) * height * 0.22;
	VERTEX.x += wind_strength * bend * (breeze + tips);
	VERTEX.y += wind_strength * bend * 0.12 * sin(time * 1.4 + UV.x * 12.0 + wind_phase);
}

void fragment() {
	COLOR = plant_tint * texture(TEXTURE, atlas_origin + UV * atlas_size);
}
