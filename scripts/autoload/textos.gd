extends Node
## Textos centralizados del juego (español). Ver data/textos_es.json.
## Permite traducir mas adelante sin tocar el codigo.

var _textos: Dictionary = {}

func _ready() -> void:
	var f := FileAccess.open("res://data/textos_es.json", FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir data/textos_es.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_textos = parsed


func t(clave: String, params: Dictionary = {}) -> String:
	var s: String = _textos.get(clave, clave)
	for k in params:
		s = s.replace("{%s}" % k, str(params[k]))
	return s
