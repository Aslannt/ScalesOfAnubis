extends Node
## Textos centralizados del juego. Base en espanol (data/textos_es.json); con
## otro idioma elegido en Opciones se superpone data/i18n/textos_<idioma>.json
## (lo que falte cae al espanol). Fase 7: ingles.

signal idioma_cambiado()

var _textos: Dictionary = {}
var idioma := "es"


func _ready() -> void:
	idioma = String(Opciones.get_v("idioma"))
	cargar()


## Carga (o recarga) los textos del idioma actual.
func cargar() -> void:
	_textos = load_json("res://data/textos_es.json")
	if idioma != "es":
		_textos.merge(load_json("res://data/i18n/textos_%s.json" % idioma), true)


## Cambia el idioma de todo el juego: textos, dialogos, codice y cultivos.
func set_idioma(nuevo: String) -> void:
	idioma = nuevo
	cargar()
	Dialogos.cargar()
	Codex.cargar_textos()
	GameState.cargar_nombres_cultivos()
	idioma_cambiado.emit()


static func load_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed != null else {}


## Mezcla profunda: los valores de 'over' reemplazan a los de 'base'.
static func deep_merge(base, over):
	if base is Dictionary and over is Dictionary:
		var out: Dictionary = base.duplicate()
		for k in over:
			out[k] = deep_merge(base.get(k), over[k]) if base.has(k) else over[k]
		return out
	return over


func t(clave: String, params: Dictionary = {}) -> String:
	var s: String = _textos.get(clave, clave)
	for k in params:
		s = s.replace("{%s}" % k, str(params[k]))
	return s
