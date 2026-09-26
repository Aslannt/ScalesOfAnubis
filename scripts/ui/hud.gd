extends CanvasLayer
## HUD: balanza/deben/reloj/vida/herramienta (GDD 11). Construido por codigo
## para mantener el layout simple y facil de ajustar.

var _lbl_deben: Label
var _lbl_reloj: Label
var _bar_vida: ProgressBar
var _bar_corazon: ProgressBar
var _lbl_corazon_flot: Label
var _lbl_arma: Label
var _root: Control


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_deben()
	_build_reloj()
	_build_vida()
	_build_corazon()
	_build_arma()

	GameState.deben_changed.connect(_on_deben_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.heart_weight_changed.connect(_on_heart_changed)
	GameTime.cycle_updated.connect(_on_cycle_updated)
	GameState.day_changed.connect(_on_day_changed)

	_on_deben_changed(GameState.deben)
	_on_health_changed(GameState.health, GameState.max_health)
	_bar_corazon.value = GameState.heart_weight


func _panel(pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.72)
	style.set_corner_radius_all(3)
	style.set_border_width_all(1)
	style.border_color = Color(0.7, 0.55, 0.2, 0.9)
	p.add_theme_stylebox_override("panel", style)
	_root.add_child(p)
	return p


func _build_deben() -> void:
	var p := _panel(Vector2(8, 8), Vector2(72, 20))
	var icon := TextureRect.new()
	icon.texture = load("res://assets/sprites/icons/deben.png")
	icon.position = Vector2(4, 2)
	icon.size = Vector2(16, 16)
	icon.texture_filter = TextureRect.TEXTURE_FILTER_NEAREST
	p.add_child(icon)
	_lbl_deben = Label.new()
	_lbl_deben.position = Vector2(24, 2)
	_lbl_deben.add_theme_font_size_override("font_size", 12)
	p.add_child(_lbl_deben)


func _build_reloj() -> void:
	_lbl_reloj = Label.new()
	_lbl_reloj.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lbl_reloj.position = Vector2(-90, 8)
	_lbl_reloj.size = Vector2(180, 20)
	_lbl_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_reloj.add_theme_font_size_override("font_size", 12)
	_root.add_child(_lbl_reloj)


func _build_vida() -> void:
	var p := _panel(Vector2(8, 34), Vector2(90, 14))
	_bar_vida = ProgressBar.new()
	_bar_vida.position = Vector2(3, 2)
	_bar_vida.size = Vector2(84, 10)
	_bar_vida.show_percentage = false
	_bar_vida.max_value = 100
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.7, 0.15, 0.12)
	_bar_vida.add_theme_stylebox_override("fill", fg)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.05, 0.05)
	_bar_vida.add_theme_stylebox_override("background", bg)
	p.add_child(_bar_vida)


func _build_corazon() -> void:
	var p := _panel(Vector2(190, 8), Vector2(100, 20))
	var icon := TextureRect.new()
	icon.texture = load("res://assets/sprites/icons/feather.png")
	icon.position = Vector2(4, 2)
	icon.size = Vector2(14, 14)
	icon.texture_filter = TextureRect.TEXTURE_FILTER_NEAREST
	p.add_child(icon)
	_bar_corazon = ProgressBar.new()
	_bar_corazon.position = Vector2(22, 4)
	_bar_corazon.size = Vector2(72, 12)
	_bar_corazon.max_value = 100
	_bar_corazon.show_percentage = false
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.75, 0.6, 0.2)
	_bar_corazon.add_theme_stylebox_override("fill", fg)
	p.add_child(_bar_corazon)
	_lbl_corazon_flot = Label.new()
	_lbl_corazon_flot.position = Vector2(0, -14)
	_lbl_corazon_flot.add_theme_font_size_override("font_size", 10)
	_lbl_corazon_flot.modulate = Color(1, 1, 1, 0)
	p.add_child(_lbl_corazon_flot)


func _build_arma() -> void:
	_lbl_arma = Label.new()
	_lbl_arma.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_lbl_arma.position = Vector2(8, -24)
	_lbl_arma.add_theme_font_size_override("font_size", 11)
	_root.add_child(_lbl_arma)


func _on_deben_changed(v: int) -> void:
	_lbl_deben.text = str(v)


func _on_health_changed(v: int, m: int) -> void:
	_bar_vida.max_value = m
	_bar_vida.value = v


func _on_heart_changed(v: float, delta: float, _motivo: String) -> void:
	_bar_corazon.value = v
	if absf(delta) > 0.01:
		var texto := Textos.t("heart_isfet", {"n": int(delta)}) if delta > 0 else Textos.t("heart_maat", {"n": int(-delta)})
		_lbl_corazon_flot.text = texto
		_lbl_corazon_flot.modulate = Color(1, 1, 1, 1)
		var tw := create_tween()
		tw.tween_property(_lbl_corazon_flot, "modulate:a", 0.0, 1.4).set_delay(0.6)


func _on_cycle_updated(_elapsed: float, _total: float, _phase: int) -> void:
	_lbl_reloj.text = "%s %d — %s" % [Textos.t("hud_dia"), GameState.current_day, GameTime.phase_name()]


func _on_day_changed(_d: int) -> void:
	pass


func set_weapon_label(text: String) -> void:
	_lbl_arma.text = text
