extends Camera3D
## Camara fija en diagonal que sigue al jugador con suavizado (GDD 8).
## La rotacion se define una sola vez en la escena; aqui solo se traslada.

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 7.5, 8.5)
@export var smoothing: float = 4.0

var target: Node3D = null
var _shake_t: float = 0.0
var _shake_amount: float = 0.0
var _shake_seed: float = 0.0


func _ready() -> void:
	_shake_seed = randf() * 100.0
	if target_path != NodePath():
		target = get_node(target_path)


func set_target(node: Node3D) -> void:
	target = node
	if target:
		global_position = target.global_position + offset


func shake(amount: float = 0.15, duration: float = 0.2) -> void:
	# todo se suaviza a la mitad y con tope (antes mareaba)
	amount = minf(amount * 0.5, 0.12)
	_shake_amount = maxf(_shake_amount, amount)
	_shake_t = maxf(_shake_t, duration)


func _process(delta: float) -> void:
	if target == null:
		return
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, clampf(smoothing * delta, 0.0, 1.0))

	if _shake_t > 0.0:
		_shake_t -= delta
		var t := Time.get_ticks_msec() / 1000.0 + _shake_seed
		var falloff := clampf(_shake_t / 0.2, 0.0, 1.0)
		var off := Vector3(sin(t * 47.0), sin(t * 61.0), 0) * _shake_amount * falloff
		global_position += off
		if _shake_t <= 0.0:
			_shake_amount = 0.0
