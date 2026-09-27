// Suelo del mundo: textura pixelada + sombras de nubes que pasan
// (PROMPT_PULIDO.md punto 3). La intensidad de las nubes la baja el ciclo
// dia/noche via el global cloud_shadow_strength (0 de noche).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform vec2 uv_scale = vec2(1.0);
uniform sampler2D cloud_tex : filter_linear, repeat_enable;
global uniform float cloud_shadow_strength;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 col = texture(albedo_tex, UV * uv_scale).rgb;
	// cuantizado a 0.25 m para que la sombra de nube tambien sea "pixelada"
	vec2 p = floor(world_pos.xz * 4.0) / 4.0;
	vec2 cuv = p * 0.011 + vec2(TIME * 0.0045, TIME * 0.0022);
	float c = texture(cloud_tex, cuv).r;
	float sh = smoothstep(0.52, 0.68, c) * cloud_shadow_strength;
	ALBEDO = col * (1.0 - sh);
	ROUGHNESS = 1.0;
}
