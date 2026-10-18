shader_type canvas_item;

// A very light breeze for low plants in the ground plate. The separate tree
// canopies use tree_leaves.gdshader and never pass through this texture effect.
uniform float wind_strength_pixels : hint_range(0.0, 2.0) = 0.35;
uniform float wind_speed : hint_range(0.1, 3.0) = 1.0;
uniform float water_strength : hint_range(0.0, 2.0) = 0.8;

float foliage(vec3 colour) {
	return smoothstep(0.015, 0.12, colour.g - max(colour.r, colour.b));
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float breeze = sin(TIME * wind_speed * 1.35 + UV.x * 9.0 + UV.y * 18.0);
	breeze += 0.3 * sin(TIME * wind_speed * 2.1 + UV.y * 31.0);
	vec2 offset = vec2(breeze, 0.2 * sin(TIME * wind_speed + UV.x * 15.0));
	offset *= TEXTURE_PIXEL_SIZE * wind_strength_pixels;
	vec4 swayed = texture(TEXTURE, clamp(UV + offset, vec2(0.0), vec2(1.0)));
	// Include the incoming leaf colour so the canopy silhouette can shift too.
	float leaves = max(foliage(original.rgb), foliage(swayed.rgb));
	COLOR = mix(original, swayed, leaves);
	// Only the turquoise pond is refracted. Shore rocks, lily pads and the
	// ground keep their edges, while soft crossing waves catch the light.
	vec2 pond = (UV - vec2(0.635, 0.682)) / vec2(0.102, 0.095);
	float inside = 1.0 - smoothstep(0.78, 1.0, length(pond));
	float turquoise = smoothstep(0.025, 0.12, min(original.g, original.b) - original.r);
	float water = inside * turquoise;
	vec2 pixels = UV / TEXTURE_PIXEL_SIZE;
	float wave = sin(pixels.x * 0.10 + pixels.y * 0.14 - TIME * 1.6);
	float crossing = sin(pixels.x * 0.065 - pixels.y * 0.12 + TIME * 1.1);
	vec2 ripple = vec2(wave, crossing) * TEXTURE_PIXEL_SIZE * water_strength;
	vec4 refracted = texture(TEXTURE, UV + ripple * water);
	float light = pow(0.5 + 0.5 * sin(pixels.x * 0.08 + pixels.y * 0.19 - TIME * 1.3), 12.0);
	refracted.rgb += vec3(0.045, 0.075, 0.065) * light * water_strength;
	COLOR = mix(COLOR, refracted, water * 0.8);
}
