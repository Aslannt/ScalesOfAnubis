extends Node
## Dirige las oleadas de criaturas de Ammit cada noche (GDD 6.4 y 7), leidas
## de data/waves.json. Noche 1: pocas sombras. Noche 2: sombras hacia la
## aldea + crias hacia los cultivos (decision moral 2). Noche 3: oleadas y el
## Heraldo de Ammit, que retiene la noche hasta morir.

signal boss_spawned(boss: Node)

const SCENES := {
	"sombra": preload("res://scenes/enemies/Sombra.tscn"),
	"cria": preload("res://scenes/enemies/Cria.tscn"),
	"jefe": preload("res://scenes/enemies/Heraldo.tscn"),
}

var world_builder: WorldBuilder = null
var _waves: Dictionary = {}
var _schedule: Array = []  # [{t, tipo, desde, grupo}] ordenado por t
var _night_t: float = 0.0
var _enemies_root: Node3D
var boss: Node = null


func _ready() -> void:
	_enemies_root = Node3D.new()
	_enemies_root.name = "Enemigos"
	get_parent().add_child.call_deferred(_enemies_root)
	var f := FileAccess.open("res://data/waves.json", FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_waves = parsed
	GameTime.night_started.connect(_on_night_started)
	GameTime.dawn_summary_ready.connect(_on_dawn)


func _on_night_started() -> void:
	var day := GameState.current_day
	var key := str(clampi(day, 1, 3))
	_schedule.clear()
	_night_t = 0.0
	GameState.village_damage = 0
	GameState.village_kills = 0
	GameState.village_raiders_total = 0
	var banner = get_tree().get_first_node_in_group("combat_banner")
	if banner:
		banner.announce(Textos.t("noche_titulo", {"n": day}), Textos.t("noche_mas_fuerte") if day > 1 else Textos.t("noche_sub"))
	var entries: Array = _waves.get(key, []) if not GameState.modo_libre else _free_mode_entries()
	if GameState.modo_libre:
		GameState.boss_defeated = false
	for ei in range(entries.size()):
		var entry: Dictionary = entries[ei]
		var n := int(entry.get("n", 1))
		# un corazon pesado atrae mas criaturas (el jefe no se duplica)
		if entry.get("tipo", "") != "jefe":
			n += int(round(n * GameState.heart_mod("oleada_extra", 0.0)))
		var win: Array = entry.get("ventana", [0.0, 0.5])
		for i in range(n):
			var frac := lerpf(float(win[0]), float(win[1]), (i + 0.5) / n) if n > 1 else float(win[0])
			_schedule.append({
				"t": frac * GameTime.NIGHT_SECONDS + randf_range(-0.8, 0.8),
				"tipo": entry.get("tipo", "sombra"),
				"desde": entry.get("desde", "desierto"),
				"grupo": entry.get("grupo", ""),
				"entrada": ei,
			})
			if entry.get("grupo", "") == "aldea":
				GameState.village_raiders_total += 1
	_schedule.sort_custom(func(a, b): return a["t"] < b["t"])


## Oleadas del modo libre: las de la estacion, cada vez mas numerosas, y el
## Heraldo la ultima noche de cada estacion.
func _free_mode_entries() -> Array:
	var sd: Dictionary = GameState.seasons_data
	var base: Array = sd.get("estaciones", {}).get(GameState.season(), {}).get("oleadas", [])
	var extra_dias := maxi(0, GameState.current_day - int(sd.get("primer_dia_libre", 4)))
	var factor := 1.0 + float(sd.get("crece", 0.12)) * extra_dias
	var out: Array = []
	for e in base:
		var c: Dictionary = (e as Dictionary).duplicate()
		c["n"] = int(round(int(c.get("n", 1)) * factor))
		out.append(c)
	if GameState.is_season_last_day():
		out.append(sd.get("jefe", {"tipo": "jefe", "n": 1, "desde": "desierto", "ventana": [0.4, 0.4]}))
	return out


## Al amanecer las criaturas que quedan se desvanecen (vuelven al Duat).
func _on_dawn() -> void:
	_schedule.clear()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("vanish"):
			e.vanish()


func _process(delta: float) -> void:
	if not GameTime.is_night():
		return
	_night_t += delta
	while not _schedule.is_empty() and _schedule[0]["t"] <= _night_t:
		var s: Dictionary = _schedule.pop_front()
		_announce_entry(s)
		spawn(s["tipo"], s["desde"], s["grupo"])


var _announced: Dictionary = {}


## Cartel grande la primera vez que aparece cada grupo de la oleada.
func _announce_entry(s: Dictionary) -> void:
	var key := "%d_%d" % [GameState.current_day, s["entrada"]]
	if _announced.has(key):
		return
	_announced[key] = true
	var banner = get_tree().get_first_node_in_group("combat_banner")
	if banner == null:
		return
	var title := Textos.t("oleada_" + String(s["desde"]))
	var sub := Textos.t("oleada_sub_cria") if s["tipo"] == "cria" else Textos.t("oleada_sub_sombra")
	if s["grupo"] == "aldea":
		title = Textos.t("oleada_noreste")
		sub = Textos.t("oleada_sub_aldea")
	if s["tipo"] == "jefe":
		title = Textos.t("oleada_jefe")
		sub = ""
	banner.announce(title, sub)


func spawn_point(nombre: String) -> Vector3:
	if world_builder and world_builder.spawn_points.has(nombre):
		return world_builder.spawn_points[nombre]
	return Vector3(30, 0, 0)


func spawn(tipo: String, desde: String, grupo: String = "", at: Vector3 = Vector3.INF) -> Node:
	var scene: PackedScene = SCENES.get(tipo, SCENES["sombra"])
	var inst: Node3D = scene.instantiate()
	var base := spawn_point(desde) if at == Vector3.INF else at
	var jitter := Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)) if at == Vector3.INF else Vector3.ZERO
	inst.position = base + jitter + Vector3(0, 0.1, 0)
	if grupo != "":
		inst.set("group_id", grupo)
	_enemies_root.add_child(inst)
	if tipo == "jefe":
		if GameState.modo_libre:
			# cada regreso del Heraldo es mas duro
			GameState.jefes_libre += 1
			var k := 1.0 + float(GameState.seasons_data.get("jefe_vida_extra", 0.3)) * GameState.jefes_libre
			inst.max_health = int(inst.max_health * k)
			inst.health = inst.max_health
		boss = inst
		GameTime.hold_night = true
		boss_spawned.emit(inst)
	return inst
