extends CanvasLayer
## HUD (GDD 11, PROMPT_PULIDO.md punto 5). Construido por codigo:
## - arriba izq.: vida (marco dorado, icono, fondo con la vida perdida,
##   barra "fantasma" que baja con retraso al recibir dano) + deben
## - arriba centro: balanza del corazon animada
## - arriba der.: panel propio de fase del dia (icono sol/luna, dia, fase,
##   estacion Peret y progreso de la fase)
## - abajo izq.: slots con icono de herramienta/arma y amuleto
## - abajo der.: cosechas en el inventario
## - abajo centro: pista contextual de la tecla E ("[E] Arar", etc.)

const ICONS := "res://assets/sprites/icons/"
const BAR_W := 72.0

var _root: Control

# vida
var _vida_panel: Panel
var _bar_fill: ColorRect
var _bar_ghost: ColorRect
var _bar_hi: ColorRect
var _lbl_vida: Label
var _vida_icon: TextureRect
var _vida_prev: int = 100
var _lbl_deben: Label

# balanza
var _viga: TextureRect
var _lbl_corazon_flot: Label
var _balanza_panel: Panel

# fase
var _fase_icon: TextureRect
var _lbl_dia: Label
var _lbl_fase: Label
var _fase_bar: ColorRect
var _last_phase: int = -1

# slots
var _slot_arma_icon: TextureRect
var _slot_arma_key: Label
var _slot_arma_panel: Panel
var _slot_amuleto_icon: TextureRect
var _last_arma: String = ""
var _last_amuleto: String = "?"

# inventario / pista
var _inv_box: HBoxContainer
var _lbl_hint: Label
var _hint_panel: Panel


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_vida()
	_build_balanza()
	_build_fase()
	_build_slots()
	_build_inventario()
	_build_hint()

	GameState.deben_changed.connect(_on_deben_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.heart_weight_changed.connect(_on_heart_changed)
	GameState.inventory_changed.connect(_refresh_inventario)
	GameTime.cycle_updated.connect(_on_cycle_updated)

	_on_deben_changed(GameState.deben)
	_vida_prev = GameState.health
	_set_vida_bars(GameState.health, GameState.max_health, false)
	_set_balanza_rotation(GameState.heart_weight)
	_refresh_inventario()


# ---------------------------------------------------------------- vida
func _build_vida() -> void:
	_vida_panel = UIStyle.make_panel(_root, Vector2(6, 6), Vector2(112, 34))
	_vida_icon = UIStyle.make_icon(_vida_panel, ICONS + "heart.png", Vector2(3, 2))
	# marco de la barra
	var frame := ColorRect.new()
	frame.color = UIStyle.GOLD_DARK
	frame.position = Vector2(21, 5)
	frame.size = Vector2(BAR_W + 2, 10)
	_vida_panel.add_child(frame)
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.06, 0.06)
	bg.position = Vector2(1, 1)
	bg.size = Vector2(BAR_W, 8)
	frame.add_child(bg)
	_bar_ghost = ColorRect.new()
	_bar_ghost.color = Color(0.98, 0.86, 0.52)
	_bar_ghost.position = Vector2(1, 1)
	_bar_ghost.size = Vector2(BAR_W, 8)
	frame.add_child(_bar_ghost)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.78, 0.17, 0.13)
	_bar_fill.position = Vector2(1, 1)
	_bar_fill.size = Vector2(BAR_W, 8)
	frame.add_child(_bar_fill)
	_bar_hi = ColorRect.new()
	_bar_hi.color = Color(0.96, 0.42, 0.32)
	_bar_hi.position = Vector2(1, 2)
	_bar_hi.size = Vector2(BAR_W, 1)
	frame.add_child(_bar_hi)
	_lbl_vida = UIStyle.make_label(_vida_panel, "100", Vector2(97, 3), UIStyle.SMALL)

	UIStyle.make_icon(_vida_panel, ICONS + "deben.png", Vector2(3, 17))
	_lbl_deben = UIStyle.make_label(_vida_panel, "0", Vector2(22, 19), UIStyle.SMALL, Color(0.98, 0.8, 0.45))
	var lbl := UIStyle.make_label(_vida_panel, Textos.t("hud_deben"), Vector2(48, 19), UIStyle.SMALL, UIStyle.TEXT_DIM)
	lbl.name = "DebenTxt"


