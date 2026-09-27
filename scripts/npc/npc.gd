class_name NPC
extends Node3D
## Aldeanos (GDD 4 y 6.7): Meret, Ptahmose e Iry. Dialogo simple con
## data/dialogues.json; la logica de mision/venta esta aqui porque son solo
## tres NPCs y una maquina de dialogo generica no aporta en una sola noche.

@export var npc_id: String = ""
@export var sheet_path: String = ""
@export var layout_path: String = ""

var sprite: AnimatedSprite3D
var _dialogue: Node = null


func _ready() -> void:
	add_to_group("npcs")
	sprite = AnimatedSprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.pixel_size = 0.052
	sprite.shaded = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.position = Vector3(0, 0.84, 0)
	add_child(sprite)
	sprite.sprite_frames = SpritesheetLoader.build(sheet_path, layout_path, 6.0)
	sprite.play("south_idle")
	CharacterFX.add_blob_shadow(self, 0.4)
	_t = randf() * 10.0
	# "!" amarillo cuando el aldeano tiene algo nuevo que decir
	_news = Label3D.new()
	_news.text = "!"
	_news.font_size = 96
	_news.outline_size = 18
	_news.modulate = Color(1.0, 0.85, 0.25)
	_news.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_news.pixel_size = 0.01
	_news.position.y = 2.3
	add_child(_news)
	call_deferred("_find_dialogue_box")


var _t: float = 0.0
var _news: Label3D
## Paseo corto alrededor de su lugar (tercera ronda: mundo vivo). Se quedan
## quietos y te miran cuando te acercas, y de noche no salen.
const WANDER := {"meret": 2.2, "ptahmose": 0.9, "iry": 2.6}
var _home := Vector3.INF
var _goal := Vector3.ZERO
var _wait := 2.0
var _facing := "south"


func _process(delta: float) -> void:
	_t += delta
	sprite.offset.y = CharacterFX.breathe_offset(_t, 1.9)
	_wander(delta)
	_news.visible = has_news()
	if _news.visible:
		_news.position.y = 2.3 + absf(sin(_t * 3.0)) * 0.25


func _wander(delta: float) -> void:
	if _home == Vector3.INF:
		_home = position
		_goal = position
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var near := player != null and player.global_position.distance_to(global_position) < 3.4
	if near or GameTime.is_night():
		if near:
			_face((player.global_position - global_position))
		sprite.play(_facing + "_idle")
		return
	var to := _goal - position
	to.y = 0
	if to.length() > 0.12:
		position += to.normalized() * minf(0.85 * delta, to.length())
		_face(to)
		sprite.play(_facing + "_walk")
		return
	sprite.play(_facing + "_idle")
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = randf_range(2.5, 6.0)
	var r: float = WANDER.get(npc_id, 1.5)
	var ang := randf() * TAU
	var cand := _home + Vector3(cos(ang), 0, sin(ang)) * randf_range(0.4, r)
	# no atravesar muros ni puestos: si algo solido se cruza, se queda
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.5, 0), (get_parent() as Node3D).to_global(cand) + Vector3(0, 0.5, 0))
	if space.intersect_ray(q).is_empty():
		_goal = cand


func _face(dir: Vector3) -> void:
	if absf(dir.x) > absf(dir.z) * 1.2:
		_facing = "east"
		sprite.flip_h = dir.x < 0
	else:
		_facing = "south" if dir.z > 0 else "north"
		sprite.flip_h = false


## true si hablar con este aldeano avanza algo (intro, mision, regalo...).
func has_news() -> bool:
	match npc_id:
		"meret":
			if not GameState.meret_intro_shown:
				return true
			if GameState.decisiones.has("noche2") and not GameState.tutorial.get("meret_d2", false):
				return true
			if GameState.current_day >= 3 and not GameState.owned_amulets.has("escarabajo"):
				return true
			return not GameState.meret_mission_done and GameState.item_count("lino") >= GameState.MERET_CROPS_NEEDED
		"ptahmose":
			if not GameState.ptahmose_intro_shown:
				return true
			for cid in ["trigo", "papiro"]:
				if GameState.item_count(cid) > 0:
					return true
			return false
		"iry":
			if not GameState.iry_intro_shown:
				return true
			if GameState.current_day >= 2 and not GameState.tutorial.get("iry_d2", false):
				return true
			var sn: String = GameState.tutorial.get("iry_senet", "")
			if GameState.current_day >= 2 and (sn == "" or sn == "encontrado"):
				return true
			return GameState.current_day >= 3 and not GameState.tutorial.get("iry_d3", false)
	return false


func _find_dialogue_box() -> void:
	_dialogue = get_tree().get_first_node_in_group("dialogue_box")


func interact() -> void:
	if _dialogue == null:
		_find_dialogue_box()
	match npc_id:
		"meret": _meret()
		"ptahmose": _ptahmose()
		"iry": _iry()


func _meret() -> void:
	if not GameState.meret_intro_shown:
		GameState.meret_intro_shown = true
		_dialogue.show_lines(Dialogos.lines("meret", "intro"))
		return
	# reaccion a la decision de la noche 2 (una vez)
	var d2: String = GameState.decisiones.get("noche2", "")
	if d2 != "" and not GameState.tutorial.get("meret_d2", false):
		GameState.tutorial["meret_d2"] = true
		_dialogue.show_lines(Dialogos.lines("meret", "defendiste" if d2 == "aldea" else "abandonaste"))
		return
	# dia 3: Meret entrega el escarabajo del corazon (GDD 7)
	if GameState.current_day >= 3 and not GameState.owned_amulets.has("escarabajo"):
		_dialogue.show_lines(Dialogos.lines("meret", "escarabajo"), func():
			GameState.owned_amulets.append("escarabajo")
			GameState.equipped_amulet = "escarabajo"
			SFX.play("coin")
			Codex.unlock("amuletos"))
		return
	if GameState.meret_mission_done or GameState.item_count("lino") < GameState.MERET_CROPS_NEEDED and GameState.tutorial.get("meret_recordado_d%d" % GameState.current_day, false):
		_social_menu()
		return
	# mision: tres manojos de lino para las vendas del templo (GDD 6.7)
	if GameState.item_count("lino") >= GameState.MERET_CROPS_NEEDED:
		GameState.remove_item("lino", GameState.MERET_CROPS_NEEDED)
		GameState.meret_mission_done = true
		GameState.shift_heart(-8.0, "meret_mision")
		Codex.unlock("aaru")
		_dialogue.show_lines(Dialogos.lines("meret", "mision_completa"))
	else:
		GameState.tutorial["meret_recordado_d%d" % GameState.current_day] = true
		_dialogue.show_lines(Dialogos.lines("meret", "recordatorio"))


func _ptahmose() -> void:
	if not GameState.ptahmose_intro_shown:
		GameState.ptahmose_intro_shown = true
		_dialogue.show_lines(Dialogos.lines("ptahmose", "intro"))
		return
	var box = get_tree().get_first_node_in_group("choice_box")
	var valor := _valor_cosecha()
	var opciones := [
		Textos.t("ptah_vender", {"v": valor}) if valor > 0 else Textos.t("ptah_nada"),
	]
	for id in GameState.SEED_IDS:
		opciones.append(Textos.t("ptah_semilla", {"n": GameState.crops[id]["nombre_corto"], "p": _precio_pack(id)}))
	opciones.append(Textos.t("ptah_rumor"))
	opciones.append(Textos.t("ptah_mejoras"))
	opciones.append(Textos.t("ptah_charlar"))
	opciones.append(Textos.t("ptah_regalar"))
	opciones.append(Textos.t("ptah_adios"))
	box.ask(Textos.t("ptah_titulo", {"d": GameState.deben}) + "\n" + Textos.t("npc_titulo", {"n": Textos.t("nombre_ptahmose"), "l": GameState.friend_level("ptahmose")}), opciones, _on_ptahmose_choice)


const PACK := 3


func _precio_pack(id: String) -> int:
	# precio de amigo (amistad con Ptahmose nivel 1)
	return int(ceil(int(GameState.crops[id]["precio_semilla"]) * PACK * (1.0 - GameState.friend_bonus("descuento"))))


