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
	mi.material_override = WorldMaterials.terrain(tex_name, tiles)
	return mi


## Agua del Nilo: plano subdividido (para el leve oleaje en vertice) con el
## shader animado. shore_x = borde de la orilla en X de mundo.
static func water_plane(size: Vector2, shore_x: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = 8
	mesh.subdivide_depth = 40
	mi.mesh = mesh
	mi.material_override = WorldMaterials.water(shore_x)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func house(rng_seed: int = 0) -> Node3D:
	## Casa de adobe revocada, como en las aldeas del Nilo: techo plano con
	## parapeto, vigas asomando, escalera al techo y toldo de hojas de palma
	## (se vivia y dormia en el techo). Antes era un bloque de ladrillo con
	## una losa de tablas encima.
	var root := Node3D.new()
	root.name = "CasaAdobe"
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed + 11
	var w := 3.6
	var d := 3.2
	var h := 2.3
	var plaster := _mat("plaster", Vector3(2, 1, 1))
	var plaster_top := _mat("plaster", Vector3(1, 1, 1))
	var wood := _mat("wood")
	var dark := _solid_mat(Color(0.07, 0.05, 0.05))
	root.add_child(_box(Vector3(w, h, d), plaster, Vector3(0, h * 0.5, 0)))
	# zocalo de barro mas oscuro
	root.add_child(_box(Vector3(w + 0.06, 0.3, d + 0.06), _solid_mat(Color(0.55, 0.38, 0.22)), Vector3(0, 0.15, 0)))
	# esquinas marcadas (pilastras claras) y cornisa con sombra debajo: los
	# bordes se leen desde la camara alta (antes parecia una caja de carton)
	var trim := _solid_mat(Color(0.93, 0.84, 0.66))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			root.add_child(_box(Vector3(0.2, h, 0.2), trim, Vector3(sx * (w * 0.5 - 0.02), h * 0.5, sz * (d * 0.5 - 0.02))))
	root.add_child(_box(Vector3(w + 0.34, 0.18, d + 0.34), _solid_mat(Color(0.52, 0.34, 0.2)), Vector3(0, h + 0.02, 0)))
	# vigas de palmera asomando bajo el techo
	for i in range(5):
		root.add_child(_box(Vector3(0.12, 0.12, 0.35), wood, Vector3(-w * 0.4 + i * (w * 0.2), h - 0.12, d * 0.5 + 0.12)))
	var pitched := rng.randf() < 0.6
	if pitched:
		# techo de hojas de palma a dos aguas, con alero y cumbrera
		var roof := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(w + 0.9, 1.2, d + 0.9)
		roof.mesh = pm
		roof.material_override = _mat("thatch", Vector3(2, 2, 1))
		roof.position = Vector3(0, h + 0.7, 0)
		root.add_child(roof)
		root.add_child(_box(Vector3(0.14, 0.14, d + 1.0), wood, Vector3(0, h + 1.3, 0)))
		# hastiales (triangulos de barro bajo el techo)
		for side in [-1, 1]:
			var gable := MeshInstance3D.new()
			var gm := PrismMesh.new()
			gm.size = Vector3(w, 1.0, 0.08)
			gable.mesh = gm
			gable.material_override = plaster_top
			gable.position = Vector3(0, h + 0.6, side * (d * 0.5 + 0.02))
			root.add_child(gable)
	else:
		# techo plano de barro (mas oscuro que el muro) con parapeto y toldo
		root.add_child(_box(Vector3(w + 0.1, 0.1, d + 0.1), _mat("roof_mud", Vector3(2, 2, 1)), Vector3(0, h + 0.16, 0)))
		for side in [-1, 1]:
			root.add_child(_box(Vector3(w + 0.1, 0.34, 0.14), trim, Vector3(0, h + 0.3, side * (d * 0.5))))
			root.add_child(_box(Vector3(0.14, 0.34, d + 0.1), trim, Vector3(side * (w * 0.5), h + 0.3, 0)))
		for px in [-1.4, 0.0]:
			for pz in [-1.2, 0.2]:
				root.add_child(_box(Vector3(0.07, 1.1, 0.07), wood, Vector3(px, h + 0.7, pz)))
		var awning := _box(Vector3(1.8, 0.08, 1.8), _mat("thatch"), Vector3(-0.7, h + 1.25, -0.5))
		awning.rotation.x = 0.12
		root.add_child(awning)
		var jar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.14
		cyl.bottom_radius = 0.2
		cyl.height = 0.4
		jar.mesh = cyl
		jar.material_override = _solid_mat(Color(0.62, 0.36, 0.2))
		jar.position = Vector3(1.1, h + 0.41, -0.9)
		root.add_child(jar)
		# escalera al techo por el costado
		for i in range(5):
			var sh := (i + 1) * (h / 5.0)
			root.add_child(_box(Vector3(0.5, sh, 0.45), plaster, Vector3(w * 0.5 + 0.25, sh * 0.5, d * 0.5 - 0.3 - i * 0.45)))
	# puerta hundida con marco y dintel azul
	root.add_child(_box(Vector3(1.1, 1.8, 0.08), trim, Vector3(-0.5, 0.9, d * 0.5 + 0.03)))
	root.add_child(_box(Vector3(0.9, 1.6, 0.1), dark, Vector3(-0.5, 0.8, d * 0.5 + 0.05)))
	root.add_child(_box(Vector3(1.3, 0.18, 0.18), _solid_mat(Color(0.18, 0.32, 0.6)), Vector3(-0.5, 1.72, d * 0.5 + 0.06)))
	# ventanitas altas con alfeizar
	for x in [0.7, 1.3]:
		root.add_child(_box(Vector3(0.36, 0.36, 0.06), trim, Vector3(x, h - 0.6, d * 0.5 + 0.03)))
		root.add_child(_box(Vector3(0.26, 0.26, 0.1), dark, Vector3(x, h - 0.6, d * 0.5 + 0.05)))
	var body := _collision_box(Vector3(w + 0.6, h, d))
	root.add_child(body)
	var torch := Torch.new()
	torch.position = Vector3(0.35, 0, d * 0.5 + 0.35)
	root.add_child(torch)
	return root


static func temple() -> Node3D:
	## Templo de Maat: pilono de entrada (dos torres en talud con bandas
	## pintadas y cornisa dorada), disco solar alado sobre la puerta, patio
	## con columnas papiriformes y santuario al fondo. La entrada mira a +Z.
	var root := Node3D.new()
	root.name = "TemploMaat"
	var plaster := _mat("plaster", Vector3(2, 1, 1))
	var stone := _mat("stone", Vector3(3, 2, 1))
	var gold := _solid_mat(Color(0.91, 0.73, 0.14))
	var lapis := _solid_mat(Color(0.16, 0.3, 0.6))
	var turq := _solid_mat(Color(0.16, 0.6, 0.55))
	var red := _solid_mat(Color(0.62, 0.2, 0.14))
	var dark := _solid_mat(Color(0.06, 0.05, 0.05))
	# plataforma baja (caminable)
	root.add_child(_box(Vector3(10, 0.15, 8.5), stone, Vector3(0, 0.075, 0)))
	# --- pilono ---
	var ph := 4.6
	for side in [-1, 1]:
		var tower := _tapered_box(Vector2(1.7, 0.8), Vector2(1.3, 0.55), ph, plaster)
		tower.position = Vector3(side * 2.35, 0.15, 3.4)
		root.add_child(tower)
		# bandas pintadas en el frente de cada torre (azul, turquesa, rojo)
		var bands := [[lapis, 3.5], [turq, 3.25], [red, 3.0]]
		for bnd in bands:
			var y: float = bnd[1]
			var k := 1.0 - (y / ph) * (1.0 - 0.55 / 0.8)
			root.add_child(_box(Vector3(2.7 * (1.0 - y / ph * 0.23), 0.16, 0.05), bnd[0], Vector3(side * 2.35, 0.15 + y, 3.4 + 0.8 * k + 0.02)))
		# cornisa dorada
		root.add_child(_box(Vector3(2.8, 0.22, 1.3), gold, Vector3(side * 2.35, 0.15 + ph + 0.11, 3.4)))
		# relieve de Maat (pluma) pintado en la torre
		root.add_child(_box(Vector3(0.18, 1.1, 0.04), _solid_mat(Color(0.95, 0.92, 0.8)), Vector3(side * 2.35, 1.6, 3.4 + 0.72)))
	# puerta entre las torres
	root.add_child(_box(Vector3(1.9, 3.3, 0.5), dark, Vector3(0, 1.8, 3.2)))
	root.add_child(_box(Vector3(2.6, 0.5, 1.0), plaster, Vector3(0, 3.6, 3.4)))
	root.add_child(_box(Vector3(2.7, 0.12, 1.1), gold, Vector3(0, 3.91, 3.4)))
	# disco solar alado sobre la puerta
	var disk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.26
	cyl.bottom_radius = 0.26
	cyl.height = 0.08
	disk.mesh = cyl
	disk.material_override = gold
	disk.rotation_degrees.x = 90
	disk.position = Vector3(0, 3.6, 3.93)
	root.add_child(disk)
	for side in [-1, 1]:
		var wing := _box(Vector3(0.9, 0.16, 0.05), lapis, Vector3(side * 0.7, 3.62, 3.92))
		wing.rotation.z = side * 0.12
		root.add_child(wing)
	# --- patio con columnas papiriformes ---
	for side in [-1, 1]:
		for i in range(2):
			var z := 1.6 - i * 1.7
			var col := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.26
			c.bottom_radius = 0.32
			c.height = 3.0
			col.mesh = c
			col.material_override = plaster
			col.position = Vector3(side * 2.4, 1.65, z)
			root.add_child(col)
			var cap := MeshInstance3D.new()
			var cc := CylinderMesh.new()
			cc.top_radius = 0.5
			cc.bottom_radius = 0.28
			cc.height = 0.45
			cap.mesh = cc
			cap.material_override = turq
			cap.position = Vector3(side * 2.4, 3.35, z)
			root.add_child(cap)
			root.add_child(_box(Vector3(0.8, 0.12, 0.8), gold, Vector3(side * 2.4, 3.62, z)))
	# vigas del patio
	for side in [-1, 1]:
		root.add_child(_box(Vector3(0.5, 0.3, 4.2), plaster, Vector3(side * 2.4, 3.8, 0.6)))
	# --- santuario ---
	var sh := 3.4
	root.add_child(_box(Vector3(6.4, sh, 3.0), plaster, Vector3(0, 0.15 + sh * 0.5, -2.6)))
	root.add_child(_box(Vector3(6.7, 0.25, 3.3), gold, Vector3(0, 0.15 + sh + 0.12, -2.6)))
	root.add_child(_box(Vector3(6.6, 0.18, 3.2), lapis, Vector3(0, 0.15 + sh - 0.25, -2.6)))
	root.add_child(_box(Vector3(1.1, 2.0, 0.1), dark, Vector3(0, 1.15, -1.08)))
	# obeliscos pequenos flanqueando la entrada
	for side in [-1, 1]:
		root.add_child(_box(Vector3(0.6, 0.3, 0.6), stone, Vector3(side * 4.3, 0.3, 4.2)))
		root.add_child(_tapered_box(Vector2(0.22, 0.22), Vector2(0.15, 0.15), 2.8, stone))
		root.get_child(root.get_child_count() - 1).position = Vector3(side * 4.3, 0.45, 4.2)
		var tip := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.3, 0.35, 0.3)
		tip.mesh = pm
		tip.material_override = gold
		tip.position = Vector3(side * 4.3, 3.42, 4.2)
		root.add_child(tip)
	# colisiones: torres, santuario, columnas y obeliscos (el patio se camina)
	for side in [-1, 1]:
		var t := _collision_box(Vector3(3.2, ph, 1.6))
		t.position = Vector3(side * 2.35, 0, 3.4)
		root.add_child(t)
		var o := _collision_box(Vector3(0.7, 3.0, 0.7))
		o.position = Vector3(side * 4.3, 0, 4.2)
		root.add_child(o)
		for i in range(2):
			var cb := _collision_box(Vector3(0.6, 3.0, 0.6))
			cb.position = Vector3(side * 2.4, 0, 1.6 - i * 1.7)
			root.add_child(cb)
	var san := _collision_box(Vector3(6.4, sh, 3.0))
	san.position = Vector3(0, 0, -2.6)
	root.add_child(san)
	var door := _collision_box(Vector3(1.9, 3.3, 0.5))
	door.position = Vector3(0, 0, 3.2)
	root.add_child(door)
	for side in [-1, 1]:
		var torch := Torch.new()
		torch.position = Vector3(side * 1.35, 0.15, 4.5)
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
	trunk.material_override = WorldMaterials.wind(Color.WHITE, 0.012, "wood", Vector2(1, 3))
	trunk.position = Vector3(0, trunk_h * 0.5, 0)
	trunk.rotation_degrees = Vector3(0, 0, 5)
	root.add_child(trunk)

	var mat_a := WorldMaterials.wind(Color(0.34, 0.56, 0.26), 0.02)
	var mat_b := WorldMaterials.wind(Color(0.24, 0.44, 0.22), 0.02)
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
	var mat := WorldMaterials.wind(Color(0.36, 0.56, 0.30), 0.09)
	var mat_dark := WorldMaterials.wind(Color(0.24, 0.43, 0.24), 0.09)
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
	var stem_mat := WorldMaterials.wind(Color(0.22, 0.48, 0.30), 0.08)
	var tuft_mat := WorldMaterials.wind(Color(0.40, 0.62, 0.28), 0.08)
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
	var stem := _box(Vector3(0.03, 0.25, 0.03), WorldMaterials.wind(Color(0.30, 0.50, 0.24), 0.25), Vector3(0, 0.12, 0))
	root.add_child(stem)
	var bloom := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.06
	sph.height = 0.08
	bloom.mesh = sph
	bloom.material_override = WorldMaterials.wind(petal_col, 0.25)
	bloom.position = Vector3(0, 0.27, 0)
	root.add_child(bloom)
	return root


