class_name DefenseSpot
extends Node3D
## Pedestal donde se construye una defensa de dia (GDD 6.5). Se interactua
## con E como con un aldeano (WorldBuilder lo mete en la lista de npcs).

const DATA_PATH := "res://data/defenses.json"
static var _data: Dictionary = {}

var npc_id: String = "defensa"
var built: String = ""  # "" | "muro" | "brasero" | "estatua"
var level: int = 0
var spent: int = 0  # deben invertidos (para el reembolso al cambiar de tipo)
var _defense: Node3D
var _pips: Node3D
var _spike_t: float = 0.0
var _base: Node3D
var _ring: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	add_to_group("defense_spots")
	_base = Node3D.new()
	add_child(_base)
	var stone := BuildingFactory._mat("stone")
	_base.add_child(BuildingFactory._box(Vector3(1.4, 0.12, 1.4), stone, Vector3(0, 0.06, 0)))
	_base.add_child(BuildingFactory._box(Vector3(1.2, 0.18, 1.2), stone, Vector3(0, 0.21, 0)))
	# filo dorado fino alrededor de la losa superior
	var gold := BuildingFactory._solid_mat(Color(0.86, 0.66, 0.22))
	for side in [-1, 1]:
		_base.add_child(BuildingFactory._box(Vector3(1.22, 0.04, 0.04), gold, Vector3(0, 0.3, side * 0.6)))
		_base.add_child(BuildingFactory._box(Vector3(0.04, 0.04, 1.22), gold, Vector3(side * 0.6, 0.3, 0)))
	# anillo que late suave para que se note que es "construible"
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 0.95
	torus.rings = 24
	torus.ring_segments = 4
	_ring.mesh = torus
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.85, 0.4, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = m
	_ring.position.y = 0.04
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	var body := BuildingFactory._collision_box(Vector3(1.2, 0.3, 1.2))
	add_child(body)


func _process(delta: float) -> void:
	_t += delta
	if built == "muro" and level >= 2:
		_wall_spikes(delta)
	if _ring.visible:
		_ring.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.05)
		(_ring.material_override as StandardMaterial3D).albedo_color.a = 0.3 + 0.25 * (0.5 + 0.5 * sin(_t * 3.0))


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(DATA_PATH, FileAccess.READ)
		if f:
			_data = JSON.parse_string(f.get_as_text())
	return _data


static func tier(kind: String, lv: int) -> Dictionary:
	var arr: Array = data().get(kind, [])
	if lv < 1 or lv > arr.size():
		return {}
	return arr[lv - 1]


static func max_level(kind: String) -> int:
	return (data().get(kind, []) as Array).size()


static func unlocked(kind: String, lv: int) -> bool:
	return GameState.current_day >= int(tier(kind, lv).get("dia", 99))


static func desc(kind: String, lv: int) -> String:
	var t := tier(kind, lv)
	var x = t.get("dano", t.get("espinas", 0))
	return Textos.t("def_desc_%s_%d" % [kind, lv], {"x": x})


func refund() -> int:
	return int(floor(spent * float(data().get("reembolso", 0.5))))


func interact() -> void:
	if GameTime.is_night():
		if built != "":
			GameState.thot(Dialogos.thot(built), true)
		return
	var box = get_tree().get_first_node_in_group("choice_box")
	if box == null:
		return
	var opts: Array = []
	var descs: Array = []
	var locked: Array = []
	var actions: Array = []  # [accion, tipo, costo]
	if built == "":
		for kind in data().get("orden", []):
			var t := tier(kind, 1)
			if unlocked(kind, 1):
				opts.append(Textos.t("def_comprar", {"n": Textos.t("def_nombre_" + kind), "p": int(t["costo"])}))
				descs.append(desc(kind, 1))
				locked.append(false)
			else:
				opts.append(Textos.t("def_bloqueada", {"d": int(t["dia"])}))
				descs.append(Textos.t("def_desc_bloqueada"))
				locked.append(true)
			actions.append(["comprar", kind, int(t.get("costo", 0))])
		box.ask(Textos.t("defensa_titulo", {"d": GameState.deben}), opts + [Textos.t("cancelar")], _on_choice.bind(actions), descs + [Textos.t("def_desc_salir")], locked + [false])
		return
	# ya construida: mejorar o cambiar de tipo
	if level < max_level(built):
		var nt := tier(built, level + 1)
		if unlocked(built, level + 1):
			opts.append(Textos.t("def_mejorar", {"l": level + 1, "p": int(nt["costo"])}))
			descs.append(desc(built, level + 1))
			locked.append(false)
		else:
			opts.append(Textos.t("def_mejora_bloqueada", {"l": level + 1, "d": int(nt["dia"])}))
			descs.append(Textos.t("def_desc_bloqueada"))
			locked.append(true)
		actions.append(["mejorar", built, int(nt.get("costo", 0))])
	else:
		opts.append(Textos.t("def_max"))
		descs.append(Textos.t("def_desc_max"))
		locked.append(true)
		actions.append(["nada", built, 0])
	for kind in data().get("orden", []):
		if kind == built:
			continue
		var t := tier(kind, 1)
		var net := maxi(0, int(t["costo"]) - refund())
		if unlocked(kind, 1):
			opts.append(Textos.t("def_cambiar", {"n": Textos.t("def_nombre_" + kind), "p": net}))
			descs.append(desc(kind, 1) + " " + Textos.t("def_desc_cambiar", {"r": refund()}))
			locked.append(false)
		else:
			opts.append(Textos.t("def_bloqueada", {"d": int(t["dia"])}))
			descs.append(Textos.t("def_desc_bloqueada"))
			locked.append(true)
		actions.append(["cambiar", kind, net])
	var title := Textos.t("defensa_titulo_hecha", {"n": Textos.t("def_nombre_" + built), "l": level, "d": GameState.deben})
	box.ask(title, opts + [Textos.t("def_salir")], _on_choice.bind(actions), descs + [Textos.t("def_desc_salir")], locked + [false])


func _on_choice(i: int, actions: Array) -> void:
	if i < 0 or i >= actions.size():
		return
	var a: Array = actions[i]
	var cost: int = a[2]
	if a[0] == "nada":
		return
	if not GameState.can_afford(cost):
		GameState.thot(Textos.t("sin_dinero"), true)
		SFX.play("hit_player", -10.0)
		return
	GameState.add_deben(-cost)
	match a[0]:
		"comprar":
			build(a[1])
		"mejorar":
			spent += cost
			set_level(level + 1)
		"cambiar":
			demolish()
			build(a[1])


## Construye 'kind' en nivel 1 (o en 'lv' al cargar partida).
func build(kind: String, lv: int = 1) -> void:
	built = kind
	_ring.visible = false
	_base.visible = kind != "muro"
	if kind != "muro":
		_defense = JackalStatue.new() if kind == "estatua" else Brazier.new()
		_defense.position.y = 0.3
		add_child(_defense)
	lv = clampi(lv, 1, max_level(kind))
	spent = 0
	for k in range(1, lv + 1):
		spent += int(tier(kind, k).get("costo", 0))
	_set_level_quiet(lv)
	var d := _defense
	SFX.play("build")
	_build_fx()
	d.scale = Vector3(1, 0.1, 1)
	create_tween().tween_property(d, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameState.register_decision("defensa_" + str(get_index()), kind)
	GameState.thot_once("thot_" + kind, Dialogos.thot(kind))


## Sube de nivel con fanfarria.
func set_level(lv: int) -> void:
	_set_level_quiet(lv)
	SFX.play("build")
	SFX.play("coin", -6.0)
	_build_fx()
	CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 1.4, 0), Color(1.0, 0.95, 0.6))
	if _defense:
		_defense.scale = Vector3(1.25, 0.8, 1.25)
		create_tween().tween_property(_defense, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	GameState.thot(Textos.t("def_mejorada", {"n": Textos.t("def_nombre_" + built), "l": lv}))


func _set_level_quiet(lv: int) -> void:
	level = lv
	var st := tier(built, lv)
	if built == "muro":
		# el muro cambia de forma: se reconstruye
		if _defense:
			_defense.queue_free()
		_defense = _make_wall(lv)
		add_child(_defense)
		_rebake()
	elif _defense and _defense.has_method("set_level"):
		_defense.set_level(lv, st)
	_update_pips()


func demolish() -> void:
	if _defense:
		CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.3, 0), 16)
		_defense.queue_free()
		_defense = null
	var was_wall := built == "muro"
	built = ""
	level = 0
	_base.visible = true
	_ring.visible = true
	_update_pips()
	if was_wall:
		_rebake()


