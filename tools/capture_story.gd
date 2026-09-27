extends Node
## Capturas de la intro y el final (con ventana). Correr sin --headless.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://shots")
	GameState.reset()
	var intro: Node = load("res://scenes/story/Intro.tscn").instantiate()
	add_child(intro)
	await _t(4.2)
	_shot("20a_intro_tarjeta")
	await _t(9.0)
	_shot("20b_intro_tarjeta_ammit")
	for i in range(8):
		intro._advance = true
		await _t(0.4)
	while not intro._hall.visible:
		intro._advance = true
		await _t(0.2)
	await _t(2.6)
	_shot("20c_intro_balanza_oscila")
	while not intro._stamp.visible:
		await _t(0.1)
	await _t(0.6)
	_shot("20_intro_balanza")
	while not intro._dlg.visible:
		await _t(0.2)
	await _t(1.5)
	_shot("21_intro_anubis")
	while intro._thot.position.x > 300 or intro._dlg.visible:
		if intro._dlg.visible and intro._thot.position.x > 300:
			intro._dlg._advance()
		await _t(0.3)
		if not intro._dlg.visible and intro._thot.position.x < 300:
			break
	await _t(1.8)
	_shot("21b_intro_thot")
	while intro._dlg.visible:
		intro._dlg._advance()
		await _t(0.3)
	await _t(1.2)
	_shot("21c_intro_mision")
	intro.queue_free()
	GameState.heart_weight = 38.0
	GameState.register_decision("robo_altar", "respetado")
	GameState.register_decision("noche2", "aldea")
	GameState.total_enemies_defeated = 31
	var fin: Node = load("res://scenes/story/Final.tscn").instantiate()
	add_child(fin)
	var shots := {"pesaje": false, "ba": false}
	var t := 0.0
	while not fin._can_leave and t < 90.0:
		if fin._dlg.visible:
			await _t(1.2)
			if not shots["pesaje"] and fin._result.text != "":
				shots["pesaje"] = true
				_shot("22_final_pesaje")
			elif not shots["ba"] and not fin._scale.visible:
				shots["ba"] = true
				await _t(2.0)
				_shot("23_final_recuerdo_ba")
			fin._dlg._advance()
			fin._dlg._advance()
		await _t(0.2)
		t += 1.4
	await _t(0.5)
	_shot("24_gracias")
	print("STORY CAPTURE DONE")
	get_tree().quit()


func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://shots/%s.png" % n)
	print("captured ", n)


func _t(s: float) -> void:
	await get_tree().create_timer(s, true).timeout
