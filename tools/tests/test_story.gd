extends Node
## Prueba de intro y final: avanza los dialogos y verifica que la intro
## llega a la granja y el final llega a la pantalla de gracias sin errores.

func _ready() -> void:
	var ok := true
	GameState.reset()
	GameState.heart_weight = 38.0
	GameState.register_decision("robo_altar", "respetado")
	GameState.register_decision("noche2", "aldea")
	var fin: Node = load("res://scenes/story/Final.tscn").instantiate()
	add_child(fin)
	var t := 0.0
	while not fin._can_leave and t < 80.0:
		if fin._dlg.visible:
			fin._dlg._advance()
		await get_tree().create_timer(0.25, true, false, true).timeout
		t += 0.25
	if fin._can_leave and fin._thanks != null:
		print("  ok: el final llega a la pantalla de gracias (%.1fs)" % t)
	else:
		ok = false
		printerr("  FALLO: el final no llego a gracias")
	fin.queue_free()
	GameTime.paused = false
	var intro: Node = load("res://scenes/story/Intro.tscn").instantiate()
	add_child(intro)
	t = 0.0
	while not intro._leaving and t < 90.0:
		if intro._dlg.visible:
			intro._dlg._advance()
		else:
			intro._advance = true
		await get_tree().create_timer(0.25, true, false, true).timeout
		t += 0.25
	if intro._leaving:
		print("  ok: la intro termina y pasa a la granja (%.1fs)" % t)
	else:
		ok = false
		printerr("  FALLO: la intro no termino")
	print("TEST HISTORIA: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)
