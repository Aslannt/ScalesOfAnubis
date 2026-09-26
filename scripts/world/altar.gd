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
	if GameState.decisiones.has("robo_altar"):
		_dialogue.show_lines(["Thot: La ofrenda ya no está. Espero que lo recuerdes en el pesaje."])
		return
	if GameState.current_day < DIA_DISPONIBLE:
		_dialogue.show_lines(["Thot: Ofrendas para Maat. No deberías ni pensarlo."])
		return
	_dialogue.show_lines([
		"Thot: Esa ofrenda no es tuya, campesino.",
		"Nakht toma la ofrenda del altar sin que nadie lo vea.",
		"Thot: Lo vi yo. Siempre lo veo.",
	], _robar)


func _robar() -> void:
	GameState.add_deben(DEBEN_ROBADOS)
	GameState.shift_heart(PESO_ROBO, "robo_altar")
	GameState.register_decision("robo_altar", "robado")