## La cosecha que se vende; el lino se guarda si la mision de Meret sigue
## abierta (para no venderle al jugador su propia mision sin querer).
func _vendibles() -> Array:
	var ids := ["trigo", "papiro"]
	if GameState.meret_mission_done:
		ids.append("lino")
	return ids


func _valor_cosecha() -> int:
	var total := 0
	for cid in _vendibles():
		total += int(GameState.crops[cid]["precio_venta"]) * GameState.item_count(cid)
	total = int(round(total * (GameState.heart_mod("venta", 1.0) + GameState.friend_bonus("precio_venta"))))
	return total


func _on_ptahmose_choice(i: int) -> void:
	if i == 0:
		var total := _valor_cosecha()
		if total <= 0:
			_dialogue.show_lines(Dialogos.lines("ptahmose", "vender_vacio"))
			return
		for cid in _vendibles():
			GameState.remove_item(cid, GameState.item_count(cid))
		GameState.add_deben(total)
		GameState.tutorial["vendio"] = true
		_dialogue.show_lines(Dialogos.lines("ptahmose", "vender_exito"))
	elif i >= 1 and i <= 3:
		var id: String = GameState.SEED_IDS[i - 1]
		var precio := _precio_pack(id)
		if not GameState.can_afford(precio):
			_dialogue.show_lines(Dialogos.lines("ptahmose", "sin_dinero"))
			return
		GameState.add_deben(-precio)
		GameState.add_item("semilla_" + id, PACK)
		_dialogue.show_lines(Dialogos.lines("ptahmose", "compra_ok"))
	elif i == 4:
		var rumores: Array = Dialogos.data.get("ptahmose", {}).get("rumores", [])
		if rumores.is_empty():
			return
		var k: int = GameState.tutorial.get("rumor_idx", 0)
		GameState.tutorial["rumor_idx"] = k + 1
		_dialogue.show_lines(rumores[k % rumores.size()])
	elif i == 5:
		_upgrades_menu()
	elif i == 6:
		_charlar()
	elif i == 7:
		_regalar_menu()


func _iry() -> void:
	if not GameState.iry_intro_shown:
		GameState.iry_intro_shown = true
		Codex.unlock("ba")
		_dialogue.show_lines(Dialogos.lines("iry", "intro"))
		return
	var key := "repeat"
	# mision de la ficha de senet (dia 2 en adelante)
	var senet: String = GameState.tutorial.get("iry_senet", "")
	if senet == "encontrado":
		GameState.tutorial["iry_senet"] = "entregado"
		GameState.shift_heart(-5.0, "ayudar_iry")
		_dialogue.show_lines(Dialogos.lines("iry", "senet_gracias"))
		return
	if GameState.current_day >= 2 and GameState.tutorial.get("iry_d2", false) and senet == "":
		GameState.tutorial["iry_senet"] = "pedido"
		_dialogue.show_lines(Dialogos.lines("iry", "senet_pedido"))
		return
	if GameState.current_day >= 3 and not GameState.tutorial.get("iry_d3", false):
		GameState.tutorial["iry_d3"] = true
		key = "dia3"
	elif GameState.current_day >= 2 and not GameState.tutorial.get("iry_d2", false):
		GameState.tutorial["iry_d2"] = true
		key = "dia2"
		Codex.unlock("sheut")
	if key == "repeat":
		_social_menu()
		return
	_dialogue.show_lines(Dialogos.lines("iry", key))


# ------------------------------------------------------------------
# Fase 2: amistad (charlar y regalar), templo de Maat y mejoras.

