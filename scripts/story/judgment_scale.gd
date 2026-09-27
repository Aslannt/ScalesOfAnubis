extends Control
## Balanza del juicio animada por piezas (intro y final): la viga oscila como
## un resorte amortiguado hacia el angulo objetivo y los platos cuelgan
## siempre derechos de sus puntas. Corazon en el plato izquierdo, pluma de
## Maat en el derecho. Positivo = baja el corazon (mas pesado).

const S := "res://assets/sprites/story/"
const ICONS := "res://assets/sprites/icons/"

var target_deg := 0.0
var _angle := 0.0
var _vel := 0.0
var stiffness := 18.0
var damping := 2.4
var _beam: TextureRect
var _pans: Array = []
var _glow := 0.0


func _ready() -> void:
	size = Vector2(128, 110)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pillar := _tex(S + "scale_pillar.png", Vector2(40, 12))
	pillar.z_index = 0
	_beam = _tex(S + "scale_beam.png", Vector2(10, 32))
	_beam.pivot_offset = Vector2(54, 4)
	for side in [0, 1]:
		var pan := Control.new()
		pan.size = Vector2(32, 30)
		add_child(pan)
		var img := _tex(S + "scale_pan.png", Vector2.ZERO, pan)
		img.name = "Plato"
		var item := _tex(ICONS + ("heart.png" if side == 0 else "feather.png"), Vector2(8, 5), pan)
		item.name = "Objeto"
		_pans.append(pan)
	_place()


func _tex(path: String, pos: Vector2, parent: Node = self) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## Empuja la viga (efecto de "peso que cae").
func kick(amount: float) -> void:
	_vel += amount


func settle_exact() -> void:
	target_deg = 0.0


func _process(delta: float) -> void:
	# resorte amortiguado: da el vaiven natural de una balanza real
	var acc := (target_deg - _angle) * stiffness - _vel * damping
	_vel += acc * delta
	_angle += _vel * delta
	_place()
	if _glow > 0.0:
		_glow = maxf(0.0, _glow - delta)
		modulate = Color(1, 1, 1).lerp(Color(1.8, 1.6, 1.1), _glow)


func flash() -> void:
	_glow = 1.0


func _place() -> void:
	_beam.rotation = deg_to_rad(_angle)
	var c := Vector2(64, 36)
	var half := 50.0
	var a := deg_to_rad(_angle)
	var ends := [c + Vector2(-half * cos(a), -half * sin(a)), c + Vector2(half * cos(a), half * sin(a))]
	for i in range(2):
		_pans[i].position = (ends[i] - Vector2(16, 0)).round()
