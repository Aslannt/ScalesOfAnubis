extends Node
## Musica por fase (GDD 9): loop de dia y loop de noche con crossfade suave.
## Boss theme se activa manualmente (ver night_director/heraldo, futuro).

var _dia: AudioStreamPlayer
var _noche: AudioStreamPlayer
var _jefe: AudioStreamPlayer
var _boss := false

const VOL_ON := 0.0
const VOL_OFF := -40.0
const FADE_SPEED := 6.0


func _ready() -> void:
	_dia = _make_player("res://assets/audio/music/dia.wav")
	_noche = _make_player("res://assets/audio/music/noche.wav")
	_dia.volume_db = VOL_ON
	_noche.volume_db = VOL_OFF
	_jefe = _make_player("res://assets/audio/music/jefe.wav")
	_jefe.volume_db = VOL_OFF
	_dia.play()
	_noche.play()
	add_to_group("music_director")


func set_boss(active: bool) -> void:
	_boss = active
	if active and not _jefe.playing:
		_jefe.play()


func _make_player(path: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load(path)
	if stream:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	p.stream = stream
	p.bus = "Music"
	add_child(p)
	return p


func _process(delta: float) -> void:
	var night := GameTime.is_night() or GameTime.phase == GameTime.Phase.DUSK
	var target_dia := VOL_OFF if night else VOL_ON
	var target_noche := VOL_ON if night and not _boss else VOL_OFF
	var target_jefe := VOL_ON if _boss else VOL_OFF
	_dia.volume_db = move_toward(_dia.volume_db, target_dia, FADE_SPEED * delta * 10.0)
	_noche.volume_db = move_toward(_noche.volume_db, target_noche, FADE_SPEED * delta * 10.0)
	_jefe.volume_db = move_toward(_jefe.volume_db, target_jefe, FADE_SPEED * delta * 10.0)
	if not _boss and _jefe.playing and _jefe.volume_db <= VOL_OFF + 0.1:
		_jefe.stop()
