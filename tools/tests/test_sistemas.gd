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


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout
