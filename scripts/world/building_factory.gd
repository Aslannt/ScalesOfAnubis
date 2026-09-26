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
	# ventana pequena
	root.add_child(_box(Vector3(0.5, 0.5, 0.1), _solid_mat(Color(0.05, 0.04, 0.04)), Vector3(w * 0.5 - 0.9, h * 0.6, d * 0.5 + 0.02)))
	var body := _collision_box(Vector3(w, h, d))
	root.add_child(body)
	var torch := Torch.new()
	torch.position = Vector3(w * 0.5 - 0.1, 0, d * 0.5 + 0.3)
	root.add_child(torch)
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
	# pilonos egipcios flanqueando la entrada (torres trapezoidales
	# simplificadas como losas anchas, con banda turquesa y remate dorado)
	var pylon_h := body_h + 1.6
	for side in [-1, 1]:
		var pylon := _box(Vector3(1.8, pylon_h, 0.7), _mat("stone", Vector3(1, 2, 1)), Vector3(side * (w * 0.5 + 1.0), h + pylon_h * 0.5, d * 0.5 - 0.2))
		root.add_child(pylon)
		root.add_child(_box(Vector3(1.9, 0.5, 0.8), _solid_mat(Color(0.16, 0.55, 0.52)), Vector3(side * (w * 0.5 + 1.0), h + pylon_h - 0.6, d * 0.5 - 0.2)))
		root.add_child(_box(Vector3(1.9, 0.12, 0.8), _solid_mat(Color(0.91, 0.73, 0.14)), Vector3(side * (w * 0.5 + 1.0), h + pylon_h - 0.1, d * 0.5 - 0.2)))
	root.add_child(_collision_box(Vector3(w - 1.5, body_h + h, d - 1.5)))
	for side in [-1, 1]:
		var torch := Torch.new()
		torch.position = Vector3(side * (w * 0.5 - 0.3), h, d * 0.5 + 0.4)
		root.add_child(torch)
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
	# Antes parecia un palo con un splat verde: ahora un penacho de hojas
	# largas y caidas (dos segmentos por hoja, mas inclinacion) en vez de
	# tablas planas radiando parejas (PROMPT_PULIDO.md punto 2).
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(root.get_instance_id())

	var trunk_h := 4.2
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.14
	cyl.bottom_radius = 0.26
	cyl.height = trunk_h
	trunk.mesh = cyl
	trunk.material_override = _mat("wood", Vector3(1, 3, 1))
	trunk.position = Vector3(0, trunk_h * 0.5, 0)
	trunk.rotation_degrees = Vector3(0, 0, 5)
	root.add_child(trunk)

	var mat_a := _solid_mat(Color(0.30, 0.52, 0.32))
	var mat_b := _solid_mat(Color(0.22, 0.42, 0.26))
	var crown := Vector3(0.35, trunk_h - 0.2, 0)
	var n := 9
	for i in range(n):
		var ang := (TAU / n) * i + rng.randf_range(-0.15, 0.15)
		var droop := deg_to_rad(rng.randf_range(28.0, 42.0))
		var length := rng.randf_range(1.5, 2.0)
		var frond := Node3D.new()
		frond.position = crown
		frond.rotation.y = ang
		root.add_child(frond)
		# segmento base: sale casi horizontal
		var base_seg := _box(Vector3(length * 0.55, 0.07, 0.3), mat_a if i % 2 == 0 else mat_b, Vector3(length * 0.28, 0, 0))
		base_seg.rotate_z(-droop * 0.4)
		frond.add_child(base_seg)
		# segmento punta: cae mas pronunciado
		var tip_seg := _box(Vector3(length * 0.5, 0.05, 0.18), mat_a if i % 2 == 0 else mat_b, Vector3(length * 0.27, -length * 0.22, 0))
		tip_seg.rotate_z(-droop)
		frond.add_child(tip_seg)
	return root


static func altar() -> Node3D:
	var root := Node3D.new()
	root.name = "AltarDeOfrendas"
	root.add_child(_box(Vector3(1.4, 0.9, 1.0), _mat("stone", Vector3(1, 1, 1)), Vector3(0, 0.45, 0)))
	var bowl := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.25
	cyl.height = 0.2
	bowl.mesh = cyl
	bowl.material_override = _solid_mat(Color(0.91, 0.73, 0.14))
	bowl.position = Vector3(0, 1.0, 0)
	root.add_child(bowl)
	root.add_child(_collision_box(Vector3(1.4, 0.9, 1.0)))
	var torch := Torch.new()
	torch.position = Vector3(1.3, 0, 0)
	root.add_child(torch)
	return root


