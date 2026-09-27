extends Node
## Prueba de guardado: juega un poco, autoguarda, recarga Farm con
## "Continuar" y verifica que parcelas, defensas, deben y decisiones vuelven.

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")


func _ready() -> void:
	var ok := true
	GameState.reset()
	GameState.delete_save()
	var farm := FARM_SCENE.instantiate()
	add_child(farm)
	await _frames(5)
	var wb = farm.get_node("WorldBuilder")
	var p0 = wb.farm_plots[20]
	p0.till()
	p0.plant("lino")
	p0.water()
	GameState.add_deben(40)
	wb.defense_spots[1].build("brasero")
	GameState.register_decision("robo_altar", "robado")
	GameState.current_day = 2
	farm.get_node("StoryDirector").autosave()
	var deben := GameState.deben
	farm.queue_free()
	await _frames(3)
	ok = ok and GameState.has_save()
	GameState.reset()
	ok = ok and GameState.load_game()
	var farm2 := FARM_SCENE.instantiate()
	add_child(farm2)
	await _frames(5)
	var wb2 = farm2.get_node("WorldBuilder")
	var p1 = wb2.farm_plots[20]
	var checks := {
		"parcela": p1.state == FarmPlot.State.PLANTED and p1.crop_id == "lino" and p1.watered_today,
		"defensa": wb2.defense_spots[1].built == "brasero",
		"deben": GameState.deben == deben,
		"decision": GameState.decisiones.get("robo_altar", "") == "robado",
		"dia": GameState.current_day == 2,
	}
	for k in checks:
		print("  ", "ok: " if checks[k] else "FALLO: ", k)
		ok = ok and checks[k]
	GameState.delete_save()
	print("TEST GUARDADO: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
