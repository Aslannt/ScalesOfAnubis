extends Control
## Menu principal (GDD 11, PROMPT_PULIDO.md punto 7): fondo en capas con
## estrellas que titilan, luna con halo que respira, nubes y arena que se
## mueven, piramides con sombreado, titulo dorado con contorno. Todo por
## codigo para que sea facil de ajustar.

const TEX := "res://assets/textures/"
const OPTIONS_SCRIPT := preload("res://scripts/ui/options_panel.gd")
const STARFIELD := preload("res://scripts/ui/starfield.gd")

var _moon_halo: TextureRect
var _clouds: Array = []
var _titulo: Label
var _titulo_top: Label
var _t: float = 0.0
var _fade: ColorRect
var _opciones: PanelContainer
var _btn_nueva: Button
var _starting := false


func _ready() -> void:
	MenuMusic.play_theme()
	theme = UIStyle.theme()
	get_tree().paused = false
	_layer("title_sky.png")
	var stars := STARFIELD.new()
	stars.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stars)
	_moon_halo = _sprite("title_moon.png", Vector2(14, 6))
	for i in range(3):
		var cl := _sprite("title_cloud.png", Vector2(i * 190.0 - 40.0, 70.0 + i * 22.0))
		cl.modulate.a = 0.75 - i * 0.12
		_clouds.append({"node": cl, "speed": 3.0 + i * 2.2})
	_layer("title_far.png")
	_layer("title_near.png")
	_sand_particles()
	_build_title()
	_build_buttons()

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 1.0)


func _layer(file: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(TEX + file)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _sprite(file: String, pos: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(TEX + file)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.position = pos
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _sand_particles() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(-10, 230)
	p.amount = 60
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(4, 36)
	p.direction = Vector2(1, -0.05)
	p.spread = 6.0
	p.gravity = Vector2(0, 2)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.82, 0.55, 0.8))
	g.set_color(1, Color(1.0, 0.82, 0.55, 0.0))
	p.color_ramp = g
	add_child(p)


func _build_title() -> void:
	var bold: Font = load("res://assets/fonts/Silkscreen-Bold.ttf")
	_titulo_top = _title_label("SCALES OF", 16, bold, 24)
	_titulo = _title_label("ANUBIS", 32, bold, 40)
	var sub := _title_label(Textos.t("menu_subtitulo").to_upper(), 8, null, 80)
	sub.add_theme_color_override("font_color", Color(0.95, 0.85, 0.7))
	sub.add_theme_constant_override("outline_size", 2)
	# lineas doradas decorativas a los lados del subtitulo
	for side in [-1, 1]:
		var line := ColorRect.new()
		line.color = UIStyle.GOLD
		line.size = Vector2(46, 1)
		line.position = Vector2(240 + side * 44 - (46 if side < 0 else 0), 84)
		add_child(line)


func _title_label(text: String, size: int, font: Font, y: float) -> Label:
	var l := Label.new()
	l.text = text
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.98, 0.78, 0.28))
	l.add_theme_color_override("font_outline_color", Color(0.22, 0.1, 0.05))
	l.add_theme_constant_override("outline_size", 4 if size >= 16 else 2)
	l.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.06, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(480, size + 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _build_buttons() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.position = Vector2(240 - 85, 150)
	box.size = Vector2(170, 80)
	add_child(box)
	if GameState.has_save():
		var bc := _button(box, Textos.t("menu_continuar"), _on_continuar)
		bc.grab_focus.call_deferred()
		box.position.y -= 14
	_btn_nueva = _button(box, Textos.t("menu_nueva_partida"), _on_nueva)
	_button(box, Textos.t("menu_opciones"), _toggle_opciones)
	_button(box, Textos.t("menu_salir"), func(): SFX.play("ui_select"); get_tree().quit())
	if not GameState.has_save():
		_btn_nueva.grab_focus()

	_opciones = PanelContainer.new()
	_opciones.set_script(OPTIONS_SCRIPT)
	_opciones.position = Vector2(240 - 115, 120)
	_opciones.size = Vector2(230, 120)
	_opciones.visible = false
	add_child(_opciones)


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(170, 24)
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): b.grab_focus())
	b.focus_entered.connect(func(): SFX.play("dialogue_blip", -6.0))
	parent.add_child(b)
	return b


func _toggle_opciones() -> void:
	SFX.play("ui_select")
	_opciones.visible = not _opciones.visible


func _process(delta: float) -> void:
	_t += delta
	_moon_halo.modulate = Color(1, 1, 1, 0.85 + 0.15 * sin(_t * 1.3))
	for c in _clouds:
		var n: TextureRect = c["node"]
		n.position.x += c["speed"] * delta
		if n.position.x > 490:
			n.position.x = -150
	# el titulo "respira": flota 1 px y su dorado brilla suave
	_titulo.position.y = 40 + roundf(sin(_t * 1.6) * 1.0)
	var glow := 0.5 + 0.5 * sin(_t * 2.0)
	_titulo.add_theme_color_override("font_color", Color(0.98, 0.74, 0.24).lerp(Color(1.0, 0.92, 0.55), glow * 0.6))


func _on_nueva() -> void:
	if _starting:
		return
	_starting = true
	SFX.play("ui_select")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func():
		GameState.reset()
		GameState.delete_save()
		get_tree().change_scene_to_file("res://scenes/story/Intro.tscn"))


func _on_continuar() -> void:
	if _starting:
		return
	_starting = true
	SFX.play("ui_select")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func():
		if not GameState.load_game():
			GameState.reset()
		MenuMusic.stop_theme()
		get_tree().change_scene_to_file("res://scenes/world/Farm.tscn"))
