class_name FarmPlot
extends Node3D
## Una parcela de 2x2m. Arar -> sembrar -> regar -> crecer -> cosechar.
## Ver GDD 6.2. Puede ser danada de noche por las crias de Ammit.
## Sin colision fisica propia (el suelo ya es caminable via SueloColision en
## WorldBuilder); la deteccion del jugador es por cercania, no por raycast.

enum State { UNTILLED, TILLED, PLANTED }

var state: State = State.UNTILLED
var crop_id: String = ""
var growth_day: int = 0
var watered_today: bool = false
var is_orilla: bool = false
var tile_size: float = 2.0

var _soil_mesh: MeshInstance3D
var _crop_sprite: Sprite3D
var _mat_dry: StandardMaterial3D
var _mat_wet: StandardMaterial3D


func _ready() -> void:
	add_to_group("farm_plots")

	_mat_dry = BuildingFactory._mat("soil_dry")
	_mat_wet = BuildingFactory._mat("soil_wet")

	_soil_mesh = MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(tile_size, tile_size)
	_soil_mesh.mesh = mesh
	_soil_mesh.material_override = _mat_dry
	_soil_mesh.position = Vector3(0, 0.02, 0)
	_soil_mesh.visible = false
	add_child(_soil_mesh)

	_crop_sprite = Sprite3D.new()
	_crop_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_crop_sprite.pixel_size = 0.09
	_crop_sprite.position = Vector3(0, 0.05, 0)
	_crop_sprite.region_enabled = true
	_crop_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_crop_sprite.visible = false
	add_child(_crop_sprite)

	GameTime.day_started.connect(_on_day_started)


func till() -> bool:
	if state != State.UNTILLED:
		return false
	state = State.TILLED
	_soil_mesh.visible = true
	_soil_mesh.material_override = _mat_dry
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
	_crop_sprite.texture = load(GameState.crops[id]["sprite"])
	_update_crop_frame()
	_crop_sprite.visible = true
	return true


func water() -> bool:
	if state != State.PLANTED or watered_today:
		return false
	watered_today = true
	_soil_mesh.material_override = _mat_wet
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
	GameState.add_item(id, 1)
	Codex.unlock("cultivos")
	crop_id = ""
	growth_day = 0
	watered_today = false
	state = State.TILLED
	_crop_sprite.visible = false
	_soil_mesh.material_override = _mat_dry
	return id


func damage() -> void:
	if state != State.PLANTED:
		return
	crop_id = ""
	growth_day = 0
	watered_today = false
	state = State.TILLED
	_crop_sprite.visible = false
	_soil_mesh.material_override = _mat_dry
	GameState.crops_lost_tonight += 1


func _update_crop_frame() -> void:
	var data: Dictionary = GameState.crops.get(crop_id, {})
	var dias := int(data.get("dias_para_crecer", 1))
	var stage := 3 if growth_day >= dias else int(round(float(growth_day) / float(dias) * 3.0))
	stage = clampi(stage, 0, 3)
	_crop_sprite.region_rect = Rect2(stage * 16, 0, 16, 20)


func _on_day_started() -> void:
	if state != State.PLANTED:
		return
	if watered_today:
		growth_day += 1
		_update_crop_frame()
	watered_today = false
	_soil_mesh.material_override = _mat_dry
