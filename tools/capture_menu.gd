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
	print("CAPTURE MENU DONE")
	get_tree().quit()
