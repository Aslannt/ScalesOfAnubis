class_name FarmPlot
extends Node3D
## Una parcela de 2x2m. Arar -> sembrar -> regar -> crecer -> cosechar.
## Ver GDD 6.2. Puede ser danada de noche por las crias de Ammit.
## Sin colision fisica propia (el suelo ya es caminable via SueloColision en
## WorldBuilder); la deteccion del jugador es por cercania, no por raycast.

enum State { UNTILLED, TILLED, PLANTED }

## true mientras se reconstruye una partida guardada: sin sonidos ni
## particulas por cada parcela restaurada.
static var quiet := false

var state: State = State.UNTILLED
var crop_id: String = ""
var growth_day: int = 0
var watered_today: bool = false
var is_orilla: bool = false
var tile_size: float = 2.0

var _soil_mesh: MeshInstance3D
var _marker_mesh: MeshInstance3D
## Dos quads por parcela (fila de atras y de adelante) con el shader de
## viento, para que el cultivo se vea tupido y se meza (PROMPT_PULIDO.md 3).
var _crop_quads: Array[MeshInstance3D] = []
var _crop_mats: Array[ShaderMaterial] = []
const CROP_FRAME_W := 24.0
const CROP_FRAMES := 4
const CROP_SIZE := Vector2(1.5, 2.0)
var _mat_dry: Material
var _mat_wet: Material


func _ready() -> void:
	add_to_group("farm_plots")

	_mat_dry = WorldMaterials.terrain("soil_dry", Vector2.ONE)
	_mat_wet = WorldMaterials.terrain("soil_wet", Vector2.ONE)

	_soil_mesh = MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(tile_size, tile_size)
	_soil_mesh.mesh = mesh
	_soil_mesh.material_override = _mat_dry
	_soil_mesh.position = Vector3(0, 0.02, 0)
	_soil_mesh.visible = false
	add_child(_soil_mesh)

	# Marco visible aunque no este arada, para que se note que es tierra de
	# cultivo (PROMPT_PULIDO.md punto 2: "el mapa se ve vacio y plano").
	_marker_mesh = MeshInstance3D.new()
	var marker_plane := PlaneMesh.new()
	marker_plane.size = Vector2(tile_size, tile_size)
	_marker_mesh.mesh = marker_plane
	var marker_mat := StandardMaterial3D.new()
	marker_mat.albedo_texture = load("res://assets/textures/plot_marker.png")
	marker_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_mat.albedo_color = Color(1, 1, 1, 0.85)
	_marker_mesh.material_override = marker_mat
	_marker_mesh.position = Vector3(0, 0.015, 0)
	add_child(_marker_mesh)

	var offsets := [Vector3(-0.12, 0, -0.45), Vector3(0.14, 0, 0.35)]
	for i in range(2):
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = CROP_SIZE
		q.mesh = qm
		q.position = offsets[i] + Vector3(0, CROP_SIZE.y * 0.5, 0)
		q.visible = false
		add_child(q)
		_crop_quads.append(q)

	GameTime.day_started.connect(_on_day_started)


func till() -> bool:
	if state != State.UNTILLED:
		return false
	state = State.TILLED
	_soil_mesh.visible = true
	_soil_mesh.material_override = _mat_dry
	_marker_mesh.visible = false
	if not quiet:
		SFX.play("till")
	Codex.unlock("kemet")
	if not quiet:
		CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.15, 0), Color(0.37, 0.24, 0.15))
	return true


func can_plant(id: String) -> bool:
	if state != State.TILLED:
		return false
	var data: Dictionary = GameState.crops.get(id, {})
	if data.is_empty():
		return false
	if bool(data.get("solo_orilla", false)) and not is_orilla:
		return false
	return true


func plant(id: String) -> bool:
	if not can_plant(id):
		return false
	crop_id = id
	growth_day = 0
	watered_today = false
	state = State.PLANTED
	var sheet: Texture2D = load(GameState.crops[id]["sprite"])
	_crop_mats.clear()
	for q in _crop_quads:
		var m := WorldMaterials.sprite_wind(sheet, 0.12)
		q.material_override = m
		_crop_mats.append(m)
		q.visible = true
	_update_crop_frame()
	if not quiet:
		SFX.play("plant")
		CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.1, 0), Color(0.45, 0.62, 0.28))
	return true


func water() -> bool:
	if state != State.PLANTED or watered_today:
		return false
	watered_today = true
	_soil_mesh.material_override = _mat_wet
	if not quiet:
		SFX.play("water")
		CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.2, 0), Color(0.3, 0.7, 0.75))
	return true


func is_ready() -> bool:
	if state != State.PLANTED:
		return false
	var data: Dictionary = GameState.crops.get(crop_id, {})
	return growth_day >= int(data.get("dias_para_crecer", 1))


func harvest() -> String:
	if not is_ready():
		return ""
	var id := crop_id
	# el papiro y el lino rinden mas por parcela (tardan dos dias)
	GameState.add_item(id, 2 if id != "trigo" else 1)
	Codex.unlock("cultivos")
	SFX.play("harvest")
	CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.3, 0), Color(0.9, 0.75, 0.2))
	crop_id = ""
	growth_day = 0
	watered_today = false
	state = State.TILLED
	_hide_crop()
	_soil_mesh.material_override = _mat_dry
	return id


func damage() -> void:
	if state != State.PLANTED:
		return
	crop_id = ""
	growth_day = 0
	watered_today = false
	state = State.TILLED
	_hide_crop()
	_soil_mesh.material_override = _mat_dry
	GameState.crops_lost_tonight += 1
	GameState.thot_once("cultivo_perdido", Dialogos.thot("cultivo_perdido"))
	CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.3, 0), Color(0.2, 0.45, 0.25))


func _update_crop_frame() -> void:
	var data: Dictionary = GameState.crops.get(crop_id, {})
	var dias := int(data.get("dias_para_crecer", 1))
	var stage := 3 if growth_day >= dias else int(round(float(growth_day) / float(dias) * 3.0))
	stage = clampi(stage, 0, CROP_FRAMES - 1)
	var w := 1.0 / CROP_FRAMES
	for i in range(_crop_mats.size()):
		# la fila de adelante va espejada para que no se vean dos copias iguales
		if i == 1:
			_crop_mats[i].set_shader_parameter("region", Vector4((stage + 1) * w, 0, -w, 1))
		else:
			_crop_mats[i].set_shader_parameter("region", Vector4(stage * w, 0, w, 1))


func _hide_crop() -> void:
	for q in _crop_quads:
		q.visible = false


func _on_day_started() -> void:
	if state != State.PLANTED:
		return
	if watered_today:
		growth_day += 1
		_update_crop_frame()
	watered_today = false
	_soil_mesh.material_override = _mat_dry


func to_dict() -> Dictionary:
	return {"s": state, "c": crop_id, "g": growth_day, "w": watered_today}


func from_dict(d: Dictionary) -> void:
	var st := int(d.get("s", 0))
	if st >= State.TILLED:
		till()
	if st == State.PLANTED and String(d.get("c", "")) != "":
		plant(String(d["c"]))
		growth_day = int(d.get("g", 0))
		if bool(d.get("w", false)):
			water()
		_update_crop_frame()
