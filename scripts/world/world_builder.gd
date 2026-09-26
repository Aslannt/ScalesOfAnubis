class_name WorldBuilder
extends Node3D
## Construye el mapa (terreno + edificios + parcelas de cultivo) leyendo
## data/map_layout.json. Nada de geometria quemada a mano: todo sale de datos.

var tile_size: float = 2.0
var world_w: int = 36
var world_h: int = 28
var player_spawn_world: Vector3 = Vector3.ZERO

var farm_plots: Array = []
var npcs: Array = []


func build(layout_path: String = "res://data/map_layout.json") -> void:
	var f := FileAccess.open(layout_path, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % layout_path)
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())

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
		var plane := BuildingFactory.ground_plane(tiles * tile_size, zone["textura"], tiles)
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
		npc.layout_path = "res://assets/sprites/characters/%s_layout.txt" % sheet
		npc.position = _tile_to_world(float(tile[0]) + 0.5, float(tile[1]) + 0.5)
		npcs_node.add_child(npc)
		npcs.append(npc)

	var spawn: Array = data.get("player_spawn_tile", [world_w / 2, world_h / 2])
	player_spawn_world = _tile_to_world(float(spawn[0]) + 0.5, float(spawn[1]) + 0.5)


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


const _TUFT_TEXTURES := [
	"res://assets/sprites/fx/grass_tuft_0.png",
	"res://assets/sprites/fx/grass_tuft_1.png",
]


func _scatter_foliage(rect: Array, all_zones: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var foliage_node := Node3D.new()
	foliage_node.name = "Vegetacion"
	add_child(foliage_node)

	var area: float = float(rect[2]) - float(rect[0])
	area *= float(rect[3]) - float(rect[1])
	var count: int = int(area * 0.35)
	var textures := [load(_TUFT_TEXTURES[0]), load(_TUFT_TEXTURES[1])]

	for i in range(count):
		var tx: float = rng.randf_range(rect[0], rect[2])
		var tz: float = rng.randf_range(rect[1], rect[3])
		if _inside_any_farmland(tx, tz, all_zones):
			continue
		var sprite := Sprite3D.new()
		sprite.texture = textures[rng.randi_range(0, 1)]
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.pixel_size = 0.05 * rng.randf_range(0.8, 1.3)
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.shaded = true
		sprite.position = _tile_to_world(tx, tz)
		sprite.position.y = 0.02
		foliage_node.add_child(sprite)


func _inside_any_farmland(tx: float, tz: float, all_zones: Array) -> bool:
	for z in all_zones:
		if not z.get("farmland", false):
			continue
		var r: Array = z["rect"]
		if tx >= r[0] and tx < r[2] and tz >= r[1] and tz < r[3]:
			return true
	return false


func _build_ground_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "SueloColision"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(world_w * tile_size, 0.2, world_h * tile_size)
	col.shape = shape
	col.position = Vector3(0, -0.1, 0)
	body.add_child(col)
	add_child(body)


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
		var d: float = n.position.distance_to(pos)
		if d < best:
			best = d
			closest = n
	return closest
