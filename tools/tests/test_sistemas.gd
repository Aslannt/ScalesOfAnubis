extends Node
## Sistemas de progresion (fases 1-3 del plan): estados del corazon,
## templo de Maat, mejoras, amistad y estaciones.
## Correr: godot --headless --path . res://tools/tests/test_sistemas.tscn

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")
var ok := true
var farm: Node
var player: Player


func check(c: bool, m: String) -> void:
	print("  ", "ok: " if c else "FALLO: ", m)
	ok = ok and c


func _ready() -> void:
	GameState.reset()
	farm = FARM_SCENE.instantiate()
	add_child(farm)
	await _secs(0.3)
	player = get_tree().get_first_node_in_group("player")
	await _test_corazon()
	await _test_templo()
	await _test_mejoras()
	await _test_amistad()
	print("TEST SISTEMAS: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)


func _test_corazon() -> void:
	print("CORAZON")
	var cambios: Array = []
	GameState.heart_state_changed.connect(func(n, _a): cambios.append(n))
	check(GameState.heart_state_id == "equilibrio", "empieza en equilibrio")
	GameState.shift_heart(-25.0, "ofrenda")
	check(GameState.heart_state_id == "pluma" and cambios == ["pluma"], "corazon liviano -> favor de Maat")
	check(is_equal_approx(GameState.heart_mod("venta", 1.0), 1.25), "Maat: Ptahmose paga mas")
	# regeneracion nocturna
	GameTime.force_phase(GameTime.Phase.NIGHT)
	GameState.health = 50
	await _secs(2.5)
	check(GameState.health > 50, "Maat: de noche te curas solo (%d)" % GameState.health)
	GameState.shift_heart(60.0, "robo_altar")
	check(GameState.heart_state_id == "hambre", "corazon muy pesado -> hambre de Ammit")
	check(GameState.heart_mod("dano", 1.0) > 1.5, "Ammit: mas dano")
	var hud = farm.get_node("HUD")
	check(hud._lbl_estado.text == Textos.t("estado_hambre"), "el HUD muestra el estado")
	# robo de vida al matar
	GameState.health = 40
	var nd = farm.get_node("NightDirector")
	var e = nd.spawn("sombra", "", "", player.global_position + Vector3(3, 0, 0))
	await _secs(0.8)
	e.take_hit(999)
	await _secs(0.3)
	check(GameState.health >= 44, "Ammit: matar cura (%d)" % GameState.health)
	GameState.shift_heart(-35.0, "")
	check(GameState.heart_state_id == "equilibrio", "vuelve al equilibrio")
	GameTime.force_phase(GameTime.Phase.DAY)


func _test_templo() -> void:
	print("TEMPLO")
	var p := GameState.temple_next()
	check(p.get("id", "") == "columnas", "primera pieza: columnas")
	check(not GameState.restore_temple_piece(p), "sin recursos no se restaura")
	GameState.add_item("trigo", 3)
	GameState.add_deben(20)
	check(GameState.restore_temple_piece(p), "se restauran las columnas")
	check(GameState.max_health == 115, "bendicion: +15 vida maxima (%d)" % GameState.max_health)
	var tr = farm.get_node("WorldBuilder/Props").find_children("*", "TempleRestoration", true, false)
	check(tr.size() == 1, "el templo tiene su restauracion visual")
	await _secs(1.2)
	check(tr[0]._built["columnas"].visible and not tr[0]._ruins["columnas"].visible, "las columnas se ven restauradas")
	# por Meret: menu del templo
	var meret = _npc("meret")
	GameState.meret_intro_shown = true
	GameState.meret_mission_done = true
	player.global_position = meret.global_position + Vector3(0, 0.2, 1.2)
	meret.interact()
	await _frames(3)
	var choice = get_tree().get_first_node_in_group("choice_box")
	check(choice.visible and choice._buttons.size() == 4, "Meret ofrece charlar, regalar, templo y adios")
	choice._choose(-1)
	await _frames(3)


func _test_mejoras() -> void:
	print("MEJORAS")
	GameState.add_deben(100)
	check(GameState.buy_upgrade("regadera"), "compra de la vasija doble")
	check(not GameState.buy_upgrade("regadera"), "no se compra dos veces")
	var wb = farm.get_node("WorldBuilder")
	var plots: Array = wb.farm_plots
	var a: FarmPlot = plots[4]
	var vecinas: Array = player._neighbor_plots(a)
	check(vecinas.size() >= 2, "la parcela tiene vecinas (%d)" % vecinas.size())
	for p in [a] + vecinas:
		if p.state == FarmPlot.State.UNTILLED:
			p.till()
		if p.state == FarmPlot.State.TILLED:
			p.plant("trigo")
	player.global_position = a.global_position + Vector3(0, 0.2, 1.3)
	player._update_facing(Vector2(0, -1))
	player._try_interact()
	var regadas: int = ([a] + vecinas).filter(func(p): return p.watered_today).size()
	check(regadas >= 3, "la vasija doble riega en area (%d)" % regadas)
	GameState.buy_upgrade("khopesh_bronce")
	check(GameState.upgrade_effect("dano", "khopesh") == 4.0, "khopesh de bronce +4")


func _test_amistad() -> void:
	print("AMISTAD")
	var dlg = get_tree().get_first_node_in_group("dialogue_box")
	var iry = _npc("iry")
	GameState.iry_intro_shown = true
	iry._charlar()
	await _close(dlg)
	check(GameState.friend_points("iry") == 1, "charlar suma 1")
	iry._charlar()
	await _close(dlg)
	check(GameState.friend_points("iry") == 1, "solo una charla por dia")
	GameState.add_item("trigo", 2)
	iry._dar_regalo("trigo")
	await _close(dlg)
	check(GameState.friend_level("iry") == 1 and GameState.friend_points("iry") == 4, "regalo que le encanta: +3 y sube a nivel 1")
	check(GameState.item_count("semilla_trigo") >= 4, "recompensa de Iry nivel 1: semillas")
	# nivel 2 de Iry: riega al amanecer
	GameState.amistad["iry"] = 7
	GameState.apply_friend_reward("iry", 2)
	var sd = farm.get_node("StoryDirector")
	var wb = farm.get_node("WorldBuilder")
	var secos: Array = wb.farm_plots.filter(func(p): return p.state == FarmPlot.State.PLANTED and not p.watered_today and not p.is_ready())
	if secos.is_empty():
		var p: FarmPlot = wb.farm_plots[10]
		if p.state == FarmPlot.State.UNTILLED:
			p.till()
		p.plant("trigo")
	sd._iry_riega()
	var regadas: int = wb.farm_plots.filter(func(p): return p.watered_today).size()
	check(regadas >= 1, "Iry riega al amanecer")


func _npc(id: String) -> Node:
	for n in farm.get_node("WorldBuilder").npcs:
		if n.get("npc_id") == id:
			return n
	return null


func _close(dlg) -> void:
	await _frames(2)
	var guard := 0
	while dlg.visible and guard < 40:
		dlg._advance()
		guard += 1
		await _frames(1)
	await _frames(2)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout
