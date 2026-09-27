class_name TempleRestoration
extends Node3D
## Restauracion visible del templo de Maat (fase 2). Cada pieza de
## data/temple.json tiene su ruina y su version restaurada; al restaurarla
## (hablando con Meret) la ruina se hunde en polvo y la pieza nueva se
## levanta. Se coloca como hijo del templo (coordenadas locales, la entrada
## mira a +Z).

var _ruins: Dictionary = {}
var _built: Dictionary = {}
var _flags: Array[Node3D] = []
var _t := 0.0


func _ready() -> void:
	for p in GameState.temple_data.get("piezas", []):
		var id: String = p["id"]
		var ruin := _make_ruin(id)
		var built := _make_built(id)
		add_child(ruin)
		add_child(built)
		_ruins[id] = ruin
		_built[id] = built
		_apply(id, GameState.temple.has(id), false)
	GameState.temple_changed.connect(func(id): _apply(id, true, true))


func _process(delta: float) -> void:
	_t += delta
	for i in range(_flags.size()):
		var f := _flags[i]
		if is_instance_valid(f) and f.is_visible_in_tree():
			f.rotation.y = sin(_t * 2.2 + i) * 0.25
			f.scale.x = 1.0 + sin(_t * 3.1 + i * 1.7) * 0.06


## Muestra la ruina o la pieza. 'animado': la ruina se hunde y la pieza
## crece desde el suelo con polvo dorado.
func _apply(id: String, restored: bool, animado: bool) -> void:
	var ruin: Node3D = _ruins.get(id)
	var built: Node3D = _built.get(id)
	if ruin == null or built == null:
		return
	if not animado:
		ruin.visible = not restored
		built.visible = restored
		return
	built.visible = true
	built.scale = Vector3(1, 0.05, 1)
	var tw := create_tween()
	tw.tween_property(ruin, "position:y", -1.5, 0.6)
	tw.tween_callback(func(): ruin.visible = false)
	tw.tween_property(built, "scale", Vector3.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for k in range(3):
		CharacterFX.dust_puff(get_tree().current_scene, built.global_position + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)), 14, Color(1.0, 0.85, 0.45, 0.9))
	CombatFX.spawn_hit_particles(get_tree().current_scene, built.global_position + Vector3(0, 1.5, 0), Color(1.0, 0.9, 0.5))
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(0.1, 0.4)
	var wb = get_tree().get_first_node_in_group("world_builder")
	if wb and id == "columnas":
		wb.rebake_navigation.call_deferred()


