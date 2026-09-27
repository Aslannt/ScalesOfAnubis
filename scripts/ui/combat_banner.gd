extends CanvasLayer
## Carteles grandes de combate: anuncio de oleadas ("¡Sombras desde el
## desierto!"), "NOCHE 2", y el contador de COMBO con premio.

var _banner: Label
var _sub: Label
var _combo: Label
var _combo_n := 0
var _combo_t := 0.0
var _best := 0


func _ready() -> void:
	layer = 6
	add_to_group("combat_banner")
	var bold: Font = load("res://assets/fonts/Silkscreen-Bold.ttf")
	_banner = UIStyle.make_label(self, "", Vector2(0, 176), UIStyle.BIG, Color(1.0, 0.82, 0.35))
	_banner.add_theme_font_override("font", bold)
	_banner.add_theme_color_override("font_outline_color", Color(0.2, 0.05, 0.05))
	_banner.add_theme_constant_override("outline_size", 5)
	_banner.size = Vector2(480, 22)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.pivot_offset = Vector2(240, 11)
	_banner.modulate.a = 0.0
	_sub = UIStyle.make_label(self, "", Vector2(0, 198), UIStyle.SMALL, UIStyle.TEXT)
	_sub.position.x = 60
	_sub.size = Vector2(360, 10)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.modulate.a = 0.0
	_combo = UIStyle.make_label(self, "", Vector2(6, 208), UIStyle.BIG, Color(1.0, 0.9, 0.5))
	_combo.add_theme_font_override("font", bold)
	_combo.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.02))
	_combo.add_theme_constant_override("outline_size", 4)
	_combo.pivot_offset = Vector2(20, 10)
	_combo.modulate.a = 0.0


var _tw: Tween


func hide_now() -> void:
	if _tw:
		_tw.kill()
	_banner.modulate.a = 0.0
	_sub.modulate.a = 0.0


func announce(title: String, sub: String = "", color: Color = Color(1.0, 0.82, 0.35), hold: float = 1.8) -> void:
	if _tw:
		_tw.kill()
	_banner.text = title
	_banner.add_theme_color_override("font_color", color)
	_sub.text = sub
	_banner.scale = Vector2(1.8, 1.8)
	var tw := create_tween()
	_tw = tw
	tw.set_parallel()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sub, "modulate:a", 1.0, 0.3)
	tw.chain().tween_interval(hold)
	tw.chain().tween_property(_banner, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(_sub, "modulate:a", 0.0, 0.5)
	SFX.play("drum_hit", 0.0, 0.0)


## Lo llama el jugador en cada golpe que conecta.
func add_hit() -> void:
	_combo_n += 1
	_combo_t = 2.2
	if _combo_n >= 3:
		_combo.text = "x%d COMBO" % _combo_n
		_combo.modulate.a = 1.0
		_combo.scale = Vector2(1.35, 1.35)
		create_tween().tween_property(_combo, "scale", Vector2.ONE, 0.15)
		var hue := clampf(_combo_n / 20.0, 0.0, 1.0)
		_combo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5).lerp(Color(1.0, 0.35, 0.25), hue))
	# premio cada 10 golpes seguidos
	if _combo_n % 10 == 0:
		GameState.add_deben(_combo_n / 2)
		announce("COMBO x%d" % _combo_n, "+%d deben" % (_combo_n / 2))


func _process(delta: float) -> void:
	if _combo_t > 0.0:
		_combo_t -= delta
		if _combo_t <= 0.0:
			_best = maxi(_best, _combo_n)
			_combo_n = 0
			create_tween().tween_property(_combo, "modulate:a", 0.0, 0.4)
