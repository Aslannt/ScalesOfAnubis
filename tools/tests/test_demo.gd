extends Node
## Prueba de la demo completa (GDD 7), headless y acelerada: granja del dia 1,
## Ptahmose (compra/venta), defensas, noche 1, resumen del amanecer, cosecha,
## decision 1 (altar), noche 2 con la aldea saqueada (decision 2), Meret da el
## escarabajo y recibe el lino, noche 3 con el Heraldo, derrota y reintento,
## muerte del jefe y paso al final.
## Correr: godot --headless --path . res://tools/tests/test_demo.tscn

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")

var _fallos: Array = []
var farm: Node
var player: Player
var wb
var nd
var dlg
var choice
var dawn


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		_fallos.append(msg)
		printerr("  FALLO: ", msg)


func _ready() -> void:
	GameState.reset()
	farm = FARM_SCENE.instantiate()
	add_child(farm)
	await _frames(5)
	player = get_tree().get_first_node_in_group("player")
	wb = farm.get_node("WorldBuilder")
	nd = farm.get_node("NightDirector")
	dlg = get_tree().get_first_node_in_group("dialogue_box")
	choice = get_tree().get_first_node_in_group("choice_box")
	dawn = farm.get_node("DawnSummary")

	print("DIA 1")
	var trigo_plots := _free_plots(false, 4)
	for p in trigo_plots:
		_farm_plot(p, 3)
	check(trigo_plots.all(func(p): return p.state == FarmPlot.State.PLANTED and p.watered_today and p.crop_id == "trigo"), "trigo arado, sembrado y regado")
	GameState.select_seed("lino")
	var lino_plots := _free_plots(false, 3)
	for p in lino_plots:
		_farm_plot(p, 3)
	check(lino_plots.all(func(p): return p.crop_id == "lino"), "lino plantable")
	check(GameState.seed_count("lino") == 0, "se consumen semillas de lino")
	var orilla := _free_plots(true, 1)
	GameState.select_seed("papiro")
	_farm_plot(orilla[0], 3)
	check(orilla[0].crop_id == "papiro", "papiro en la orilla")

	var ptah = _npc("ptahmose")
	ptah.interact()
	await _close_dialogue()
	var d0 := GameState.deben
	ptah.interact()
	await _frames(3)
	check(choice.visible, "menu de Ptahmose abierto")
	choice._choose(1)  # semillas de trigo
	await _close_dialogue()
	check(GameState.deben == d0 - 6 and GameState.seed_count("trigo") >= 3, "compra de semillas de trigo")

	GameState.add_deben(60)
	var spots: Array = wb.defense_spots
	spots[0].interact()
	await _frames(3)
	choice._choose(0)  # muro Nv1
	spots[1].interact()
	await _frames(3)
	choice._choose(1)  # brasero Nv1
	spots[2].interact()
	await _frames(3)
	choice._choose(2)  # estatua: bloqueada el dia 1 (se ve como ???)
	await _frames(2)
	check(choice.visible and spots[2].built == "", "la estatua esta bloqueada el dia 1 y el menu no se cierra")
	choice._choose(3)
	await _frames(2)
	check(spots[0].built == "muro" and spots[1].built == "brasero" and spots[1].level == 1, "muro y brasero Nv1 construidos")

	print("NOCHE 1")
	await _go_night()
	nd._night_t = 70.0
	await _secs(1.5)
	await _secs(0.4)
	check(trigo_plots[1]._shown_stage >= 1 and trigo_plots[1]._shown_stage <= 2 and not trigo_plots[1].is_ready(), "el trigo crece poco a poco durante la noche (etapa %d)" % trigo_plots[1]._shown_stage)
	var n1 := get_tree().get_nodes_in_group("enemies").size()
	check(n1 >= 5, "aparecen sombras en la noche 1 (%d)" % n1)
	# que el brasero queme: poner un enemigo cerca
	var e0 = get_tree().get_nodes_in_group("enemies")[0]
	e0.global_position = spots[1].global_position + Vector3(1.0, 0.2, 0)
	var hp0: int = e0.health
	await _secs(0.7)
	check(not is_instance_valid(e0) or e0.health < hp0, "el brasero quema")
	# una cria comiendose un cultivo: tarda, muestra barra y avisa
	_kill_all()
	await _secs(0.5)
	var victim = trigo_plots[0]
	var cr = nd.spawn("cria", "", "", victim.global_position + Vector3(0.5, 0, 0))
	cr.max_health = 999
	cr.health = 999
	await _secs(2.5)
	check(victim.state == FarmPlot.State.PLANTED and victim.eat_progress > 0.1 and victim.is_being_eaten(), "la cria tarda en comerse el cultivo (%.2f)" % victim.eat_progress)
	await _secs(4.5)
	check(victim.state != FarmPlot.State.PLANTED, "si nadie la detiene, el cultivo se pierde")
	cr.take_hit(99999)
	victim.till()
	GameState.add_item("semilla_trigo", 1)
	victim.plant("trigo")
	victim.water()
	# baston: el proyectil hiere a distancia
	var e1 = null
	for e in get_tree().get_nodes_in_group("enemies"):
		e1 = e
	if e1:
		player.global_position = e1.global_position + Vector3(-5, 0, 0)
		player._select_slot(2)
		var hp1: int = e1.health
		var b := Player.StaffBolt.new()
		b.dir = Vector3.RIGHT
		b.damage = 7
		farm.add_child(b)
		b.global_position = player.global_position + Vector3(0.6, 0.9, 0)
		await _secs(0.6)
		check(GameState.equipped_weapon == "baston" and (not is_instance_valid(e1) or e1.health < hp1), "el baston dispara y hiere a distancia")
		player._select_slot(0)
	_kill_all()
	await _secs(0.8)
	await _go_dawn()
	check(dawn.visible and get_tree().paused, "resumen del amanecer visible")
	await _close_dawn()

	print("DIA 2")
	await _go_day()
	check(GameState.current_day == 2, "es el dia 2")
	# defensas: mejorar el brasero y cambiar el muro por una estatua
	GameState.add_deben(80)
	var dd0 := GameState.deben
	spots[1].interact()
	await _frames(3)
	choice._choose(0)
	await _frames(2)
	check(spots[1].level == 2 and GameState.deben == dd0 - 22, "brasero mejorado a Nv2")
	spots[1].interact()
	await _frames(3)
	choice._choose(0)  # Nv3 bloqueado hasta el dia 3
	await _frames(2)
	check(choice.visible and spots[1].level == 2, "Nv3 bloqueado el dia 2")
	choice._choose(-1)
	await _frames(2)
	dd0 = GameState.deben
	spots[0].interact()
	await _frames(3)
	choice._choose(2)  # muro -> estatua (orden: mejorar, brasero, estatua)
	await _frames(2)
	check(spots[0].built == "estatua" and spots[0].level == 1 and GameState.deben == dd0 - (26 - 4), "muro cambiado por estatua con reembolso")
	var ready_n := trigo_plots.filter(func(p): return p.is_ready()).size()
	check(ready_n == 4, "trigo maduro al dia 2 (%d/4)" % ready_n)
	for p in trigo_plots:
		_face(p)
		player._try_interact()
	check(GameState.item_count("trigo") == 4, "cosecha de trigo")
	for p in lino_plots + orilla:
		_face(p)
		player._try_interact()  # regar dia 2
	var dv := GameState.deben
	ptah.interact()
	await _frames(3)
	choice._choose(0)
	await _close_dialogue()
	check(GameState.deben == dv + 24 and GameState.item_count("trigo") == 0, "venta a Ptahmose")
	# ofrenda: aligera el corazon
	GameState.add_item("trigo", 1)
	var hof := GameState.heart_weight
	var altar = _npc("altar")
	altar.interact()
	await _frames(3)
	choice._choose(_option("Ofrecer"))
	check(GameState.heart_weight < hof and GameState.item_count("trigo") == 0, "ofrenda en el altar aligera el corazon")
	var h0 := GameState.heart_weight
	altar.interact()
	await _frames(3)
	choice._choose(_option("Tomar"))
	await _close_dialogue()
	check(GameState.decisiones.get("robo_altar", "") == "robado" and GameState.heart_weight > h0, "decision 1: robar la ofrenda pesa")

	# actividades de dia: shabti, mision de Iry, campamento
	var sh = null
	var senet = null
	for c in get_tree().get_nodes_in_group("collectibles"):
		if c.npc_id == "shabti" and sh == null:
			sh = c
		if c.npc_id == "senet":
			senet = c
	var dsh := GameState.deben
	sh.interact()
	check(GameState.tutorial.get("shabtis", 0) == 1 and GameState.deben == dsh + 8, "recoger un shabti")
	var iry = _npc("iry")
	for i in range(3):
		iry.interact()
		await _close_dialogue()
	check(GameState.tutorial.get("iry_senet", "") == "pedido" and senet.is_available(), "Iry pide su ficha de senet")
	senet.interact()
	var hi := GameState.heart_weight
	iry.interact()
	await _close_dialogue()
	check(GameState.tutorial.get("iry_senet", "") == "entregado" and GameState.heart_weight < hi, "devolver la ficha a Iry aligera el corazon")
	var camp = _npc("campamento")
	camp.interact()
	await _frames(3)
	choice._choose(0)
	await _secs(2.0)
	check(GameTime.phase == GameTime.Phase.DUSK, "descansar en el campamento lleva al atardecer")

	print("NOCHE 2")
	await _go_night()
	nd._night_t = 40.0
	await _secs(1.0)
	var raiders := get_tree().get_nodes_in_group("enemies").filter(func(e): return e.group_id == "aldea")
	check(raiders.size() == 6, "6 sombras van a la aldea")
	for r in raiders:
		r.global_position = wb.village_center + Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1))
	player.global_position = wb.player_spawn_world + Vector3(0, 0.3, 0)
	await _secs(3.5)
	check(GameState.village_sacked(), "la aldea se saquea si nadie la defiende (%d)" % GameState.village_damage)
	_kill_all()
	var hn := GameState.heart_weight
	await _go_dawn()
	check(GameState.decisiones.get("noche2", "") == "cultivos" and GameState.heart_weight > hn, "decision 2 registrada: abandonar la aldea pesa")
	await _close_dawn()

	print("DIA 3")
	await _go_day()
	var meret = _npc("meret")
	for i in range(4):
		meret.interact()
		await _close_dialogue()
	check(GameState.owned_amulets.has("escarabajo"), "Meret entrega el escarabajo el dia 3")
	for p in lino_plots + orilla:
		_face(p)
		player._try_interact()
	check(GameState.item_count("lino") >= 3, "cosecha de lino (%d)" % GameState.item_count("lino"))
	var hm := GameState.heart_weight
	meret.interact()
	await _close_dialogue()
	check(GameState.meret_mission_done and GameState.heart_weight < hm, "mision de Meret con lino")

	print("NOCHE 3")
	await _go_night()
	nd._night_t = 35.5
	await _secs(1.5)
	var boss = nd.boss
	check(boss != null and is_instance_valid(boss), "aparece el Heraldo de Ammit")
	check(GameTime.hold_night, "el jefe retiene la noche")
	player.global_position = boss.global_position + Vector3(-5, 0.2, 0)
	GameState.max_health = 999
	GameState.full_heal()
	await _secs(8.0)
	check(is_instance_valid(boss) and boss.state != Heraldo.S.INTRO, "el jefe pelea (estado %d)" % boss.state)
	GameState.max_health = 100
	GameState.equipped_amulet = ""
	GameState.take_damage(9999)
	await _secs(6.0)
	check(not player.dead and GameState.health == 100, "derrota: el jugador vuelve a la granja")
	check(boss.health == boss.max_health, "derrota ante el jefe: reintento con vida llena")
	# esperar que no quede en pausa de dialogo
	boss.take_hit(9999)
	await _secs(5.8)
	check(GameState.boss_defeated, "el Heraldo cae")
	check(GameState.demo_finished, "tras el amanecer pasa al final de la demo")
	check(GameState.has_save(), "queda guardado el inicio del modo libre")
	var kills := GameState.total_enemies_defeated
	check(GameState.load_game() and GameState.modo_libre and GameState.current_day == 4 and GameState.total_enemies_defeated == kills, "el modo libre retoma en el dia 4 (Shemu)")
	check(GameState.season() == "shemu", "el dia 4 es Shemu")
	GameState.delete_save()

	if _fallos.is_empty():
		print("TEST DEMO: OK")
	else:
		printerr("TEST DEMO: %d fallos" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)