func _set_vida_bars(v: int, m: int, animate: bool) -> void:
	var ratio := clampf(float(v) / float(maxi(m, 1)), 0.0, 1.0)
	var w := roundf(BAR_W * ratio)
	_lbl_vida.text = str(v)
	if not animate:
		_bar_fill.size.x = w
		_bar_hi.size.x = w
		_bar_ghost.size.x = w
		return
	var tw := create_tween()
	tw.tween_property(_bar_fill, "size:x", w, 0.12)
	tw.parallel().tween_property(_bar_hi, "size:x", w, 0.12)
	var tg := create_tween()
	tg.tween_interval(0.35)
	tg.tween_property(_bar_ghost, "size:x", w, 0.45).set_trans(Tween.TRANS_QUAD)


func _on_health_changed(v: int, m: int) -> void:
	var damaged := v < _vida_prev
	_set_vida_bars(v, m, true)
	if damaged:
		# sacudida del panel y destello del icono
		var base := Vector2(6, 6)
		var tw := create_tween()
		for i in range(4):
			tw.tween_property(_vida_panel, "position", base + Vector2(randf_range(-2, 2), randf_range(-1, 1)), 0.03)
		tw.tween_property(_vida_panel, "position", base, 0.03)
		_vida_icon.modulate = Color(3, 3, 3)
		create_tween().tween_property(_vida_icon, "modulate", Color.WHITE, 0.25)
	elif v > _vida_prev:
		_bar_fill.color = Color(0.5, 0.9, 0.45)
		create_tween().tween_property(_bar_fill, "color", Color(0.78, 0.17, 0.13), 0.4)
	_vida_prev = v
	_lbl_vida.add_theme_color_override("font_color", Color(1, 0.45, 0.35) if v <= m * 0.3 else UIStyle.TEXT)


func _on_deben_changed(v: int) -> void:
	_lbl_deben.text = str(v)
	_lbl_deben.pivot_offset = Vector2(4, 4)
	var tw := create_tween()
	tw.tween_property(_lbl_deben, "scale", Vector2(1.4, 1.4), 0.06)
	tw.tween_property(_lbl_deben, "scale", Vector2.ONE, 0.12)


# ------------------------------------------------------------- balanza
func _build_balanza() -> void:
	# Balanza dorada (GDD 6.1): corazon a un lado, pluma al otro, se inclina
	# con suavizado segun GameState.heart_weight (50 = equilibrio exacto).
	_balanza_panel = UIStyle.make_panel(_root, Vector2(188, 4), Vector2(104, 38))
	var p := _balanza_panel
	var pivote := UIStyle.make_icon(p, ICONS + "balanza_pivote.png", Vector2(44, 15), Vector2(16, 20))
	pivote.stretch_mode = TextureRect.STRETCH_SCALE

	_viga = TextureRect.new()
	_viga.texture = load(ICONS + "balanza_viga.png")
	_viga.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_viga.size = Vector2(64, 10)
	_viga.position = Vector2(20, 12)
	_viga.pivot_offset = Vector2(32, 5)
	p.add_child(_viga)

	var corazon := UIStyle.make_icon(_viga, ICONS + "heart.png", Vector2(-8, 4))
	corazon.name = "Corazon"
	var pluma := UIStyle.make_icon(_viga, ICONS + "feather.png", Vector2(56, 4))
	pluma.name = "Pluma"

	_lbl_corazon_flot = UIStyle.make_label(_root, "", Vector2(188, 44), UIStyle.SMALL)
	_lbl_corazon_flot.size = Vector2(104, 10)
	_lbl_corazon_flot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_corazon_flot.modulate = Color(1, 1, 1, 0)


func _set_balanza_rotation(v: float) -> void:
	_viga.rotation = deg_to_rad(lerpf(-18.0, 18.0, (v - 50.0) / 50.0 * 0.5 + 0.5))
	# contrarrotar los platos para que queden colgando derechos
	for c in _viga.get_children():
		c.rotation = -_viga.rotation


