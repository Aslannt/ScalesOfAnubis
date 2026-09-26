extends Camera3D
## Camara fija en diagonal que sigue al jugador con suavizado (GDD 8).
## La rotacion se define una sola vez en la escena; aqui solo se traslada.

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 7.5, 8.5)
@export var smoothing: float = 4.0

var target: Node3D = null


func _ready() -> void:
	if target_path != NodePath():
		target = get_node(target_path)


func set_target(node: Node3D) -> void:
	target = node
	if target:
		global_position = target.global_position + offset


func _process(delta: float) -> void:
	if target == null:
		return
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, clampf(smoothing * delta, 0.0, 1.0))
