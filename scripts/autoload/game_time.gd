extends Node
## Ciclo dia/noche: amanecer -> dia -> atardecer -> noche -> amanecer...
## No mueve luces directamente (eso lo hace scripts/world/day_night_controller.gd,
## que escucha las senales de aqui). Este autoload solo lleva el reloj.

enum Phase { DAWN, DAY, DUSK, NIGHT }

signal phase_changed(new_phase: Phase)
signal cycle_updated(elapsed: float, total: float, phase: Phase)
signal night_started()
signal day_started()
signal dawn_summary_ready()

const DAWN_SECONDS := 12.0
const DAY_SECONDS := 180.0
const DUSK_SECONDS := 18.0
const NIGHT_SECONDS := 100.0
const TOTAL_SECONDS := DAWN_SECONDS + DAY_SECONDS + DUSK_SECONDS + NIGHT_SECONDS

var elapsed: float = DAWN_SECONDS  # arrancamos ya en pleno dia 1
var phase: Phase = Phase.DAY
var paused: bool = false
## Mientras sea true la noche no termina (el jefe sigue vivo, GDD 7 noche 3):
## el reloj se queda en el ultimo tramo de la noche.
var hold_night: bool = false

var _bounds := {}


func _ready() -> void:
	_bounds = {
		Phase.DAWN: [0.0, DAWN_SECONDS],
		Phase.DAY: [DAWN_SECONDS, DAWN_SECONDS + DAY_SECONDS],
		Phase.DUSK: [DAWN_SECONDS + DAY_SECONDS, DAWN_SECONDS + DAY_SECONDS + DUSK_SECONDS],
		Phase.NIGHT: [DAWN_SECONDS + DAY_SECONDS + DUSK_SECONDS, TOTAL_SECONDS],
	}


func _process(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	if hold_night and phase == Phase.NIGHT and elapsed > TOTAL_SECONDS - 6.0:
		elapsed = TOTAL_SECONDS - 6.0
	if elapsed >= TOTAL_SECONDS:
		elapsed -= TOTAL_SECONDS
		GameState.next_day()
	_update_phase()
	cycle_updated.emit(elapsed, TOTAL_SECONDS, phase)


func _update_phase() -> void:
	var new_phase := phase
	for p in _bounds.keys():
		var b = _bounds[p]
		if elapsed >= b[0] and elapsed < b[1]:
			new_phase = p
			break
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)
		if phase == Phase.NIGHT:
			night_started.emit()
		elif phase == Phase.DAY:
			day_started.emit()
		elif phase == Phase.DAWN:
			dawn_summary_ready.emit()
		elif phase == Phase.DUSK:
			SFX.play("dusk_transform")


## Progreso 0..1 dentro de la fase actual.
func phase_progress() -> float:
	var b = _bounds[phase]
	return clampf((elapsed - b[0]) / (b[1] - b[0]), 0.0, 1.0)


## Progreso continuo 0..1 de todo el ciclo, para animar sol/luna sin saltos.
func cycle_progress() -> float:
	return elapsed / TOTAL_SECONDS


func phase_name(p: Phase = phase) -> String:
	match p:
		Phase.DAWN: return Textos.t("hud_fase_amanecer")
		Phase.DAY: return Textos.t("hud_fase_dia")
		Phase.DUSK: return Textos.t("hud_fase_atardecer")
		Phase.NIGHT: return Textos.t("hud_fase_noche")
	return ""


func is_night() -> bool:
	return phase == Phase.NIGHT


func reset() -> void:
	elapsed = DAWN_SECONDS + 0.01
	phase = Phase.DAY
	paused = false
	hold_night = false


## Salta al amanecer del dia siguiente (derrota de noche, o fin del jefe).
func skip_to_dawn() -> void:
	hold_night = false
	elapsed = TOTAL_SECONDS - 0.01


func force_phase(p: Phase) -> void:
	elapsed = _bounds[p][0] + 0.01
	_update_phase()
