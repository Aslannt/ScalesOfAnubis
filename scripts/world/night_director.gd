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
	for entry in _waves.get(key, []):
		var n := int(entry.get("n", 1))
		var win: Array = entry.get("ventana", [0.0, 0.5])
		for i in range(n):
			var frac := lerpf(float(win[0]), float(win[1]), (i + 0.5) / n) if n > 1 else float(win[0])
			_schedule.append({
				"t": frac * GameTime.NIGHT_SECONDS + randf_range(-0.8, 0.8),
				"tipo": entry.get("tipo", "sombra"),
				"desde": entry.get("desde", "desierto"),
				"grupo": entry.get("grupo", ""),
			})
			if entry.get("grupo", "") == "aldea":
				GameState.village_raiders_total += 1
	_schedule.sort_custom(func(a, b): return a["t"] < b["t"])


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
		spawn(s["tipo"], s["desde"], s["grupo"])


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
		boss = inst
		GameTime.hold_night = true
		boss_spawned.emit(inst)
	return inst
