extends CanvasLayer
## Códice / Libro de los Muertos (Tab). GDD 6.8: solo lore verificado.
## Se ve como un rollo de papiro: tinta marron, titulos en tinta roja (los
## escribas egipcios usaban rojo para encabezados, las "rubricas") y el
## comentario de Thot en azul lapislazuli.

const PAPYRUS := Color(0.87, 0.78, 0.58)
const PAPYRUS_D := Color(0.72, 0.6, 0.4)
const INK := Color(0.24, 0.15, 0.08)
const RUBRIC := Color(0.66, 0.16, 0.1)
const LAPIS := Color(0.12, 0.22, 0.48)

var _list: ItemList
var _detalle_titulo: Label
var _detalle_texto: Label
var _detalle_thot: Label
var _icono: TextureRect
var _contador: Label
var _ids_visibles: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.05, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# rollo de papiro: cuerpo + dos varillas de madera a los lados
	var scroll := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPYRUS
	sb.border_color = PAPYRUS_D
	sb.set_border_width_all(2)
	sb.anti_aliasing = false
	scroll.add_theme_stylebox_override("panel", sb)
	scroll.position = Vector2(34, 22)
	scroll.size = Vector2(412, 226)
	bg.add_child(scroll)
	for x in [26.0, 446.0]:
		var rod := ColorRect.new()
		rod.color = Color(0.42, 0.26, 0.12)
		rod.position = Vector2(x, 16)
		rod.size = Vector2(8, 238)
		bg.add_child(rod)
		for y in [12.0, 252.0]:
			var cap := ColorRect.new()
			cap.color = UIStyle.GOLD
			cap.position = Vector2(x - 1, y)
			cap.size = Vector2(10, 6)
			bg.add_child(cap)
	# fibras horizontales del papiro
	for i in range(14):
		var f := ColorRect.new()
		f.color = Color(PAPYRUS_D, 0.35)
		f.position = Vector2(2, 8 + i * 16)
		f.size = Vector2(408, 1)
		scroll.add_child(f)

	var titulo := UIStyle.make_label(scroll, Textos.t("codex_titulo"), Vector2(0, 6), UIStyle.SMALL, RUBRIC)
	titulo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	titulo.size = Vector2(412, 10)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contador = UIStyle.make_label(scroll, "", Vector2(330, 6), UIStyle.SMALL, INK)
	_contador.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))

	_list = ItemList.new()
	_list.position = Vector2(8, 22)
	_list.size = Vector2(124, 196)
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(PAPYRUS_D, 0.35)
	clear.anti_aliasing = false
	_list.add_theme_stylebox_override("panel", clear)
	var sel := StyleBoxFlat.new()
	sel.bg_color = Color(RUBRIC, 0.85)
	sel.anti_aliasing = false
	_list.add_theme_stylebox_override("selected", sel)
	_list.add_theme_stylebox_override("selected_focus", sel)
	_list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_list.add_theme_stylebox_override("cursor", StyleBoxEmpty.new())
	_list.add_theme_stylebox_override("cursor_unfocused", StyleBoxEmpty.new())
	_list.add_theme_color_override("font_color", INK)
	_list.add_theme_color_override("font_selected_color", PAPYRUS)
	_list.add_theme_color_override("font_hovered_color", RUBRIC)
	_list.add_theme_font_size_override("font_size", UIStyle.SMALL)
	_list.item_selected.connect(_on_selected)
	scroll.add_child(_list)

	var frame := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(PAPYRUS_D, 0.4)
	fs.border_color = INK
	fs.set_border_width_all(1)
	fs.anti_aliasing = false
	frame.add_theme_stylebox_override("panel", fs)
	frame.position = Vector2(140, 22)
	frame.size = Vector2(52, 52)
	scroll.add_child(frame)
	_icono = TextureRect.new()
	_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icono.texture_filter = TextureRect.TEXTURE_FILTER_NEAREST
	_icono.position = Vector2(4, 4)
	_icono.size = Vector2(44, 44)
	frame.add_child(_icono)

	_detalle_titulo = _ink_label(scroll, Vector2(200, 26), Vector2(204, 20), UIStyle.BIG, RUBRIC)
	_detalle_texto = _ink_label(scroll, Vector2(140, 80), Vector2(262, 80), UIStyle.SMALL, INK)
	_detalle_thot = _ink_label(scroll, Vector2(140, 166), Vector2(262, 50), UIStyle.SMALL, LAPIS)

	var hint := UIStyle.make_label(bg, Textos.t("codex_cerrar"), Vector2(0, 256), UIStyle.SMALL, UIStyle.TEXT_DIM)
	hint.size = Vector2(480, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	Codex.entry_unlocked.connect(_on_unlocked)
	_refresh_list()


func _ink_label(parent: Node, pos: Vector2, size: Vector2, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("line_spacing", 2)
	parent.add_child(l)
	return l


func _on_unlocked(id: String) -> void:
	_refresh_list()
	var e := Codex.get_entry(id)
	if not e.is_empty() and is_inside_tree():
		GameState.thot(Textos.t("codex_nueva", {"n": e["titulo"]}))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("codex"):
		# no abrir encima de dialogos/menus (ya pausan el juego)
		if not visible and get_tree().paused:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	SFX.play("ui_select", -4.0)
	if visible:
		_refresh_list()
		_list.grab_focus()
	else:
		GameState.lock_player_input(0.2)


func _refresh_list() -> void:
	var sel := _list.get_selected_items()
	_list.clear()
	_ids_visibles.clear()
	for e in Codex.entries:
		var texto: String = e["titulo"] if e["desbloqueada"] else "? ? ?"
		_list.add_item(texto)
		_ids_visibles.append(e["id"])
	_contador.text = "%d/%d" % [Codex.unlocked_count(), Codex.entries.size()]
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
		_detalle_titulo.text = "? ? ?"
		_detalle_texto.text = Textos.t("codex_vacia")
		_detalle_thot.text = ""
		_icono.texture = null
		return
	_detalle_titulo.text = e["titulo"]
	_detalle_texto.text = e["texto"]
	_detalle_thot.text = "Thot: \"%s\"" % e["thot"]
	_icono.texture = load(e["icono"])
