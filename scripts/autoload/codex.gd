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
	cargar_textos()


var _es: Dictionary = {}


## Titulos y textos del idioma elegido (data/i18n/codex_<idioma>.json:
## {id: {campo: texto}}); lo que falte queda en espanol.
func cargar_textos() -> void:
	if _es.is_empty():
		for e in entries:
			_es[e["id"]] = e.duplicate()
	var over = Textos.load_json("res://data/i18n/codex_%s.json" % Textos.idioma) if Textos.idioma != "es" else {}
	for e in entries:
		var src: Dictionary = _es[e["id"]]
		for k in src:
			if k != "desbloqueada" and k != "id":
				e[k] = src[k]
		if over is Dictionary and over.has(e["id"]):
			for k in over[e["id"]]:
				e[k] = over[e["id"]][k]


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


func reset() -> void:
	for e in entries:
		e["desbloqueada"] = false
	unlock("anubis")
	unlock("thot")
