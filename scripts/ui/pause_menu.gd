extends CanvasLayer
## Pausa (GDD 11): Esc alterna. Sigue activo mientras el arbol esta pausado.

const OPTIONS_SCRIPT := preload("res://scripts/ui/options_panel.gd")

var _panel: Panel
var _opciones: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	visible = false

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-70, -60)
	_panel.size = Vector2(140, 120)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.position = Vector2(10, 8)
	box.size = Vector2(120, 104)
	_panel.add_child(box)

	var titulo := Label.new()
	titulo.text = Textos.t("pausa_titulo")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	_opciones.set_anchors_preset(Control.PRESET_CENTER)
	_opciones.position = Vector2(-110, -70)
	_opciones.size = Vector2(220, 140)
	_opciones.visible = false
	add_child(_opciones)
	btn_opciones.pressed.connect(func(): _opciones.visible = not _opciones.visible)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	SFX.play("ui_select")
	visible = not visible
	get_tree().paused = visible
	if not visible:
		_opciones.visible = false


func _salir_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/Main.tscn")
