extends Node
## Herramienta de captura visual (PROMPT_PULIDO.md, regla obligatoria).
## Carga Farm.tscn de verdad (con ventana, sin --headless), pone al jugador
## en puntos clave del mapa, fija la hora del día y guarda PNGs en shots/.
## Correr con: godot --path . res://tools/capture.tscn (SIN --headless)

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")

# tile en coordenadas de data/map_layout.json (ver world_builder._tile_to_world)
const SCENARIOS := [
	{"name": "01_granja_dia", "tile": Vector2(13, 14), "phase": 1, "wide": false},
	{"name": "02_granja_atardecer", "tile": Vector2(13, 14), "phase": 2, "wide": false},
	{"name": "03_granja_noche", "tile": Vector2(13, 14), "phase": 3, "wide": false},
	{"name": "04_aldea_dia", "tile": Vector2(26, 10), "phase": 1, "wide": false},
	{"name": "05_aldea_noche", "tile": Vector2(26, 10), "phase": 3, "wide": false},
	{"name": "06_necropolis_noche", "tile": Vector2(26, 21), "phase": 3, "wide": false},
	{"name": "07_orilla_nilo_dia", "tile": Vector2(6, 12), "phase": 1, "wide": false},
	{"name": "08_vista_general_dia", "tile": Vector2(14, 12), "phase": 1, "wide": true},
	{"name": "12_anim_orilla", "tile": Vector2(8, 13), "phase": 1, "wide": false, "frames": 4, "ambient": true},
	{"name": "13_anim_noche", "tile": Vector2(12, 18), "phase": 3, "wide": false, "frames": 3},
	{"name": "14_jefe", "tile": Vector2(14, 22), "phase": 3, "wide": false, "setup": "jefe", "bark": true},
	{"name": "15_defensas_noche", "tile": Vector2(17.2, 13.6), "phase": 3, "wide": false, "setup": "defensas"},
	{"name": "16_ptahmose_menu", "tile": Vector2(6, 5.8), "phase": 1, "wide": false, "setup": "ptahmose"},
	{"name": "16b_defensa_menu", "tile": Vector2(16, 14), "phase": 1, "wide": false, "setup": "defensa_menu"},
	{"name": "17_resumen_amanecer", "tile": Vector2(13, 14), "phase": 0, "wide": false, "setup": "amanecer"},
	{"name": "18_combate_noche", "tile": Vector2(14, 13), "phase": 3, "wide": false, "setup": "combate", "bark": true},
	{"name": "19_dialogo_meret", "tile": Vector2(24, 9.4), "phase": 1, "wide": false, "setup": "dialogo"},
	{"name": "25_codice", "tile": Vector2(13, 14), "phase": 1, "wide": false, "setup": "codice"},
	{"name": "26_templo_dia", "tile": Vector2(24, 8.5), "phase": 1, "wide": true},
	{"name": "27_necropolis_dia", "tile": Vector2(26, 23), "phase": 1, "wide": true},
	{"name": "28_casa_cerca", "tile": Vector2(27.2, 9.6), "phase": 1, "wide": false},
	{"name": "29_piramide_escalonada", "tile": Vector2(29.5, 24.5), "phase": 1, "wide": false},
	{"name": "30_casa_translucida", "tile": Vector2(28, 5.6), "phase": 1, "wide": false},
	{"name": "31_orilla_gansos", "tile": Vector2(8, 6.5), "phase": 1, "wide": false},
	{"name": "32_aldea_gato", "tile": Vector2(25, 11.5), "phase": 2, "wide": false},
	{"name": "33_corazon_hambre", "tile": Vector2(14, 13), "phase": 3, "wide": false, "setup": "hambre", "bark": true},
	{"name": "34_corazon_pluma", "tile": Vector2(13, 14), "phase": 1, "wide": false, "setup": "pluma", "bark": true},
	{"name": "10_horizonte_piramides", "tile": Vector2(22, 3), "phase": 1, "wide": true, "pitch": 2.0},
	{"name": "11_horizonte_atardecer", "tile": Vector2(22, 3), "phase": 2, "wide": true, "pitch": 2.0},
]

