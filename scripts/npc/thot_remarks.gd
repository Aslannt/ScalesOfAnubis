class_name ThotRemarks
extends Node
## Comentarios de ambiente de Thot (fase 4: "Thot con personalidad"). Pocos
## y espaciados: como mucho uno cada AMBIENT_COOLDOWN segundos, siempre en
## la cola normal (esperan a que Thot este callado). Cada lugar o hazana se
## comenta una sola vez; los de "quieto" se repiten con mucho espacio.

const AMBIENT_COOLDOWN := 120.0
const CHECK_EVERY := 1.0

var player: Player
var world_builder: WorldBuilder
var _cool := 40.0
var _check := 0.0
var _idle := 0.0
var _dodges: Array = []
var _zones: Dictionary = {}  # nombre -> Rect2 en mundo (x, z)
var _temple_pos := Vector3.INF


func setup(p: Player, wb: WorldBuilder) -> void:
	player = p
	world_builder = wb
	for z in wb.layout.get("zones", []):
		var r: Array = z["rect"]
		var a: Vector3 = wb._tile_to_world(float(r[0]), float(r[1]))
		var b: Vector3 = wb._tile_to_world(float(r[2]), float(r[3]))
		_zones[z["nombre"]] = Rect2(Vector2(a.x, a.z), Vector2(b.x - a.x, b.z - a.z))
	for pr in wb.layout.get("props", []):
		if pr.get("tipo") == "temple":
			var tt: Array = pr["tile"]
			_temple_pos = wb._tile_to_world(float(tt[0]) + 0.5, float(tt[1]) + 0.5)
	GameState.deben_changed.connect(_on_deben)
	p.dodged.connect(_on_dodge)


func _process(delta: float) -> void:
	if player == null or get_tree().paused:
		return
	_cool = maxf(0.0, _cool - delta)
	var day := not GameTime.is_night()
	if day and player.velocity.length() < 0.2:
		_idle += delta
	else:
		_idle = 0.0
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	var p2 := Vector2(player.global_position.x, player.global_position.z)
	if day and _zones.has("necropolis") and _zones["necropolis"].has_point(p2):
		_say_once("amb_necropolis")
	if day and player.global_position.x < world_builder.river_shore_x + 2.5:
		_say_once("amb_rio")
	if day and _temple_pos != Vector3.INF and player.global_position.distance_to(_temple_pos) < 9.0:
		_say_once("amb_templo")
	if _idle > 30.0 and _cool <= 0.0:
		_idle = 0.0
		_say("amb_quieto")
	var banner = get_tree().get_first_node_in_group("combat_banner")
	if banner and int(banner.get("_combo_n")) >= 10:
		_say_once("amb_combo", true)
	if GameState.total_enemies_defeated >= 50:
		_say_once("amb_50", true)


func _on_dodge() -> void:
	if GameTime.is_night():
		return
	var now := Time.get_ticks_msec()
	_dodges.append(now)
	_dodges = _dodges.filter(func(t): return now - t < 6000)
	if _dodges.size() >= 5:
		_say_once("amb_esquiva")


var _last_deben := -1


func _on_deben(total: int) -> void:
	if _last_deben >= 0 and total - _last_deben >= 60:
		_say_once("amb_rico", true)
	_last_deben = total


func _say_once(key: String, ignore_cooldown: bool = false) -> void:
	if GameState.tutorial.get("amb_" + key, false):
		return
	if not ignore_cooldown and _cool > 0.0:
		return
	GameState.tutorial["amb_" + key] = true
	_say(key)


func _say(key: String) -> void:
	_cool = AMBIENT_COOLDOWN
	GameState.thot(Dialogos.thot(key))
