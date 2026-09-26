extends PanelContainer
## Panel de opciones reutilizable (menu principal y pausa): volumen y pantalla
## completa. GDD 11.

var _buses := ["Master", "Music", "SFX"]
var _sliders: Dictionary = {}


func _ready() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var labels := {
		"Master": Textos.t("opciones_volumen_general"),
		"Music": Textos.t("opciones_volumen_musica"),
		"SFX": Textos.t("opciones_volumen_sfx"),
	}

	for bus_name in _buses:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = labels[bus_name]
		lbl.custom_minimum_size = Vector2(90, 0)
		row.add_child(lbl)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size = Vector2(120, 0)
		var idx := AudioServer.get_bus_index(bus_name)
		if idx == -1:
			slider.value = 1.0
		else:
			slider.value = db_to_linear(AudioServer.get_bus_volume_db(idx))
		slider.value_changed.connect(func(v): _on_volume_changed(bus_name, v))
		row.add_child(slider)
		box.add_child(row)
		_sliders[bus_name] = slider

	var fs_row := HBoxContainer.new()
	var fs_lbl := Label.new()
	fs_lbl.text = Textos.t("opciones_pantalla_completa")
	fs_lbl.custom_minimum_size = Vector2(90, 0)
	fs_row.add_child(fs_lbl)
	var fs_check := CheckBox.new()
	fs_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.toggled.connect(_on_fullscreen_toggled)
	fs_row.add_child(fs_check)
	box.add_child(fs_row)

	var btn_volver := Button.new()
	btn_volver.text = Textos.t("opciones_volver")
	btn_volver.pressed.connect(func(): visible = false)
	box.add_child(btn_volver)


func _on_volume_changed(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))


func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)
