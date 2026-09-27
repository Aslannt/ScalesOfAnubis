extends Node
## Estado persistente de la partida: deben, peso del corazon, inventario,
## dia actual y datos de cultivos cargados desde data/crops.json.

signal deben_changed(nuevo_total: int)
signal heart_weight_changed(nuevo_peso: float, delta: float, motivo: String)
signal inventory_changed()
signal day_changed(dia: int)
signal decision_tomada(id: String, valor: String)
## Comentario de Thot no bloqueante (tutorial integrado y reacciones, GDD 4)
signal thot_says(texto: String)
signal village_damaged(total: int)
signal seed_selected(id: String)

const HEART_START := 50.0
const HEART_MIN := 0.0
const HEART_MAX := 100.0

var deben: int = 15
var heart_weight: float = HEART_START
var current_day: int = 1
var inventory: Dictionary = {}  # item_id -> cantidad
var owned_amulets: Array = ["anj"]  # el escarabajo lo da Meret el dia 3 (GDD 7)
var equipped_amulet: String = ""
var equipped_weapon: String = "khopesh"  # khopesh | martillo
var escarabajo_usado_esta_noche: bool = false
var decisiones: Dictionary = {}  # id_decision -> valor elegido

# progreso de dialogo con NPCs (GDD 6.7)
var meret_intro_shown: bool = false
var meret_mission_done: bool = false
var ptahmose_intro_shown: bool = false
var iry_intro_shown: bool = false
const MERET_CROPS_NEEDED := 3

var crops: Dictionary = {}
var selected_seed: String = "trigo"
const SEED_IDS := ["trigo", "lino", "papiro"]

# decision moral 2 (GDD 6.7): la aldea y los cultivos atacados a la vez
const VILLAGE_SACK_LIMIT := 14
var village_damage: int = 0
var village_kills: int = 0
var village_raiders_total: int = 0

# estructura de la demo (GDD 7)
var tutorial: Dictionary = {}  # flags de tutorial/eventos ya mostrados
var heart_at_night_start: float = HEART_START
var total_enemies_defeated: int = 0
var boss_defeated: bool = false
var demo_finished: bool = false
var current_tool_index: int = 0  # 0=agricola/1=arma, ver Player

# vida del jugador (para HUD / combate M4)
var max_health: int = 100
var health: int = 100
signal health_changed(nuevo: int, maximo: int)

# resumen de la noche (para la pantalla de amanecer, M8)
var crops_lost_tonight: int = 0
var enemies_defeated_tonight: int = 0


# Bloqueo breve de la tecla interactuar/atacar tras cerrar un dialogo: el
# jugador lee Input.is_action_just_pressed en su propio proceso y, en el mismo
# frame en que la caja de dialogo consume la E y quita la pausa, volvia a
# abrir la conversacion (bug real reportado por Deivid: dialogo en bucle).
var _input_lock_until_ms: int = 0


func lock_player_input(segundos: float = 0.2) -> void:
	_input_lock_until_ms = Time.get_ticks_msec() + int(segundos * 1000.0)


func player_input_locked() -> bool:
	return Time.get_ticks_msec() < _input_lock_until_ms


## Deja todo como al empezar una partida nueva (los autoloads sobreviven al
## cambio de escena: sin esto, "Salir al menu" + "Nueva partida" arrastraba
## el deben, el inventario y el peso del corazon de la partida anterior).
func reset() -> void:
	deben = 15
	heart_weight = HEART_START
	current_day = 1
	inventory = {"semilla_trigo": 8, "semilla_lino": 3, "semilla_papiro": 2}
	owned_amulets = ["anj"]
	equipped_amulet = ""
	equipped_weapon = "khopesh"
	escarabajo_usado_esta_noche = false
	decisiones = {}
	meret_intro_shown = false
	meret_mission_done = false
	ptahmose_intro_shown = false
	iry_intro_shown = false
	selected_seed = "trigo"
	max_health = 100
	health = 100
	crops_lost_tonight = 0
	enemies_defeated_tonight = 0
	village_damage = 0
	village_kills = 0
	village_raiders_total = 0
	tutorial = {}
	heart_at_night_start = HEART_START
	total_enemies_defeated = 0
	boss_defeated = false
	demo_finished = false
	_input_lock_until_ms = 0
	Codex.reset()
	GameTime.reset()


func thot(texto: String) -> void:
	thot_says.emit(texto)


## Muestra un comentario de Thot solo la primera vez (flag de tutorial).
func thot_once(flag: String, texto: String) -> bool:
	if tutorial.get(flag, false):
		return false
	tutorial[flag] = true
	thot_says.emit(texto)
	return true


func seed_count(id: String) -> int:
	return item_count("semilla_" + id)


func select_seed(id: String) -> void:
	selected_seed = id
	seed_selected.emit(id)


func damage_village(n: int = 1) -> void:
	village_damage += n
	village_damaged.emit(village_damage)


func village_sacked() -> bool:
	return village_damage >= VILLAGE_SACK_LIMIT


func _ready() -> void:
	inventory = {"semilla_trigo": 8, "semilla_lino": 3, "semilla_papiro": 2}
	_cargar_crops()
	GameTime.night_started.connect(func():
		crops_lost_tonight = 0
		enemies_defeated_tonight = 0
		heart_at_night_start = heart_weight
		escarabajo_usado_esta_noche = false
		Codex.unlock("sheut")
		Codex.unlock("duat")
	)
	GameTime.day_started.connect(func(): Codex.unlock("maat"))
	Codex.unlock("anubis")
	Codex.unlock("thot")


func _cargar_crops() -> void:
	var f := FileAccess.open("res://data/crops.json", FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir data/crops.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		crops = parsed


func add_deben(cantidad: int) -> void:
	deben = max(0, deben + cantidad)
	deben_changed.emit(deben)
	if cantidad > 0:
		SFX.play("coin")


func can_afford(cantidad: int) -> bool:
	return deben >= cantidad


func add_item(item_id: String, cantidad: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + cantidad
	inventory_changed.emit()


func remove_item(item_id: String, cantidad: int = 1) -> bool:
	if cantidad <= 0:
		return true
	if inventory.get(item_id, 0) < cantidad:
		return false
	inventory[item_id] -= cantidad
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	inventory_changed.emit()
	return true


func item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)


func shift_heart(delta: float, motivo: String = "") -> void:
	heart_weight = clampf(heart_weight + delta, HEART_MIN, HEART_MAX)
	heart_weight_changed.emit(heart_weight, delta, motivo)
	if absf(delta) > 0.01:
		SFX.play("heart_shift")


func register_decision(id: String, valor: String) -> void:
	decisiones[id] = valor
	decision_tomada.emit(id, valor)


func next_day() -> void:
	current_day += 1
	day_changed.emit(current_day)


func take_damage(cantidad: int) -> void:
	health = max(0, health - cantidad)
	health_changed.emit(health, max_health)


func heal(cantidad: int) -> void:
	health = min(max_health, health + cantidad)
	health_changed.emit(health, max_health)


func full_heal() -> void:
	health = max_health
	health_changed.emit(health, max_health)
