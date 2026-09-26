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

# color_luz, energia_luz, cielo_cenit, cielo_horizonte, energia_ambiente, fog_energia
const TARGETS := {
	0: [Color(0.95, 0.75, 0.55), 1.05, Color(0.45, 0.62, 0.78), Color(0.92, 0.72, 0.52), 0.65, 0.7],   # DAWN
	1: [Color(1.0, 0.96, 0.88), 1.35, Color(0.14, 0.32, 0.62), Color(0.62, 0.80, 0.80), 0.85, 0.9],     # DAY
	2: [Color(1.0, 0.48, 0.22), 0.85, Color(0.16, 0.10, 0.28), Color(0.90, 0.40, 0.18), 0.5, 0.85],     # DUSK
	3: [Color(0.55, 0.65, 0.95), 0.45, Color(0.035, 0.04, 0.11), Color(0.10, 0.09, 0.24), 0.34, 0.55],  # NIGHT: azul/violeta profundo, NUNCA rojo
}

var _prev_target: Array = TARGETS[3]
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
	]


func _apply(v: Array) -> void:
	sun.light_color = v[0]
	sun.light_energy = v[1]
	if env and env.environment:
		var e := env.environment
		e.sky.sky_material.set("sky_top_color", v[2])
		e.sky.sky_material.set("sky_horizon_color", v[3])
		e.sky.sky_material.set("ground_bottom_color", v[3] * 0.6)
		e.ambient_light_energy = v[4]
		e.fog_light_color = v[3]
		e.fog_light_energy = v[5]
