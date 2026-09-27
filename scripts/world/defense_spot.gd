class_name DefenseSpot
extends Node3D
## Pedestal donde se construye una defensa de dia (GDD 6.5). Se interactua
## con E como con un aldeano (WorldBuilder lo mete en la lista de npcs).

const COSTO_ESTATUA := 30
const COSTO_BRASERO := 18

var npc_id: String = "defensa"
var built: String = ""  # "" | "estatua" | "brasero"
var _base: Node3D
var _ring: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	add_to_group("defense_spots")
	_base = Node3D.new()
	add_child(_base)
	var stone := BuildingFactory._mat("stone")
	_base.add_child(BuildingFactory._box(Vector3(1.4, 0.12, 1.4), stone, Vector3(0, 0.06, 0)))
	_base.add_child(BuildingFactory._box(Vector3(1.2, 0.18, 1.2), stone, Vector3(0, 0.21, 0)))
	# filo dorado fino alrededor de la losa superior
	var gold := BuildingFactory._solid_mat(Color(0.86, 0.66, 0.22))
	for side in [-1, 1]:
		_base.add_child(BuildingFactory._box(Vector3(1.22, 0.04, 0.04), gold, Vector3(0, 0.3, side * 0.6)))
		_base.add_child(BuildingFactory._box(Vector3(0.04, 0.04, 1.22), gold, Vector3(side * 0.6, 0.3, 0)))
	# anillo que late suave para que se note que es "construible"
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 0.95
	torus.rings = 24
	torus.ring_segments = 4
	_ring.mesh = torus
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.85, 0.4, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = m
	_ring.position.y = 0.04
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	var body := BuildingFactory._collision_box(Vector3(1.2, 0.3, 1.2))
	add_child(body)


func _process(delta: float) -> void:
	_t += delta
	if _ring.visible:
		_ring.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.05)
		(_ring.material_override as StandardMaterial3D).albedo_color.a = 0.3 + 0.25 * (0.5 + 0.5 * sin(_t * 3.0))


func interact() -> void:
	if built != "":
		GameState.thot(Dialogos.thot("estatua" if built == "estatua" else "brasero"))
		return
	if GameTime.is_night():
		return
	var box = get_tree().get_first_node_in_group("choice_box")
	if box == null:
		return
	box.ask(Textos.t("defensa_titulo", {"d": GameState.deben}), [
		Textos.t("defensa_estatua", {"p": COSTO_ESTATUA}),
		Textos.t("defensa_brasero", {"p": COSTO_BRASERO}),
		Textos.t("cancelar"),
	], _on_choice)


func _on_choice(i: int) -> void:
	var kind := ""
	var cost := 0
	if i == 0:
		kind = "estatua"
		cost = COSTO_ESTATUA
	elif i == 1:
		kind = "brasero"
		cost = COSTO_BRASERO
	else:
		return
	if not GameState.can_afford(cost):
		GameState.thot(Textos.t("sin_dinero"))
		SFX.play("hit_player", -10.0)
		return
	GameState.add_deben(-cost)
	build(kind)


func build(kind: String) -> void:
	built = kind
	_ring.visible = false
	var d: Node3D = JackalStatue.new() if kind == "estatua" else Brazier.new()
	d.position.y = 0.3
	add_child(d)
	SFX.play("build")
	CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.6, 0), Color(1.0, 0.85, 0.4))
	CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.2, 0), 12)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(0.08, 0.2)
	d.scale = Vector3(1, 0.1, 1)
	create_tween().tween_property(d, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameState.register_decision("defensa_" + str(get_index()), kind)
	GameState.thot_once("thot_" + kind, Dialogos.thot("estatua" if kind == "estatua" else "brasero"))
