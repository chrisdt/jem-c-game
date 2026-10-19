shader_type canvas_item;

uniform sampler2D revealed_mask : filter_linear, repeat_disable;
uniform sampler2D landscape : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 scout_position;
uniform float clear_radius = 210.0;
uniform float reveal_radius = 265.0;
uniform vec4 mist_colour : source_color = vec4(0.55, 0.64, 0.61, 1.0);
uniform float mist_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float blur_radius : hint_range(0.0, 32.0) = 18.0;
uniform float blur_offset = 7.5;
uniform bool apply_tint = true;

float hash(vec2 point) {
	// Bounded arithmetic avoids large sine hashes that vary between GPU compilers.
	vec3 seed = fract(vec3(point.xyx) * 0.1031);
	seed += dot(seed, seed.yzx + 33.33);
	return fract((seed.x + seed.y) * seed.z);
}

float cloud_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 part = fract(point);
	part = part * part * (3.0 - 2.0 * part);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), part.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), part.x), part.y);
}

// Four bilinear taps per stage form a smooth, bounded Kawase blur. Earlier
// stages soften fine detail before later stages spread it, avoiding sparse-tap
// grain. Explicit BackBufferCopy nodes supply each stage's base-level screen.
vec3 soft_landscape(vec2 uv, vec2 span) {
	vec3 result = texture(landscape, uv + vec2(-span.x, -span.y)).rgb;
	result += texture(landscape, uv + vec2(span.x, -span.y)).rgb;
	result += texture(landscape, uv + vec2(-span.x, span.y)).rgb;
	result += texture(landscape, uv + vec2(span.x, span.y)).rgb;
	return result * 0.25;
}

void fragment() {
	vec2 world = UV * vec2(2000.0, 1400.0);
	float remembered = texture(revealed_mask, UV).r;
	float nearby = 1.0 - smoothstep(clear_radius, reveal_radius, distance(world, scout_position));
	float revealed = max(remembered, nearby);
	// Express the radius in world pixels, so Retina/device pixel ratios do not
	// change the amount of blur. Derivatives stay outside the divergent branch.
	vec2 world_per_pixel = vec2(length(dFdx(world)), length(dFdy(world)));
	vec2 span = SCREEN_PIXEL_SIZE * (blur_radius / 12.0) * blur_offset / max(world_per_pixel, vec2(0.001));
	vec3 sharp = texture(landscape, SCREEN_UV).rgb;
	if (revealed >= 0.999) {
		// Explored ground stays sharp and avoids all cloud/blur work.
		COLOR = vec4(sharp, 1.0);
	} else {
		vec3 misty_landscape = soft_landscape(SCREEN_UV, span);
		if (apply_tint) {
			vec2 drift = vec2(TIME * 0.025, TIME * -0.016);
			float clouds = cloud_noise(UV * vec2(9.0, 6.3) + drift);
			clouds += 0.45 * cloud_noise(UV * vec2(20.0, 14.0) - drift * 1.5);
			misty_landscape = mix(misty_landscape, mist_colour.rgb, clamp(mist_opacity + clouds * 0.08, 0.0, 1.0));
		}
		// Ore is withheld by discovery logic; translucency reveals only scenery.
		COLOR = vec4(mix(sharp, misty_landscape, 1.0 - revealed), 1.0);
	}
}
