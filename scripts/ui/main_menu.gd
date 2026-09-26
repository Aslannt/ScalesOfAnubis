extends Control
## Menu principal (GDD 11): Nueva partida, Opciones, Salir.

@onready var titulo: Label = $Titulo
@onready var subtitulo: Label = $Subtitulo
@onready var btn_nueva: Button = $Botones/Nueva
@onready var btn_opciones: Button = $Botones/Opciones
@onready var btn_salir: Button = $Botones/Salir
@onready var opciones: Control = $Opciones


func _ready() -> void:
	titulo.text = Textos.t("menu_titulo")
	subtitulo.text = Textos.t("menu_subtitulo")
	btn_nueva.text = Textos.t("menu_nueva_partida")
	btn_opciones.text = Textos.t("menu_opciones")
	btn_salir.text = Textos.t("menu_salir")
	btn_nueva.pressed.connect(_on_nueva)
	btn_opciones.pressed.connect(func(): opciones.visible = not opciones.visible)
	btn_salir.pressed.connect(func(): get_tree().quit())
	opciones.visible = false
	btn_nueva.grab_focus()


func _on_nueva() -> void:
	get_tree().change_scene_to_file("res://scenes/world/Farm.tscn")
