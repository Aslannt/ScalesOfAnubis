extends Node
## Herramienta de captura visual (PROMPT_PULIDO.md, regla obligatoria).
## Carga Farm.tscn de verdad (con ventana, sin --headless), pone al jugador
## en puntos clave del mapa, fija la hora del día y guarda PNGs en shots/.
## Correr con: godot --path . res://tools/capture.tscn (SIN --headless)

const FARM_SCENE := preload("res://scenes/world/Farm.tscn")

# tile en coordenadas de data/map_layout.json (ver world_builder._tile_to_world)
const SCENARIOS := [
	{"name": "01_granja_dia", "tile": Vector2(13, 14), "phase": 1, "wide": false},
	{"name": "02_granja_atardecer", "tile": Vector2(13, 14), "phase": 2, "wide": false},
	{"name": "03_granja_noche", "tile": Vector2(13, 14), "phase": 3, "wide": false},
	{"name": "04_aldea_dia", "tile": Vector2(26, 10), "phase": 1, "wide": false},
	{"name": "05_aldea_noche", "tile": Vector2(26, 10), "phase": 3, "wide": false},
	{"name": "06_necropolis_noche", "tile": Vector2(26, 21), "phase": 3, "wide": false},
	{"name": "07_orilla_nilo_dia", "tile": Vector2(6, 12), "phase": 1, "wide": false},
	{"name": "08_vista_general_dia", "tile": Vector2(14, 12), "phase": 1, "wide": true},
	{"name": "12_anim_orilla", "tile": Vector2(8, 13), "phase": 1, "wide": false, "frames": 4, "ambient": true},
	{"name": "13_anim_noche", "tile": Vector2(12, 18), "phase": 3, "wide": false, "frames": 3},
	{"name": "10_horizonte_piramides", "tile": Vector2(22, 3), "phase": 1, "wide": true, "pitch": -12.0},
	{"name": "11_horizonte_atardecer", "tile": Vector2(22, 3), "phase": 2, "wide": true, "pitch": -12.0},
]

var farm: Node3D
var world_builder
var player
var camera_rig
var day_night
var _base_offset: Vector3
var _base_pitch: float


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://shots")
	farm = FARM_SCENE.instantiate()
	add_child(farm)
	await get_tree().process_frame
	await get_tree().process_frame

	world_builder = farm.get_node("WorldBuilder")
	camera_rig = farm.get_node("CameraRig")
	day_night = farm.get_node("DayNightController")
	player = get_tree().get_first_node_in_group("player")
	_base_offset = camera_rig.offset
	_base_pitch = camera_rig.rotation_degrees.x

	_plant_demo_crops()
	var only := OS.get_environment("SOA_ONLY")
	for s in SCENARIOS:
		if only != "" and not String(s["name"]).contains(only):
			continue
		await _run_scenario(s)

	print("CAPTURE DONE")
	get_tree().quit()


func _run_scenario(s: Dictionary) -> void:
	GameTime.force_phase(s["phase"])
	day_night.snap_to_current_phase()
	camera_rig.offset = _base_offset * (1.8 if s.get("wide", false) else 1.0)
	player.global_position = world_builder._tile_to_world(s["tile"].x, s["tile"].y) + Vector3(0, 0.2, 0)
	camera_rig.set_target(player)
	camera_rig.rotation_degrees.x = s.get("pitch", _base_pitch)
	for i in range(12):
		await get_tree().process_frame
	if OS.get_environment("SOA_DEBUG_LIGHT") == "1":
		var e = farm.get_node("WorldEnvironment").environment
		var sun := farm.get_node("Sun") as DirectionalLight3D
		print(s["name"], " phase=", GameTime.phase, " sun_color=", sun.light_color, " sun_energy=", sun.light_energy,
			" ambient=", e.ambient_light_energy, " horizon=", e.sky.sky_material.get("sky_horizon_color"),
			" top=", e.sky.sky_material.get("sky_top_color"), " fog_color=", e.fog_light_color,
			" fog_enabled=", e.fog_enabled, " glow=", e.glow_enabled)
	if s.get("ambient", false):
		var amb = farm.get_node("AmbientFX")
		amb._spawn_fish()
		await get_tree().create_timer(0.3).timeout
		get_viewport().get_texture().get_image().save_png("res://shots/%s_pez.png" % s["name"])
		amb._spawn_flock()
		await get_tree().create_timer(3.2).timeout
	var n: int = s.get("frames", 1)
	for f in range(n):
		var img := get_viewport().get_texture().get_image()
		var suffix := "" if n == 1 else "_f%d" % f
		img.save_png("res://shots/%s%s.png" % [s["name"], suffix])
		if n > 1:
			await get_tree().create_timer(0.3).timeout
	print("captured ", s["name"])


## Siembra algunas parcelas en distintas etapas para que las capturas
## muestren cultivos (y el viento sobre ellos).
func _plant_demo_crops() -> void:
	var i := 0
	for plot in world_builder.farm_plots:
		i += 1
		if i % 3 == 0:
			continue
		plot.till()
		var id: String = "papiro" if plot.is_orilla else ("lino" if i % 5 == 0 else "trigo")
		plot.plant(id)
		plot.growth_day = i % 4
		if i % 4 == 1:
			plot.water()
		plot._update_crop_frame()
