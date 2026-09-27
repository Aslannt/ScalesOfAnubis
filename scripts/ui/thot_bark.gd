extends CanvasLayer
## Comentarios de Thot que NO pausan el juego (GDD 4 y M7).
## Feedback de Deivid: "habla demasiado". Ahora:
## - los urgentes (respuestas a lo que acabas de hacer, avisos de combate)
##   salen enseguida y pasan al frente;
## - los normales (tutorial, curiosidades) esperan una pausa de silencio
##   entre uno y otro, y solo se guardan los 2 mas recientes;
## - el nombre THOT se ve siempre, y el ibis del mundo mueve el pico.

const PORTRAIT := "res://assets/sprites/portraits/thot.png"
const CHAR_SPEED := 0.022
const HOLD_MIN := 2.4
const QUIET_BETWEEN := 9.0   # silencio minimo entre comentarios normales
const PANEL_X := 6.0
const PANEL_Y := 46.0
const PANEL_W := 168.0

signal speaking(active: bool)

var _panel: Panel
var _name: Label
var _lbl: Label
var _urgent: Array = []
var _normal: Array = []
var _full: String = ""
var _t: float = 0.0
var _hold: float = 0.0
var _showing := false
var _quiet: float = 0.0
var _faces: Dictionary = {}
var _face: TextureRect
var _emo := "normal"


func _ready() -> void:
	layer = 8
	add_to_group("thot_bark")
	_panel = UIStyle.make_panel(self, Vector2(PANEL_X, PANEL_Y), Vector2(PANEL_W, 42))
	_panel.add_theme_stylebox_override("panel", UIStyle.panel_style(Color(0.05, 0.07, 0.12, 0.9), Color(0.6, 0.72, 0.95)))
	# cara de Thot: recorte de la cabeza de su retrato (con expresiones y el
	# pico que se abre mientras habla)
	for e in ["normal", "habla", "sarcasmo", "sorpresa"]:
		var at := AtlasTexture.new()
		at.atlas = load(PORTRAIT if e == "normal" else PORTRAIT.replace(".png", "_%s.png" % e))
		at.region = Rect2(14, 3, 32, 32)
		_faces[e] = at
	# fondo claro detras de la cara: la cabeza negra del ibis se pierde sobre
	# el panel oscuro
	var bg := ColorRect.new()
	bg.color = Color(0.62, 0.7, 0.86, 0.9)
	bg.position = Vector2(2, 3)
	bg.size = Vector2(32, 32)
	_panel.add_child(bg)
	_face = TextureRect.new()
	_face.texture = _faces["normal"]
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_face.position = Vector2(2, 3)
	_face.size = Vector2(32, 32)
	_face.name = "Retrato"
	_panel.add_child(_face)
	_name = UIStyle.make_label(_panel, Textos.t("nombre_thot").to_upper(), Vector2(37, 3), UIStyle.SMALL, UIStyle.GOLD)
	_lbl = UIStyle.make_label(_panel, "", Vector2(37, 13), UIStyle.SMALL, Color(0.86, 0.92, 1.0))
	_lbl.size = Vector2(PANEL_W - 40, 36)
	_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl.add_theme_constant_override("line_spacing", -1)
	_panel.visible = false
	GameState.thot_says.connect(say)


func say(texto: String, urgente: bool = false) -> void:
	if texto == "" or (_showing and texto.ends_with(_full)) or _urgent.has(texto) or _normal.has(texto):
		return
	if urgente:
		_urgent.append(texto)
		# si esta diciendo algo normal, lo acorta para dar paso
		if _showing:
			_hold = minf(_hold, 0.6)
	else:
		_normal.append(texto)
		while _normal.size() > 2:
			_normal.pop_front()
	if not _showing:
		_try_next()


func _try_next() -> bool:
	var txt := ""
	if not _urgent.is_empty():
		txt = _urgent.pop_front()
	elif not _normal.is_empty() and _quiet <= 0.0:
		txt = _normal.pop_front()
	if txt == "":
		return false
	_showing = true
	# "(sarcasmo) texto" -> expresion de Thot para este comentario
	_emo = "normal"
	if txt.begins_with("("):
		var close := txt.find(") ")
		if close > 0 and close < 12:
			var tag := txt.substr(1, close - 1)
			_emo = tag if _faces.has(tag) else "normal"
			txt = txt.substr(close + 2)
	_full = txt
	_t = 0.0
	_hold = HOLD_MIN + _full.length() * 0.03
	_lbl.text = _full
	var lines := maxi(2, _lbl.get_line_count())
	_panel.size.y = lines * 10 + 18
	_lbl.size.y = lines * 10
	_lbl.text = ""
	_panel.visible = true
	_panel.modulate.a = 1.0
	_panel.position.y = PANEL_Y - 6.0
	create_tween().tween_property(_panel, "position:y", PANEL_Y, 0.15)
	SFX.play("dialogue_blip", -6.0)
	speaking.emit(true)
	return true


func _finish() -> void:
	_showing = false
	_quiet = QUIET_BETWEEN
	speaking.emit(false)
	if not _try_next():
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func():
			if not _showing:
				_panel.visible = false)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if not _showing:
		_quiet = maxf(0.0, _quiet - delta)
		if _quiet <= 0.0 and not _normal.is_empty():
			_try_next()
		elif not _urgent.is_empty():
			_try_next()
		return
	_t += delta
	var n := mini(int(_t / (CHAR_SPEED * (0.35 if bool(Opciones.get_v("texto_rapido")) else 1.0))), _full.length())
	_lbl.text = _full.substr(0, n)
	# el pico se abre y cierra mientras escribe
	var talking := n < _full.length() and int(_t / 0.11) % 2 == 0
	_face.texture = _faces["habla"] if talking else _faces[_emo]
	if n >= _full.length():
		_hold -= delta
		if _hold <= 0.0:
			_finish()


func is_speaking() -> bool:
	return _showing and _lbl.text.length() < _full.length()


func clear() -> void:
	_urgent.clear()
	_normal.clear()
	_hold = 0.0
