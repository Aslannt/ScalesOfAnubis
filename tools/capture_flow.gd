extends Node
## Reproduce el flujo real (Main.tscn -> "Nueva partida" -> Farm.tscn) sin
## que este propio nodo watcher se autodestruya (change_scene_to_file
## libera el current_scene, y este nodo lo es al arrancar por CLI).

const MENU_SCENE := preload("res://scenes/ui/Main.tscn")
const FARM_SCENE := preload("res://scenes/world/Farm.tscn")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://shots")
	var menu := MENU_SCENE.instantiate()
	get_tree().root.add_child(menu)
	for i in range(10):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://shots/flow_01_menu.png")
	print("menu captured")

	menu.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var farm := FARM_SCENE.instantiate()
	get_tree().root.add_child(farm)
	get_tree().current_scene = farm
	for i in range(6):
		await get_tree().process_frame
	var img2 := get_viewport().get_texture().get_image()
	img2.save_png("res://shots/flow_02_farm_recien_cargado.png")
	print("farm just-loaded captured")

	for i in range(150):
		await get_tree().process_frame
	var cam = farm.get_node("CameraRig")
	print("camera current:", cam.current, " global_pos:", cam.global_position)
	var player = get_tree().get_first_node_in_group("player")
	print("player found:", player != null)
	if player:
		print("player global_pos:", player.global_position, " visible:", player.visible)
		print("player distance to camera:", player.global_position.distance_to(cam.global_position))
	var img3 := get_viewport().get_texture().get_image()
	img3.save_png("res://shots/flow_03_farm_2seg_despues.png")
	print("farm settled captured")
	print("FLOW CAPTURE DONE")
	get_tree().quit()
