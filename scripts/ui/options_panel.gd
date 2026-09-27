extends PanelContainer
## Panel de opciones reutilizable (menu principal y pausa). Todo se guarda en
## user://opciones.cfg a traves del autoload Opciones (fase 7): volumenes,
## pantalla completa, vibracion del mando, sacudida de camara, destellos de
## pantalla, texto rapido e idioma.

var _buses := ["Master", "Music", "SFX"]
var _box: VBoxContainer


func _ready() -> void:
	_build()
	visibility_changed.connect(_recenter)
	Textos.idioma_cambiado.connect(_rebuild)


func _build() -> void:
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)
	var title := Label.new()
	title.text = Textos.t("opciones_titulo").to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	_box.add_child(title)

	var labels := {
		"Master": Textos.t("opciones_volumen_general"),
		"Music": Textos.t("opciones_volumen_musica"),
		"SFX": Textos.t("opciones_volumen_sfx"),
	}
	for bus_name in _buses:
		var key: String = "vol_" + bus_name
		_slider_row(labels[bus_name], float(Opciones.get_v(key)), func(v): Opciones.set_v(key, v))
	_slider_row(Textos.t("opciones_sacudida"), float(Opciones.get_v("sacudida")), func(v): Opciones.set_v("sacudida", v))
	_check_row(Textos.t("opciones_pantalla_completa"), bool(Opciones.get_v("pantalla_completa")), func(on): Opciones.set_v("pantalla_completa", on))
	_check_row(Textos.t("opciones_vibracion"), bool(Opciones.get_v("vibracion")), func(on): Opciones.set_v("vibracion", on))
	_check_row(Textos.t("opciones_efectos_pantalla"), bool(Opciones.get_v("efectos_pantalla")), func(on): Opciones.set_v("efectos_pantalla", on))
	_check_row(Textos.t("opciones_texto_rapido"), bool(Opciones.get_v("texto_rapido")), func(on): Opciones.set_v("texto_rapido", on))

	# idioma: boton que alterna Espanol / English
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = Textos.t("opciones_idioma")
	lbl.custom_minimum_size = Vector2(110, 0)
	row.add_child(lbl)
	var lang := Button.new()
	lang.text = Textos.t("idioma_" + String(Opciones.get_v("idioma")))
	lang.add_theme_font_size_override("font_size", UIStyle.SMALL)
	lang.custom_minimum_size = Vector2(110, 14)
	lang.pressed.connect(func():
		var nuevo := "en" if String(Opciones.get_v("idioma")) == "es" else "es"
		Opciones.set_v("idioma", nuevo)
		Textos.set_idioma(nuevo)
		SFX.play("ui_select"))
	row.add_child(lang)
	_box.add_child(row)

	var btn_volver := Button.new()
	btn_volver.text = Textos.t("opciones_volver")
	btn_volver.add_theme_font_size_override("font_size", UIStyle.SMALL)
	btn_volver.pressed.connect(func(): visible = false)
	_box.add_child(btn_volver)


func _rebuild() -> void:
	if _box:
		_box.queue_free()
		_box = null
	_build.call_deferred()
	_recenter.call_deferred()


func _slider_row(text: String, value: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(110, 0)
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(110, 0)
	slider.value_changed.connect(cb)
	row.add_child(slider)
	_box.add_child(row)


func _check_row(text: String, on: bool, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(110, 0)
	row.add_child(lbl)
	var check := CheckBox.new()
	check.button_pressed = on
	check.toggled.connect(cb)
	row.add_child(check)
	_box.add_child(row)


## Centrado en la pantalla de 480x270 (antes crecia hacia abajo y se salia).
func _recenter() -> void:
	if not visible:
		return
	await get_tree().process_frame
	reset_size()
	position = (Vector2(480, 270) - size) * 0.5
