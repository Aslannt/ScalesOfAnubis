class_name WorldBuilder
extends Node3D
## Construye el mapa (terreno + edificios + parcelas de cultivo) leyendo
## data/map_layout.json. Nada de geometria quemada a mano: todo sale de datos.

var tile_size: float = 2.0
var world_w: int = 36
var world_h: int = 28
var player_spawn_world: Vector3 = Vector3.ZERO

var farm_plots: Array = []
var river_shore_x: float = -26.0
var spawn_points: Dictionary = {}
var village_center: Vector3 = Vector3.ZERO
var defense_spots: Array = []
## map_layout.json completo (otros sistemas leen sus secciones).
var layout: Dictionary = {}
var river_min_x: float = -36.0
var npcs: Array = []


func build(layout_path: String = "res://data/map_layout.json") -> void:
	var f := FileAccess.open(layout_path, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % layout_path)
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	layout = data

	tile_size = float(data.get("tile_size", 2.0))
	world_w = int(data["world_tiles"]["w"])
	world_h = int(data["world_tiles"]["h"])

	_build_ground_collision()

	var zones_node := Node3D.new()
	zones_node.name = "Terreno"
	add_child(zones_node)

	var y_offset := 0.0
	for zone in data["zones"]:
		var rect: Array = zone["rect"]
		var x0: float = rect[0]
		var z0: float = rect[1]
		var x1: float = rect[2]
		var z1: float = rect[3]
		var tiles := Vector2(x1 - x0, z1 - z0)
		var center_tile := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
		var plane: MeshInstance3D
		if zone.get("textura") == "water":
			var shore_x: float = _tile_to_world(x1, 0).x
			river_shore_x = shore_x
			river_min_x = _tile_to_world(x0, 0).x
			plane = BuildingFactory.water_plane(tiles * tile_size, shore_x)
			_build_river_bank(shore_x)
		else:
			plane = BuildingFactory.ground_plane(tiles * tile_size, zone["textura"], tiles)
		plane.position = _tile_to_world(center_tile.x, center_tile.y)
		plane.position.y = y_offset
		zones_node.add_child(plane)
		y_offset += 0.002

		if zone.get("farmland", false):
			_build_farmland(rect, bool(zone.get("orilla", false)))
		elif zone.get("textura") == "grass_nile":
			_scatter_foliage(rect, data.get("zones", []))

	var props_node := Node3D.new()
	props_node.name = "Props"
	add_child(props_node)
	for prop in data["props"]:
		var tile: Array = prop["tile"]
		var node := BuildingFactory.build(prop["tipo"])
		node.position = _tile_to_world(float(tile[0]) + 0.5, float(tile[1]) + 0.5)
		node.rotation_degrees.y = float(prop.get("rot", 0))
		props_node.add_child(node)
		if prop["tipo"] == "temple":
			node.add_child(TempleRestoration.new())

	_build_horizon(data.get("horizonte", {}))

	var npcs_node := Node3D.new()
	npcs_node.name = "NPCs"
	add_child(npcs_node)

	for altar_data in data.get("altares", []):
		var tile_a: Array = altar_data["tile"]
		var altar := Altar.new()
		altar.position = _tile_to_world(float(tile_a[0]) + 0.5, float(tile_a[1]) + 0.5)
		altar.rotation_degrees.y = float(altar_data.get("rot", 0))
		npcs_node.add_child(altar)
		npcs.append(altar)

	for npc_data in data.get("npcs", []):
		var tile: Array = npc_data["tile"]
		var npc := NPC.new()
		npc.npc_id = npc_data["id"]
		var sheet: String = npc_data["sheet"]
		npc.sheet_path = "res://assets/sprites/characters/%s.png" % sheet
		npc.layout_path = "res://assets/sprites/characters/%s_layout.json" % sheet
		npc.position = _tile_to_world(float(tile[0]) + 0.5, float(tile[1]) + 0.5)
		npcs_node.add_child(npc)
		npcs.append(npc)

	for nombre in data.get("spawns", {}):
		var t: Array = data["spawns"][nombre]
		spawn_points[nombre] = _tile_to_world(float(t[0]), float(t[1]))
	var vc: Array = data.get("aldea_centro", [26, 8])
	village_center = _tile_to_world(float(vc[0]), float(vc[1]))
	var marker := Marker3D.new()
	marker.name = "CentroAldea"
	marker.add_to_group("village_center")
	add_child(marker)
	marker.position = village_center

	for dd in data.get("defensas", []):
		var tt: Array = dd["tile"]
		var spot := DefenseSpot.new()
		spot.position = _tile_to_world(float(tt[0]), float(tt[1]))
		npcs_node.add_child(spot)
		npcs.append(spot)
		defense_spots.append(spot)

	var ct: Array = data.get("campamento", [])
	if ct.size() == 2:
		var camp := Camp.new()
		camp.position = _tile_to_world(float(ct[0]), float(ct[1]))
		npcs_node.add_child(camp)
		npcs.append(camp)
	for cd in data.get("coleccionables", []):
		var col := Collectible.new()
		col.npc_id = cd["id"]
		var tc: Array = cd["tile"]
		col.position = _tile_to_world(float(tc[0]), float(tc[1]))
		npcs_node.add_child(col)
		npcs.append(col)

	var spawn: Array = data.get("player_spawn_tile", [world_w / 2, world_h / 2])
	player_spawn_world = _tile_to_world(float(spawn[0]) + 0.5, float(spawn[1]) + 0.5)
	_build_navigation()


