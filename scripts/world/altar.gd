class_name Altar
extends Node3D
## Altar de ofrendas del templo (GDD 6.7, decision moral 1). Desde el dia 2
## se puede robar la ofrenda: +deben inmediato, pero +peso del corazon.
## Es una decision silenciosa (el jugador elige interactuar o no), sin menu
## de dialogo con opciones.

const DEBEN_ROBADOS := 20
const PESO_ROBO := 10.0
const DIA_DISPONIBLE := 2

var npc_id: String = "altar"
var _dialogue: Node = null


func _ready() -> void:
	add_child(BuildingFactory.altar())
	call_deferred("_find_dialogue_box")


func _find_dialogue_box() -> void:
	_dialogue = get_tree().get_first_node_in_group("dialogue_box")


const PESO_OFRENDA := 2.0
const OFRENDAS_POR_DIA := 3


func _cosecha_para_ofrecer() -> String:
	for id in ["trigo", "papiro", "lino"]:
		if GameState.item_count(id) > 0:
			return id
	return ""


## Altar de Maat: ofrecer cosecha aligera el corazon (GDD 6.1) y, desde el
## dia 2, se puede robar la ofrenda (decision moral 1, GDD 6.7).
func interact() -> void:
	if _dialogue == null:
		_find_dialogue_box()
	var box = get_tree().get_first_node_in_group("choice_box")
	var crop := _cosecha_para_ofrecer()
	var hoy_key := "ofrendas_dia_%d" % GameState.current_day
	var hechas: int = GameState.tutorial.get(hoy_key, 0)
	var opciones: Array = []
	var acciones: Array = []
	if crop != "" and hechas < OFRENDAS_POR_DIA:
		opciones.append(Textos.t("altar_ofrecer", {"n": GameState.crops[crop]["nombre_corto"]}))
		acciones.append("ofrecer")
	elif crop == "":
		opciones.append(Textos.t("altar_sin_cosecha"))
		acciones.append("nada")
	var robado: bool = GameState.decisiones.get("robo_altar", "") == "robado"
	if GameState.current_day >= DIA_DISPONIBLE and not robado:
		opciones.append(Textos.t("altar_robar"))
		acciones.append("robar")
	opciones.append(Textos.t("altar_irse"))
	acciones.append("irse")
	_acciones = acciones
	_crop = crop
	_hoy_key = hoy_key
	box.ask(Textos.t("altar_titulo"), opciones, _on_choice)


var _acciones: Array = []
var _crop: String = ""
var _hoy_key: String = ""


func _on_choice(i: int) -> void:
	if i < 0 or i >= _acciones.size():
		return
	var accion: String = _acciones[i]
	if accion == "ofrecer":
		GameState.remove_item(_crop, 1)
		GameState.tutorial[_hoy_key] = int(GameState.tutorial.get(_hoy_key, 0)) + 1
		GameState.shift_heart(-PESO_OFRENDA, "ofrenda")
		CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 1.2, 0), Color(1.0, 0.9, 0.5))
		GameState.thot_once("ofrenda", Dialogos.thot("ofrenda"))
	elif accion == "robar":
		_dialogue.show_lines(Dialogos.lines("altar", "robar"), _robar)
	elif accion == "irse":
		if GameState.current_day >= DIA_DISPONIBLE and not GameState.decisiones.has("robo_altar"):
			GameState.register_decision("robo_altar", "respetado")


func _robar() -> void:
	GameState.add_deben(DEBEN_ROBADOS)
	GameState.shift_heart(PESO_ROBO, "robo_altar")
	GameState.register_decision("robo_altar", "robado")
	GameState.thot(Dialogos.thot("robo"), true)
