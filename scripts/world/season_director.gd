class_name SeasonDirector
extends Node3D
## Estaciones del Nilo en el mundo (fase 3, modo libre):
## - Akhet: el Nilo crece y cubre la orilla (plano de agua que sube); las
##   parcelas de la orilla quedan bajo el agua y los campos se riegan solos.
##   Al bajar el agua, la orilla queda con limo fertil.
## - Shemu: luz mas calida y seca. Peret: la de siempre.
## - Al cambiar de estacion: cartel, comentario de Thot y resumen.

const FLOOD_W := 7.0

var world_builder: WorldBuilder
var day_night: Node
var _flood: MeshInstance3D
var _flood_on := false


func setup(wb: WorldBuilder, dn: Node) -> void:
	world_builder = wb
	day_night = dn
	_build_flood()
	GameTime.phase_changed.connect(_on_phase)
	_apply_season.call_deferred(true)


func _build_flood() -> void:
	var shore := world_builder.river_shore_x
	var depth := float(world_builder.world_h) * world_builder.tile_size
	_flood = BuildingFactory.water_plane(Vector2(FLOOD_W + 1.0, depth), shore + FLOOD_W)
	_flood.position = Vector3(shore + FLOOD_W * 0.5 - 0.5, -0.4, world_builder._tile_to_world(0, float(world_builder.world_h) * 0.5).z)
	_flood.visible = false
	add_child(_flood)


func is_flooded(pos: Vector3) -> bool:
	return _flood_on and pos.x < world_builder.river_shore_x + FLOOD_W


func _on_phase(phase: int) -> void:
	if phase == GameTime.Phase.DAY:
		_apply_season(true)
		_auto_water.call_deferred()


## Aplica luz, agua y parcelas de la estacion actual. 'anunciar': la
## primera vez que se ve esta estacion en este ciclo, cartel y Thot.
func _apply_season(anunciar: bool) -> void:
	var s := GameState.season() if GameState.modo_libre else "peret"
	var tint := Color.WHITE
	var clouds := 0.0
	match s:
		"shemu":
			tint = Color(1.08, 0.97, 0.84)
		"akhet":
			tint = Color(0.9, 0.97, 1.05)
			clouds = 0.12
	if day_night:
		day_night.season_tint = tint
		day_night.season_clouds = clouds
	_set_flood(GameState.season_mod("inunda_orilla") > 0.0)
	var key := "estacion_vista_%s_%d" % [s, GameState.current_day - GameState.season_day() + 1]
	if anunciar and GameState.modo_libre and not GameState.tutorial.get(key, false):
		GameState.tutorial[key] = true
		var banner = get_tree().get_first_node_in_group("combat_banner")
		if banner:
			banner.announce(Textos.t("estacion_llega", {"n": Textos.t("estacion_" + s)}), Textos.t("estacion_desc_" + s), Color(0.6, 0.9, 1.0) if s == "akhet" else Color(1.0, 0.82, 0.35), 3.5)
		SFX.play("jingle_estacion", 0.0, 0.0)
		GameState.thot(Dialogos.thot("estacion_" + s), true)


func _set_flood(on: bool) -> void:
	if on == _flood_on:
		return
	_flood_on = on
	if on:
		_flood.visible = true
		create_tween().tween_property(_flood, "position:y", 0.07, 2.5).set_trans(Tween.TRANS_SINE)
		# la crecida se lleva lo plantado en la orilla (lo maduro se cosecha antes)
		for p in world_builder.farm_plots:
			if p.is_orilla:
				if p.is_ready():
					GameState.add_item(p.crop_id, 2)
				FarmPlot.quiet = true
				if p.state == FarmPlot.State.PLANTED:
					p.harvest_silent()
				FarmPlot.quiet = false
				p.flooded = true
		GameState.orilla_limo = true
	else:
		var tw := create_tween()
		tw.tween_property(_flood, "position:y", -0.4, 2.5).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): _flood.visible = false)
		for p in world_builder.farm_plots:
			p.flooded = false


## Akhet: el agua alta riega todos los campos al amanecer.
func _auto_water() -> void:
	if GameState.season_mod("riego_auto") <= 0.0:
		return
	var n := 0
	for p in world_builder.farm_plots:
		if p.state == FarmPlot.State.PLANTED and not p.watered_today and not p.is_ready() and not p.flooded:
			FarmPlot.quiet = true
			p.water()
			FarmPlot.quiet = false
			n += 1
	if n > 0:
		GameState.thot_once("akhet_riego_%d" % GameState.current_day, Dialogos.thot("akhet_riego"))
