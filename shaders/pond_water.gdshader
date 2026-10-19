shader_type canvas_item;

// Repaint only the moving water over the original illustration. The traced
// mask keeps bridges, shorelines and stone islands still on every Earth map.
uniform sampler2D water_mask : filter_linear;
uniform float water_strength : hint_range(0.0, 2.0) = 0.8;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float turquoise = smoothstep(0.025, 0.12, min(original.g, original.b) - original.r);
	float water = texture(water_mask, UV).r * turquoise;
	vec2 pixels = UV / TEXTURE_PIXEL_SIZE;
	float wave = sin(pixels.x * 0.10 + pixels.y * 0.14 - TIME * 1.6);
	float crossing = sin(pixels.x * 0.065 - pixels.y * 0.12 + TIME * 1.1);
	vec2 ripple = vec2(wave, crossing) * TEXTURE_PIXEL_SIZE * water_strength;
	vec4 refracted = texture(TEXTURE, UV + ripple * water);
	float light = pow(0.5 + 0.5 * sin(pixels.x * 0.08 + pixels.y * 0.19 - TIME * 1.3), 12.0);
	refracted.rgb += vec3(0.045, 0.075, 0.065) * light * water_strength;
	COLOR = vec4(refracted.rgb, original.a * water * 0.8);
}