var farm: Node3D
var world_builder
var player
var camera_rig
var day_night
var _base_offset: Vector3
var _base_pitch: float


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://shots")
	farm = FARM_SCENE.instantiate()
	add_child(farm)
	await get_tree().process_frame
	await get_tree().process_frame

	world_builder = farm.get_node("WorldBuilder")
	camera_rig = farm.get_node("CameraRig")
	day_night = farm.get_node("DayNightController")
	player = get_tree().get_first_node_in_group("player")
	_base_offset = camera_rig.offset
	_base_pitch = camera_rig.rotation_degrees.x

	_plant_demo_crops()
	var only := OS.get_environment("SOA_ONLY")
	for s in SCENARIOS:
		if only != "" and not Array(only.split(",")).any(func(o): return String(s["name"]).contains(o)):
			continue
		await _run_scenario(s)

	print("CAPTURE DONE")
	get_tree().quit()


func _run_scenario(s: Dictionary) -> void:
	GameTime.force_phase(s["phase"])
	day_night.snap_to_current_phase()
	camera_rig.offset = _base_offset * (1.8 if s.get("wide", false) else 1.0)
	player.global_position = world_builder._tile_to_world(s["tile"].x, s["tile"].y) + Vector3(0, 0.2, 0)
	camera_rig.set_target(player)
	camera_rig.rotation_degrees.x = s.get("pitch", _base_pitch)
	# los comentarios de Thot tapan la escena en las capturas: solo se
	# muestran en los escenarios marcados con "bark"
	var bark = get_tree().get_first_node_in_group("thot_bark")
	bark.clear()
	bark._showing = false
	bark._panel.visible = false
	var want_bark: bool = s.get("bark", false)
	if want_bark and not GameState.thot_says.is_connected(bark.say):
		GameState.thot_says.connect(bark.say)
	elif not want_bark and GameState.thot_says.is_connected(bark.say):
		GameState.thot_says.disconnect(bark.say)
	for i in range(12):
		await get_tree().process_frame
	await _setup(s.get("setup", ""))
	if OS.get_environment("SOA_DEBUG_LIGHT") == "1":
		var e = farm.get_node("WorldEnvironment").environment
		var sun := farm.get_node("Sun") as DirectionalLight3D
		print(s["name"], " phase=", GameTime.phase, " sun_color=", sun.light_color, " sun_energy=", sun.light_energy,
			" ambient=", e.ambient_light_energy, " horizon=", e.sky.sky_material.get("sky_horizon_color"),
			" top=", e.sky.sky_material.get("sky_top_color"), " fog_color=", e.fog_light_color,
			" fog_enabled=", e.fog_enabled, " glow=", e.glow_enabled)
	if s.get("ambient", false):
		var amb = farm.get_node("AmbientFX")
		amb._spawn_fish()
		await get_tree().create_timer(0.3).timeout
		get_viewport().get_texture().get_image().save_png("res://shots/%s_pez.png" % s["name"])
		amb._spawn_flock()
		await get_tree().create_timer(3.2).timeout
	if not s.get("bark", false):
		var bk = get_tree().get_first_node_in_group("thot_bark")
		bk.clear()
		bk._showing = false
		bk._panel.visible = false
	if not s.get("bark", false):
		get_tree().get_first_node_in_group("combat_banner").hide_now()
	var n: int = s.get("frames", 1)
	for f in range(n):
		var img := get_viewport().get_texture().get_image()
		var suffix := "" if n == 1 else "_f%d" % f
		img.save_png("res://shots/%s%s.png" % [s["name"], suffix])
		if n > 1:
			await get_tree().create_timer(0.3).timeout
	print("captured ", s["name"])
	_cleanup()


## Siembra algunas parcelas en distintas etapas para que las capturas
## muestren cultivos (y el viento sobre ellos).
func _plant_demo_crops() -> void:
	var i := 0
	for plot in world_builder.farm_plots:
		i += 1
		if i % 3 == 0:
			continue
		plot.till()
		var id: String = "papiro" if plot.is_orilla else ("lino" if i % 5 == 0 else "trigo")
		plot.plant(id)
		plot.growth_day = i % 4
		if i % 4 == 1:
			plot.water()
		plot._update_crop_frame()


func _setup(kind: String) -> void:
	var nd = farm.get_node("NightDirector")
	match kind:
		"jefe":
			var b = nd.spawn("jefe", "", "", player.global_position + Vector3(1.2, 0, -3.6))
			await get_tree().create_timer(2.6).timeout
			b._enter(Heraldo.S.ROAR)
			get_tree().get_first_node_in_group("combat_banner").announce(Textos.t("oleada_jefe"))
			player._start_attack()
			await get_tree().create_timer(0.35).timeout
		"defensas":
			GameState.add_deben(200)
			GameState.current_day = 3
			world_builder.defense_spots[0].build("estatua", 3)
			world_builder.defense_spots[1].build("brasero", 3)
			world_builder.defense_spots[3].build("muro", 3)
			for k in range(3):
				nd.spawn("sombra", "", "", world_builder.defense_spots[0].global_position + Vector3(2.5 + k, 0, k - 1.0))
			await get_tree().create_timer(1.6).timeout
		"hambre":
			GameState.shift_heart(40.0, "robo_altar")
			await get_tree().create_timer(1.0).timeout
		"pluma":
			GameState.shift_heart(-30.0, "ofrenda")
			await get_tree().create_timer(1.0).timeout
		"defensa_menu":
			GameState.current_day = 2
			GameState.add_deben(40)
			world_builder.defense_spots[1].build("brasero")
			await get_tree().create_timer(0.5).timeout
			world_builder.defense_spots[1].interact()
			await get_tree().create_timer(0.5).timeout
			get_tree().get_first_node_in_group("choice_box")._focus(1)
			await get_tree().create_timer(0.3).timeout
		"ptahmose":
			GameState.ptahmose_intro_shown = true
			GameState.add_item("trigo", 4)
			for n in world_builder.npcs:
				if n.npc_id == "ptahmose":
					n.interact()
			await get_tree().create_timer(0.5).timeout
		"amanecer":
			GameState.enemies_defeated_tonight = 7
			GameState.crops_lost_tonight = 2
			GameState.heart_at_night_start = 50.0
			GameState.shift_heart(-6.0, "defender_aldea")
			GameState.shift_heart(-3.0, "ofrenda")
			farm.get_node("DawnSummary").show_summary(2, [[Textos.t("amanecer_aldea_salvada"), Color(0.55, 0.9, 1.0)]])
			await get_tree().create_timer(4.0).timeout
		"codice":
			for id in ["anubis", "thot", "maat", "ammit", "kemet", "cultivos"]:
				Codex.unlock(id)
			var cm = farm.get_node("CodexMenu")
			cm.toggle()
			cm._list.select(2)
			cm._on_selected(2)
			await get_tree().create_timer(0.4).timeout
		"dialogo":
			for n in world_builder.npcs:
				if n.npc_id == "meret":
					n.interact()
			await get_tree().create_timer(2.5).timeout
		"combate":
			for k in range(4):
				nd.spawn("sombra" if k % 2 == 0 else "cria", "", "", player.global_position + Vector3(-2.5 + k * 1.6, 0, -2.0))
			await get_tree().create_timer(1.2).timeout
			var banner = get_tree().get_first_node_in_group("combat_banner")
			banner.announce(Textos.t("oleada_desierto"), Textos.t("oleada_sub_sombra"))
			for k in range(6):
				banner.add_hit()
			var es := get_tree().get_nodes_in_group("enemies")
			if es.size() > 0:
				es[0].take_hit(999)
			await get_tree().create_timer(0.35).timeout
			player._start_attack()
			await get_tree().create_timer(0.08).timeout


func _cleanup() -> void:
	get_tree().paused = false
	GameState.heart_weight = 50.0
	GameState._refresh_heart_state()
	var bn = get_tree().get_first_node_in_group("combat_banner")
	if bn:
		bn.hide_now()
		bn._combo.modulate.a = 0.0
		bn._combo_n = 0
	farm.get_node("HUD")._boss_panel.visible = false
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	var dsum = farm.get_node("DawnSummary")
	dsum.visible = false
	dsum._open = false
	var cmn = farm.get_node("CodexMenu")
	if cmn.visible:
		cmn.toggle()
	var dl = get_tree().get_first_node_in_group("dialogue_box")
	dl.visible = false
	var cb = get_tree().get_first_node_in_group("choice_box")
	if cb.visible:
		cb._choose(-1)
