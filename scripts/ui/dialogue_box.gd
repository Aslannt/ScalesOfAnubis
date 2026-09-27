extends CanvasLayer
## Caja de dialogo con maquina de escribir (GDD 11). Pausa el juego mientras
## habla para que se sienta como una escena, no como un mensaje flotante.

signal finished()

var _lines: Array = []
var _idx: int = 0
var _char_i: int = 0
var _typing: bool = false
var _timer: float = 0.0
const CHAR_SPEED := 0.025

var _panel: Panel
var _lbl_nombre: Label
var _lbl_texto: Label
var _retrato: TextureRect
var _on_finished: Callable = Callable()

const PORTRAITS := {
	"nakht": "res://assets/sprites/portraits/player.png",
	"meret": "res://assets/sprites/portraits/meret.png",
	"ptahmose": "res://assets/sprites/portraits/ptahmose.png",
	"iry": "res://assets/sprites/portraits/iry.png",
	"thot": "res://assets/sprites/portraits/thot.png",
	"anubis": "res://assets/sprites/portraits/anubis.png",
}


func _ready() -> void:
	add_to_group("dialogue_box")
	add_to_group("modal")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	visible = false

	_panel = UIStyle.make_panel(self, Vector2(14, 270 - 72), Vector2(452, 64))
	var frame := UIStyle.make_panel(_panel, Vector2(5, 5), Vector2(54, 54))
	frame.add_theme_stylebox_override("panel", UIStyle.panel_style(Color(0.2, 0.15, 0.12, 1.0), UIStyle.GOLD_DARK))

	_retrato = TextureRect.new()
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = TextureRect.TEXTURE_FILTER_NEAREST
	_retrato.position = Vector2(2, 2)
	_retrato.size = Vector2(50, 50)
	frame.add_child(_retrato)

	_lbl_nombre = UIStyle.make_label(_panel, "", Vector2(66, 5), UIStyle.SMALL, Color(0.98, 0.78, 0.3))

	_lbl_texto = UIStyle.make_label(_panel, "", Vector2(66, 18), UIStyle.SMALL, UIStyle.TEXT)
	_lbl_texto.size = Vector2(376, 42)
	_lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_texto.add_theme_constant_override("line_spacing", 2)

	_next_icon = UIStyle.make_label(_panel, "E", Vector2(438, 50), UIStyle.SMALL, UIStyle.GOLD)
	_next_icon.visible = false


var _next_icon: Label
var _blink_t: float = 0.0


func show_lines(raw_lines: Array, on_finished: Callable = Callable()) -> void:
	if raw_lines.is_empty():
		return
	_lines = raw_lines
	_idx = 0
	_on_finished = on_finished
	visible = true
	get_tree().paused = true
	_start_line()


func _start_line() -> void:
	_char_i = 0
	_typing = true
	_timer = 0.0
	SFX.play("dialogue_blip")
	var parts: PackedStringArray = String(_lines[_idx]).split(": ", true, 1)
	if parts.size() == 2:
		# "Meret (triste): texto" -> nombre Meret, retrato triste
		var hablante := parts[0]
		var emo := ""
		var par := hablante.find(" (")
		if par > 0 and hablante.ends_with(")"):
			emo = hablante.substr(par + 2, hablante.length() - par - 3)
			hablante = hablante.substr(0, par)
		_lbl_nombre.text = hablante.to_upper()
		_lbl_texto.text = ""
		_full_text = parts[1]
		_update_retrato(hablante, emo)
	else:
		_lbl_nombre.text = ""
		_lbl_texto.text = ""
		_full_text = parts[0]
		_retrato.texture = load("res://assets/sprites/icons/feather.png")


func _update_retrato(hablante: String, emo: String = "") -> void:
	var key := hablante.to_lower().strip_edges()
	if PORTRAITS.has(key):
		var path: String = PORTRAITS[key]
		if emo != "":
			var alt := path.replace(".png", "_%s.png" % emo)
			if ResourceLoader.exists(alt):
				path = alt
		_retrato.texture = load(path)
		# pequeno salto del retrato al cambiar de expresion
		_retrato.scale = Vector2(1.06, 1.06)
		_retrato.pivot_offset = Vector2(25, 25)
		create_tween().tween_property(_retrato, "scale", Vector2.ONE, 0.12)
	else:
		_retrato.texture = null


var _full_text: String = ""


func _process(delta: float) -> void:
	if not visible:
		return
	_blink_t += delta
	_next_icon.visible = not _typing and fmod(_blink_t, 0.8) < 0.5
	if _typing:
		_timer += delta
		var target := int(_timer / CHAR_SPEED)
		_char_i = mini(target, _full_text.length())
		_lbl_texto.text = _full_text.substr(0, _char_i)
		if _char_i >= _full_text.length():
			_typing = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _typing:
		_char_i = _full_text.length()
		_lbl_texto.text = _full_text
		_typing = false
		return
	_idx += 1
	if _idx >= _lines.size():
		visible = false
		GameState.lock_player_input(0.25)
		get_tree().paused = false
		var cb := _on_finished
		_on_finished = Callable()
		if cb.is_valid():
			cb.call()
		finished.emit()
		return
	_start_line()
