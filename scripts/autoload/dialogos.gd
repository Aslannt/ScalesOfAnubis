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
