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
	call_deferred("_find_dialogue_box")


var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	sprite.offset.y = CharacterFX.breathe_offset(_t, 1.9)


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
	if GameState.current_day >= 3 and not GameState.tutorial.get("iry_d3", false):
		GameState.tutorial["iry_d3"] = true
		key = "dia3"
	elif GameState.current_day >= 2 and not GameState.tutorial.get("iry_d2", false):
		GameState.tutorial["iry_d2"] = true
		key = "dia2"
		Codex.unlock("sheut")
	_dialogue.show_lines(Dialogos.lines("iry", key))
