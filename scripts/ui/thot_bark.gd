extends CanvasLayer
## Comentarios de Thot que NO pausan el juego (GDD 4 y M7: tutorial
## integrado, reacciones en combate y a las decisiones). Caja chica abajo a
## la derecha con su retrato, efecto maquina de escribir y cola de mensajes.

const PORTRAIT := "res://assets/sprites/portraits/thot.png"
const CHAR_SPEED := 0.022
const HOLD_MIN := 2.6
## Arriba a la izquierda, bajo la vida: ni el centro (donde aparecen el jefe
## y las criaturas, por encima del jugador) ni el HUD de abajo.
const PANEL_X := 6.0
const PANEL_Y := 46.0
const PANEL_W := 212.0

var _panel: Panel
var _lbl: Label
var _queue: Array = []
var _full: String = ""
var _t: float = 0.0
var _hold: float = 0.0
var _showing := false


func _ready() -> void:
	layer = 8
	add_to_group("thot_bark")
	_panel = UIStyle.make_panel(self, Vector2(PANEL_X, PANEL_Y), Vector2(PANEL_W, 42))
	_panel.add_theme_stylebox_override("panel", UIStyle.panel_style(Color(0.05, 0.07, 0.12, 0.9), Color(0.6, 0.72, 0.95)))
	var face := UIStyle.make_icon(_panel, PORTRAIT, Vector2(3, 3), Vector2(26, 30))
	face.name = "Retrato"
	_lbl = UIStyle.make_label(_panel, "", Vector2(32, 3), UIStyle.SMALL, Color(0.86, 0.92, 1.0))
	_lbl.size = Vector2(PANEL_W - 36, 36)
	_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl.add_theme_constant_override("line_spacing", -1)
	_panel.visible = false
	GameState.thot_says.connect(say)


func say(texto: String) -> void:
	if texto == "" or (_showing and texto == _full) or _queue.has(texto):
		return
	_queue.append(texto)
	if not _showing:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_showing = false
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func(): _panel.visible = false)
		return
	_showing = true
	_full = _queue.pop_front()
	_t = 0.0
	_hold = HOLD_MIN + _full.length() * 0.035
	# alto segun el texto (medido con el texto completo antes de escribirlo)
	_lbl.text = _full
	var lines := maxi(3, _lbl.get_line_count())
	_panel.size.y = lines * 10 + 8
	_lbl.size.y = lines * 10
	_lbl.text = ""
	_panel.visible = true
	_panel.modulate.a = 1.0
	_panel.position.y = PANEL_Y - 6.0
	create_tween().tween_property(_panel, "position:y", PANEL_Y, 0.15)
	SFX.play("dialogue_blip", -4.0)


func _process(delta: float) -> void:
	if not _showing or get_tree().paused:
		return
	_t += delta
	var n := mini(int(_t / CHAR_SPEED), _full.length())
	_lbl.text = _full.substr(0, n)
	if n >= _full.length():
		_hold -= delta
		if _hold <= 0.0:
			_next()


func clear() -> void:
	_queue.clear()
	_hold = 0.0
