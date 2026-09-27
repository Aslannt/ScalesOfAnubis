extends CanvasLayer
## Menu de opciones modal (comprar, construir defensas, decisiones). Pausa
## el juego. W/S o flechas para moverse, E / Enter / clic para elegir, Esc
## cancela (devuelve -1).
## Uso: get_tree().get_first_node_in_group("choice_box").ask(titulo, [..], cb)

var _panel: PanelContainer
var _title: Label
var _box: VBoxContainer
var _buttons: Array = []
var _cb: Callable = Callable()
var _idx: int = 0


func _ready() -> void:
	add_to_group("choice_box")
	add_to_group("modal")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 13
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.theme = UIStyle.theme()
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_panel.add_child(v)
	_title = Label.new()
	_title.add_theme_color_override("font_color", Color(0.98, 0.8, 0.35))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(200, 0)
	v.add_child(_title)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 2)
	v.add_child(_box)


func is_open() -> bool:
	return visible


func ask(title: String, options: Array, cb: Callable) -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	_title.text = title
	for i in range(options.size()):
		var b := Button.new()
		b.text = String(options[i])
		b.add_theme_font_size_override("font_size", UIStyle.SMALL)
		b.custom_minimum_size = Vector2(200, 16)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx := i
		b.pressed.connect(func(): _choose(idx))
		b.mouse_entered.connect(func(): _focus(idx))
		_box.add_child(b)
		_buttons.append(b)
	_cb = cb
	visible = true
	get_tree().paused = true
	await get_tree().process_frame
	_panel.reset_size()
	_panel.position = (Vector2(480, 270) - _panel.size) * 0.5 + Vector2(0, 20)
	_focus(0)
	SFX.play("ui_select", -4.0)


func _focus(i: int) -> void:
	if _buttons.is_empty():
		return
	_idx = clampi(i, 0, _buttons.size() - 1)
	_buttons[_idx].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_focus((_idx - 1 + _buttons.size()) % _buttons.size())
		SFX.play("dialogue_blip", -8.0)
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_focus((_idx + 1) % _buttons.size())
		SFX.play("dialogue_blip", -8.0)
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_choose(_idx)
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_choose(-1)
	else:
		return
	get_viewport().set_input_as_handled()


func _choose(i: int) -> void:
	if not visible:
		return
	visible = false
	GameState.lock_player_input(0.25)
	get_tree().paused = false
	SFX.play("ui_select", -4.0)
	var cb := _cb
	_cb = Callable()
	if cb.is_valid():
		cb.call(i)
