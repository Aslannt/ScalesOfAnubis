class_name CoinPickup
extends Node3D
## Moneda de deben que sueltan las criaturas al morir: salta, cae y vuela
## hacia el jugador cuando esta cerca (iman). Da recompensa inmediata a
## cada muerte (pedido de Deivid: "que se sienta emocionante").

const TEX := preload("res://assets/sprites/icons/deben.png")
var value := 1
var _vel := Vector3.ZERO
var _t := 0.0
var _sprite: Sprite3D
var _magnet := false


static func burst(root: Node, pos: Vector3, total: int) -> void:
	var n := clampi(total, 1, 8)
	var per := maxi(1, total / n)
	var rest := total - per * n
	for i in range(n):
		var c := CoinPickup.new()
		c.value = per + (rest if i == 0 else 0)
		root.add_child(c)
		c.global_position = pos + Vector3(0, 0.6, 0)
		var a := randf() * TAU
		c._vel = Vector3(cos(a) * randf_range(1.0, 2.5), randf_range(3.5, 5.0), sin(a) * randf_range(1.0, 2.5))


func _ready() -> void:
	_sprite = Sprite3D.new()
	_sprite.texture = TEX
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = 0.035
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.shaded = false
	add_child(_sprite)


func _process(delta: float) -> void:
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player and (_magnet or (_t > 0.45 and global_position.distance_to(player.global_position) < 3.5)):
		_magnet = true
		var to := player.global_position + Vector3(0, 0.8, 0) - global_position
		if to.length() < 0.5:
			GameState.add_deben(value)
			SFX.play("coin", -8.0, 0.15)
			queue_free()
			return
		global_position += to.normalized() * minf(to.length(), (6.0 + _t * 8.0) * delta)
	else:
		_vel.y -= 14.0 * delta
		global_position += _vel * delta
		if global_position.y < 0.25:
			global_position.y = 0.25
			_vel = _vel * Vector3(0.5, -0.4, 0.5)
	_sprite.scale.x = absf(cos(_t * 8.0)) * 0.8 + 0.2  # gira
	if _t > 20.0:
		queue_free()
