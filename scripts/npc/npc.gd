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
	if GameState.meret_mission_done:
		_dialogue.show_lines(Dialogos.lines("meret", "repeat"))
		return
	# mision: tres manojos de lino para las vendas del templo (GDD 6.7)
	if GameState.item_count("lino") >= GameState.MERET_CROPS_NEEDED:
		GameState.remove_item("lino", GameState.MERET_CROPS_NEEDED)
		GameState.meret_mission_done = true
		GameState.shift_heart(-8.0, "meret_mision")
		Codex.unlock("aaru")
		_dialogue.show_lines(Dialogos.lines("meret", "mision_completa"))
	else:
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
	opciones.append(Textos.t("ptah_adios"))
	box.ask(Textos.t("ptah_titulo", {"d": GameState.deben}), opciones, _on_ptahmose_choice)


const PACK := 3


func _precio_pack(id: String) -> int:
	return int(GameState.crops[id]["precio_semilla"]) * PACK


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
	total = int(round(total * GameState.heart_mod("venta", 1.0)))
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
	_dialogue.show_lines(Dialogos.lines("iry", key))
