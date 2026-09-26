extends Node
## Dirige las oleadas de criaturas de Ammit cada noche (GDD 6.4 y 7).
## Noche 1: pocas sombras. Noche 2: sombras + crias. Noche 3+: oleada grande.

const SOMBRA_SCENE := preload("res://scenes/enemies/Sombra.tscn")
const CRIA_SCENE := preload("res://scenes/enemies/Cria.tscn")

@export var spawn_center: Vector3 = Vector3(-10, 0, 0)
@export var spawn_radius: float = 20.0

var _queue: Array = []
var _spawn_timer: float = 0.0
var _spawn_interval: float = 6.0
var _enemies_root: Node3D


func _ready() -> void:
	_enemies_root = Node3D.new()
	_enemies_root.name = "Enemigos"
	get_parent().add_child.call_deferred(_enemies_root)
	GameTime.night_started.connect(_on_night_started)
	GameTime.day_started.connect(_on_day_started)


func _on_night_started() -> void:
	var day := GameState.current_day
	_queue.clear()
	if day <= 1:
		for i in range(4):
			_queue.append("sombra")
	elif day == 2:
		for i in range(6):
			_queue.append("sombra")
		for i in range(4):
			_queue.append("cria")
	else:
		for i in range(9):
			_queue.append("sombra")
		for i in range(7):
			_queue.append("cria")
	_queue.shuffle()
	_spawn_interval = GameTime.NIGHT_SECONDS / max(1, _queue.size() + 1)
	_spawn_timer = 1.0


func _on_day_started() -> void:
	_queue.clear()


func _process(delta: float) -> void:
	if _queue.is_empty() or not GameTime.is_night():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _spawn_interval
		_spawn_one(_queue.pop_back())


func _spawn_one(kind: String) -> void:
	var scene: PackedScene = SOMBRA_SCENE if kind == "sombra" else CRIA_SCENE
	var inst := scene.instantiate()
	var angle := randf_range(-100.0, 100.0)
	var rad := deg_to_rad(angle)
	var pos := spawn_center + Vector3(cos(rad), 0, sin(rad)) * spawn_radius
	inst.position = pos
	_enemies_root.add_child(inst)
