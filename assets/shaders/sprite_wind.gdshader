// Sprite de cultivo con viento: un quad con una region de la hoja de
// sprites. La base queda fija y la punta se mece (PROMPT_PULIDO.md punto 3).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D sheet : source_color, filter_nearest;
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0); // x, y, w, h en UV
uniform float sway = 0.08;
uniform vec4 tint : source_color = vec4(1.0);
global uniform float wind_strength;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float top = 1.0 - UV.y;
	float g = (sin(TIME * 0.9 - wp.x * 0.18 - wp.z * 0.07) * 0.5 + 0.5);
	g = 0.3 + 0.7 * g * g;
	float wave = sin(TIME * 2.0 + wp.x * 0.8 + wp.z * 0.6);
	VERTEX.x += top * top * (g * 0.7 + wave * 0.3) * sway * wind_strength;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec4 t = texture(sheet, region.xy + UV * region.zw);
	if (t.a < 0.5) {
		discard;
	}
	ALBEDO = t.rgb * tint.rgb;
	ROUGHNESS = 1.0;
}
