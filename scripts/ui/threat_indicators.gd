extends Control
## Indicadores en el borde de la pantalla (GDD 6.4: "aparecen desde el
## desierto y la necropolis, con indicadores en el borde de la pantalla"):
## una flecha por criatura fuera de camara, y un aviso grande hacia la
## aldea cuando la estan saqueando (decision moral 2).

const MARGIN := 10.0
var _t: float = 0.0
var _village_alert: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.village_damaged.connect(func(_n): _village_alert = 3.0)


func _process(delta: float) -> void:
	_t += delta
	_village_alert = maxf(0.0, _village_alert - delta)
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or not GameTime.is_night():
		return
	var rect := Rect2(Vector2(MARGIN, MARGIN + 40), Vector2(480 - MARGIN * 2, 270 - MARGIN * 2 - 70))
	for e in get_tree().get_nodes_in_group("enemies"):
		var is_boss: bool = e.is_in_group("boss")
		var col := Color(1.0, 0.3, 0.25, 0.85) if not is_boss else Color(1.0, 0.75, 0.2, 1.0)
		if e.get("group_id") == "aldea":
			col = Color(1.0, 0.55, 0.2, 0.85)
		_arrow_to(cam, e.global_position + Vector3(0, 0.8, 0), rect, col, 5.0 if not is_boss else 8.0, "")
	if _village_alert > 0.0:
		var vc := get_tree().get_first_node_in_group("village_center")
		if vc:
			var blink := 0.5 + 0.5 * sin(_t * 10.0)
			_arrow_to(cam, vc.global_position, rect, Color(1.0, 0.45, 0.15, 0.6 + 0.4 * blink), 9.0, Textos.t("aldea_bajo_ataque"))


func _arrow_to(cam: Camera3D, world: Vector3, rect: Rect2, col: Color, size: float, label: String) -> void:
	var on_screen := not cam.is_position_behind(world)
	var p := cam.unproject_position(world)
	# el viewport de la camara es la resolucion base (480x270)
	if on_screen and rect.grow(MARGIN).has_point(p):
		return
	var center := Vector2(240, 135)
	var dir := (p - center)
	if not on_screen:
		dir = -dir
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	# interseccion del rayo desde el centro con el rectangulo
	var tx := INF
	var ty := INF
	if dir.x > 0.0:
		tx = (rect.end.x - center.x) / dir.x
	elif dir.x < 0.0:
		tx = (rect.position.x - center.x) / dir.x
	if dir.y > 0.0:
		ty = (rect.end.y - center.y) / dir.y
	elif dir.y < 0.0:
		ty = (rect.position.y - center.y) / dir.y
	var pos := center + dir * minf(tx, ty)
	pos = pos.round()
	var side := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([pos + dir * size, pos - dir * size * 0.6 + side * size * 0.8, pos - dir * size * 0.6 - side * size * 0.8])
	draw_colored_polygon(pts, Color(0.05, 0.02, 0.02, 0.8))
	var inner := PackedVector2Array([pos + dir * (size - 2), pos - dir * (size * 0.6 - 1) + side * (size * 0.8 - 2), pos - dir * (size * 0.6 - 1) - side * (size * 0.8 - 2)])
	draw_colored_polygon(inner, col)
	if label != "":
		var font := get_theme_default_font()
		var lp := pos - dir * (size + 12) - Vector2(label.length() * 3, -3)
		draw_string(font, lp + Vector2(1, 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0, 0, 0, 0.8))
		draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
