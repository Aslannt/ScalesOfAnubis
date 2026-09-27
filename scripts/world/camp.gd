class_name Camp
extends Node3D
## Campamento de Nakht junto al campo: de dia permite "esperar hasta el
## atardecer" cuando ya no queda nada que hacer (no obliga a mirar el reloj).

var npc_id: String = "campamento"


func _ready() -> void:
	var linen := BuildingFactory._solid_mat(Color(0.86, 0.8, 0.64))
	var tent := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(1.9, 1.3, 1.8)
	tent.mesh = pm
	tent.material_override = linen
	tent.position = Vector3(-0.6, 0.65, -0.3)
	add_child(tent)
	add_child(BuildingFactory._box(Vector3(0.5, 0.9, 0.05), BuildingFactory._solid_mat(Color(0.12, 0.08, 0.06)), Vector3(-0.6, 0.45, 0.61)))
	var mat := BuildingFactory._box(Vector3(1.2, 0.04, 0.8), BuildingFactory._mat("palm_mat"), Vector3(0.9, 0.02, 0.4))
	add_child(mat)
	var fire := Torch.new()
	fire.position = Vector3(1.0, -0.35, 1.2)
	add_child(fire)
	var body := BuildingFactory._collision_box(Vector3(1.9, 1.2, 1.8))
	body.position = Vector3(-0.6, 0, -0.3)
	add_child(body)


func interact() -> void:
	if GameTime.phase != GameTime.Phase.DAY:
		GameState.thot(Dialogos.thot("campamento_noche"), true)
		return
	var box = get_tree().get_first_node_in_group("choice_box")
	box.ask(Textos.t("camp_titulo"), [Textos.t("camp_esperar"), Textos.t("cancelar")], func(i: int):
		if i == 0:
			_wait_until_dusk())


func _wait_until_dusk() -> void:
	var sd = get_tree().get_first_node_in_group("story_director")
	if sd and sd.has_method("fade_skip_to"):
		sd.fade_skip_to(GameTime.Phase.DUSK)
