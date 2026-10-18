shader_type canvas_item;

uniform sampler2D revealed_mask : filter_linear, repeat_disable;
uniform sampler2D landscape : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform vec2 scout_position;
uniform float clear_radius = 210.0;
uniform float reveal_radius = 265.0;
uniform vec4 mist_colour : source_color = vec4(0.55, 0.64, 0.61, 1.0);
uniform float mist_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float blur_level : hint_range(0.0, 6.0) = 4.2;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float cloud_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 part = fract(point);
	part = part * part * (3.0 - 2.0 * part);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), part.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), part.x), part.y);
}

void fragment() {
	vec2 world = UV * vec2(2000.0, 1400.0);
	float remembered = texture(revealed_mask, UV).r;
	float nearby = 1.0 - smoothstep(clear_radius, reveal_radius, distance(world, scout_position));
	float revealed = max(remembered, nearby);
	vec2 drift = vec2(TIME * 0.025, TIME * -0.016);
	float clouds = cloud_noise(UV * vec2(9.0, 6.3) + drift);
	clouds += 0.45 * cloud_noise(UV * vec2(20.0, 14.0) - drift * 1.5);
	// Filtered screen mipmaps soften fine details without offset silhouettes.
	vec3 sharp = texture(landscape, SCREEN_UV).rgb;
	vec3 blurred = textureLod(landscape, SCREEN_UV, blur_level).rgb;
	vec3 misty_landscape = mix(blurred, mist_colour.rgb, clamp(mist_opacity + clouds * 0.08, 0.0, 1.0));
	// Ore is withheld by discovery logic, so translucency reveals only scenery.
	COLOR = vec4(mix(sharp, misty_landscape, 1.0 - revealed), 1.0);
}
