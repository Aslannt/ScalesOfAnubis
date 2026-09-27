// Pasto denso con MultiMesh: cada instancia es un quad vertical con un
// mechon de pasto del atlas (INSTANCE_CUSTOM.x = frame). La punta se mece
// con el viento; la base queda fija. La normal apunta hacia arriba para que
// el pasto se ilumine igual que el suelo (sin "cartones" brillantes).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D atlas : source_color, filter_nearest;
uniform float frames = 4.0;
uniform float sway = 0.18;
global uniform float wind_strength;

varying float v_frame;
varying float v_tint;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	v_frame = INSTANCE_CUSTOM.x;
	v_tint = INSTANCE_CUSTOM.y;
	float top = 1.0 - UV.y;
	float g = (sin(TIME * 0.9 - wp.x * 0.18 - wp.z * 0.07) * 0.5 + 0.5);
	g = 0.3 + 0.7 * g * g;
	float wave = sin(TIME * 2.3 + wp.x * 0.9 + wp.z * 0.5 + INSTANCE_CUSTOM.z * 6.28);
	VERTEX.x += top * top * (g * 0.7 + wave * 0.3) * sway * wind_strength;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec2 uv = vec2((UV.x + floor(v_frame)) / frames, UV.y);
	vec4 t = texture(atlas, uv);
	if (t.a < 0.5) {
		discard;
	}
	ALBEDO = t.rgb * (0.9 + v_tint * 0.2);
	ROUGHNESS = 1.0;
}
