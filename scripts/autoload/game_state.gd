extends Node
## Estado persistente de la partida: deben, peso del corazon, inventario,
## dia actual y datos de cultivos cargados desde data/crops.json.

signal deben_changed(nuevo_total: int)
signal heart_weight_changed(nuevo_peso: float, delta: float, motivo: String)
signal inventory_changed()
signal day_changed(dia: int)
signal decision_tomada(id: String, valor: String)

const HEART_START := 50.0
const HEART_MIN := 0.0
const HEART_MAX := 100.0

var deben: int = 15
var heart_weight: float = HEART_START
var current_day: int = 1
var inventory: Dictionary = {}  # item_id -> cantidad
var equipped_amulet: String = ""
var decisiones: Dictionary = {}  # id_decision -> valor elegido

var crops: Dictionary = {}
var current_tool_index: int = 0  # 0=agricola/1=arma, ver Player

# vida del jugador (para HUD / combate M4)
var max_health: int = 100
var health: int = 100
signal health_changed(nuevo: int, maximo: int)

# resumen de la noche (para la pantalla de amanecer, M8)
var crops_lost_tonight: int = 0
var enemies_defeated_tonight: int = 0


func _ready() -> void:
	_cargar_crops()
	GameTime.night_started.connect(func(): crops_lost_tonight = 0; enemies_defeated_tonight = 0)


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


func can_afford(cantidad: int) -> bool:
	return deben >= cantidad


func add_item(item_id: String, cantidad: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + cantidad
	inventory_changed.emit()


func remove_item(item_id: String, cantidad: int = 1) -> bool:
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