## Menu social cuando el aldeano no tiene nada nuevo que contar.
func _social_menu() -> void:
	var box = get_tree().get_first_node_in_group("choice_box")
	var charlo: bool = int(GameState.amistad_charla.get(npc_id, 0)) == GameState.current_day
	var opts: Array = [Textos.t("npc_charlar_hecho") if charlo else Textos.t("npc_charlar"), Textos.t("npc_regalar")]
	var descs: Array = [Textos.t("desc_charlar"), Textos.t("desc_regalar")]
	var acts: Array = [_charlar, _regalar_menu]
	if npc_id == "meret":
		opts.append(Textos.t("npc_templo", {"n": GameState.temple.size()}))
		descs.append(Textos.t("desc_templo"))
		acts.append(_templo_menu)
	opts.append(Textos.t("npc_adios"))
	descs.append(Textos.t("desc_adios"))
	acts.append(func(): pass)
	GameState.thot_once("amistad_explica", Dialogos.thot("amistad_explica"))
	box.ask(Textos.t("npc_titulo", {"n": Textos.t("nombre_" + npc_id), "l": GameState.friend_level(npc_id)}), opts,
		func(i: int):
			if i >= 0 and i < acts.size():
				acts[i].call(),
		descs)


func _amistad_lines(key: String) -> Array:
	return Dialogos.data.get(npc_id, {}).get("amistad", {}).get(key, [])


func _charlar() -> void:
	if int(GameState.amistad_charla.get(npc_id, 0)) == GameState.current_day:
		_dialogue.show_lines(_amistad_lines("ya_charlaste"))
		return
	GameState.amistad_charla[npc_id] = GameState.current_day
	var pool: Array = _amistad_lines("charla")
	var k: int = GameState.tutorial.get("charla_idx_" + npc_id, 0)
	GameState.tutorial["charla_idx_" + npc_id] = k + 1
	var lines: Array = (pool[k % pool.size()] as Array).duplicate() if not pool.is_empty() else []
	_sumar_amistad(int(GameState.friendship_data.get("charla", 1)), lines)


## Suma amistad y, si sube de nivel, encadena la escena del nivel y da la
## recompensa al terminar.
func _sumar_amistad(pts: int, lines: Array) -> void:
	var subio := GameState.add_friendship(npc_id, pts)
	var lv := GameState.friend_level(npc_id)
	if subio:
		lines = lines + _amistad_lines("nivel%d" % lv)
	_bump_hearts()
	_dialogue.show_lines(lines, func():
		if subio:
			GameState.apply_friend_reward(npc_id, lv)
			SFX.play("heart_shift", 0.0, 0.0)
			SFX.play("coin", -4.0)
			var banner = get_tree().get_first_node_in_group("combat_banner")
			if banner:
				banner.announce(Textos.t("amistad_sube", {"n": Textos.t("nombre_" + npc_id), "l": lv}), "", Color(1.0, 0.6, 0.7)))


