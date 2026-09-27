extends Control
## Intro (GDD 7), rehecha para que la entienda alguien que no sabe nada de
## mitologia egipcia (pedido de Deivid):
## 1. Tarjetas narradas en lenguaje simple: que es la balanza, la pluma de
##    Maat, Aaru, Ammit y quien eres. Cada una con su imagen animada.
## 2. El juicio en el Duat con la balanza animada por piezas: oscila y queda
##    EXACTA. Anubis explica el trato; Thot llega volando.
## 3. Tarjeta de mision: que tienes que lograr.
## E / clic avanza, Esc salta todo.

const FARM := "res://scenes/world/Farm.tscn"
const DLG := preload("res://scripts/ui/dialogue_box.gd")
const SCALE := preload("res://scripts/story/judgment_scale.gd")
const HALL := preload("res://scripts/story/duat_hall.gd")
const STARS := preload("res://scripts/ui/starfield.gd")
const TEX := "res://assets/textures/"
const ICONS := "res://assets/sprites/icons/"

var _fade: ColorRect
var _skip: Label
var _leaving := false
var _advance := false
var _t := 0.0

# tarjetas
var _cards_root: Control
var _card_text: Label
var _card_img: Control
var _layers: Array = []

# juicio
var _hall: Control
var _scale: Control
var _anubis: TextureRect
var _thot: AnimatedSprite2D
var _stamp: Label
var _place_lbl: Label
var _dlg: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_build_cards()
	_build_hall()
	_skip = UIStyle.make_label(self, Textos.t("intro_saltar"), Vector2(404, 4), UIStyle.SMALL, UIStyle.TEXT_DIM)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_dlg = DLG.new()
	add_child(_dlg)
	_run()


# ------------------------------------------------------------ tarjetas
func _build_cards() -> void:
	_cards_root = Control.new()
	_cards_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cards_root)
	for f in ["title_sky.png", "", "title_far.png", "title_near.png"]:
		if f == "":
			var st := STARS.new()
			st.set_anchors_preset(Control.PRESET_FULL_RECT)
			_cards_root.add_child(st)
			continue
		var r := TextureRect.new()
		r.texture = load(TEX + f)
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.size = Vector2(500, 270)
		_cards_root.add_child(r)
		_layers.append(r)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cards_root.add_child(dim)
	_card_img = Control.new()
	_card_img.position = Vector2(240, 104)
	_cards_root.add_child(_card_img)
	_card_text = UIStyle.make_label(_cards_root, "", Vector2(30, 168), UIStyle.BIG, Color(0.98, 0.9, 0.72))
	_card_text.size = Vector2(420, 90)
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_text.add_theme_constant_override("line_spacing", 3)


func _card_image(kind: String) -> void:
	for c in _card_img.get_children():
		c.queue_free()
	var node: Control = null
	match kind:
		"corazon":
			node = _big_icon(ICONS + "heart.png", 5)
		"pluma":
			node = _big_icon(ICONS + "feather.png", 5)
		"aaru":
			node = _big_icon(ICONS + "anj.png", 5)
			var w := _big_icon(ICONS + "item_trigo.png", 3)
			w.position = Vector2(-90, -10)
			var w2 := _big_icon(ICONS + "item_trigo.png", 3)
			w2.position = Vector2(42, -10)
		"ammit":
			var t := AtlasTexture.new()
			t.atlas = load("res://assets/sprites/enemies/heraldo.png")
			t.region = Rect2(72 * 10, 0, 72, 52)  # frame de rugido
			node = TextureRect.new()
			node.texture = t
			node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node.scale = Vector2(2, 2)
			node.position = Vector2(-72, -70)
			node.modulate = Color(0.25, 0.1, 0.2)
			_card_img.add_child(node)
			return
		"nakht":
			var t2 := AtlasTexture.new()
			t2.atlas = load("res://assets/sprites/characters/player.png")
			t2.region = Rect2(0, 0, 24, 32)
			node = TextureRect.new()
			node.texture = t2
			node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node.scale = Vector2(3, 3)
			node.position = Vector2(-36, -70)
			_card_img.add_child(node)
			create_tween().tween_property(node, "modulate", Color(0.45, 0.45, 0.55, 0.8), 3.0)
			return
		_:
			return


