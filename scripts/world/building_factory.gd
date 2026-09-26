class_name BuildingFactory
extends RefCounted
## Fabrica de geometria 3D low-poly generada por script (sin cubos grises: todo
## usa las texturas pixeladas de assets/textures con la paleta del juego).

const TEX_DIR := "res://assets/textures/"
static var _cache: Dictionary = {}


static func _mat(tex_name: String, uv_scale: Vector3 = Vector3.ONE) -> StandardMaterial3D:
	var key := "%s|%s" % [tex_name, uv_scale]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	var tex: Texture2D = load(TEX_DIR + tex_name + ".png")
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_scale = uv_scale
	m.roughness = 0.9
	_cache[key] = m
	return m


static func _solid_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m


static func _box(size: Vector3, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi


static func _collision_box(size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)
	return body


static func ground_plane(size: Vector2, tex_name: String, tiles: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(tex_name, Vector3(tiles.x, tiles.y, 1))
	return mi


static func house(rng_seed: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "AdobeHouse"
	var w := 4.0
	var d := 3.6
	var h := 2.6
	root.add_child(_box(Vector3(w, h, d), _mat("adobe", Vector3(2, 1, 1)), Vector3(0, h * 0.5, 0)))
	# techo (losa plana con viguetas de madera asomando)
	root.add_child(_box(Vector3(w + 0.4, 0.25, d + 0.4), _mat("wood", Vector3(2, 1, 1)), Vector3(0, h + 0.12, 0)))
	# entrada (hueco oscuro)
	root.add_child(_box(Vector3(1.0, 1.7, 0.1), _solid_mat(Color(0.05, 0.04, 0.04)), Vector3(0, 0.85, d * 0.5 + 0.02)))
	var body := _collision_box(Vector3(w, h, d))
	root.add_child(body)
	return root


static func temple() -> Node3D:
	var root := Node3D.new()
	root.name = "TemploMaat"
	var w := 9.0
	var d := 7.0
	var h := 0.6
	# plataforma
	root.add_child(_box(Vector3(w, h, d), _mat("stone", Vector3(3, 2, 1)), Vector3(0, h * 0.5, 0)))
	# cuerpo
	var body_h := 3.2
	root.add_child(_box(Vector3(w - 1.5, body_h, d - 1.5), _mat("wall_papyrus", Vector3(2, 1, 1)), Vector3(0, h + body_h * 0.5, 0)))
	# techo
	root.add_child(_box(Vector3(w, 0.4, d), _mat("stone", Vector3(3, 2, 1)), Vector3(0, h + body_h + 0.2, 0)))
	# columnas de entrada
	for side in [-1, 1]:
		for i in range(3):
			var col := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.35
			cyl.bottom_radius = 0.4
			cyl.height = body_h
			col.mesh = cyl
			col.material_override = _mat("stone", Vector3(1, 1, 1))
			col.position = Vector3(side * (w * 0.5 - 0.6), h + body_h * 0.5, d * 0.5 - 0.8 - i * 1.8)
			root.add_child(col)
	# acento dorado sobre la entrada
	root.add_child(_box(Vector3(2.4, 0.5, 0.2), _solid_mat(Color(0.91, 0.73, 0.14)), Vector3(0, h + body_h + 0.1, d * 0.5)))
	root.add_child(_collision_box(Vector3(w - 1.5, body_h + h, d - 1.5)))
	return root


static func obelisk() -> Node3D:
	var root := Node3D.new()
	root.name = "Obelisco"
	var base_h := 0.8
	root.add_child(_box(Vector3(1.6, base_h, 1.6), _mat("stone", Vector3(1, 1, 1)), Vector3(0, base_h * 0.5, 0)))
	var shaft_h := 6.0
	root.add_child(_box(Vector3(0.9, shaft_h, 0.9), _mat("stone", Vector3(1, 3, 1)), Vector3(0, base_h + shaft_h * 0.5, 0)))
	var tip := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.9, 1.0, 0.9)
	tip.mesh = prism
	tip.material_override = _solid_mat(Color(0.91, 0.73, 0.14))
	tip.position = Vector3(0, base_h + shaft_h + 0.5, 0)
	root.add_child(tip)
	root.add_child(_collision_box(Vector3(1.6, base_h + shaft_h, 1.6)))
	return root


static func tomb() -> Node3D:
	var root := Node3D.new()
	root.name = "Tumba"
	root.add_child(_box(Vector3(2.2, 1.4, 2.2), _mat("stone", Vector3(1, 1, 1)), Vector3(0, 0.7, 0)))
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.4, 1.0, 2.4)
	roof.mesh = prism
	roof.material_override = _mat("stone", Vector3(1, 1, 1))
	roof.position = Vector3(0, 1.9, 0)
	root.add_child(roof)
	root.add_child(_box(Vector3(0.7, 1.0, 0.1), _solid_mat(Color(0.04, 0.03, 0.03)), Vector3(0, 0.5, 1.15)))
	root.add_child(_collision_box(Vector3(2.2, 1.4, 2.2)))
	return root


static func dock() -> Node3D:
	var root := Node3D.new()
	root.name = "MuelleDePtahmose"
	var plank := _box(Vector3(2.4, 0.2, 6.0), _mat("wood", Vector3(1, 3, 1)), Vector3(0, 0.6, 0))
	root.add_child(plank)
	for i in range(4):
		var pylon := _box(Vector3(0.3, 1.2, 0.3), _mat("wood", Vector3(1, 1, 1)), Vector3(1.0 if i % 2 == 0 else -1.0, 0.0, -2.4 + i * 1.6))
		root.add_child(pylon)
	# barca sencilla
	var boat := _box(Vector3(1.2, 0.5, 2.8), _mat("wood", Vector3(1, 1, 1)), Vector3(1.8, 0.35, 1.0))
	root.add_child(boat)
	root.add_child(_collision_box(Vector3(2.4, 0.4, 6.0)))
	return root


static func column() -> Node3D:
	var root := Node3D.new()
	var col := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.4
	cyl.height = 3.0
	col.mesh = cyl
	col.material_override = _mat("stone", Vector3(1, 1, 1))
	col.position = Vector3(0, 1.5, 0)
	root.add_child(col)
	root.add_child(_collision_box(Vector3(0.8, 3.0, 0.8)))
	return root


static func rock() -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.2
	mi.mesh = sphere
	mi.material_override = _mat("stone", Vector3(1, 1, 1))
	mi.position = Vector3(0, 0.5, 0)
	mi.scale = Vector3(1.3, 0.7, 1.0)
	root.add_child(mi)
	root.add_child(_collision_box(Vector3(1.6, 0.8, 1.3)))
	return root


static func palm() -> Node3D:
	var root := Node3D.new()
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.25
	cyl.height = 4.0
	trunk.mesh = cyl
	trunk.material_override = _mat("wood", Vector3(1, 2, 1))
	trunk.position = Vector3(0, 2.0, 0)
	trunk.rotation_degrees = Vector3(0, 0, 4)
	root.add_child(trunk)
	var frond_mat := _solid_mat(Color(0.24, 0.48, 0.30))
	for i in range(6):
		var frond := _box(Vector3(1.6, 0.08, 0.35), frond_mat, Vector3(0.9, 3.9, 0))
		frond.rotate_y(deg_to_rad(60.0 * i))
		frond.rotate_z(deg_to_rad(18))
		root.add_child(frond)
	return root


static func reed() -> Node3D:
	var root := Node3D.new()
	var mat := _solid_mat(Color(0.30, 0.55, 0.38))
	for i in range(4):
		var stalk := _box(Vector3(0.06, 1.4 + i * 0.15, 0.06), mat, Vector3(randf_range(-0.3, 0.3), 0.7, randf_range(-0.3, 0.3)))
		root.add_child(stalk)
	return root


static func build(tipo: String) -> Node3D:
	match tipo:
		"house": return house()
		"temple": return temple()
		"obelisk": return obelisk()
		"tomb": return tomb()
		"dock": return dock()
		"column": return column()
		"rock": return rock()
		"palm": return palm()
		"reed": return reed()
	return Node3D.new()
