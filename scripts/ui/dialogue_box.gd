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
var _on_finished: Callable = Callable()


func _ready() -> void:
	add_to_group("dialogue_box")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	visible = false

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 20
	_panel.offset_right = -20
	_panel.offset_top = -74
	_panel.offset_bottom = -10
	add_child(_panel)

	_lbl_nombre = Label.new()
	_lbl_nombre.position = Vector2(10, 4)
	_lbl_nombre.add_theme_font_size_override("font_size", 13)
	_lbl_nombre.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	_panel.add_child(_lbl_nombre)

	_lbl_texto = Label.new()
	_lbl_texto.position = Vector2(10, 24)
	_lbl_texto.size = Vector2(420, 36)
	_lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	_panel.add_child(_lbl_texto)


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
		_lbl_nombre.text = parts[0]
		_lbl_texto.text = ""
		_full_text = parts[1]
	else:
		_lbl_nombre.text = ""
		_lbl_texto.text = ""
		_full_text = parts[0]


var _full_text: String = ""


func _process(delta: float) -> void:
	if not visible:
		return
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
		get_tree().paused = false
		var cb := _on_finished
		_on_finished = Callable()
		if cb.is_valid():
			cb.call()
		finished.emit()
		return
	_start_line()
