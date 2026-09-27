extends Node
## Prueba de audio: toda la musica/ambiente tiene loop valido (el bug real
## era loop_end = 0: la musica no sonaba nada) y el director de musica la
## esta reproduciendo al entrar a la granja.

func _ready() -> void:
	var ok := true
	var dir := DirAccess.open("res://assets/audio/music")
	for f in dir.get_files():
		if not f.ends_with(".wav"):
			continue
		var s: AudioStreamWAV = load("res://assets/audio/music/" + f)
		var good := s.loop_mode != AudioStreamWAV.LOOP_DISABLED and s.loop_end > s.loop_begin + 1000
		print("  ", "ok: " if good else "FALLO: ", f, " loop_mode=", s.loop_mode, " loop_end=", s.loop_end)
		ok = ok and good
	var farm: Node = load("res://scenes/world/Farm.tscn").instantiate()
	add_child(farm)
	await get_tree().create_timer(0.5).timeout
	var md = farm.get_node("MusicDirector")
	var playing := false
	for c in md.get_children():
		if c is AudioStreamPlayer and c.playing and c.volume_db > -10.0:
			playing = true
	print("  ", "ok: " if playing else "FALLO: ", "suena musica en la granja")
	ok = ok and playing
	print("TEST AUDIO: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)