static func reed() -> Node3D:
	## Juncos: mas densos que antes (PROMPT_PULIDO.md punto 2).
	var root := Node3D.new()
	var mat := _solid_mat(Color(0.30, 0.55, 0.38))
	var mat_dark := _solid_mat(Color(0.20, 0.42, 0.28))
	for i in range(9):
		var h := 1.1 + randf_range(0.0, 0.9)
		var stalk := _box(Vector3(0.05, h, 0.05), mat if i % 2 == 0 else mat_dark,
			Vector3(randf_range(-0.45, 0.45), h * 0.5, randf_range(-0.45, 0.45)))
		stalk.rotation.z = randf_range(-0.08, 0.08)
		root.add_child(stalk)
	return root


static func papyrus_plant() -> Node3D:
	## Papiro de verdad: tallo + penacho triangular arriba (como el sprite
	## de cultivo listo), no solo juncos genericos.
	var root := Node3D.new()
	var stem_mat := _solid_mat(Color(0.16, 0.48, 0.44))
	var tuft_mat := _solid_mat(Color(0.28, 0.55, 0.32))
	for i in range(4):
		var h := 1.3 + randf_range(0.0, 0.5)
		var ox := randf_range(-0.3, 0.3)
		var oz := randf_range(-0.3, 0.3)
		var stem := _box(Vector3(0.07, h, 0.07), stem_mat, Vector3(ox, h * 0.5, oz))
		root.add_child(stem)
		for j in range(6):
			var blade := _box(Vector3(0.35, 0.04, 0.05), tuft_mat, Vector3(ox + 0.16, h, oz))
			blade.rotate_y(deg_to_rad(60.0 * j))
			blade.rotate_z(deg_to_rad(12))
			root.add_child(blade)
	return root


static func pottery() -> Node3D:
	## Vasija de barro junto a la orilla/aldea.
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.12
	cyl.height = 0.45
	mesh.mesh = cyl
	mesh.material_override = _mat("adobe", Vector3(1, 1, 1))
	mesh.position = Vector3(0, 0.22, 0)
	root.add_child(mesh)
	var neck := MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl2.top_radius = 0.1
	cyl2.bottom_radius = 0.14
	cyl2.height = 0.12
	neck.mesh = cyl2
	neck.material_override = _mat("adobe", Vector3(1, 1, 1))
	neck.position = Vector3(0, 0.5, 0)
	root.add_child(neck)
	return root


static func basket() -> Node3D:
	## Cesta de mimbre.
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.16
	cyl.height = 0.3
	mesh.mesh = cyl
	mesh.material_override = _mat("wood", Vector3(2, 1, 1))
	mesh.position = Vector3(0, 0.15, 0)
	root.add_child(mesh)
	return root


static func cane_fence() -> Node3D:
	## Cerca baja de caña, un tramo de ~1.8m.
	var root := Node3D.new()
	var mat := _mat("wood", Vector3(1, 1, 1))
	for i in range(6):
		var post := _box(Vector3(0.06, 0.55, 0.06), mat, Vector3(-0.9 + i * 0.36, 0.27, 0))
		root.add_child(post)
	root.add_child(_box(Vector3(1.9, 0.06, 0.06), mat, Vector3(0, 0.42, 0)))
	root.add_child(_box(Vector3(1.9, 0.06, 0.06), mat, Vector3(0, 0.18, 0)))
	return root


static func shaduf() -> Node3D:
	## Shaduf: palanca para sacar agua del Nilo, icono de la orilla egipcia.
	var root := Node3D.new()
	var wood := _mat("wood", Vector3(1, 2, 1))
	root.add_child(_box(Vector3(0.7, 0.7, 0.15), wood, Vector3(0, 0.35, 0)))
	var beam := _box(Vector3(2.6, 0.1, 0.1), wood, Vector3(0, 1.0, 0))
	beam.rotation.z = deg_to_rad(18)
	root.add_child(beam)
	var counterweight := _box(Vector3(0.3, 0.3, 0.3), _solid_mat(Color(0.3, 0.28, 0.24)), Vector3(-1.15, 0.55, 0))
	root.add_child(counterweight)
	var rope := _box(Vector3(0.03, 0.9, 0.03), _solid_mat(Color(0.5, 0.42, 0.3)), Vector3(1.2, 0.55, 0))
	root.add_child(rope)
	var bucket := _box(Vector3(0.18, 0.16, 0.18), _mat("wood", Vector3(1, 1, 1)), Vector3(1.2, 0.05, 0))
	root.add_child(bucket)
	return root


static func flower() -> Node3D:
	## Flor pequena (loto/lino silvestre), solo color, para salpicar el suelo.
	var root := Node3D.new()
	var petal_options: Array[Color] = [Color(0.85, 0.55, 0.65), Color(0.55, 0.65, 0.9), Color(0.95, 0.8, 0.3)]
	var petal_col: Color = petal_options[randi() % petal_options.size()]
	var stem := _box(Vector3(0.03, 0.25, 0.03), _solid_mat(Color(0.24, 0.45, 0.28)), Vector3(0, 0.12, 0))
	root.add_child(stem)
	var bloom := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.06
	sph.height = 0.08
	bloom.mesh = sph
	bloom.material_override = _solid_mat(petal_col)
	bloom.position = Vector3(0, 0.27, 0)
	root.add_child(bloom)
	return root