## Corazoncitos que suben sobre el aldeano al ganar amistad.
func _bump_hearts() -> void:
	var l := Label3D.new()
	l.text = "+"
	l.font_size = 72
	l.outline_size = 14
	l.modulate = Color(1.0, 0.45, 0.6)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.01
	l.position.y = 2.0
	add_child(l)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(l, "position:y", 2.8, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


func _regalar_menu() -> void:
	if int(GameState.amistad_regalo.get(npc_id, 0)) == GameState.current_day:
		_dialogue.show_lines(_amistad_lines("ya_regalaste"))
		return
	var items: Array = []
	for cid in GameState.SEED_IDS:
		if GameState.item_count(cid) > 0:
			items.append(cid)
	if items.is_empty():
		_dialogue.show_lines(_amistad_lines("nada_que_regalar"))
		return
	var opts: Array = []
	var descs: Array = []
	for cid in items:
		opts.append(Textos.t("regalo_item", {"n": GameState.crops[cid]["nombre"], "c": GameState.item_count(cid)}))
		var known: String = GameState.tutorial.get("gusto_%s_%s" % [npc_id, cid], "")
		descs.append(Textos.t("gusto_" + known) if known != "" else Textos.t("gusto_desconocido"))
	opts.append(Textos.t("cancelar"))
	descs.append(Textos.t("desc_adios"))
	var box = get_tree().get_first_node_in_group("choice_box")
	box.ask(Textos.t("regalo_titulo", {"n": Textos.t("nombre_" + npc_id)}), opts, func(i: int):
		if i >= 0 and i < items.size():
			_dar_regalo(items[i]), descs)


func _dar_regalo(cid: String) -> void:
	GameState.remove_item(cid, 1)
	GameState.amistad_regalo[npc_id] = GameState.current_day
	var taste := GameState.friend_taste(npc_id, cid)
	GameState.tutorial["gusto_%s_%s" % [npc_id, cid]] = taste
	var pts := int(GameState.friendship_data.get("regalo", {}).get(taste, 1))
	_sumar_amistad(pts, _amistad_lines("regalo_" + taste).duplicate())


# --- templo de Maat (con Meret) ---
func _templo_menu() -> void:
	var p := GameState.temple_next()
	if p.is_empty():
		_dialogue.show_lines(_amistad_lines("templo_completo"))
		return
	if not GameState.tutorial.get("templo_intro", false):
		GameState.tutorial["templo_intro"] = true
		_dialogue.show_lines(_amistad_lines("templo_intro"), _templo_menu)
		return
	var coste: Array = []
	for item in p.get("coste", {}):
		coste.append("%d %s" % [int(p["coste"][item]), GameState.crops[item]["nombre_corto"]])
	coste.append(Textos.t("templo_deben", {"d": int(p.get("deben", 0))}))
	var box = get_tree().get_first_node_in_group("choice_box")
	var opts := [Textos.t("templo_pieza", {"n": Textos.t("pieza_" + p["id"]), "c": " + ".join(coste)}), Textos.t("npc_adios")]
	var descs := [Textos.t("bendicion_" + p["id"]), Textos.t("desc_adios")]
	box.ask(Textos.t("templo_titulo", {"n": GameState.temple.size()}), opts, func(i: int):
		if i != 0:
			return
		if not GameState.restore_temple_piece(p):
			_dialogue.show_lines(_amistad_lines("templo_falta"))
			SFX.play("hit_player", -10.0)
			return
		SFX.play("build")
		var banner = get_tree().get_first_node_in_group("combat_banner")
		if banner:
			banner.announce(Textos.t("templo_hecho", {"n": Textos.t("pieza_" + p["id"])}), Textos.t("bendicion_" + p["id"]), Color(0.55, 0.9, 1.0), 3.0)
		_dialogue.show_lines(_amistad_lines("templo_hecho_" + p["id"])), descs, [not GameState.can_restore(p), false])


# --- mejoras (con Ptahmose) ---
func _upgrades_menu() -> void:
	var list: Array = GameState.upgrades_data.get("mejoras", [])
	var opts: Array = []
	var descs: Array = []
	var locked: Array = []
	for u in list:
		var nombre := Textos.t("mejora_" + u["id"])
		if GameState.has_upgrade(u["id"]):
			opts.append(Textos.t("mejora_tienes", {"n": nombre}))
			locked.append(true)
		elif GameState.current_day < int(u.get("dia", 1)):
			opts.append(Textos.t("mejora_bloqueada", {"d": int(u["dia"])}))
			locked.append(true)
		else:
			opts.append(Textos.t("mejora_item", {"n": nombre, "p": int(u["precio"])}))
			locked.append(false)
		descs.append(Textos.t("mejora_desc_" + u["id"]) if GameState.current_day >= int(u.get("dia", 1)) else Textos.t("def_desc_bloqueada"))
	opts.append(Textos.t("npc_adios"))
	descs.append(Textos.t("desc_adios"))
	locked.append(false)
	var box = get_tree().get_first_node_in_group("choice_box")
	box.ask(Textos.t("mejoras_titulo", {"d": GameState.deben}), opts, func(i: int):
		if i < 0 or i >= list.size():
			return
		var u: Dictionary = list[i]
		if not GameState.buy_upgrade(u["id"]):
			_dialogue.show_lines(Dialogos.lines("ptahmose", "sin_dinero"))
			return
		SFX.play("coin")
		SFX.play("build", -6.0)
		var banner = get_tree().get_first_node_in_group("combat_banner")
		if banner:
			banner.announce(Textos.t("mejora_comprada", {"n": Textos.t("mejora_" + u["id"])}), Textos.t("mejora_desc_" + u["id"]), Color(1.0, 0.85, 0.4), 2.4)
		_dialogue.show_lines(Dialogos.lines("ptahmose", "compra_ok")), descs, locked)
