extends Control
## Final de la demo (GDD 7): amanecer -> pesaje de prueba con el resultado
## actual -> primer recuerdo del ba (el nino que se parece a Iry) ->
## "Gracias por jugar la demo de Scales of Anubis".

const MENU := "res://scenes/ui/Main.tscn"
const DLG := preload("res://scripts/ui/dialogue_box.gd")

var _fade: ColorRect
var _scale: TextureRect
var _anubis: TextureRect
var _dlg: CanvasLayer
var _result: Label
var _frames: Array = []
var _thanks: Control
var _can_leave := false


func _ready() -> void:
	MenuMusic.play_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameTime.paused = true
	add_child(preload("res://scripts/story/duat_hall.gd").new())
	for i in range(3):
		_frames.append(load("res://assets/sprites/story/scale_%d.png" % i))
	_scale = _tex(_frames[1], Vector2(300 - 64, 88))
	_anubis = _tex(load("res://assets/sprites/story/anubis_bust.png"), Vector2(40, 40))
	_anubis.scale = Vector2(2, 2)
	_result = UIStyle.make_label(self, "", Vector2(0, 16), UIStyle.SMALL, Color(0.98, 0.8, 0.35))
	_result.size = Vector2(480, 10)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_dlg = DLG.new()
	add_child(_dlg)
	Codex.unlock("ba")
	_run()


func _tex(t: Texture2D, pos: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.position = pos
	add_child(r)
	return r


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func _run() -> void:
	await create_tween().tween_property(_fade, "color:a", 0.0, 1.5).finished
	_dlg.show_lines(Dialogos.lines("final", "pesaje_intro"))
	await _dlg.finished
	# pesaje de prueba: la balanza duda y se inclina segun el peso final
	var w := GameState.heart_weight
	var final_frame := 1
	var key := "empate"
	if w < 49.5:
		final_frame = 0
		key = "liviano"
	elif w > 50.5:
		final_frame = 2
		key = "pesado"
	for f in [0, 2, 1, final_frame]:
		_scale.texture = _frames[f]
		SFX.play("heart_shift", -4.0, 0.0)
		await _wait(0.6)
	_result.text = Textos.t("final_resultado", {"n": int(round(w))})
	_result.modulate.a = 0.0
	create_tween().tween_property(_result, "modulate:a", 1.0, 0.8)
	await _wait(1.0)
	_dlg.show_lines(Dialogos.lines("final", key))
	await _dlg.finished
	# recuerdo del ba
	await create_tween().tween_property(_fade, "color:a", 1.0, 1.2).finished
	var memory := _tex(load("res://assets/sprites/story/ba_memory.png"), Vector2(48, 0))
	memory.scale = Vector2(2, 2)
	memory.position = Vector2(48, 6)
	move_child(_fade, get_child_count() - 1)
	move_child(_dlg, get_child_count() - 1)
	_anubis.visible = false
	_scale.visible = false
	_result.visible = false
	await create_tween().tween_property(_fade, "color:a", 0.0, 2.0).finished
	# lento acercamiento al nino
	create_tween().tween_property(memory, "position", Vector2(24, -8), 14.0).set_trans(Tween.TRANS_SINE)
	_dlg.show_lines(Dialogos.lines("final", "ba"))
	await _dlg.finished
	await create_tween().tween_property(_fade, "color:a", 1.0, 1.5).finished
	memory.visible = false
	_show_thanks()
	await create_tween().tween_property(_fade, "color:a", 0.0, 1.5).finished
	_can_leave = true


func _show_thanks() -> void:
	_thanks = Control.new()
	_thanks.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_thanks)
	move_child(_thanks, get_child_count() - 3)
	for f in ["title_sky.png", "title_far.png", "title_near.png"]:
		var r := TextureRect.new()
		r.texture = load("res://assets/textures/" + f)
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_thanks.add_child(r)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_thanks.add_child(dim)
	var y := 36.0
	var bold: Font = load("res://assets/fonts/Silkscreen-Bold.ttf")
	for row in [
		[Textos.t("gracias_titulo"), 8, null, Color(0.95, 0.88, 0.75)],
		["SCALES OF", 16, bold, Color(0.98, 0.78, 0.28)],
		["ANUBIS", 32, bold, Color(0.98, 0.78, 0.28)],
	]:
		var l := UIStyle.make_label(_thanks, row[0], Vector2(0, y), row[1], row[3])
		if row[2]:
			l.add_theme_font_override("font", row[2])
		l.add_theme_color_override("font_outline_color", Color(0.22, 0.1, 0.05))
		l.add_theme_constant_override("outline_size", 4 if row[1] >= 16 else 0)
		l.size = Vector2(480, row[1] + 4)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		y += row[1] + 8
	var decs: Array = []
	var robo: String = GameState.decisiones.get("robo_altar", "")
	decs.append(Textos.t("dec_robo") if robo == "robado" else Textos.t("dec_no_robo"))
	var n2: String = GameState.decisiones.get("noche2", "")
	if n2 != "":
		decs.append(Textos.t("dec_aldea") if n2 == "aldea" else Textos.t("dec_cultivos"))
	var panel := UIStyle.make_panel(_thanks, Vector2(240 - 150, 132), Vector2(300, 62))
	var lines := [
		Textos.t("final_resultado", {"n": int(round(GameState.heart_weight))}),
		Textos.t("final_stats", {"k": GameState.total_enemies_defeated, "d": GameState.deben}),
		Textos.t("final_decisiones", {"t": ", ".join(decs)}),
		Textos.t("gracias_subtitulo"),
	]
	for i in range(lines.size()):
		var l := UIStyle.make_label(panel, lines[i], Vector2(0, 6 + i * 13), UIStyle.SMALL, UIStyle.TEXT if i < 3 else Color(0.6, 0.85, 1.0))
		l.size = Vector2(300, 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var back := UIStyle.make_label(_thanks, Textos.t("libre_seguir") if GameState.has_save() else Textos.t("gracias_volver"), Vector2(0, 236), UIStyle.SMALL, UIStyle.TEXT_DIM)
	back.size = Vector2(480, 10)
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tw := back.create_tween().set_loops()
	tw.tween_property(back, "modulate:a", 0.3, 0.6)
	tw.tween_property(back, "modulate:a", 1.0, 0.6)
	SFX.play("coin")


func _unhandled_input(event: InputEvent) -> void:
	if not _can_leave:
		return
	var seguir := (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")) and GameState.has_save()
	if seguir or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		_can_leave = false
		get_viewport().set_input_as_handled()
		await create_tween().tween_property(_fade, "color:a", 1.0, 1.0).finished
		GameTime.paused = false
		if seguir:
			continue_free_mode()
		else:
			get_tree().change_scene_to_file(MENU)


## Modo libre: carga el amanecer del dia 4 guardado antes del final.
func continue_free_mode() -> void:
	if not GameState.load_game():
		get_tree().change_scene_to_file(MENU)
		return
	GameState.modo_libre = true
	get_tree().change_scene_to_file("res://scenes/world/Farm.tscn")
