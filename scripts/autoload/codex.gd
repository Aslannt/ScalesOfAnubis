extends Node
## Libro de los Muertos: entradas de codice cargadas desde data/codex.json.
## Solo usa lore verificado (GDD seccion 12).

signal entry_unlocked(id: String)

var entries: Array = []
var _by_id: Dictionary = {}


func _ready() -> void:
	var f := FileAccess.open("res://data/codex.json", FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir data/codex.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		entries = parsed
		for e in entries:
			_by_id[e["id"]] = e


func unlock(id: String) -> void:
	if not _by_id.has(id):
		return
	if _by_id[id]["desbloqueada"]:
		return
	_by_id[id]["desbloqueada"] = true
	entry_unlocked.emit(id)


func is_unlocked(id: String) -> bool:
	return _by_id.has(id) and _by_id[id]["desbloqueada"]


func get_entry(id: String) -> Dictionary:
	return _by_id.get(id, {})


func unlocked_count() -> int:
	var n := 0
	for e in entries:
		if e["desbloqueada"]:
			n += 1
	return n
