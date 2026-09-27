extends Node
## Registro de playtest (fase 8). Anota en user://playtest/partida_<fecha>.log
## lo que pasa en cada partida, una linea por evento con el minuto de juego:
## inicio de cada fase, muertes (y donde), cambios de la balanza, compras,
## amistad, templo, cultivos perdidos y momentos en que el jugador se queda
## quieto mucho rato de dia (senal de que no sabe que hacer).
## En Windows: %APPDATA%\Godot\app_userdata\Scales of Anubis\playtest\
## Es solo local: no se envia a ningun lado.

var _file: FileAccess
var _t0 := 0
var _idle := 0.0
var _idle_logged := false
var _day_start_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameTime.phase_changed.connect(_on_phase)
	GameState.heart_weight_changed.connect(func(w, d, m): _log("balanza", "%+.0f -> %.0f (%s)" % [d, w, m]))
	GameState.heart_state_changed.connect(func(n, a): _log("estado_corazon", "%s -> %s" % [a, n]))
	GameState.temple_changed.connect(func(p): _log("templo", p))
	GameState.upgrades_changed.connect(func(): _log("mejora", ",".join(GameState.upgrades)))
	GameState.friendship_changed.connect(func(n, l, subio): if subio: _log("amistad", "%s nivel %d" % [n, l]))
	GameState.season_changed.connect(func(s): _log("estacion", s))
	GameState.decision_tomada.connect(func(id, v): _log("decision", "%s = %s" % [id, v]))


## Empieza un archivo nuevo (lo llama la granja al cargarse).
func start_session() -> void:
	if _file:
		return
	DirAccess.make_dir_recursive_absolute("user://playtest")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	_file = FileAccess.open("user://playtest/partida_%s.log" % stamp, FileAccess.WRITE)
	_t0 = Time.get_ticks_msec()
	_day_start_ms = _t0
	_log("inicio", "dia %d, modo libre %s, idioma %s" % [GameState.current_day, GameState.modo_libre, Textos.idioma])


func _log(tipo: String, detalle: String = "") -> void:
	if _file == null:
		return
	var mins := (Time.get_ticks_msec() - _t0) / 60000.0
	_file.store_line("%6.2f min | dia %d | %s | %s" % [mins, GameState.current_day, tipo, detalle])
	_file.flush()


func event(tipo: String, detalle: String = "") -> void:
	_log(tipo, detalle)


func _on_phase(phase: int) -> void:
	if phase == GameTime.Phase.DAY:
		var dur := (Time.get_ticks_msec() - _day_start_ms) / 60000.0
		_day_start_ms = Time.get_ticks_msec()
		_log("empieza_dia", "el dia anterior duro %.1f min reales, deben %d, vida %d/%d" % [dur, GameState.deben, GameState.health, GameState.max_health])
	elif phase == GameTime.Phase.NIGHT:
		_log("empieza_noche", "vida %d/%d, corazon %.0f" % [GameState.health, GameState.max_health, GameState.heart_weight])
	elif phase == GameTime.Phase.DAWN:
		_log("amanecer", "criaturas %d, cultivos perdidos %d" % [GameState.enemies_defeated_tonight, GameState.crops_lost_tonight])


func _process(delta: float) -> void:
	if _file == null or get_tree().paused:
		return
	var p := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if p == null:
		return
	if not GameTime.is_night() and p.velocity.length() < 0.2:
		_idle += delta
		if _idle > 45.0 and not _idle_logged:
			_idle_logged = true
			_log("quieto_45s", "pos (%.0f, %.0f)" % [p.global_position.x, p.global_position.z])
	else:
		_idle = 0.0
		_idle_logged = false
