shader_type canvas_item;

// A very light breeze for low plants in the ground plate. The separate tree
// canopies use tree_leaves.gdshader and never pass through this texture effect.
uniform float wind_strength_pixels : hint_range(0.0, 2.0) = 0.35;
uniform float wind_speed : hint_range(0.1, 3.0) = 1.0;

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
}
