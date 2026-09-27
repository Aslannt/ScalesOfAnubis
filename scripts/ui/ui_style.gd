class_name UIStyle
extends RefCounted
## Estilo visual comun de la interfaz (HUD, pausa, dialogo, menus): paneles
## oscuros con marco dorado de 1 px, sin antialias, y la fuente pixel en
## tamanos multiplos de 8 para que se vea nitida a 480x270.

const GOLD := Color(0.86, 0.66, 0.22)
const GOLD_DARK := Color(0.52, 0.37, 0.12)
const INK := Color(0.07, 0.055, 0.05, 0.86)
const TEXT := Color(0.96, 0.92, 0.82)
const TEXT_DIM := Color(0.72, 0.66, 0.55)
const SMALL := 8
const BIG := 16


static func panel_style(bg: Color = INK, border: Color = GOLD) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.anti_aliasing = false
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 0
	s.shadow_offset = Vector2(1, 1)
	return s


static func make_panel(parent: Node, pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", panel_style())
	parent.add_child(p)
	# esquinas doradas de 2x2 (detalle egipcio minimo)
	for corner in [Vector2(0, 0), Vector2(size.x - 2, 0), Vector2(0, size.y - 2), Vector2(size.x - 2, size.y - 2)]:
		var r := ColorRect.new()
		r.color = GOLD
		r.position = corner
		r.size = Vector2(2, 2)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(r)
	return p


static func make_label(parent: Node, text: String, pos: Vector2, font_size: int = SMALL, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


static func make_icon(parent: Node, tex_path: String, pos: Vector2, size: Vector2 = Vector2(16, 16)) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(tex_path)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.position = pos
	t.size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t
