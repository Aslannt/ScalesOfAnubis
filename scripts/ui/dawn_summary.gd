extends CanvasLayer
## Resumen al amanecer (GDD 5 y 11): cultivos perdidos, criaturas vencidas
## y cambio en la balanza durante la noche. Pausa el juego; E continua.

signal closed()

var _panel: Panel
var _lines: VBoxContainer
var _title: Label
var _cont: Label
var _open := false
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 14
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.03, 0.02, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = UIStyle.make_panel(self, Vector2(240 - 110, 135 - 64), Vector2(220, 128))
	UIStyle.make_icon(_panel, "res://assets/sprites/icons/phase_dawn.png", Vector2(102, 4))
	_title = UIStyle.make_label(_panel, "", Vector2(0, 22), UIStyle.BIG, Color(0.98, 0.8, 0.35))
	_title.size = Vector2(220, 18)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lines = VBoxContainer.new()
	_lines.position = Vector2(14, 44)
	_lines.size = Vector2(192, 60)
	_lines.add_theme_constant_override("separation", 2)
	_panel.add_child(_lines)
	_cont = UIStyle.make_label(_panel, Textos.t("amanecer_continuar"), Vector2(0, 112), UIStyle.SMALL, UIStyle.TEXT_DIM)
	_cont.size = Vector2(220, 10)
	_cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func show_summary(day: int, extra_lines: Array = []) -> void:
	for c in _lines.get_children():
		c.queue_free()
	_title.text = Textos.t("amanecer_titulo", {"n": day})
	var delta := GameState.heart_weight - GameState.heart_at_night_start
	var rows := [
		[Textos.t("amanecer_enemigos_derrotados", {"n": GameState.enemies_defeated_tonight}), UIStyle.TEXT],
		[Textos.t("amanecer_cultivos_perdidos", {"n": GameState.crops_lost_tonight}), Color(1, 0.6, 0.5) if GameState.crops_lost_tonight > 0 else UIStyle.TEXT],
		[Textos.t("amanecer_balanza", {"n": int(round(GameState.heart_weight))}), UIStyle.TEXT],
	]
	if absf(delta) >= 0.5:
		rows.append([Textos.t("amanecer_cambio", {"n": ("%+d" % int(round(delta)))}), Color(1, 0.5, 0.4) if delta > 0 else Color(0.55, 0.9, 1.0)])
	for e in extra_lines:
		rows.append(e)
	for r in rows:
		var l := Label.new()
		l.text = r[0]
		l.add_theme_font_size_override("font_size", UIStyle.SMALL)
		l.add_theme_color_override("font_color", r[1])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(192, 0)
		l.modulate.a = 0.0
		_lines.add_child(l)
	visible = true
	_open = true
	_t = 0.0
	get_tree().paused = true
	SFX.play("heart_shift")
	# las lineas aparecen una por una
	var i := 0
	for l in _lines.get_children():
		var tw := create_tween()
		tw.tween_interval(0.25 + i * 0.25)
		tw.tween_property(l, "modulate:a", 1.0, 0.2)
		i += 1


func _process(delta: float) -> void:
	if _open:
		_t += delta
		_cont.modulate.a = 0.5 + 0.5 * sin(_t * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _open or _t < 0.6:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_open = false
		visible = false
		GameState.lock_player_input(0.3)
		get_tree().paused = false
		SFX.play("ui_select")
		closed.emit()
