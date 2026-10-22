shader_type canvas_item;
render_mode unshaded;
uniform vec4 cut_rect;
void fragment() {
	vec2 source_pixel = UV * vec2(1536.0, 1024.0);
	if (source_pixel.x >= cut_rect.x && source_pixel.x < cut_rect.z &&
		source_pixel.y >= cut_rect.y && source_pixel.y < cut_rect.w) {
		COLOR.a = 0.0;
	}
}
