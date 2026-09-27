extends Node
## El alma del look: ciclo dia/noche con iluminacion dinamica (GDD 8).
## Un solo DirectionalLight3D hace de sol de dia y luna de noche; solo cambian
## su color/energia/angulo y los tonos del cielo/ambiente segun la fase.
##
## IMPORTANTE (bug real encontrado con capturas reales, ver DECISIONES.md):
## la transicion de color NO debe tardar toda la fase (podian ser 100s+ de
## noche mostrando todavia el naranja del atardecer). Usa un temporizador
## propio y corto (TRANSITION_SECONDS) sin importar cuanto dure la fase.

@export var sun_path: NodePath
@export var env_path: NodePath

var sun: DirectionalLight3D
var env: WorldEnvironment

const TRANSITION_SECONDS := 4.0

# color_luz, energia_luz, cielo_cenit, cielo_horizonte, energia_ambiente,
# fog_energia, color_ambiente, color_niebla, sombra_nubes
#
# La luz ambiental NO sale del cielo sino de un color propio por fase: el
# radiance del cielo se actualiza con retraso y dejaba la noche tenida del
# rojo del atardecer durante varios segundos (bug real visto en capturas).
const TARGETS := {
	0: [Color(0.98, 0.78, 0.60), 1.0, Color(0.42, 0.55, 0.78), Color(0.95, 0.74, 0.58), 0.62, 0.55,
		Color(0.72, 0.62, 0.62), Color(0.86, 0.72, 0.62), 0.15],   # DAWN
	1: [Color(1.0, 0.95, 0.86), 1.25, Color(0.22, 0.45, 0.78), Color(0.86, 0.86, 0.80), 0.72, 0.6,
		Color(0.66, 0.70, 0.76), Color(0.86, 0.84, 0.78), 0.32],   # DAY
	2: [Color(1.0, 0.62, 0.36), 1.0, Color(0.22, 0.16, 0.36), Color(0.95, 0.55, 0.30), 0.55, 0.5,
		Color(0.62, 0.48, 0.52), Color(0.80, 0.52, 0.40), 0.12],   # DUSK: naranja calido, sin saturar todo
	3: [Color(0.55, 0.66, 1.0), 0.72, Color(0.03, 0.035, 0.10), Color(0.10, 0.10, 0.26), 0.68, 0.5,
		Color(0.26, 0.30, 0.58), Color(0.08, 0.09, 0.22), 0.0],    # NIGHT: azul/violeta profundo, NUNCA rojo
}

var _prev_target: Array = TARGETS[3]
## Tono de la estacion (lo fija SeasonDirector): Shemu mas calido y seco,
## Akhet mas fresco y nublado.
var season_tint := Color.WHITE
var season_clouds := 0.0
var _t: float = TRANSITION_SECONDS


func _ready() -> void:
	sun = get_node(sun_path)
	env = get_node(env_path)
	GameTime.phase_changed.connect(_on_phase_changed)
	_t = TRANSITION_SECONDS
	_apply(TARGETS[GameTime.phase])


func _on_phase_changed(new_phase: int) -> void:
	var prev_phase := (new_phase + 3) % 4
	_prev_target = TARGETS[prev_phase]
	_t = 0.0


## Salta directo al look final de la fase actual, sin animar. Lo usa
## tools/capture.gd para que las capturas no queden a mitad de transicion.
func snap_to_current_phase() -> void:
	_t = TRANSITION_SECONDS
	_apply(TARGETS[GameTime.phase])


func _process(delta: float) -> void:
	if _t < TRANSITION_SECONDS:
		_t = minf(_t + delta, TRANSITION_SECONDS)
		var t := _t / TRANSITION_SECONDS
		t = t * t * (3.0 - 2.0 * t)  # smoothstep: entra y sale de la transicion suave
		_apply(_lerp_target(_prev_target, TARGETS[GameTime.phase], t))
	sun.rotation_degrees.x = -160.0 + 360.0 * GameTime.cycle_progress()
	sun.rotation_degrees.y = 25.0


func _lerp_target(a: Array, b: Array, t: float) -> Array:
	return [
		a[0].lerp(b[0], t), lerpf(a[1], b[1], t),
		a[2].lerp(b[2], t), a[3].lerp(b[3], t), lerpf(a[4], b[4], t), lerpf(a[5], b[5], t),
		a[6].lerp(b[6], t), a[7].lerp(b[7], t), lerpf(a[8], b[8], t),
	]


func _apply(v: Array) -> void:
	sun.light_color = v[0] * season_tint
	sun.light_energy = v[1]
	if env and env.environment:
		var e := env.environment
		e.sky.sky_material.set("sky_top_color", v[2])
		e.sky.sky_material.set("sky_horizon_color", v[3])
		e.sky.sky_material.set("ground_bottom_color", v[7] * 0.7)
		# sin franja turquesa bajo el horizonte: el "suelo" del cielo toma el
		# color de la niebla, asi se funde con el desierto lejano
		e.sky.sky_material.set("ground_horizon_color", v[7])
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = v[6]
		e.ambient_light_energy = v[4]
		e.fog_light_color = v[7] * season_tint
		e.fog_light_energy = v[5]
	RenderingServer.global_shader_parameter_set("cloud_shadow_strength", v[8] + season_clouds)
