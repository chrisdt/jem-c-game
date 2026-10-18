shader_type canvas_item;

// Keep world geometry fixed: only the foliage colours are sampled in motion.
// Broad canopy masks increase the motion on trees; grass and small plants
// receive a much lighter breeze. Pixel-sized offsets stay subtle when zoomed out.
uniform float wind_strength_pixels : hint_range(0.0, 5.0) = 2.4;
uniform float wind_speed : hint_range(0.1, 3.0) = 1.0;

float canopy(vec2 uv, vec2 center, vec2 radius) {
	return 1.0 - smoothstep(0.5, 1.0, length((uv - center) / radius));
}

float foliage(vec3 colour) {
	return smoothstep(0.015, 0.12, colour.g - max(colour.r, colour.b));
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float trees = canopy(UV, vec2(0.08, 0.07), vec2(0.14, 0.10));
	trees = max(trees, canopy(UV, vec2(0.30, 0.06), vec2(0.11, 0.08)));
	trees = max(trees, canopy(UV, vec2(0.47, 0.07), vec2(0.11, 0.09)));
	trees = max(trees, canopy(UV, vec2(0.03, 0.37), vec2(0.07, 0.17)));
	trees = max(trees, canopy(UV, vec2(0.97, 0.30), vec2(0.07, 0.17)));
	trees = max(trees, canopy(UV, vec2(0.03, 0.65), vec2(0.08, 0.14)));
	trees = max(trees, canopy(UV, vec2(0.13, 0.88), vec2(0.12, 0.11)));
	trees = max(trees, canopy(UV, vec2(0.30, 0.95), vec2(0.17, 0.09)));
	trees = max(trees, canopy(UV, vec2(0.60, 0.97), vec2(0.19, 0.10)));
	trees = max(trees, canopy(UV, vec2(0.93, 0.89), vec2(0.14, 0.14)));
	float breeze = sin(TIME * wind_speed * 1.35 + UV.x * 9.0 + UV.y * 18.0);
	breeze += 0.3 * sin(TIME * wind_speed * 2.1 + UV.y * 31.0);
	float amount = mix(0.17, 1.0, trees);
	vec2 offset = vec2(breeze, 0.2 * sin(TIME * wind_speed + UV.x * 15.0));
	offset *= TEXTURE_PIXEL_SIZE * wind_strength_pixels * amount;
	vec4 swayed = texture(TEXTURE, clamp(UV + offset, vec2(0.0), vec2(1.0)));
	// Include the incoming leaf colour so the canopy silhouette can shift too.
	float leaves = max(foliage(original.rgb), foliage(swayed.rgb));
	COLOR = mix(original, swayed, leaves);
}
