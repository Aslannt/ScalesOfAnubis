extends CanvasLayer
## Pausa (GDD 11): Esc alterna. Sigue activo mientras el arbol esta pausado.

const OPTIONS_SCRIPT := preload("res://scripts/ui/options_panel.gd")

var _panel: Panel
var _opciones: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("modal")
	layer = 20
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_panel = Panel.new()
	_panel.theme = UIStyle.theme()
	_panel.position = Vector2(240 - 90, 135 - 62)
	_panel.size = Vector2(180, 124)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.position = Vector2(10, 8)
	box.size = Vector2(160, 108)
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)

	var titulo := Label.new()
	titulo.text = Textos.t("pausa_titulo").to_upper()
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 16)
	titulo.add_theme_color_override("font_color", Color(0.98, 0.78, 0.28))
	box.add_child(titulo)

	var btn_continuar := Button.new()
	btn_continuar.text = Textos.t("pausa_continuar")
	btn_continuar.pressed.connect(toggle)
	box.add_child(btn_continuar)

	var btn_opciones := Button.new()
	btn_opciones.text = Textos.t("pausa_opciones")
	box.add_child(btn_opciones)

	var btn_salir := Button.new()
	btn_salir.text = Textos.t("pausa_salir_menu")
	btn_salir.pressed.connect(_salir_al_menu)
	box.add_child(btn_salir)

	_opciones = PanelContainer.new()
	_opciones.set_script(OPTIONS_SCRIPT)
	_opciones.theme = UIStyle.theme()
	_opciones.position = Vector2(240 - 115, 135 - 60)
	_opciones.size = Vector2(230, 120)
	_opciones.visible = false
	add_child(_opciones)
	btn_opciones.pressed.connect(func(): _opciones.visible = not _opciones.visible)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	# no abrir la pausa encima de un dialogo o del codice (ambos ya pausan)
	if not visible and get_tree().paused:
		return
	SFX.play("ui_select")
	visible = not visible
	get_tree().paused = visible
	if not visible:
		_opciones.visible = false
		GameState.lock_player_input(0.2)


func _salir_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/Main.tscn")
