extends Node
## Prueba automatizada del bug "dialogo en bucle" (reporte de Deivid):
## hablar con un NPC, avanzar TODAS las lineas con E (teclado real simulado)
## y confirmar que el dialogo se cierra, no se reabre solo y el jugador
## puede moverse despues.
## Correr: godot --headless --path . res://tools/tests/test_dialogue.tscn

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")

var _fallos: Array = []


func _ready() -> void:
	var farm := FARM_SCENE.instantiate()
	add_child(farm)
	await _frames(5)
	var player: Player = get_tree().get_first_node_in_group("player")
	var wb = farm.get_node("WorldBuilder")
	var dlg = get_tree().get_first_node_in_group("dialogue_box")

	for npc_id in ["meret", "ptahmose", "iry"]:
		var npc = null
		for n in wb.npcs:
			if n.npc_id == npc_id:
				npc = n
		player.global_position = npc.global_position + Vector3(0, 0.2, 1.2)
		await _frames(3)

		# dos conversaciones seguidas por NPC: intro y la siguiente
		for vuelta in range(2):
			await _tap_key(KEY_E)
			if not dlg.visible:
				_fallos.append("%s: el dialogo no se abrio (vuelta %d)" % [npc_id, vuelta])
				continue
			var guard := 0
			while dlg.visible and guard < 40:
				await _tap_key(KEY_E)
				guard += 1
			await _frames(10)
			if dlg.visible:
				_fallos.append("%s: el dialogo se reabrio solo / no se cerro (vuelta %d)" % [npc_id, vuelta])
			if get_tree().paused:
				_fallos.append("%s: el arbol quedo en pausa" % npc_id)
			# esperar a que pase el bloqueo corto antes de la siguiente vuelta
			await get_tree().create_timer(0.35).timeout

		# el jugador debe poder moverse despues de hablar
		var antes := player.global_position
		Input.action_press("move_left")
		await _frames(20)
		Input.action_release("move_left")
		if player.global_position.distance_to(antes) < 0.3:
			_fallos.append("%s: el jugador no se puede mover despues del dialogo" % npc_id)

	if _fallos.is_empty():
		print("TEST DIALOGO: OK")
	else:
		for f in _fallos:
			printerr("TEST DIALOGO FALLO: ", f)
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _tap_key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame
