extends Node
## Carga data/dialogues.json. Las lineas usan el formato "Hablante: texto".

var data: Dictionary = {}


func _ready() -> void:
	var f := FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir data/dialogues.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed


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
