shader_type canvas_item;
uniform float phase = 0.0;
uniform float seconds = 0.0;
uniform float strength = 2.0;
uniform vec4 frame_region = vec4(0.0, 0.0, 1.0, 1.0);
void vertex() {
	float leaf = pow(1.0 - UV.y, 2.0);
	VERTEX.x += sin(seconds * 1.45 + phase + UV.y * 4.0) * strength * leaf;
	VERTEX.y += sin(seconds * 1.1 + phase + UV.x * 5.0) * strength * 0.18 * leaf;
	UV = frame_region.xy + UV * frame_region.zw;
}
