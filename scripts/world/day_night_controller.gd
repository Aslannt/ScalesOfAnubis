extends Node
## El alma del look: ciclo dia/noche con iluminacion dinamica (GDD 8).
## Un solo DirectionalLight3D hace de sol de dia y luna de noche; solo cambian
## su color/energia/angulo y los tonos del cielo/ambiente segun la fase.

@export var sun_path: NodePath
@export var env_path: NodePath

var sun: DirectionalLight3D
var env: WorldEnvironment

# color_luz, energia_luz, cielo_cenit, cielo_horizonte, energia_ambiente
const TARGETS := {
	0: [Color(0.95, 0.75, 0.55), 1.0, Color(0.45, 0.55, 0.68), Color(0.85, 0.65, 0.48), 0.6],   # DAWN
	1: [Color(1.0, 0.95, 0.85), 1.3, Color(0.16, 0.29, 0.55), Color(0.55, 0.75, 0.72), 0.8],     # DAY
	2: [Color(1.0, 0.45, 0.2), 0.9, Color(0.20, 0.10, 0.30), Color(0.92, 0.38, 0.15), 0.5],      # DUSK
	3: [Color(0.60, 0.68, 0.88), 0.22, Color(0.05, 0.05, 0.13), Color(0.14, 0.10, 0.26), 0.22],  # NIGHT
}

var _prev_target: Array = TARGETS[3]


func _ready() -> void:
	sun = get_node(sun_path)
	env = get_node(env_path)
	GameTime.phase_changed.connect(_on_phase_changed)
	_apply(TARGETS[GameTime.phase], 1.0)


func _on_phase_changed(new_phase: int) -> void:
	var prev_phase := (new_phase + 3) % 4
	_prev_target = TARGETS[prev_phase]


func _process(_delta: float) -> void:
	var p := GameTime.phase_progress()
	var target: Array = TARGETS[GameTime.phase]
	_apply(_lerp_target(_prev_target, target, p), 1.0)
	sun.rotation_degrees.x = -160.0 + 360.0 * GameTime.cycle_progress()
	sun.rotation_degrees.y = 25.0


func _lerp_target(a: Array, b: Array, t: float) -> Array:
	return [
		a[0].lerp(b[0], t), lerpf(a[1], b[1], t),
		a[2].lerp(b[2], t), a[3].lerp(b[3], t), lerpf(a[4], b[4], t),
	]


func _apply(v: Array, _unused: float) -> void:
	sun.light_color = v[0]
	sun.light_energy = v[1]
	if env and env.environment:
		var e := env.environment
		e.sky.sky_material.set("sky_top_color", v[2])
		e.sky.sky_material.set("sky_horizon_color", v[3])
		e.sky.sky_material.set("ground_bottom_color", v[3] * 0.6)
		e.ambient_light_energy = v[4]