func _on_heart_changed(v: float, delta: float, _motivo: String) -> void:
	var tw := create_tween()
	tw.tween_method(_set_balanza_rotation, v - delta, v, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if absf(delta) > 0.01:
		var texto := Textos.t("heart_isfet", {"n": int(round(delta))}) if delta > 0 else Textos.t("heart_maat", {"n": int(round(-delta))})
		_lbl_corazon_flot.text = texto
		_lbl_corazon_flot.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35) if delta > 0 else Color(0.55, 0.9, 1.0))
		_lbl_corazon_flot.modulate = Color(1, 1, 1, 1)
		_lbl_corazon_flot.position.y = 44
		var tw2 := create_tween()
		tw2.tween_property(_lbl_corazon_flot, "position:y", 50.0, 1.6)
		tw2.parallel().tween_property(_lbl_corazon_flot, "modulate:a", 0.0, 1.0).set_delay(0.9)
		var flash := create_tween()
		_balanza_panel.modulate = Color(1.6, 1.4, 1.0)
		flash.tween_property(_balanza_panel, "modulate", Color.WHITE, 0.5)


# ---------------------------------------------------------------- fase
func _build_fase() -> void:
	var p := UIStyle.make_panel(_root, Vector2(480 - 6 - 104, 6), Vector2(104, 34))
	_fase_icon = UIStyle.make_icon(p, ICONS + "phase_sun.png", Vector2(3, 3))
	_lbl_dia = UIStyle.make_label(p, "", Vector2(23, 3), UIStyle.SMALL)
	_lbl_fase = UIStyle.make_label(p, "", Vector2(23, 13), UIStyle.SMALL, UIStyle.TEXT_DIM)
	var est := UIStyle.make_label(p, Textos.t("hud_estacion"), Vector2(60, 3), UIStyle.SMALL, Color(0.55, 0.85, 0.75))
	est.size = Vector2(40, 10)
	est.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var track := ColorRect.new()
	track.color = Color(0.18, 0.14, 0.1)
	track.position = Vector2(4, 27)
	track.size = Vector2(96, 3)
	p.add_child(track)
	_fase_bar = ColorRect.new()
	_fase_bar.color = UIStyle.GOLD
	_fase_bar.position = Vector2(4, 27)
	_fase_bar.size = Vector2(0, 3)
	p.add_child(_fase_bar)


func _on_cycle_updated(_elapsed: float, _total: float, phase: int) -> void:
	_lbl_dia.text = "%s %d" % [Textos.t("hud_dia"), GameState.current_day]
	if phase != _last_phase:
		_last_phase = phase
		_lbl_fase.text = GameTime.phase_name()
		var icon := "phase_sun"
		match phase:
			GameTime.Phase.DAWN: icon = "phase_dawn"
			GameTime.Phase.DUSK: icon = "phase_dusk"
			GameTime.Phase.NIGHT: icon = "phase_moon"
		_fase_icon.texture = load(ICONS + icon + ".png")
		_fase_bar.color = Color(0.55, 0.65, 1.0) if phase == GameTime.Phase.NIGHT else UIStyle.GOLD
		_fase_icon.pivot_offset = Vector2(8, 8)
		var tw := create_tween()
		tw.tween_property(_fase_icon, "scale", Vector2(1.5, 1.5), 0.12)
		tw.tween_property(_fase_icon, "scale", Vector2.ONE, 0.25)
	_fase_bar.size.x = roundf(96.0 * GameTime.phase_progress())


# --------------------------------------------------------------- slots
func _slot(pos: Vector2, key: String) -> Array:
	var p := UIStyle.make_panel(_root, pos, Vector2(24, 24))
	var icon := UIStyle.make_icon(p, ICONS + "hoe.png", Vector2(4, 4))
	var k := UIStyle.make_label(_root, key, pos + Vector2(1, 23), UIStyle.SMALL, UIStyle.TEXT_DIM)
	return [p, icon, k]


func _build_slots() -> void:
	var a := _slot(Vector2(6, 270 - 38), "1/2")
	_slot_arma_panel = a[0]
	_slot_arma_icon = a[1]
	_slot_arma_key = a[2]
	var b := _slot(Vector2(34, 270 - 38), "Q")
	_slot_amuleto_icon = b[1]


