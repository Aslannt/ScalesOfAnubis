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


func interact() -> void:
	if _dialogue == null:
		_find_dialogue_box()
	if GameState.decisiones.get("robo_altar", "") == "robado":
		_dialogue.show_lines(Dialogos.lines("altar", "ya_robado"))
		return
	if GameState.current_day < DIA_DISPONIBLE:
		_dialogue.show_lines(Dialogos.lines("altar", "bloqueado"))
		return
	# decision moral 1 (GDD 6.7): ahora es una eleccion explicita
	var box = get_tree().get_first_node_in_group("choice_box")
	var alt: Dictionary = Dialogos.data.get("altar", {})
	box.ask(alt.get("pregunta", ""), [alt.get("op_robar", ""), alt.get("op_dejar", "")], func(i: int):
		if i == 0:
			_dialogue.show_lines(Dialogos.lines("altar", "robar"), _robar)
		elif i == 1 and not GameState.decisiones.has("robo_altar"):
			GameState.register_decision("robo_altar", "respetado")
			GameState.shift_heart(-2.0, "respetar_altar")
			_dialogue.show_lines(Dialogos.lines("altar", "dejar")))


func _robar() -> void:
	GameState.add_deben(DEBEN_ROBADOS)
	GameState.shift_heart(PESO_ROBO, "robo_altar")
	GameState.register_decision("robo_altar", "robado")
