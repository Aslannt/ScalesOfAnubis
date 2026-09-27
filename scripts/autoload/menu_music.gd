extends Node
## Tema del titulo (menu, intro y final). Las escenas lo piden con
## MenuMusic.play_theme() / stop_theme(); se desvanece suave.

var _p: AudioStreamPlayer
var _target := -60.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_p = AudioStreamPlayer.new()
	var s: AudioStreamWAV = load("res://assets/audio/music/titulo.wav")
	if s:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_p.stream = s
	_p.bus = "Music"
	_p.volume_db = -60.0
	add_child(_p)


func play_theme() -> void:
	_target = -2.0
	if not _p.playing:
		_p.play()


func stop_theme() -> void:
	_target = -60.0


func _process(delta: float) -> void:
	_p.volume_db = move_toward(_p.volume_db, _target, delta * 30.0)
	if _target < -50.0 and _p.playing and _p.volume_db <= -59.0:
		_p.stop()