# ------------------------------------------------------------ navegacion
## Malla de navegacion horneada al cargar (a partir de las colisiones del
## mapa): las criaturas rodean casas, tumbas y muros en vez de quedar
## atascadas (reporte de Deivid: enemigos y el Heraldo trabados).
var nav_region: NavigationRegion3D


func _build_navigation() -> void:
	add_to_group("navmesh_source")
	add_to_group("world_builder")
	nav_region = NavigationRegion3D.new()
	nav_region.name = "Navegacion"
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nm.geometry_source_group_name = "navmesh_source"
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_radius = 0.75
	nm.agent_height = 1.5
	nm.agent_max_climb = 0.25
	var hw := world_w * tile_size * 0.5
	var hh := world_h * tile_size * 0.5
	nm.filter_baking_aabb = AABB(Vector3(-hw, -1, -hh), Vector3(hw * 2, 4, hh * 2))
	nav_region.navigation_mesh = nm
	add_child(nav_region)
	rebake_navigation()


## Se vuelve a hornear cuando cambia el mapa (p. ej. al construir un muro).
func rebake_navigation() -> void:
	if nav_region == null:
		return
	if nav_region.is_baking():
		await nav_region.bake_finished
	nav_region.bake_navigation_mesh(true)


## Suelo de desierto exterior (bajo el mapa jugable) y piramides lejanas:
## el borde del mundo nunca muestra vacio (PROMPT_PULIDO.md punto 2).
func _build_horizon(h: Dictionary) -> void:
	if h.is_empty():
		return
	var node := Node3D.new()
	node.name = "Horizonte"
	add_child(node)
	var suelo: Dictionary = h.get("suelo_exterior", {})
	if not suelo.is_empty():
		var size := float(suelo.get("tamano_m", 400))
		var reps := float(suelo.get("repeticiones", 100))
		var plane := BuildingFactory.ground_plane(Vector2(size, size), suelo.get("textura", "sand"), Vector2(reps, reps))
		plane.position.y = -0.03
		plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(plane)
	for p in h.get("piramides", []):
		var tile: Array = p["tile"]
		var pyr := BuildingFactory.distant_pyramid(float(p.get("size", 24)), bool(p.get("cap", false)))
		pyr.position = _tile_to_world(float(tile[0]), float(tile[1]))
		pyr.position.y = -0.05
		pyr.rotation_degrees.y = float(p.get("rot", 12.0))
		node.add_child(pyr)


func _build_farmland(rect: Array, orilla: bool) -> void:
	var plots_node := Node3D.new()
	plots_node.name = "Parcelas"
	add_child(plots_node)
	for tx in range(int(rect[0]), int(rect[2])):
		for tz in range(int(rect[1]), int(rect[3])):
			var plot := FarmPlot.new()
			plot.tile_size = tile_size
			plot.is_orilla = orilla
			plot.position = _tile_to_world(tx + 0.5, tz + 0.5)
			plots_node.add_child(plot)
			farm_plots.append(plot)


const GRASS_ATLAS := preload("res://assets/sprites/fx/grass_atlas.png")
const GRASS_FRAMES := 6


