extends Control
## Estrellas que titilan + estrella fugaz ocasional (menu principal, punto 7).

var _stars: Array = []
var _t: float = 0.0
var _shoot_t: float = 3.0
var _shoot: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(110):
		var y := rng.randf_range(0, 150) * rng.randf_range(0.4, 1.0)
		_stars.append({
			"p": Vector2(roundf(rng.randf_range(0, 480)), roundf(y)),
			"ph": rng.randf() * TAU,
			"sp": rng.randf_range(1.0, 3.5),
			"big": rng.randf() < 0.08,
			"col": Color(1.0, 0.95, 0.85) if rng.randf() < 0.3 else Color(0.85, 0.9, 1.0),
		})


func _process(delta: float) -> void:
	_t += delta
	_shoot_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = randf_range(4.0, 9.0)
		_shoot = {"p": Vector2(randf_range(160, 460), randf_range(8, 60)), "life": 0.0}
	if not _shoot.is_empty():
		_shoot["life"] += delta
		if _shoot["life"] > 0.7:
			_shoot = {}
	queue_redraw()


func _draw() -> void:
	for s in _stars:
		var a: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(_t * s["sp"] + s["ph"]))
		var col: Color = s["col"]
		col.a = a
		var p: Vector2 = s["p"]
		draw_rect(Rect2(p, Vector2.ONE), col)
		if s["big"] and a > 0.75:
			var c2 := col
			c2.a = a * 0.5
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2.ONE), c2)
			draw_rect(Rect2(p + Vector2(1, 0), Vector2.ONE), c2)
			draw_rect(Rect2(p + Vector2(0, -1), Vector2.ONE), c2)
			draw_rect(Rect2(p + Vector2(0, 1), Vector2.ONE), c2)
	if not _shoot.is_empty():
		var life: float = _shoot["life"]
		var head: Vector2 = _shoot["p"] + Vector2(-90, 36) * life
		for i in range(10):
			var c3 := Color(1, 0.95, 0.85, (1.0 - i / 10.0) * (1.0 - life / 0.7))
			draw_rect(Rect2((head + Vector2(3, -1.2) * i).round(), Vector2.ONE), c3)
