extends Control
## Fondo de la Sala de las Dos Verdades en el Duat (intro y final): muro
## oscuro violeta, columnas con bandas doradas, dos braseros que titilan y
## polvo dorado flotando. Dibujado por codigo.

var _t: float = 0.0
var _motes: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in range(40):
		_motes.append([Vector2(rng.randf_range(0, 480), rng.randf_range(0, 270)), rng.randf_range(4, 12), rng.randf() * TAU])
	for x in [70.0, 410.0]:
		var f := AnimatedSprite2D.new()
		f.sprite_frames = SpritesheetLoader.build("res://assets/sprites/fx/flame.png", "res://assets/sprites/fx/flame_layout.json", 8.0)
		f.play("burn")
		f.position = Vector2(x, 172)
		f.scale = Vector2(2, 2)
		f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(f)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# muro con degradado en bandas
	for i in range(18):
		var k := i / 17.0
		draw_rect(Rect2(0, i * 15, 480, 15), Color(0.06, 0.04, 0.1).lerp(Color(0.16, 0.08, 0.16), k))
	# suelo
	draw_rect(Rect2(0, 200, 480, 70), Color(0.1, 0.07, 0.1))
	for i in range(8):
		draw_rect(Rect2(0, 200 + i * 9, 480, 1), Color(0.18, 0.12, 0.16))
	# columnas
	for x in [20.0, 120.0, 344.0, 444.0]:
		draw_rect(Rect2(x, 20, 18, 180), Color(0.2, 0.14, 0.2))
		draw_rect(Rect2(x + 12, 20, 6, 180), Color(0.13, 0.09, 0.14))
		for y in [40.0, 100.0, 160.0]:
			draw_rect(Rect2(x - 2, y, 22, 3), Color(0.72, 0.55, 0.2))
			draw_rect(Rect2(x - 2, y + 4, 22, 2), Color(0.18, 0.32, 0.55))
		draw_rect(Rect2(x - 4, 14, 26, 8), Color(0.72, 0.55, 0.2))
	# resplandor de braseros
	for x in [70.0, 410.0]:
		var fl := 0.8 + 0.2 * sin(_t * 9.0 + x)
		for r in [40.0, 28.0, 16.0]:
			draw_circle(Vector2(x, 168), r * fl, Color(1.0, 0.55, 0.2, 0.05))
		draw_rect(Rect2(x - 10, 176, 20, 6), Color(0.55, 0.36, 0.16))
		draw_rect(Rect2(x - 3, 182, 6, 18), Color(0.4, 0.26, 0.12))
	# polvo dorado
	for m in _motes:
		var p: Vector2 = m[0] + Vector2(sin(_t * 0.4 + m[2]) * 6.0, -fmod(_t * m[1], 270.0))
		p.y = fposmod(p.y, 270.0)
		draw_rect(Rect2(p.round(), Vector2.ONE), Color(1.0, 0.85, 0.5, 0.35 + 0.3 * sin(_t * 2.0 + m[2])))
