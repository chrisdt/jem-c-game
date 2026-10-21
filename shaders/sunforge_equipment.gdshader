shader_type canvas_item;
// Recolour only the blue blade or silver cutting tip as Sunforge ruby.
// Clothing, skin, helmet and brass retain their authored colours in both outfits.
uniform vec4 tool_bounds = vec4(0.60,0.38,1.0,0.78);
uniform vec2 atlas_origin = vec2(0.0);
uniform vec2 atlas_size = vec2(1.0);
uniform bool blade = false;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec4 ink = texture(TEXTURE, UV) * vertex_tint;
	vec2 local = (UV-atlas_origin)/atlas_size;
	bool inside_tip = local.x > tool_bounds.x && local.x < tool_bounds.z && local.y > tool_bounds.y && local.y < tool_bounds.w;
	if (blade && inside_tip) {
		if (ink.b > ink.r*1.25 && ink.g > ink.r*1.2) {
			float light = max(ink.r,max(ink.g,ink.b));
			ink.rgb = vec3(light,light*0.24,light*0.055);
		}
	} else if (!blade && inside_tip) {
		float bright = max(ink.r,max(ink.g,ink.b));
		float dark = min(ink.r,min(ink.g,ink.b));
		if (bright-dark < 0.17 && bright > 0.20) {
			float facet = step(0.52,fract(local.x*19.0+local.y*11.0));
			ink.rgb = vec3(1.0,0.25,0.055)*bright*(0.85+facet*0.35);
		}
	}
	COLOR = ink;
}