func _make_ruin(id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Ruina_" + id
	var stone := BuildingFactory._mat("stone")
	var plaster := BuildingFactory._mat("plaster")
	match id:
		"columnas":
			for side in [-1, 1]:
				var stump := _cylinder(0.32, 0.35, 0.6, plaster)
				stump.position = Vector3(side * 5.6, 0.3, 6.0)
				root.add_child(stump)
				var fallen := _cylinder(0.3, 0.3, 2.4, plaster)
				fallen.rotation = Vector3(0, side * 0.6, PI * 0.5)
				fallen.position = Vector3(side * 6.4, 0.3, 6.9)
				root.add_child(fallen)
				root.add_child(BuildingFactory._box(Vector3(0.5, 0.3, 0.4), stone, Vector3(side * 5.0, 0.15, 7.2)))
		"estatua":
			root.add_child(BuildingFactory._box(Vector3(1.0, 0.35, 1.0), stone, Vector3(4.2, 0.17, 7.4)))
			var head := BuildingFactory._box(Vector3(0.4, 0.4, 0.35), plaster, Vector3(4.9, 0.2, 8.1))
			head.rotation.y = 0.7
			root.add_child(head)
			root.add_child(BuildingFactory._box(Vector3(0.3, 0.2, 0.5), stone, Vector3(3.7, 0.1, 8.0)))
		"estandartes":
			for x in [-1.6, 1.6]:
				var pole := BuildingFactory._box(Vector3(0.12, 0.12, 2.6), BuildingFactory._mat("wood"), Vector3(x, 0.08, 5.2))
				pole.rotation.y = 0.4 * signf(x)
				root.add_child(pole)
		"santuario":
			# puerta del santuario tapiada con escombros
			for i in range(4):
				root.add_child(BuildingFactory._box(Vector3(0.45, 0.3, 0.3), stone, Vector3(-0.5 + i * 0.33, 0.15 + (i % 2) * 0.25, -0.9)))
	return root


func _make_built(id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Restaurado_" + id
	var plaster := BuildingFactory._mat("plaster")
	var gold := BuildingFactory._solid_mat(Color(0.91, 0.73, 0.14))
	gold.metallic = 0.4
	gold.roughness = 0.4
	var lapis := BuildingFactory._solid_mat(Color(0.16, 0.3, 0.62))
	match id:
		"columnas":
			for side in [-1, 1]:
				var col := _cylinder(0.3, 0.34, 3.0, plaster)
				col.position = Vector3(side * 5.6, 1.5, 6.0)
				root.add_child(col)
				var cap := _cylinder(0.5, 0.3, 0.45, BuildingFactory._solid_mat(Color(0.35, 0.6, 0.4)))
				cap.position = Vector3(side * 5.6, 3.2, 6.0)
				root.add_child(cap)
				root.add_child(BuildingFactory._box(Vector3(0.8, 0.14, 0.8), gold, Vector3(side * 5.6, 3.48, 6.0)))
				for k in range(3):
					root.add_child(BuildingFactory._box(Vector3(0.64, 0.08, 0.64), lapis, Vector3(side * 5.6, 0.6 + k * 0.9, 6.0)))
				var body := BuildingFactory._collision_box(Vector3(0.7, 3.0, 0.7))
				body.position = Vector3(side * 5.6, 0, 6.0)
				root.add_child(body)
		"estatua":
			var stone := BuildingFactory._mat("stone")
			root.add_child(BuildingFactory._box(Vector3(1.1, 0.5, 1.1), stone, Vector3(4.2, 0.25, 7.4)))
			root.add_child(BuildingFactory._box(Vector3(1.2, 0.08, 1.2), gold, Vector3(4.2, 0.52, 7.4)))
			# Maat sentada: cuerpo, tunica, cabeza con la pluma de avestruz
			root.add_child(BuildingFactory._box(Vector3(0.6, 0.55, 0.7), stone, Vector3(4.2, 0.83, 7.35)))
			root.add_child(BuildingFactory._box(Vector3(0.5, 0.75, 0.4), BuildingFactory._solid_mat(Color(0.93, 0.9, 0.8)), Vector3(4.2, 1.3, 7.25)))
			root.add_child(BuildingFactory._box(Vector3(0.34, 0.36, 0.32), BuildingFactory._solid_mat(Color(0.62, 0.4, 0.25)), Vector3(4.2, 1.85, 7.25)))
			root.add_child(BuildingFactory._box(Vector3(0.38, 0.14, 0.36), lapis, Vector3(4.2, 2.06, 7.22)))
			var feather := BuildingFactory._box(Vector3(0.1, 0.55, 0.06), BuildingFactory._solid_mat(Color(0.98, 0.97, 0.92)), Vector3(4.2, 2.4, 7.18))
			feather.rotation.x = -0.2
			root.add_child(feather)
			var glow := OmniLight3D.new()
			glow.light_color = Color(1.0, 0.85, 0.5)
			glow.light_energy = 0.8
			glow.omni_range = 3.5
			glow.position = Vector3(4.2, 2.0, 8.0)
			root.add_child(glow)
			var body := BuildingFactory._collision_box(Vector3(1.1, 1.2, 1.1))
			body.position = Vector3(4.2, 0, 7.4)
			root.add_child(body)
		"estandartes":
			var cols := [Color(0.72, 0.18, 0.14), Color(0.16, 0.3, 0.62), Color(0.72, 0.18, 0.14), Color(0.16, 0.3, 0.62)]
			var xs := [-3.3, -1.4, 1.4, 3.3]
			for i in range(4):
				var pole := BuildingFactory._box(Vector3(0.1, 6.2, 0.1), BuildingFactory._mat("wood"), Vector3(xs[i], 3.1, 4.35))
				root.add_child(pole)
				var pivot := Node3D.new()
				pivot.position = Vector3(xs[i], 5.6, 4.35)
				root.add_child(pivot)
				var flag := BuildingFactory._box(Vector3(0.9, 0.5, 0.03), BuildingFactory._solid_mat(cols[i]), Vector3(0.45, 0, 0))
				pivot.add_child(flag)
				_flags.append(pivot)
		"santuario":
			var door := BuildingFactory._box(Vector3(1.0, 1.9, 0.05), BuildingFactory._solid_mat(Color(1.0, 0.8, 0.35)), Vector3(0, 1.1, -1.0))
			var m := door.material_override as StandardMaterial3D
			m.emission_enabled = true
			m.emission = Color(1.0, 0.75, 0.3)
			m.emission_energy_multiplier = 1.4
			root.add_child(door)
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.82, 0.45)
			light.light_energy = 2.2
			light.omni_range = 7.0
			light.position = Vector3(0, 1.6, 0.4)
			root.add_child(light)
	return root


func _cylinder(top: float, bottom: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 10
	mi.mesh = c
	mi.material_override = mat
	return mi
