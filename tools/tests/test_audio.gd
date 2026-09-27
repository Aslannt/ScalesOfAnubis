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
	# las capas del groove deben durar lo mismo para quedar sincronizadas
	var lens := []
	for f in ["groove_base", "groove_dia", "groove_noche", "estacion_peret", "estacion_shemu", "estacion_akhet"]:
		lens.append(snappedf(load("res://assets/audio/music/%s.wav" % f).get_length(), 0.001))
	var sync: bool = lens.all(func(l): return l == lens[0])
	print("  ", "ok: " if sync else "FALLO: ", "capas del groove del mismo largo ", lens)
	ok = ok and sync
	# modo libre: la capa de la estacion sube de dia
	GameState.modo_libre = true
	GameState.current_day = 7
	await get_tree().create_timer(2.0).timeout
	var akhet_on: bool = md._seasons["akhet"].volume_db > -10.0 and md._seasons["shemu"].volume_db < -40.0
	print("  ", "ok: " if akhet_on else "FALLO: ", "en Akhet suena la capa de la crecida")
	ok = ok and akhet_on
	GameState.modo_libre = false
	GameState.current_day = 1
	# la musica no se corta durante un dialogo (arbol en pausa)
	get_tree().paused = true
	await get_tree().create_timer(0.3, true).timeout
	var still := false
	for c in md.get_children():
		if c is AudioStreamPlayer and c.playing and not c.stream_paused and c.volume_db > -10.0 and c.can_process():
			still = true
	get_tree().paused = false
	print("  ", "ok: " if still else "FALLO: ", "la musica sigue en pausa")
	ok = ok and still
	print("TEST AUDIO: ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)
