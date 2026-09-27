extends Node
## Musica adaptativa (GDD 9, pedido de Deivid: "algo adictivo como Balatro").
## Tres capas del MISMO largo y tempo arrancan juntas y quedan sincronizadas;
## segun la fase solo cambia el volumen de cada una, asi la cancion nunca se
## corta: el dia suma el gancho calido, el atardecer mete tension y la noche
## la darbuka y la lengueta. El jefe tiene su propia version rapida.
## Sigue sonando en pausa (dialogos, menus), si no se cortaba al hablar.

const DIR := "res://assets/audio/music/"
const OFF := -50.0
const FADE_DB_PER_SEC := 30.0

# volumen objetivo por fase: [base, dia, noche]
const MIX := {
	0: [-3.0, -9.0, OFF],   # amanecer
	1: [0.0, 0.0, OFF],     # dia
	2: [0.0, -10.0, -5.0],  # atardecer: sube la tension
	3: [0.0, OFF, 0.0],     # noche
}

var _base: AudioStreamPlayer
var _dia: AudioStreamPlayer
var _noche: AudioStreamPlayer
var _jefe: AudioStreamPlayer
var _amb_dia: AudioStreamPlayer
var _amb_noche: AudioStreamPlayer
var _boss := false
const AMB_ON := -6.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("music_director")
	_base = _make_player("groove_base.wav", "Music")
	_dia = _make_player("groove_dia.wav", "Music")
	_noche = _make_player("groove_noche.wav", "Music")
	_jefe = _make_player("jefe.wav", "Music")
	_amb_dia = _make_player("amb_dia.wav", "SFX")
	_amb_noche = _make_player("amb_noche.wav", "SFX")
	var mix: Array = MIX[GameTime.phase]
	_base.volume_db = mix[0]
	_dia.volume_db = mix[1]
	_noche.volume_db = mix[2]
	# las tres capas arrancan en el mismo instante: quedan en fase
	for p in [_base, _dia, _noche, _amb_dia, _amb_noche]:
		p.play()


func _make_player(file: String, bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	# el loop se define en la importacion (edit/loop_mode=2 en el .import):
	# fijarlo por codigo dejaba loop_end en 0 y la musica no sonaba (bug real)
	p.stream = load(DIR + file)
	p.bus = bus
	p.volume_db = OFF
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


func set_boss(active: bool) -> void:
	_boss = active
	if active and not _jefe.playing:
		_jefe.play()


func _process(delta: float) -> void:
	var mix: Array = MIX[GameTime.phase]
	var step := FADE_DB_PER_SEC * delta
	var groove_mul := OFF if _boss else 0.0
	_base.volume_db = move_toward(_base.volume_db, maxf(OFF, mix[0] + groove_mul), step)
	_dia.volume_db = move_toward(_dia.volume_db, maxf(OFF, mix[1] + groove_mul), step)
	_noche.volume_db = move_toward(_noche.volume_db, maxf(OFF, mix[2] + groove_mul), step)
	_jefe.volume_db = move_toward(_jefe.volume_db, 0.0 if _boss else OFF, step)
	if not _boss and _jefe.playing and _jefe.volume_db <= OFF + 0.1:
		_jefe.stop()
	var night := GameTime.is_night()
	_amb_dia.volume_db = move_toward(_amb_dia.volume_db, OFF if night else AMB_ON, step)
	_amb_noche.volume_db = move_toward(_amb_noche.volume_db, AMB_ON if night else OFF, step)