## Pasto denso que se mece con el viento: un solo MultiMesh con miles de
## mechones (antes eran ~150 Sprite3D quietos). Evita parcelas y caminos.
func _scatter_foliage(rect: Array, all_zones: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337 + int(rect[0]) * 31 + int(rect[1])
	var area: float = (float(rect[2]) - float(rect[0])) * (float(rect[3]) - float(rect[1]))
	var target: int = int(area * 7.0)
	var transforms: Array[Transform3D] = []
	var customs: Array[Color] = []
	var tries := 0
	while transforms.size() < target and tries < target * 3:
		tries += 1
		var tx: float = rng.randf_range(rect[0], rect[2])
		var tz: float = rng.randf_range(rect[1], rect[3])
		if _inside_any_farmland(tx, tz, all_zones, 0.25) or _inside_texture(tx, tz, all_zones, ["path", "water"]):
			continue
		var s := rng.randf_range(0.7, 1.25)
		var pos := _tile_to_world(tx, tz)
		pos.y = 0.3 * s
		transforms.append(Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
		var frame := rng.randi_range(0, GRASS_FRAMES - 1)
		if rng.randf() < 0.55:
			frame = rng.randi_range(0, 1)
		customs.append(Color(frame, rng.randf(), rng.randf(), 0))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.69, 0.6)
	mm.mesh = quad
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, customs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Pasto"
	mmi.multimesh = mm
	mmi.material_override = WorldMaterials.grass(GRASS_ATLAS, GRASS_FRAMES)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _inside_texture(tx: float, tz: float, all_zones: Array, textures: Array) -> bool:
	for z in all_zones:
		if not textures.has(z.get("textura", "")):
			continue
		var r: Array = z["rect"]
		if tx >= r[0] and tx < r[2] and tz >= r[1] and tz < r[3]:
			return true
	return false


## Borde invisible en la orilla para que el jugador no camine sobre el Nilo
## (antes se podia entrar al rio).
func _build_river_bank(shore_x: float) -> void:
	var body := StaticBody3D.new()
	body.name = "OrillaNilo"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 3.0, world_h * tile_size)
	col.shape = shape
	col.position = Vector3(shore_x - 0.8, 1.5, 0)
	body.add_child(col)
	add_child(body)


func _inside_any_farmland(tx: float, tz: float, all_zones: Array, margin: float = 0.0) -> bool:
	for z in all_zones:
		if not z.get("farmland", false):
			continue
		var r: Array = z["rect"]
		if tx >= r[0] - margin and tx < r[2] + margin and tz >= r[1] - margin and tz < r[3] + margin:
			return true
	return false


func _build_ground_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "SueloColision"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	# el suelo es mucho mas grande que el mapa: aunque algo empuje al jugador
	# fuera del borde, nunca cae al vacio (bug real: se caia por el sur)
	shape.size = Vector3(world_w * tile_size * 3.0, 0.2, world_h * tile_size * 3.0)
	col.shape = shape
	col.position = Vector3(0, -0.1, 0)
	body.add_child(col)
	add_child(body)
	# muros invisibles en los cuatro bordes del mapa jugable
	var half_w := world_w * tile_size * 0.5
	var half_h := world_h * tile_size * 0.5
	var walls := [
		[Vector3(0, 2, -half_h - 0.5), Vector3(world_w * tile_size + 2, 4, 1)],
		[Vector3(0, 2, half_h + 0.5), Vector3(world_w * tile_size + 2, 4, 1)],
		[Vector3(-half_w - 0.5, 2, 0), Vector3(1, 4, world_h * tile_size + 2)],
		[Vector3(half_w + 0.5, 2, 0), Vector3(1, 4, world_h * tile_size + 2)],
	]
	for wd in walls:
		var wb := StaticBody3D.new()
		wb.name = "BordeMapa"
		var wc := CollisionShape3D.new()
		var ws := BoxShape3D.new()
		ws.size = wd[1]
		wc.shape = ws
		wb.position = wd[0]
		wb.add_child(wc)
		add_child(wb)


func _tile_to_world(tx: float, tz: float) -> Vector3:
	var x := tx * tile_size - (world_w * tile_size) * 0.5
	var z := tz * tile_size - (world_h * tile_size) * 0.5
	return Vector3(x, 0, z)


func plot_at_world(pos: Vector3, max_dist: float = 3.0) -> FarmPlot:
	var closest: FarmPlot = null
	var best := max_dist
	for p in farm_plots:
		var d: float = p.position.distance_to(pos)
		if d < best:
			best = d
			closest = p
	return closest


## Devuelve NPC o Altar (ambos exponen interact()); sin tipo estricto a
## proposito para permitir duck typing entre las dos clases.
func npc_at_world(pos: Vector3, max_dist: float = 2.4):
	var closest = null
	var best := max_dist
	for n in npcs:
		# coleccionables ya recogidos (liberados) u ocultos no cuentan
		if not is_instance_valid(n) or not n.visible:
			continue
		var d: float = n.position.distance_to(pos)
		if d < best:
			best = d
			closest = n
	return closest