# ---------------------------------------------------------------- utils
func _free_plots(orilla: bool, n: int) -> Array:
	var out: Array = []
	for p in wb.farm_plots:
		if p.is_orilla == orilla and p.state == FarmPlot.State.UNTILLED and _clear_of_npcs(p):
			out.append(p)
			if out.size() >= n:
				break
	return out


func _clear_of_npcs(p) -> bool:
	for n in wb.npcs:
		if n.position.distance_to(p.position + Vector3(0, 0, 1.2)) < 3.0:
			return false
	return true


func _face(p) -> void:
	player.global_position = p.global_position + Vector3(0, 0.2, 1.2)
	player.facing = "north"


func _farm_plot(p, times: int) -> void:
	_face(p)
	for i in range(times):
		player._try_interact()


func _option(prefix: String) -> int:
	for i in range(choice._buttons.size()):
		if String(choice._buttons[i].text).begins_with(prefix):
			return i
	return -1


func _npc(id: String):
	for n in wb.npcs:
		if n.npc_id == id:
			return n
	return null


func _close_dialogue() -> void:
	await _frames(2)
	var guard := 0
	while (dlg.visible or choice.visible) and guard < 60:
		if choice.visible:
			choice._choose(-1)
		else:
			dlg._advance()
		guard += 1
		await _frames(1)
	await _frames(2)


func _close_dawn() -> void:
	await _secs(0.8)
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	dawn._unhandled_input(ev)
	await _frames(3)


func _kill_all() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_in_group("boss"):
			e.take_hit(9999)


func _go_night() -> void:
	GameTime.force_phase(GameTime.Phase.NIGHT)
	await _frames(3)


func _go_dawn() -> void:
	GameTime.elapsed = GameTime.TOTAL_SECONDS - 0.02
	await _secs(0.5)


func _go_day() -> void:
	GameTime.elapsed = GameTime.DAWN_SECONDS - 0.02
	await _secs(0.3)


func _secs(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
