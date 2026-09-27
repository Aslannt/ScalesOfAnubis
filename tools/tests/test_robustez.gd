extends Node
## Robustez (reporte de Deivid: "no me pude mover luego de eso"):
## - pausa sin ningun menu visible -> el vigilante la quita
## - tiempo frenado (hit-stop colgado) -> se restaura
## - jugador encerrado dentro de un edificio -> el desatascador lo saca

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")
var ok := true


func check(c: bool, m: String) -> void:
	print("  ", "ok: " if c else "FALLO: ", m)
	ok = ok and c


func _ready() -> void:
	GameState.reset()
	var farm := FARM_SCENE.instantiate()
	add_child(farm)
	await _secs(0.3)
	var player: Player = get_tree().get_first_node_in_group("player")
	get_tree().paused = true
	await _secs(1.2)
	check(not get_tree().paused, "pausa huerfana se quita sola")
	Engine.time_scale = 0.05
	await _secs(1.5)
	check(Engine.time_scale == 1.0, "tiempo frenado se restaura")
	# encerrar al jugador dentro de una casa
	var house_pos := Vector3.ZERO
	for n in farm.get_node("WorldBuilder/Props").get_children():
		if n.name.begins_with("CasaAdobe"):
			house_pos = n.global_position
			break
	player.global_position = house_pos + Vector3(0, 0.3, 0)
	Input.action_press("move_left")
	await _secs(2.5)
	Input.action_release("move_left")
	var d := Vector2(player.global_position.x - house_pos.x, player.global_position.z - house_pos.z).length()
	check(d > 1.5, "jugador encerrado sale solo (%.1f m)" % d)
	# una sombra con el templo en medio debe rodearlo y llegar al jugador
	var nd = farm.get_node("NightDirector")
	GameTime.force_phase(GameTime.Phase.NIGHT)
	nd._schedule.clear()
	await _secs(1.5)
	var temple_pos := Vector3.ZERO
	for n in farm.get_node("WorldBuilder/Props").get_children():
		if n.name.begins_with("TemploMaat"):
			temple_pos = n.global_position
	player.global_position = temple_pos + Vector3(0, 0.3, 7.5)   # frente al templo
	GameState.max_health = 99999
	GameState.full_heal()
	var e = nd.spawn("sombra", "", "", temple_pos + Vector3(0, 0, -6.5))  # detras
	e.can_lunge = false
	var reached := false
	for i in range(30):
		await _secs(0.5)
		if is_instance_valid(e) and e.global_position.distance_to(player.global_position) < 2.5:
			reached = true
			break
	check(reached, "una sombra rodea el templo y llega al jugador (navegacion)")
	print("TEST ROBUSTEZ: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)


func _secs(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout
