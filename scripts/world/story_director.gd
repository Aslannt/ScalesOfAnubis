extends Node
## Estructura de la demo de 3 dias (GDD 7) y reacciones de Thot (GDD 4, M7):
## - Dia 1: tutorial suave con comentarios de Thot segun lo que haces.
## - Noche 1: pocas sombras. Noche 2: decision moral 2 (aldea vs cultivos).
## - Dia 3: Meret da el escarabajo. Noche 3: Heraldo de Ammit.
## - Amanecer: resumen de la noche. Final: pesaje, recuerdo del ba, gracias.
## - Derrota: Anubis te devuelve a la granja (o reintentas el jefe).

const FINAL_SCENE := "res://scenes/story/Final.tscn"

var player: Player
var night_director: Node
var dawn_summary: Node
var _fade: ColorRect
var _fade_lbl: Label
var _t: float = 0.0
var _moved := false
var _village_warned := false
var _ending := false


func _ready() -> void:
	add_to_group("story_director")
	GameTime.phase_changed.connect(_on_phase)
	GameState.village_damaged.connect(_on_village_damaged)
	GameState.heart_state_changed.connect(_on_heart_state_changed)
	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fade_lbl = UIStyle.make_label(layer, "", Vector2(0, 118), UIStyle.BIG, Color(0.98, 0.8, 0.35))
	_fade_lbl.size = Vector2(480, 40)
	_fade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fade_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fade_lbl.modulate.a = 0.0


## El corazon cambio de estado: cartel con lo que eso significa y un
## comentario de Thot la primera vez.
func _on_heart_state_changed(nuevo: String, _anterior: String) -> void:
	var banner = get_tree().get_first_node_in_group("combat_banner")
	if banner:
		banner.announce(Textos.t("estado_cambio", {"n": Textos.t("estado_" + nuevo)}), Textos.t("estado_desc_" + nuevo), GameState.heart_state_color(nuevo), 3.2)
	SFX.play("heart_shift", 2.0, 0.0)
	GameState.thot_once("estado_" + nuevo, Dialogos.thot("estado_" + nuevo))


func setup(p: Player, nd: Node, ds: Node) -> void:
	player = p
	night_director = nd
	dawn_summary = ds
	player.died.connect(_on_player_died)
	nd.boss_spawned.connect(_on_boss_spawned)
	if GameState.pending_world.is_empty():
		autosave.call_deferred()
	_apply_pending_world()
	if GameState.modo_libre:
		GameState.thot_once("libre_inicio", Dialogos.thot("libre_inicio"), true)
	# fundido de entrada al despertar en la granja
	_fade.color.a = 1.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(_fade, "color:a", 0.0, 1.2)


func _process(delta: float) -> void:
	if player == null or get_tree().paused:
		return
	_t += delta
	var day := GameState.current_day
	if day == 1 and GameTime.phase == GameTime.Phase.DAY:
		if _t > 1.5:
			GameState.thot_once("inicio", Dialogos.thot("inicio"))
		if not _moved and player.velocity.length() > 0.5:
			_moved = true
		if _moved and _t > 6.0:
			GameState.thot_once("t_arar", Dialogos.thot("arar"))
		if _t > 55.0:
			GameState.thot_once("aldeanos", Dialogos.thot("aldeanos"))
	if day == 2 and GameTime.phase == GameTime.Phase.DAY:
		if GameState.deben >= 18:
			GameState.thot_once("defensa", Dialogos.thot("defensa"))
		if GameTime.phase_progress() > 0.35:
			GameState.thot_once("altar_d2", Dialogos.thot("altar_d2"))


func _on_phase(phase: int) -> void:
	var day := GameState.current_day
	match phase:
		GameTime.Phase.DUSK:
			GameState.thot_once("dusk_%d" % day, Dialogos.thot("atardecer"), true)
		GameTime.Phase.NIGHT:
			var key: String = ["noche1", "noche2", "noche3"][clampi(day, 1, 3) - 1]
			GameState.thot_once("night_%d" % day, Dialogos.thot(key), true)
			_village_warned = false
		GameTime.Phase.DAWN:
			_on_dawn()
		GameTime.Phase.DAY:
			_iry_riega.call_deferred()
			autosave()
			if day == 2:
				GameState.thot_once("dia2", Dialogos.thot("dia2"))
				GameState.thot_once("misterio_d2", Dialogos.thot("misterio_d2"))
				GameState.thot_once("templo_objetivo", Dialogos.thot("templo_objetivo"))
			elif day == 3:
				GameState.thot_once("dia3", Dialogos.thot("dia3"))
				GameState.thot_once("misterio_d3", Dialogos.thot("misterio_d3"))


## Amistad con Iry nivel 2: al amanecer riega algunos cultivos.
func _iry_riega() -> void:
	var n := int(GameState.friend_bonus("iry_riega"))
	if n <= 0 or player == null:
		return
	var regadas := 0
	for p in player.world_builder.farm_plots:
		if regadas >= n:
			break
		if p.state == FarmPlot.State.PLANTED and not p.watered_today and not p.is_ready():
			FarmPlot.quiet = true
			p.water()
			FarmPlot.quiet = false
			regadas += 1
	if regadas > 0:
		GameState.thot(Dialogos.thot("iry_riega").replace("{n}", str(regadas)))


## Autoguardado al empezar cada dia: parcelas y defensas + GameState.
func autosave() -> void:
	if player == null or GameState.demo_finished:
		return
	var wb: WorldBuilder = player.world_builder
	var plots: Array = []
	for p in wb.farm_plots:
		plots.append(p.to_dict())
	var defs: Array = []
	for d in wb.defense_spots:
		defs.append(d.save_code())
	GameState.save_game({"plots": plots, "defenses": defs})


func _apply_pending_world() -> void:
	var w: Dictionary = GameState.pending_world
	if w.is_empty():
		return
	GameState.pending_world = {}
	var wb: WorldBuilder = player.world_builder
	var plots: Array = w.get("plots", [])
	FarmPlot.quiet = true
	for i in range(mini(plots.size(), wb.farm_plots.size())):
		wb.farm_plots[i].from_dict(plots[i])
	FarmPlot.quiet = false
	var defs: Array = w.get("defenses", [])
	for i in range(mini(defs.size(), wb.defense_spots.size())):
		wb.defense_spots[i].load_code(String(defs[i]))
	for c in get_tree().get_nodes_in_group("collectibles"):
		if c.already_taken():
			c.queue_free()
	# silenciar los sonidos/particulas de reconstruir al cargar
	GameState.thot(Textos.t("partida_cargada", {"n": GameState.current_day}))


## Objetivos del modo libre: la estacion, el regreso del Heraldo y las
## metas largas (templo, amistad).
func _free_objectives() -> Array:
	var out: Array = []
	var per := int(GameState.seasons_data.get("dias_por_estacion", 3))
	out.append([Textos.t("obj_estacion", {"s": Textos.t("estacion_nombre_" + GameState.season()), "d": GameState.season_day(), "t": per}), false])
	if GameState.is_season_last_day():
		out.append([Textos.t("obj_jefe_vuelve"), GameState.boss_defeated])
	if GameState.temple.size() < 4:
		out.append([Textos.t("obj_templo", {"n": GameState.temple.size()}), false])
	else:
		var lv := 0
		for n in ["meret", "ptahmose", "iry"]:
			lv += GameState.friend_level(n)
		out.append([Textos.t("obj_amistad", {"n": lv}), lv >= 9])
	return out


## Objetivos del momento para el HUD: [[texto, cumplido], ...]. Siempre dice
## que hacer y donde (pedido de Deivid: "no sabia que hacer").
func objectives() -> Array:
	if player == null:
		return []
	var day := GameState.current_day
	var out: Array = []
	var wb: WorldBuilder = player.world_builder
	if GameState.modo_libre:
		return _free_objectives()
	if GameTime.is_night() or GameTime.phase == GameTime.Phase.DUSK:
		if day == 2:
			out.append([Textos.t("obj_noche2"), false])
		if day >= 3 and night_director and night_director.boss != null and is_instance_valid(night_director.boss):
			out.append([Textos.t("obj_jefe"), GameState.boss_defeated])
		out.append([Textos.t("obj_sobrevivir"), false])
		out.append([Textos.t("obj_proteger"), false])
		if day == 1:
			out.append([Textos.t("obj_controles"), false])
		return out
	match day:
		1:
			var sown := 0
			for p in wb.farm_plots:
				if p.state == FarmPlot.State.PLANTED and (p.watered_today or p.growth_day > 0):
					sown += 1
			out.append([Textos.t("obj_sembrar", {"n": mini(sown, 3)}), sown >= 3])
			var met := int(GameState.meret_intro_shown) + int(GameState.ptahmose_intro_shown) + int(GameState.iry_intro_shown)
			out.append([Textos.t("obj_aldeanos", {"n": met}), met >= 3])
			out.append([Textos.t("obj_prepararse"), false])
		2:
			var ready := 0
			for p in wb.farm_plots:
				if p.is_ready():
					ready += 1
			out.append([Textos.t("obj_cosechar"), ready == 0])
			out.append([Textos.t("obj_vender"), GameState.tutorial.get("vendio", false)])
			var built := false
			for sp in wb.defense_spots:
				if sp.built != "":
					built = true
			out.append([Textos.t("obj_defensa"), built])
		_:
			if not GameState.owned_amulets.has("escarabajo"):
				out.append([Textos.t("obj_meret_escarabajo"), false])
			if not GameState.meret_mission_done:
				out.append([Textos.t("obj_lino", {"n": mini(GameState.item_count("lino"), 3)}), false])
			out.append([Textos.t("obj_gran_noche"), false])
	# misiones opcionales de dia
	var sn: String = GameState.tutorial.get("iry_senet", "")
	if sn == "pedido":
		out.append([Textos.t("obj_senet"), false])
	elif sn == "encontrado":
		out.append([Textos.t("obj_senet_volver"), false])
	var sh: int = GameState.tutorial.get("shabtis", 0)
	if sh < 5:
		out.append([Textos.t("obj_shabtis", {"n": sh}), false])
	return out


## Fundido a negro, salto de hora y vuelta (campamento: "descansar").
func fade_skip_to(phase: int) -> void:
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "color:a", 1.0, 0.7)
	await tw.finished
	GameTime.elapsed = GameTime._bounds[phase][0] - 0.3
	await get_tree().create_timer(0.6).timeout
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(_fade, "color:a", 0.0, 0.9)


func _on_village_damaged(total: int) -> void:
	if not _village_warned and total >= 1:
		_village_warned = true
		GameState.thot(Dialogos.thot("aldea_atacada"), true)


## Amanecer: evalua la decision 2 (si fue la noche 2) y muestra el resumen.
## Tras la noche 3 con el jefe vencido, pasa al final de la demo.
func _on_dawn() -> void:
	var night_of := GameState.current_day - 1  # next_day ya corrio
	if night_of >= 3 and GameState.boss_defeated and not GameState.modo_libre:
		_go_final()
		return
	var extra: Array = []
	if night_of == 2 and GameState.village_raiders_total > 0 and not GameState.decisiones.has("noche2"):
		var defended := not GameState.village_sacked() and GameState.village_kills >= int(GameState.village_raiders_total * 0.5)
		if defended:
			GameState.register_decision("noche2", "aldea")
			GameState.shift_heart(-10.0, "defender_aldea")
			extra.append([Textos.t("amanecer_aldea_salvada"), Color(0.55, 0.9, 1.0)])
		else:
			GameState.register_decision("noche2", "cultivos")
			GameState.shift_heart(8.0, "abandonar_aldea")
			extra.append([Textos.t("amanecer_aldea_saqueada"), Color(1, 0.5, 0.4)])
	if dawn_summary:
		for kind in DefenseSpot.data().get("orden", []):
			var nuevas := false
			for lv in range(1, DefenseSpot.max_level(kind) + 1):
				if int(DefenseSpot.tier(kind, lv).get("dia", 0)) == GameState.current_day:
					nuevas = true
			if nuevas:
				extra.append([Textos.t("defensas_nuevas"), UIStyle.GOLD])
				break
		dawn_summary.show_summary(GameState.current_day, extra)
		await dawn_summary.closed
	GameState.thot_once("amanecer", Dialogos.thot("amanecer"))
	_thot_recuerda()
	if night_of == 2:
		GameState.thot(Dialogos.thot("aldea_salvada") if GameState.decisiones.get("noche2", "") == "aldea" else Dialogos.thot("robo"))


## Cada amanecer (desde el dia 2) Thot cuenta un recuerdo suyo: mitos reales
## y, poco a poco, por que la balanza de Nakht dudo.
func _thot_recuerda() -> void:
	var lista := Dialogos.thot_list("recuerdos")
	var k: int = GameState.tutorial.get("recuerdo_idx", 0)
	if GameState.current_day < 2 or k >= lista.size() or GameState.tutorial.get("recuerdo_dia", 0) == GameState.current_day:
		return
	GameState.tutorial["recuerdo_idx"] = k + 1
	GameState.tutorial["recuerdo_dia"] = GameState.current_day
	GameState.thot(String(lista[k]))


func _on_boss_spawned(boss: Node) -> void:
	get_tree().call_group("music_director", "set_boss", true)
	boss.defeated.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	get_tree().call_group("music_director", "set_boss", false)
	await get_tree().create_timer(4.0).timeout
	GameTime.skip_to_dawn()


func _go_final() -> void:
	if _ending:
		return
	_ending = true
	# se guarda el amanecer del dia 4 como punto de partida del modo libre:
	# desde la pantalla de gracias (o "Continuar") se sigue jugando
	GameState.modo_libre = true
	GameState.boss_defeated = false
	autosave()
	GameState.modo_libre = false
	GameState.boss_defeated = true
	GameState.demo_finished = true
	GameTime.paused = true
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "color:a", 1.0, 1.5)
	tw.tween_callback(func(): get_tree().change_scene_to_file(FINAL_SCENE))


# ------------------------------------------------------------- derrota
func _on_player_died() -> void:
	GameState.thot(Dialogos.thot("derrota"), true)
	var boss = night_director.boss if night_director else null
	var boss_alive: bool = boss != null and is_instance_valid(boss) and not GameState.boss_defeated
	var lost := 0
	if not boss_alive:
		lost = int(GameState.deben * 0.25)
	await get_tree().create_timer(0.8).timeout
	_fade_lbl.text = Textos.t("derrota_titulo")
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "color:a", 1.0, 0.8)
	tw.parallel().tween_property(_fade_lbl, "modulate:a", 1.0, 0.8)
	await tw.finished
	GameTime.paused = true
	await get_tree().create_timer(1.2).timeout
	_fade_lbl.text = Textos.t("derrota_jefe") if boss_alive else Textos.t("derrota_texto", {"n": lost})
	await get_tree().create_timer(1.8).timeout
	# volver a la granja
	if lost > 0:
		GameState.add_deben(-lost)
	GameState.full_heal()
	player.global_position = player.world_builder.player_spawn_world + Vector3(0, 0.3, 0)
	player.revive()
	if boss_alive:
		# reintentar al jefe: vuelve a su punto, con vida llena, sin crias
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss and e.has_method("vanish"):
				e.vanish()
		boss.reset_for_retry(night_director.spawn_point("necropolis"))
		GameTime.paused = false
	else:
		GameTime.paused = false
		GameTime.skip_to_dawn()
	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(_fade, "color:a", 0.0, 1.0)
	tw2.parallel().tween_property(_fade_lbl, "modulate:a", 0.0, 0.6)
