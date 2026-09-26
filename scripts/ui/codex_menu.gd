extends CanvasLayer
## Códice / Libro de los Muertos (Tab). GDD 6.8: solo lore verificado.

var _list: ItemList
var _detalle_titulo: Label
var _detalle_texto: Label
var _detalle_thot: Label
var _icono: TextureRect
var _ids_visibles: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.05, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-170, -100)
	panel.size = Vector2(340, 200)
	bg.add_child(panel)

	_list = ItemList.new()
	_list.position = Vector2(6, 6)
	_list.size = Vector2(110, 188)
	_list.item_selected.connect(_on_selected)
	panel.add_child(_list)

	_icono = TextureRect.new()
	_icono.position = Vector2(124, 8)
	_icono.size = Vector2(28, 28)
	_icono.texture_filter = TextureRect.TEXTURE_FILTER_NEAREST
	_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(_icono)

	_detalle_titulo = Label.new()
	_detalle_titulo.position = Vector2(158, 10)
	_detalle_titulo.add_theme_font_size_override("font_size", 14)
	panel.add_child(_detalle_titulo)

	_detalle_texto = Label.new()
	_detalle_texto.position = Vector2(124, 42)
	_detalle_texto.size = Vector2(206, 90)
	_detalle_texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(_detalle_texto)

	_detalle_thot = Label.new()
	_detalle_thot.position = Vector2(124, 138)
	_detalle_thot.size = Vector2(206, 56)
	_detalle_thot.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detalle_thot.add_theme_color_override("font_color", Color(0.6, 0.85, 0.9))
	panel.add_child(_detalle_thot)

	Codex.entry_unlocked.connect(func(_id): _refresh_list())
	_refresh_list()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("codex"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh_list()


func _refresh_list() -> void:
	var sel := _list.get_selected_items()
	_list.clear()
	_ids_visibles.clear()
	for e in Codex.entries:
		var texto: String = e["titulo"] if e["desbloqueada"] else "???"
		_list.add_item(texto)
		_ids_visibles.append(e["id"])
	if sel.size() > 0:
		_list.select(sel[0])
		_on_selected(sel[0])
	elif _ids_visibles.size() > 0:
		_list.select(0)
		_on_selected(0)


func _on_selected(index: int) -> void:
	var id: String = _ids_visibles[index]
	var e: Dictionary = Codex.get_entry(id)
	if not e.get("desbloqueada", false):
		_detalle_titulo.text = "???"
		_detalle_texto.text = ""
		_detalle_thot.text = ""
		_icono.texture = null
		return
	_detalle_titulo.text = e["titulo"]
	_detalle_texto.text = e["texto"]
	_detalle_thot.text = "Thot: \"%s\"" % e["thot"]
	_icono.texture = load(e["icono"])
