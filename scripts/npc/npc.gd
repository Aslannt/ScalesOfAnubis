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
	sprite.pixel_size = 0.055
	sprite.shaded = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.position = Vector3(0, 0.85, 0)
	add_child(sprite)
	sprite.sprite_frames = SpritesheetLoader.build(sheet_path, layout_path, 6.0)
	sprite.play("south_idle")
	call_deferred("_find_dialogue_box")


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
	if GameState.meret_mission_done:
		_dialogue.show_lines(Dialogos.lines("meret", "repeat"))
		return
	var total := GameState.item_count("trigo") + GameState.item_count("papiro")
	if total >= GameState.MERET_CROPS_NEEDED:
		var restante := GameState.MERET_CROPS_NEEDED
		for cid in ["trigo", "papiro"]:
			var take: int = mini(restante, GameState.item_count(cid))
			if take > 0:
				GameState.remove_item(cid, take)
				restante -= take
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
	var total_valor := 0
	var vendio := false
	for cid in ["trigo", "lino", "papiro"]:
		var n: int = GameState.item_count(cid)
		if n <= 0:
			continue
		vendio = true
		var precio: int = int(GameState.crops[cid]["precio_venta"])
		total_valor += precio * n
		GameState.remove_item(cid, n)
	if vendio:
		GameState.add_deben(total_valor)
		_dialogue.show_lines(Dialogos.lines("ptahmose", "vender_exito"))
	else:
		_dialogue.show_lines(Dialogos.lines("ptahmose", "vender_vacio"))


func _iry() -> void:
	if not GameState.iry_intro_shown:
		GameState.iry_intro_shown = true
		Codex.unlock("ba")
		_dialogue.show_lines(Dialogos.lines("iry", "intro"))
	else:
		_dialogue.show_lines(Dialogos.lines("iry", "repeat"))
