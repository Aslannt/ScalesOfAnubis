extends Node
## Modo libre (fase 3/8): se juega del dia 4 al 7 de verdad (noches con
## oleadas, el Heraldo que vuelve la ultima noche de Shemu con mas vida, el
## amanecer que NO termina la partida y la llegada de Akhet con la crecida y
## crias que salen del rio).
## Correr: godot --headless --path . res://tools/tests/test_libre.tscn

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")
var ok := true
var farm: Node
var nd: Node
var player: Player
var dawn: Node


func check(c: bool, m: String) -> void:
	print("  ", "ok: " if c else "FALLO: ", m)
	ok = ok and c


func _ready() -> void:
	GameState.reset()
	GameState.modo_libre = true
	GameState.current_day = 4
	farm = FARM_SCENE.instantiate()
	add_child(farm)
	await _secs(0.5)
	player = get_tree().get_first_node_in_group("player")
	nd = farm.get_node("NightDirector")
	dawn = farm.get_node("DawnSummary")
	GameState.max_health = 9999
	GameState.full_heal()
	check(GameState.season() == "shemu", "dia 4: Shemu")
	var objs: Array = farm.get_node("StoryDirector").objectives()
	check(objs.size() >= 2 and String(objs[0][0]).contains("Shemu"), "objetivos del modo libre")
	for day in [4, 5, 6]:
		print("NOCHE ", day)
		GameTime.force_phase(GameTime.Phase.NIGHT)
		await _frames(3)
		var total_sched: int = nd._schedule.size()
		check(total_sched >= 15, "noche %d con oleadas (%d criaturas)" % [day, total_sched])
		nd._night_t = 60.0
		await _secs(1.2)
		if day == 6:
			var boss = nd.boss
			check(boss != null and is_instance_valid(boss), "el Heraldo vuelve al final de Shemu")
			if boss:
				check(boss.max_health > 320, "vuelve mas fuerte (%d de vida)" % boss.max_health)
				boss.take_hit(99999)
				await _secs(5.5)
		_kill_all()
		GameTime.hold_night = false
		GameTime.elapsed = GameTime.TOTAL_SECONDS - 0.02
		await _secs(0.8)
		check(not GameState.demo_finished, "el amanecer %d no termina la partida" % (day + 1))
		await _close_dawn()
		GameTime.elapsed = GameTime.DAWN_SECONDS - 0.02
		await _secs(0.6)
	check(GameState.current_day == 7 and GameState.season() == "akhet", "dia 7: llega Akhet")
	check(farm.get_node("SeasonDirector")._flood_on, "la crecida cubre la orilla")
	GameTime.force_phase(GameTime.Phase.NIGHT)
	await _frames(3)
	var rio: int = nd._schedule.filter(func(s): return String(s["desde"]).begins_with("rio")).size()
	check(rio >= 8, "en Akhet las crias salen del rio (%d)" % rio)
	print("TEST LIBRE: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)


func _kill_all() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_in_group("boss"):
			e.take_hit(9999)


func _close_dawn() -> void:
	for i in range(20):
		if dawn.visible:
			break
		await _secs(0.1)
	await _secs(0.8)
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	dawn._unhandled_input(ev)
	await _secs(0.3)


func _secs(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