func _big_icon(path: String, sc: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.scale = Vector2(sc, sc)
	r.position = Vector2(-8 * sc, -8 * sc - 10)
	r.pivot_offset = Vector2(8, 8)
	_card_img.add_child(r)
	return r


func _show_card(card: Dictionary) -> void:
	_card_image(String(card.get("imagen", "")))
	_card_img.modulate.a = 0.0
	_card_img.scale = Vector2(0.9, 0.9)
	var tw := create_tween().set_parallel()
	tw.tween_property(_card_img, "modulate:a", 1.0, 0.6)
	tw.tween_property(_card_img, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var full := String(card["texto"])
	_card_text.text = full
	_card_text.visible_characters = 0
	_advance = false
	var n := full.length()
	var k := 0.0
	while k < n and not _advance and not _leaving:
		k += get_process_delta_time() / 0.03
		_card_text.visible_characters = int(k)
		if int(k) % 3 == 0:
			pass
		await get_tree().process_frame
	_card_text.visible_characters = -1
	_advance = false
	var wait := 0.0
	while wait < 2.8 and not _advance and not _leaving:
		wait += get_process_delta_time()
		await get_tree().process_frame
	var out := create_tween().set_parallel()
	out.tween_property(_card_img, "modulate:a", 0.0, 0.35)
	out.tween_property(_card_text, "modulate:a", 0.0, 0.35)
	await out.finished
	_card_text.modulate.a = 1.0


# -------------------------------------------------------------- juicio
func _build_hall() -> void:
	_hall = Control.new()
	_hall.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hall.visible = false
	add_child(_hall)
	_hall.add_child(HALL.new())
	_scale = SCALE.new()
	_scale.position = Vector2(240 - 64, 70)
	_hall.add_child(_scale)
	_anubis = TextureRect.new()
	_anubis.texture = load("res://assets/sprites/story/anubis_bust.png")
	_anubis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anubis.scale = Vector2(2, 2)
	_anubis.position = Vector2(20, 44)
	_anubis.modulate.a = 0.0
	_hall.add_child(_anubis)
	_thot = AnimatedSprite2D.new()
	_thot.sprite_frames = SpritesheetLoader.build("res://assets/sprites/companion/thot.png", "res://assets/sprites/companion/thot_layout.json", 8.0)
	_thot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_thot.scale = Vector2(2, 2)
	_thot.flip_h = true
	_thot.position = Vector2(520, 70)
	_thot.play("fly")
	_hall.add_child(_thot)
	_place_lbl = UIStyle.make_label(_hall, Textos.t("intro_lugar"), Vector2(0, 16), UIStyle.SMALL, Color(0.95, 0.8, 0.45))
	_place_lbl.size = Vector2(480, 10)
	_place_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamp = UIStyle.make_label(_hall, Textos.t("intro_empate"), Vector2(0, 150), 32, Color(1.0, 0.85, 0.35))
	_stamp.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
	_stamp.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.04))
	_stamp.add_theme_constant_override("outline_size", 6)
	_stamp.size = Vector2(480, 40)
	_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamp.pivot_offset = Vector2(240, 20)
	_stamp.visible = false


