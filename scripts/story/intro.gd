extends Control
## Intro (GDD 7, ~1 min): pantalla negra -> juicio en el Duat, la balanza
## oscila y se equilibra EXACTA, silencio, habla Anubis, Thot aparece.
## Despiertas en tu granja. Esc salta.

const FARM := "res://scenes/world/Farm.tscn"
const DLG := preload("res://scripts/ui/dialogue_box.gd")

var _fade: ColorRect
var _lugar: Label
var _scale: TextureRect
var _anubis: TextureRect
var _dlg: CanvasLayer
var _skip: Label
var _leaving := false
var _frames: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	var hall := preload("res://scripts/story/duat_hall.gd").new()
	add_child(hall)
	for i in range(3):
		_frames.append(load("res://assets/sprites/story/scale_%d.png" % i))
	_scale = TextureRect.new()
	_scale.texture = _frames[1]
	_scale.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_scale.position = Vector2(240 - 64, 88)
	_scale.modulate.a = 0.0
	add_child(_scale)
	_anubis = TextureRect.new()
	_anubis.texture = load("res://assets/sprites/story/anubis_bust.png")
	_anubis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anubis.position = Vector2(150, 40)
	_anubis.scale = Vector2(2, 2)
	_anubis.modulate.a = 0.0
	add_child(_anubis)
	_lugar = UIStyle.make_label(self, Textos.t("intro_lugar"), Vector2(0, 16), UIStyle.SMALL, Color(0.95, 0.8, 0.45))
	_lugar.size = Vector2(480, 10)
	_lugar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lugar.modulate.a = 0.0
	_skip = UIStyle.make_label(self, Textos.t("intro_saltar"), Vector2(404, 4), UIStyle.SMALL, UIStyle.TEXT_DIM)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_dlg = DLG.new()
	add_child(_dlg)
	_run()


func _run() -> void:
	await _wait(0.8)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 2.0)
	tw.parallel().tween_property(_lugar, "modulate:a", 1.0, 1.5)
	await tw.finished
	await _wait(0.6)
	create_tween().tween_property(_scale, "modulate:a", 1.0, 1.0)
	await _wait(1.2)
	# la balanza duda... y queda exacta
	for f in [0, 2, 0, 2, 1]:
		_scale.texture = _frames[f]
		SFX.play("heart_shift", -6.0 if f != 1 else 0.0, 0.0)
		await _wait(0.55 if f != 1 else 0.2)
	_flash(Color(1, 0.95, 0.8, 0.5))
	MenuMusic.stop_theme()
	await _wait(1.8)  # silencio
	var tw2 := create_tween()
	tw2.tween_property(_scale, "position:x", 300.0, 1.0).set_trans(Tween.TRANS_SINE)
	tw2.parallel().tween_property(_anubis, "modulate:a", 1.0, 1.2)
	tw2.parallel().tween_property(_anubis, "position:x", 40.0, 1.2).set_trans(Tween.TRANS_SINE)
	await tw2.finished
	MenuMusic.play_theme()
	_dlg.show_lines(Dialogos.lines("anubis", "intro"))
	await _dlg.finished
	_leave()


func _flash(col: Color) -> void:
	var f := ColorRect.new()
	f.color = col
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	var tw := create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.6)
	tw.tween_callback(f.queue_free)


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_leave()


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
