shader_type canvas_item;

uniform vec2 atlas_origin;
uniform vec2 atlas_size;
uniform vec2 tail_base;
uniform vec2 tail_tip;
uniform float wag_phase = 0.0;
uniform float wag_amount = 18.0;
varying vec4 dog_tint;

void vertex() {
	dog_tint = COLOR;
	vec2 axis = tail_tip-tail_base;
	float along = clamp(dot(UV-tail_base,axis)/max(dot(axis,axis),0.001),0.0,1.0);
	float distance_to_tail = length(UV-(tail_base+axis*along));
	float weight = smoothstep(0.05,0.9,along)*(1.0-smoothstep(0.08,0.18,distance_to_tail));
	vec2 sideways = normalize(vec2(-axis.y,axis.x));
	VERTEX += sideways*sin(wag_phase)*wag_amount*weight;
}

void fragment() {
	COLOR = dog_tint*texture(TEXTURE,atlas_origin+clamp(UV,vec2(0.001),vec2(0.999))*atlas_size);
}
