extends Node
## Captura del menu principal (companero de capture.gd). Correr con:
## godot --path . res://tools/capture_menu.tscn (SIN --headless)

const MENU_SCENE := preload("res://scenes/ui/Main.tscn")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://shots")
	add_child(MENU_SCENE.instantiate())
	await get_tree().create_timer(1.6).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://shots/09_menu_principal.png")
	# panel de opciones abierto (espanol e ingles)
	var menu = get_child(0)
	menu._toggle_opciones()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://shots/43_opciones.png")
	Textos.set_idioma("en")
	await get_tree().create_timer(0.3).timeout
	var p = menu.get("_opciones")
	if is_instance_valid(p):
		p.visible = true
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("res://shots/44_options_en.png")
	Textos.set_idioma("es")
	print("CAPTURE MENU DONE")
	get_tree().quit()