static func tall_grass() -> Node3D:
	## Mata de pasto alto (distinta de la textura del suelo: da volumen).
	var root := Node3D.new()
	var mat := _solid_mat(Color(0.42, 0.6, 0.36))
	for i in range(5):
		var h := 0.3 + randf_range(0.0, 0.25)
		var blade := _box(Vector3(0.05, h, 0.05), mat, Vector3(randf_range(-0.2, 0.2), h * 0.5, randf_range(-0.2, 0.2)))
		blade.rotation.z = randf_range(-0.25, 0.25)
		root.add_child(blade)
	return root


static func market_stall() -> Node3D:
	## Puesto de mercado con toldo de tela para darle vida a la aldea.
	var root := Node3D.new()
	var wood := _mat("wood", Vector3(1, 2, 1))
	var table := _box(Vector3(1.6, 0.08, 0.8), wood, Vector3(0, 0.7, 0))
	root.add_child(table)
	for x in [-0.7, 0.7]:
		for z in [-0.35, 0.35]:
			root.add_child(_box(Vector3(0.08, 0.7, 0.08), wood, Vector3(x, 0.35, z)))
	for x in [-0.75, 0.75]:
		root.add_child(_box(Vector3(0.08, 1.7, 0.08), wood, Vector3(x, 0.85, 0)))
	var awning_options: Array[Color] = [Color(0.72, 0.25, 0.22), Color(0.2, 0.45, 0.55)]
	var awning_col: Color = awning_options[randi() % awning_options.size()]
	var awning := _box(Vector3(1.9, 0.08, 1.1), _solid_mat(awning_col), Vector3(0, 1.7, 0))
	root.add_child(awning)
	root.add_child(_box(Vector3(0.6, 0.3, 0.5), _solid_mat(Color(0.7, 0.55, 0.2)), Vector3(-0.3, 0.9, 0)))
	root.add_child(_box(Vector3(0.4, 0.2, 0.4), _solid_mat(Color(0.8, 0.3, 0.25)), Vector3(0.4, 0.85, 0)))
	return root


static func well() -> Node3D:
	## Pozo de piedra para la plaza de la aldea.
	var root := Node3D.new()
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 0.75
	cyl.height = 0.6
	ring.mesh = cyl
	ring.material_override = _mat("stone", Vector3(1, 1, 1))
	ring.position = Vector3(0, 0.3, 0)
	root.add_child(ring)
	var inside := MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl2.top_radius = 0.5
	cyl2.bottom_radius = 0.5
	cyl2.height = 0.1
	inside.mesh = cyl2
	inside.material_override = _solid_mat(Color(0.08, 0.12, 0.16))
	inside.position = Vector3(0, 0.58, 0)
	root.add_child(inside)
	for x in [-0.6, 0.6]:
		root.add_child(_box(Vector3(0.1, 1.3, 0.1), _mat("wood", Vector3(1, 1, 1)), Vector3(x, 0.95, 0)))
	root.add_child(_box(Vector3(1.3, 0.08, 0.08), _mat("wood", Vector3(1, 1, 1)), Vector3(0, 1.55, 0)))
	root.add_child(_collision_box(Vector3(1.5, 0.6, 1.5)))
	return root


static func dune() -> Node3D:
	## Duna baja para disimular el borde del mundo (colina de arena, no muro).
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 1.0
	mesh.mesh = sph
	mesh.material_override = _mat("sand", Vector3(2, 1, 1))
	mesh.scale = Vector3(randf_range(3.5, 5.5), randf_range(1.4, 2.2), randf_range(3.5, 5.5))
	mesh.position = Vector3(0, 0.1, 0)
	root.add_child(mesh)
	root.add_child(_collision_box(Vector3(mesh.scale.x * 1.6, mesh.scale.y * 1.2, mesh.scale.z * 1.6)))
	return root


static func distant_pyramid() -> Node3D:
	## Piramide lejana en el horizonte (silueta, se pierde en la niebla).
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	var prism := PrismMesh.new()
	var s := randf_range(10.0, 18.0)
	prism.size = Vector3(s, s * 0.72, s)
	prism.left_to_right = 0.5
	mesh.mesh = prism
	var col := Color(0.30, 0.28, 0.36) if randf() < 0.5 else Color(0.24, 0.22, 0.30)
	mesh.material_override = _solid_mat(col)
	mesh.position = Vector3(0, s * 0.36, 0)
	root.add_child(mesh)
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
		"altar": return altar()
		"papyrus_plant": return papyrus_plant()
		"pottery": return pottery()
		"basket": return basket()
		"cane_fence": return cane_fence()
		"shaduf": return shaduf()
		"flower": return flower()
		"tall_grass": return tall_grass()
		"market_stall": return market_stall()
		"well": return well()
		"dune": return dune()
		"distant_pyramid": return distant_pyramid()
	return Node3D.new()
