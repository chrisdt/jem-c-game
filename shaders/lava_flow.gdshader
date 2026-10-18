shader_type canvas_item;

uniform sampler2D lava_mask : filter_linear, repeat_disable;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float mask = texture(lava_mask, UV).r;
	// Restrict the flow to the bright molten colours inside the channel.
	// Stone ledges, the bridge and lanterns retain their painted edges.
	float molten = mask * smoothstep(0.12, 0.4, min(original.r, original.g) - original.b);
	vec2 pixels = UV / TEXTURE_PIXEL_SIZE;
	vec2 flow = vec2(sin(pixels.y * 0.065 - TIME * 1.2), cos(pixels.x * 0.045 + TIME * 0.8));
	vec4 moving = texture(TEXTURE, UV + flow * TEXTURE_PIXEL_SIZE * molten * 1.3);
	float current = pow(0.5 + 0.5 * sin(pixels.x * 0.043 + pixels.y * 0.057 - TIME * 1.7), 7.0);
	moving.rgb += vec3(0.12, 0.065, 0.008) * current;
	COLOR = mix(original, moving, molten * 0.85);
}
