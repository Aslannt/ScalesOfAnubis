extends Node
## Carga data/dialogues.json. Las lineas usan el formato "Hablante: texto".

var data: Dictionary = {}


func _ready() -> void:
	cargar()


## Dialogos en espanol con la traduccion del idioma elegido encima (fase 7).
func cargar() -> void:
	var base = Textos.load_json("res://data/dialogues.json")
	if not (base is Dictionary):
		push_error("No se pudo abrir data/dialogues.json")
		return
	data = base
	if Textos.idioma != "es":
		var over = Textos.load_json("res://data/i18n/dialogues_%s.json" % Textos.idioma)
		if over is Dictionary:
			data = Textos.deep_merge(base, over)


func lines(npc_id: String, key: String) -> Array:
	return data.get(npc_id, {}).get(key, [])


## Comentario suelto de Thot (seccion "thot" de dialogues.json).
func thot(key: String) -> String:
	var v = data.get("thot", {}).get(key, "")
	if v is Array:
		return String(v[randi() % v.size()]) if not v.is_empty() else ""
	return String(v)


## Lista de comentarios de Thot (p. ej. "recuerdos").
func thot_list(key: String) -> Array:
	var v = data.get("thot", {}).get(key, [])
	return v if v is Array else [v]