func _refresh_slots() -> void:
	var night := GameTime.is_night()
	var arma := GameState.equipped_weapon if night else "herramienta"
	if arma != _last_arma:
		_last_arma = arma
		var icon := "hoe"
		match arma:
			"khopesh": icon = "khopesh"
			"martillo": icon = "hammer"
		_slot_arma_icon.texture = load(ICONS + icon + ".png")
		_slot_arma_key.text = "1/2" if night else "E"
		_slot_arma_panel.add_theme_stylebox_override("panel", UIStyle.panel_style(
			Color(0.16, 0.1, 0.22, 0.9) if night else UIStyle.INK,
			Color(0.7, 0.75, 1.0) if night else UIStyle.GOLD))
		_slot_arma_icon.pivot_offset = Vector2(8, 8)
		var tw := create_tween()
		tw.tween_property(_slot_arma_icon, "scale", Vector2(1.4, 1.4), 0.08)
		tw.tween_property(_slot_arma_icon, "scale", Vector2.ONE, 0.18)
	var am := GameState.equipped_amulet
	if am != _last_amuleto:
		_last_amuleto = am
		# sin amuleto equipado: silueta tenue del anj como "hueco" del slot
		_slot_amuleto_icon.texture = load(ICONS + ("scarab" if am == "escarabajo" else "anj") + ".png")
		if am == "":
			_slot_amuleto_icon.modulate = Color(0, 0, 0, 0.45)
		elif am == "escarabajo" and GameState.escarabajo_usado_esta_noche:
			_slot_amuleto_icon.modulate = Color(0.4, 0.4, 0.4)
		else:
			_slot_amuleto_icon.modulate = Color.WHITE
			_slot_amuleto_icon.pivot_offset = Vector2(8, 8)
			var tw := create_tween()
			tw.tween_property(_slot_amuleto_icon, "scale", Vector2(1.4, 1.4), 0.08)
			tw.tween_property(_slot_amuleto_icon, "scale", Vector2.ONE, 0.18)


# ---------------------------------------------------------- inventario
func _build_inventario() -> void:
	_inv_box = HBoxContainer.new()
	_inv_box.add_theme_constant_override("separation", 3)
	_inv_box.position = Vector2(300, 270 - 26)
	_inv_box.size = Vector2(174, 20)
	_inv_box.alignment = BoxContainer.ALIGNMENT_END
	_inv_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_inv_box)


func _refresh_inventario() -> void:
	for c in _inv_box.get_children():
		c.queue_free()
	for id in ["trigo", "lino", "papiro"]:
		var n := GameState.item_count(id)
		if n <= 0:
			continue
		var cell := Panel.new()
		cell.custom_minimum_size = Vector2(34, 20)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_stylebox_override("panel", UIStyle.panel_style())
		_inv_box.add_child(cell)
		UIStyle.make_icon(cell, ICONS + "item_%s.png" % id, Vector2(2, 2))
		UIStyle.make_label(cell, str(n), Vector2(19, 5), UIStyle.SMALL)


# --------------------------------------------------------------- pista
func _build_hint() -> void:
	_hint_panel = UIStyle.make_panel(_root, Vector2(180, 270 - 50), Vector2(120, 14))
	_lbl_hint = UIStyle.make_label(_hint_panel, "", Vector2(0, 2), UIStyle.SMALL)
	_lbl_hint.size = Vector2(120, 10)
	_lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_panel.visible = false


func _refresh_hint() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var txt := ""
	if player and player.has_method("get_interact_hint"):
		txt = player.get_interact_hint()
	if txt == "":
		_hint_panel.visible = false
		return
	_hint_panel.visible = true
	if _lbl_hint.text != txt:
		_lbl_hint.text = txt
		var w := maxf(60.0, txt.length() * 6.0 + 12.0)
		_hint_panel.size.x = w
		_hint_panel.position.x = roundf(240.0 - w * 0.5)
		_lbl_hint.size.x = w


func _process(_delta: float) -> void:
	_refresh_slots()
	_refresh_hint()
