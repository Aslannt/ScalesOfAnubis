// Agua del Nilo animada (PROMPT_PULIDO.md punto 3): ondas que se desplazan
// corriente abajo, brillos que se mueven, y espuma/ondas en la orilla.
// Todo cuantizado a una rejilla de "pixeles de mundo" para que calce con el
// look pixel art.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.10, 0.30, 0.34, 1.0);
uniform vec4 mid_color : source_color = vec4(0.16, 0.42, 0.44, 1.0);
uniform vec4 light_color : source_color = vec4(0.30, 0.62, 0.60, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.90, 0.82, 1.0);
uniform sampler2D noise_tex : filter_linear, repeat_enable;
// x del borde de la orilla en coordenadas de mundo (el rio corre en Z)
uniform float shore_x = -26.0;
uniform float pixel_density = 5.0;
global uniform float cloud_shadow_strength;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// oleaje suave en vertice (casi imperceptible, pero da vida al reflejo)
	VERTEX.y += 0.03 + (sin(world_pos.z * 0.8 + TIME * 1.3) * 0.5 + 0.5) * 0.025;
}

void fragment() {
	vec2 p = floor(world_pos.xz * pixel_density) / pixel_density;
	// dos capas de ruido que corren con la corriente (hacia +Z) a distinta
	// velocidad: da ondas que se cruzan
	float n1 = texture(noise_tex, p * vec2(0.09, 0.035) + vec2(TIME * 0.004, TIME * 0.03)).r;
	float n2 = texture(noise_tex, p * vec2(0.05, 0.08) + vec2(-TIME * 0.006, TIME * 0.018) + 0.37).r;
	float n = n1 * 0.6 + n2 * 0.4;
	vec3 col = mix(deep_color.rgb, mid_color.rgb, smoothstep(0.35, 0.6, n));
	// crestas claras en bandas finas
	float crest = smoothstep(0.035, 0.0, abs(n - 0.62));
	col = mix(col, light_color.rgb, crest * 0.8);
	// destellos que titilan
	float spark = step(0.83, n2) * step(0.5, fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453 + TIME * 0.7));
	col = mix(col, vec3(0.95, 0.97, 0.9), spark * 0.7);
	// espuma y ondas en la orilla: bandas que avanzan y retroceden
	float d = shore_x - world_pos.x;
	float wave = 0.35 + 0.25 * sin(TIME * 1.1 + world_pos.z * 0.45);
	float foam = step(d, wave) * step(0.0, d);
	float ripple = step(abs(d - (0.9 + 0.35 * sin(TIME * 0.9 + world_pos.z * 0.3))), 0.07);
	col = mix(col, foam_color.rgb, max(foam * (0.55 + 0.45 * step(0.45, n1)), ripple * 0.45));
	// nubes tambien sobre el agua
	vec2 cuv = floor(world_pos.xz * 4.0) / 4.0 * 0.011 + vec2(TIME * 0.0045, TIME * 0.0022);
	col *= 1.0 - smoothstep(0.52, 0.68, texture(noise_tex, cuv * 0.9).r) * cloud_shadow_strength * 0.6;
	ALBEDO = col;
	ROUGHNESS = 0.6 - crest * 0.2;
	METALLIC = 0.0;
	SPECULAR = 0.3;
}