# -------------------------------------------------------------- guion
func _run() -> void:
	await _wait(0.5)
	create_tween().tween_property(_fade, "color:a", 0.0, 1.5)
	var cards: Array = Dialogos.data.get("intro_cards", [])
	for c in cards:
		if _leaving:
			return
		await _show_card(c)
	if _leaving:
		return
	# al Duat
	await create_tween().tween_property(_fade, "color:a", 1.0, 0.8).finished
	_cards_root.visible = false
	_hall.visible = true
	_scale.target_deg = 0.0
	await create_tween().tween_property(_fade, "color:a", 0.0, 1.2).finished
	await _wait(0.6)
	# el corazon cae en el plato: la balanza duda... y queda EXACTA
	SFX.play("heart_shift", 0.0, 0.0)
	_scale.kick(220.0)
	await _wait(1.0)
	_scale.kick(-160.0)
	SFX.play("heart_shift", -3.0, 0.0)
	await _wait(2.4)
	MenuMusic.stop_theme()
	_scale.flash()
	SFX.play("build", 0.0, 0.0)
	_stamp.visible = true
	_stamp.scale = Vector2(2.5, 2.5)
	_stamp.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_stamp, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_stamp, "modulate:a", 1.0, 0.2)
	await _wait(2.2)  # silencio
	create_tween().tween_property(_stamp, "modulate:a", 0.0, 0.6)
	# entra Anubis
	MenuMusic.play_theme()
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(_scale, "position:x", 300.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_anubis, "modulate:a", 1.0, 1.4)
	tw2.tween_property(_anubis, "position:y", 30.0, 1.4).set_trans(Tween.TRANS_SINE)
	await tw2.finished
	var lines: Array = Dialogos.lines("anubis", "intro")
	_dlg.show_lines(lines.slice(0, lines.size() - 1))
	await _dlg.finished
	if _leaving:
		return
	# Thot llega volando
	SFX.play("dodge", 0.0, 0.0)
	var tw3 := create_tween()
	tw3.tween_property(_thot, "position", Vector2(244, 64), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw3.finished
	_thot.play("idle")
	_dlg.show_lines(lines.slice(lines.size() - 1))
	await _dlg.finished
	if _leaving:
		return
	await _mission_card()
	_leave()


func _mission_card() -> void:
	var lines: Array = Dialogos.data.get("intro_mision", [])
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hall.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.6, 0.5)
	var panel := UIStyle.make_panel(_hall, Vector2(240 - 170, 56), Vector2(340, 150))
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style(Color(0.07, 0.05, 0.05, 0.97)))
	panel.modulate.a = 0.0
	var y := 10.0
	for i in range(lines.size()):
		var big := i == 0
		var l := UIStyle.make_label(panel, "", Vector2(12, y), UIStyle.BIG if big else UIStyle.SMALL, Color(0.98, 0.8, 0.35) if big else UIStyle.TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(316, 0)
		l.size = Vector2(316, 16 if big else 22)
		l.text = lines[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		y += 26 if big else 22
	var go := UIStyle.make_label(panel, Textos.t("intro_comenzar"), Vector2(0, 134), UIStyle.SMALL, UIStyle.GOLD)
	go.size = Vector2(340, 10)
	go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await create_tween().tween_property(panel, "modulate:a", 1.0, 0.5).finished
	_advance = false
	var t := 0.0
	while not _advance and not _leaving:
		t += get_process_delta_time()
		go.modulate.a = 0.5 + 0.5 * sin(t * 4.0)
		await get_tree().process_frame


func _process(delta: float) -> void:
	_t += delta
	# paralaje lento del fondo de las tarjetas
	for i in range(_layers.size()):
		_layers[i].position.x = -10.0 - sin(_t * 0.08) * (4.0 + i * 6.0)
	# Anubis respira y sus ojos brillan
	if _anubis and _anubis.modulate.a > 0.5:
		_anubis.position.y = 30.0 + sin(_t * 1.4) * 2.0
	if _thot and _thot.animation == "idle":
		_thot.position.y = 64.0 + sin(_t * 3.0) * 3.0
	# la imagen de la tarjeta late suave
	if _card_img:
		for c in _card_img.get_children():
			if c is TextureRect and c.scale.x > 4.0:
				var s := 5.0 + sin(_t * 2.2) * 0.15
				c.scale = Vector2(s, s)


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_leave()
	elif event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		if not _dlg.visible:
			_advance = true


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	_dlg.visible = false
	get_tree().paused = false
	move_child(_fade, get_child_count() - 1)
	_fade.color = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.9)
	MenuMusic.stop_theme()
	tw.tween_callback(func(): get_tree().change_scene_to_file(FARM))
