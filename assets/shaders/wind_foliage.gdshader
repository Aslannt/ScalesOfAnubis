// Viento para vegetacion 3D (juncos, papiros, pasto alto, hojas de palmera,
// flores). Desplaza cada vertice en espacio de MUNDO segun su altura sobre el
// suelo, con rafagas que recorren el mapa (PROMPT_PULIDO.md punto 3).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform vec2 uv_scale = vec2(1.0);
// metros de desplazamiento por metro de altura (con curva)
uniform float sway = 0.06;
uniform float flutter = 0.02;
global uniform float wind_strength;

float gust(vec2 p, float t) {
	// rafaga que viaja por el mapa + oscilacion lenta
	float g = sin(t * 0.9 - p.x * 0.18 - p.y * 0.07) * 0.5 + 0.5;
	g = g * g;
	return 0.35 + 0.65 * g;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(wp.y, 0.0);
	float bend = pow(h, 1.35);
	float g = gust(wp.xz, TIME) * wind_strength;
	float wave = sin(TIME * 2.1 + wp.x * 0.6 + wp.z * 0.4);
	vec3 disp = vec3(
		(g * 0.8 + wave * 0.35) * sway * bend + sin(TIME * 7.0 + wp.z * 3.1 + wp.x) * flutter * h * g,
		0.0,
		(wave * 0.25) * sway * bend
	);
	VERTEX += (inverse(MODEL_MATRIX) * vec4(disp, 0.0)).xyz;
}

void fragment() {
	vec4 t = texture(albedo_tex, UV * uv_scale);
	ALBEDO = albedo.rgb * t.rgb;
	ROUGHNESS = 0.95;
}
