shader_type canvas_item;

uniform vec2 atlas_origin;
uniform vec2 atlas_size;
uniform vec2 cell_size;
uniform vec2 elbow = vec2(0.18,0.46);
uniform vec2 palm = vec2(0.115,0.31);
uniform float wave_angle = 0.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
	vec2 arm = palm-elbow;
	float along = clamp(dot(UV-elbow,arm)/dot(arm,arm),0.0,1.0);
	float distance_to_arm = distance(UV,elbow+along*arm);
	float weight = smoothstep(0.0,0.7,along);
	weight *= 1.0-smoothstep(0.095,0.16,distance_to_arm);
	weight *= smoothstep(0.17,0.23,UV.y);
	float angle = wave_angle*weight;
	vec2 relative = VERTEX-elbow*cell_size;
	VERTEX = elbow*cell_size+vec2(cos(angle)*relative.x-sin(angle)*relative.y,sin(angle)*relative.x+cos(angle)*relative.y);
}

void fragment() {
	COLOR = tint*texture(TEXTURE,atlas_origin+UV*atlas_size);
}
