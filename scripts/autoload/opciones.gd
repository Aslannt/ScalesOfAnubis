extends Node
## Opciones del jugador guardadas en user://opciones.cfg (fase 5 y 7):
## volumenes, pantalla completa, vibracion del mando, intensidad de la
## sacudida de camara, velocidad del texto e idioma. Se aplican al arrancar.

signal changed(clave: String)

const PATH := "user://opciones.cfg"
const DEFAULTS := {
	"vol_Master": 1.0, "vol_Music": 1.0, "vol_SFX": 1.0,
	"pantalla_completa": false,
	"vibracion": true,
	"sacudida": 1.0,       # 0 = sin sacudidas de camara
	"texto_rapido": false,
	"efectos_pantalla": true,  # destellos rojos, bordes teñidos
	"idioma": "es",
}

var valores: Dictionary = DEFAULTS.duplicate()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for k in DEFAULTS:
			valores[k] = cfg.get_value("opciones", k, DEFAULTS[k])
	_apply_all.call_deferred()


func get_v(clave: String):
	return valores.get(clave, DEFAULTS.get(clave))


func set_v(clave: String, valor) -> void:
	valores[clave] = valor
	_apply(clave)
	_save()
	changed.emit(clave)


func _save() -> void:
	var cfg := ConfigFile.new()
	for k in valores:
		cfg.set_value("opciones", k, valores[k])
	cfg.save(PATH)


func _apply_all() -> void:
	for k in valores:
		_apply(k)


func _apply(clave: String) -> void:
	if clave.begins_with("vol_"):
		var idx := AudioServer.get_bus_index(clave.substr(4))
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(float(valores[clave]), 0.0001)))
	elif clave == "pantalla_completa" and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if valores[clave] else DisplayServer.WINDOW_MODE_WINDOWED)