func save_code() -> String:
	return "" if built == "" else "%s:%d" % [built, level]


func load_code(code: String) -> void:
	if code == "":
		return
	var parts := code.split(":")
	build(parts[0], int(parts[1]) if parts.size() > 1 else 1)


func _rebake() -> void:
	var wb = get_tree().get_first_node_in_group("world_builder")
	if wb:
		wb.rebake_navigation.call_deferred()


func _build_fx() -> void:
	CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.6, 0), Color(1.0, 0.85, 0.4))
	CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.2, 0), 12)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(0.08, 0.2)


## Gemas doradas en el borde del pedestal: una por nivel.
func _update_pips() -> void:
	if _pips:
		_pips.queue_free()
		_pips = null
	if built == "" or built == "muro":
		return
	_pips = Node3D.new()
	add_child(_pips)
	var gem := BuildingFactory._solid_mat(Color(0.3, 0.75, 0.95))
	gem.emission_enabled = true
	gem.emission = Color(0.2, 0.6, 0.9)
	gem.emission_energy_multiplier = 0.6
	for i in range(level):
		_pips.add_child(BuildingFactory._box(Vector3(0.12, 0.08, 0.06), gem, Vector3((i - (level - 1) * 0.5) * 0.22, 0.24, 0.62)))


## Muro de adobe (GDD 6.5, opcional): bloquea y canaliza. Se orienta
## perpendicular al lado del campo por donde llegan las criaturas.
func _make_wall(lv: int) -> Node3D:
	var root := Node3D.new()
	var farm_center := Vector3(-11, 0, -1)
	var off := global_position - farm_center
	var along_z := absf(off.x) > absf(off.z)
	var h := float(tier("muro", lv).get("alto", 1.3))
	var size := Vector3(0.6, h, 3.6) if along_z else Vector3(3.6, h, 0.6)
	var body_mat := BuildingFactory._mat("stone") if lv >= 3 else BuildingFactory._mat("adobe", Vector3(2, 1, 1))
	root.add_child(BuildingFactory._box(size, body_mat, Vector3(0, size.y * 0.5, 0)))
	var cap := size + Vector3(0.1, 0, 0.1)
	cap.y = 0.12
	root.add_child(BuildingFactory._box(cap, BuildingFactory._mat("plaster"), Vector3(0, size.y + 0.06, 0)))
	if lv >= 2:
		# espinas de acacia (Nv2) o de bronce (Nv3) a lo largo de ambas caras
		var spike := BuildingFactory._solid_mat(Color(0.78, 0.55, 0.25) if lv >= 3 else Color(0.45, 0.32, 0.18))
		var long := maxf(size.x, size.z)
		var n := 7
		for side in [-1, 1]:
			for k in range(n):
				var t := (k + 0.5) / n * long - long * 0.5
				var p := Vector3(side * (size.x * 0.5 + 0.08), 0.35 + 0.25 * (k % 2), t) if along_z else Vector3(t, 0.35 + 0.25 * (k % 2), side * (size.z * 0.5 + 0.08))
				var sp := BuildingFactory._box(Vector3(0.22, 0.05, 0.05) if along_z else Vector3(0.05, 0.05, 0.22), spike, p)
				root.add_child(sp)
	var body := BuildingFactory._collision_box(size)
	root.add_child(body)
	root.set_meta("size", size)
	return root


## Espinas del muro Nv2+: dañan a las criaturas que lo tocan.
func _wall_spikes(delta: float) -> void:
	var dmg := int(tier("muro", level).get("espinas", 0))
	if dmg <= 0 or _defense == null or not GameTime.is_night():
		return
	_spike_t -= delta
	if _spike_t > 0.0:
		return
	_spike_t = 0.6
	var size: Vector3 = _defense.get_meta("size", Vector3.ONE)
	for e in get_tree().get_nodes_in_group("enemies"):
		var lp: Vector3 = to_local(e.global_position)
		if absf(lp.x) < size.x * 0.5 + 0.7 and absf(lp.z) < size.z * 0.5 + 0.7:
			var push: Vector3 = e.global_position - global_position
			push.y = 0
			e.take_hit(dmg, push.normalized() * 2.5)
			CombatFX.spawn_hit_particles(get_tree().current_scene, e.global_position + Vector3(0, 0.5, 0), Color(0.9, 0.7, 0.4))
