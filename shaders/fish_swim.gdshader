shader_type canvas_item;

uniform vec2 atlas_origin = vec2(0.5, 0.5);
uniform sampler2D ground_texture : source_color;
varying vec4 fish_tint;
varying vec2 water_uv;

void vertex() {
	fish_tint = COLOR;
	float tail = 1.0 - smoothstep(0.15, 0.72, UV.x);
	VERTEX.y += 12.0 * tail * sin(TIME * 7.0 + UV.x * 7.0);
	water_uv = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy / vec2(2000.0, 1400.0);
}

void fragment() {
	COLOR = fish_tint * texture(TEXTURE, atlas_origin + UV * vec2(0.25, 0.5));
	// Swimming is below lily pads and shore stones; the separate jumping
	// sprite rises above the surface and does not use this water mask.
	vec3 ground = texture(ground_texture, water_uv).rgb;
	COLOR.a *= smoothstep(0.015, 0.065, min(ground.g, ground.b) - ground.r);
}
