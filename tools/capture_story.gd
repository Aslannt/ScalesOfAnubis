extends Node
## Capturas de la intro y el final (con ventana). Correr sin --headless.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://shots")
	GameState.reset()
	var intro: Node = load("res://scenes/story/Intro.tscn").instantiate()
	add_child(intro)
	await _t(5.2)
	_shot("20_intro_balanza")
	while not intro._dlg.visible:
		await _t(0.2)
	await _t(1.5)
	_shot("21_intro_anubis")
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