static func tall_grass() -> Node3D:
	## Mata de pasto alto (distinta de la textura del suelo: da volumen).
	var root := Node3D.new()
	var mat := WorldMaterials.wind(Color(0.46, 0.62, 0.28), 0.3)
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


static func distant_pyramid(size: float = 24.0, cap: bool = false) -> Node3D:
	## Piramide lejana: hiladas de bloques de caliza (textura) y cada cara con
	## su propio tono, asi el volumen se lee aunque la niebla aplane la luz
	## (antes era un triangulo liso "de carton").
	var root := Node3D.new()
	var h := size * 0.64
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(TEX_DIR + "pyramid_stone.png")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	root.add_child(_pyramid_mesh(size, h, mat, size / 3.0))
	if cap:
		var cap_ratio := 0.1
		var gold := _solid_mat(Color(0.93, 0.76, 0.30))
		gold.metallic = 0.3
		gold.roughness = 0.45
		var c := _pyramid_mesh(size * cap_ratio * 1.04, h * cap_ratio * 1.04, gold, 1.0)
		c.position.y = h * (1.0 - cap_ratio)
		root.add_child(c)
	return root


static func _pyramid_mesh(base: float, height: float, mat: Material, tiling: float = 1.0) -> MeshInstance3D:
	var b := base * 0.5
	var apex := Vector3(0, height, 0)
	var corners := [Vector3(-b, 0, -b), Vector3(b, 0, -b), Vector3(b, 0, b), Vector3(-b, 0, b)]
	# tono por cara: norte oscuro, sur claro (mira a la camara), este/oeste medio
	var tints := [Color(0.62, 0.6, 0.62), Color(0.86, 0.82, 0.78), Color(1.0, 0.97, 0.9), Color(0.75, 0.72, 0.72)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(4):
		var a: Vector3 = corners[i]
		var c: Vector3 = corners[(i + 1) % 4]
		var n := (c - a).cross(apex - a).normalized()
		if n.y < 0:
			n = -n
		var uvs := [Vector2(0, tiling), Vector2(tiling * 0.5, 0), Vector2(tiling, tiling)]
		var verts := [a, apex, c]
		for k in range(3):
			st.set_normal(n)
			st.set_color(tints[i])
			st.set_uv(uvs[k])
			st.add_vertex(verts[k])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _tapered_box(bottom: Vector2, top: Vector2, h: float, mat: Material) -> MeshInstance3D:
	## Caja con los lados inclinados (talud egipcio de mastabas y pilonos).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var b := [Vector3(-bottom.x, 0, -bottom.y), Vector3(bottom.x, 0, -bottom.y), Vector3(bottom.x, 0, bottom.y), Vector3(-bottom.x, 0, bottom.y)]
	var t := [Vector3(-top.x, h, -top.y), Vector3(top.x, h, -top.y), Vector3(top.x, h, top.y), Vector3(-top.x, h, top.y)]
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for i in range(4):
		var j := (i + 1) % 4
		var quad := [b[i], b[j], t[j], t[i]]
		var n: Vector3 = (b[j] - b[i]).cross(t[i] - b[i]).normalized()
		if n.dot(Vector3((b[i] + b[j]).x, 0, (b[i] + b[j]).z)) < 0:
			n = -n
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(n)
			st.set_uv(uvs[k] * Vector2(2, 1))
			st.add_vertex(quad[k])
	for k in [0, 2, 1, 0, 3, 2]:
		st.set_normal(Vector3.UP)
		st.set_uv(uvs[k])
		st.add_vertex(t[k])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func mastaba() -> Node3D:
	## Mastaba: tumba de techo plano y paredes en talud, con falsa puerta
	## (la puerta por la que el ka salia a recibir ofrendas).
	var root := Node3D.new()
	root.name = "Mastaba"
	var stone := _mat("plaster", Vector3(2, 1, 1))
	root.add_child(_tapered_box(Vector2(2.2, 1.5), Vector2(1.8, 1.15), 1.9, stone))
	var dark := _solid_mat(Color(0.08, 0.06, 0.06))
	var red := _solid_mat(Color(0.55, 0.2, 0.12))
	# falsa puerta: marco rojo ocre y nicho oscuro
	root.add_child(_box(Vector3(0.9, 1.3, 0.08), red, Vector3(0, 0.75, 1.36)))
	root.add_child(_box(Vector3(0.5, 1.0, 0.1), dark, Vector3(0, 0.62, 1.39)))
	root.add_child(_box(Vector3(1.1, 0.14, 0.12), _solid_mat(Color(0.18, 0.32, 0.6)), Vector3(0, 1.45, 1.38)))
	# mesa de ofrendas delante
	root.add_child(_box(Vector3(0.6, 0.18, 0.4), _mat("stone"), Vector3(0, 0.09, 1.9)))
	root.add_child(_collision_box(Vector3(4.2, 1.9, 3.0)))
	return root


static func stela() -> Node3D:
	## Estela funeraria de punta redondeada.
	var root := Node3D.new()
	var stone := _mat("stone")
	root.add_child(_box(Vector3(0.7, 1.1, 0.16), stone, Vector3(0, 0.55, 0)))
	var top := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.35
	cyl.height = 0.16
	top.mesh = cyl
	top.material_override = stone
	top.rotation_degrees.x = 90
	top.position = Vector3(0, 1.1, 0)
	root.add_child(top)
	# lineas de jeroglificos pintadas
	for i in range(3):
		root.add_child(_box(Vector3(0.44, 0.05, 0.02), _solid_mat(Color(0.3, 0.2, 0.15)), Vector3(0, 0.95 - i * 0.18, 0.09)))
	root.add_child(_box(Vector3(0.2, 0.2, 0.02), _solid_mat(Color(0.18, 0.32, 0.6)), Vector3(0, 1.18, 0.09)))
	root.add_child(_collision_box(Vector3(0.7, 1.2, 0.3)))
	return root


static func step_pyramid() -> Node3D:
	## Piramide escalonada pequena (como la de Djoser en Saqqara, en chico).
	var root := Node3D.new()
	root.name = "PiramideEscalonada"
	var stone := _mat("pyramid_stone", Vector3(3, 1, 1))
	var y := 0.0
	var half := 3.2
	for i in range(4):
		var h := 1.1
		root.add_child(_tapered_box(Vector2(half, half), Vector2(half - 0.25, half - 0.25), h, stone))
		root.get_child(root.get_child_count() - 1).position.y = y
		y += h
		half -= 0.75
	root.add_child(_collision_box(Vector3(6.4, 4.4, 6.4)))
	return root


static func anubis_statue() -> Node3D:
	## Estatua de Anubis echado sobre su cofre, custodiando la necropolis
	## (decorativa: mismo arte que la defensa, mas grande).
	var root := Node3D.new()
	root.add_child(_box(Vector3(1.4, 0.4, 1.0), _mat("stone"), Vector3(0, 0.2, 0)))
	var spr := Sprite3D.new()
	spr.texture = load("res://assets/sprites/fx/jackal_statue.png")
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, 32, 32)
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.pixel_size = 0.065
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.position.y = 0.4 + 1.04
	root.add_child(spr)
	root.add_child(_collision_box(Vector3(1.4, 1.2, 1.0)))
	return root


static func broken_column() -> Node3D:
	var root := Node3D.new()
	var col := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.33
	cyl.bottom_radius = 0.4
	cyl.height = randf_range(0.8, 1.8)
	col.mesh = cyl
	col.material_override = _mat("stone")
	col.position.y = cyl.height * 0.5
	col.rotation.z = randf_range(-0.08, 0.08)
	root.add_child(col)
	# tambor caido al lado
	var drum := MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl2.top_radius = 0.36
	cyl2.bottom_radius = 0.36
	cyl2.height = 0.7
	drum.mesh = cyl2
	drum.material_override = _mat("stone")
	drum.rotation_degrees = Vector3(0, randf_range(0, 180), 90)
	drum.position = Vector3(0.9, 0.36, 0.3)
	root.add_child(drum)
	root.add_child(_collision_box(Vector3(0.8, 1.2, 0.8)))
	return root


static func build(tipo: String) -> Node3D:
	match tipo:
		"house": return house(randi() % 100)
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
		"mastaba": return mastaba()
		"stela": return stela()
		"step_pyramid": return step_pyramid()
		"anubis_statue": return anubis_statue()
		"broken_column": return broken_column()
		"distant_pyramid": return distant_pyramid()
	return Node3D.new()
