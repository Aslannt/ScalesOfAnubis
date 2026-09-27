class_name Player
extends CharacterBody3D
## Controlador del jugador: movimiento top-down, granja (tecla E, contextual)
## y combate nocturno (clic para atacar hacia el mouse, espacio esquiva).
## Ver GDD 6.2 (granja) y 6.3 (combate).
## - Khopesh: combo de 3 golpes (el tercero pega mas y empuja mas).
## - Martillo: lento, golpe en area que aturde.
## - Buffer de clic: si haces clic durante un golpe, el siguiente sale solo.
## - De dia 1/2/3 eligen semilla; de noche 1/2 eligen arma.

signal died()

@export var speed: float = 5.4
@export var dodge_speed: float = 13.0
@export var dodge_duration: float = 0.22
@export var dodge_cooldown: float = 0.6
@export var interact_range: float = 2.2

var facing: String = "south"
var _move_dir := Vector2.ZERO
var _dodging := false
var _dodge_t := 0.0
var _dodge_cd_t := 0.0
var _invulnerable := false
var _hurt_iframes := 0.0
var _attacking := false
var _attack_t := 0.0
var _combo_index := 0
var _combo_reset_t := 0.0
var _buffered_attack := false
var _knock := Vector3.ZERO
var dead := false

var _anj_timer: float = 0.0
const ANJ_INTERVAL := 6.0
const ANJ_HEAL := 12

var world_builder: WorldBuilder = null
## true si lo ultimo que se toco fue un mando: se apunta con el stick
## derecho (o hacia donde caminas) en vez de con el mouse.
var using_pad := false
var _anim_t: float = 0.0
var _step_t: float = 0.0

const WEAPON_STATS := {
	"khopesh": {"dano": [8, 8, 13], "alcance": 1.7, "cooldown": 0.26, "golpes": 3, "empuje": [2.5, 2.5, 6.0], "aturde": 0.0, "arco": 1.0},
	"martillo": {"dano": [22], "alcance": 2.3, "cooldown": 0.7, "golpes": 1, "empuje": [7.0], "aturde": 0.9, "arco": 1.6},
	# baston (cayado de dia): proyectil de energia a distancia (GDD 6.3)
	"baston": {"dano": [7], "alcance": 0.0, "cooldown": 0.42, "golpes": 1, "empuje": [2.0], "aturde": 0.0, "arco": 0.0},
}
const SLASH_TEX := preload("res://assets/sprites/fx/slash.png")

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var attack_area: Area3D = $AttackArea
@onready var attack_shape: CollisionShape3D = $AttackArea/CollisionShape3D


func _ready() -> void:
	add_to_group("player")
	var frames := SpritesheetLoader.build(
		"res://assets/sprites/characters/player.png",
		"res://assets/sprites/characters/player_layout.json")
	sprite.sprite_frames = frames
	sprite.play("south_idle")
	attack_area.monitoring = false
	GameState.health_changed.connect(_on_health_changed)
	CharacterFX.add_blob_shadow(self, 0.42)
	GameTime.phase_changed.connect(_on_phase_changed)


var _regen_acc: float = 0.0


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_heart_regen(delta)
	_knock = _knock.move_toward(Vector3.ZERO, 18.0 * delta)
	if dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if _dodging:
		velocity = Vector3(_move_dir.x, 0, _move_dir.y) * dodge_speed
	elif not _attacking:
		var input_dir := Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()
		var sp := speed * GameState.heart_mod("vel", 1.0)
		var sdir = get_tree().get_first_node_in_group("season_director")
		if sdir and sdir.is_flooded(global_position):
			sp *= 0.65  # caminar por la crecida cuesta
		velocity.x = input_dir.x * sp + _knock.x
		velocity.z = input_dir.y * sp + _knock.z
		if input_dir.length_squared() > 0.01:
			_move_dir = input_dir
			_update_facing(input_dir)
	else:
		# pequeno avance con cada golpe, frenado rapido
		velocity.x = move_toward(velocity.x, 0, speed * delta * 6) + _knock.x * 0.2
		velocity.z = move_toward(velocity.z, 0, speed * delta * 6) + _knock.z * 0.2

	velocity.y = -9.8 if not is_on_floor() else -0.1
	var before := global_position
	move_and_slide()
	_check_stuck(delta, before)

	if Input.is_action_just_pressed("dodge") and not _dodging and _dodge_cd_t <= 0.0 and _move_dir.length_squared() > 0.01:
		_start_dodge()

	var input_locked := GameState.player_input_locked()
	if not input_locked and Input.is_action_just_pressed("attack") and GameTime.is_night() and not _dodging:
		if _attacking:
			_buffered_attack = true
		else:
			_start_attack()
	if _buffered_attack and not _attacking and not _dodging:
		_buffered_attack = false
		_start_attack()

	if not input_locked and Input.is_action_just_pressed("interact"):
		_try_interact()

	for i in range(3):
		if Input.is_action_just_pressed("tool_%d" % (i + 1)):
			_select_slot(i)
	if Input.is_action_just_pressed("tool_next"):
		_select_slot((_current_slot() + 1) % 3)
	if Input.is_action_just_pressed("tool_prev"):
		_select_slot((_current_slot() + 2) % 3)

	if Input.is_action_just_pressed("amulet"):
		_cycle_amulet()

	_update_amulet_passive(delta)
	_update_animation()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3):
		using_pad = true
	elif event is InputEventMouseMotion or event is InputEventKey or event is InputEventMouseButton:
		using_pad = false


func _current_slot() -> int:
	if GameTime.is_night():
		return maxi(0, ["khopesh", "martillo", "baston"].find(GameState.equipped_weapon))
	return maxi(0, GameState.SEED_IDS.find(GameState.selected_seed))


## Direccion del stick derecho del mando (o Vector2.ZERO).
func _pad_aim() -> Vector2:
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	return v if v.length() > 0.35 else Vector2.ZERO


# --- desatascador (reporte de Deivid: a veces quedaba sin poder moverse) ---
var _stuck_t: float = 0.0


func _check_stuck(delta: float, before: Vector3) -> void:
	var wants := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).length() > 0.5
	var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()
	if wants and not _attacking and not _dodging and moved < speed * delta * 0.1:
		_stuck_t += delta
		if _stuck_t > 1.2:
			_stuck_t = 0.0
			_unstick()
	else:
		_stuck_t = 0.0


## Busca el lugar libre mas cercano (anillos de 0.6 a 3 m) y se mueve ahi.
func _unstick() -> void:
	var space := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	var shape_node: CollisionShape3D = $CollisionShape3D
	params.shape = shape_node.shape
	params.collision_mask = 1
	params.exclude = [get_rid()]
	for r in [0.6, 1.0, 1.6, 2.2, 3.0]:
		for k in range(12):
			var a := TAU * k / 12.0
			var pos := global_position + Vector3(cos(a) * r, 0, sin(a) * r)
			params.transform = Transform3D(Basis(), pos + shape_node.position)
			if space.intersect_shape(params, 1).is_empty():
				global_position = pos
				CharacterFX.dust_puff(get_tree().current_scene, pos + Vector3(0, 0.1, 0), 6)
				return


func _select_slot(i: int) -> void:
	if GameTime.is_night():
		var w: String = ["khopesh", "martillo", "baston"][i]
		if w != "" and w != GameState.equipped_weapon:
			GameState.equipped_weapon = w
			SFX.play("ui_select", -6.0)
	else:
		var id: String = GameState.SEED_IDS[i]
		if id != GameState.selected_seed:
			GameState.select_seed(id)
			SFX.play("ui_select", -6.0)


func _update_timers(delta: float) -> void:
	if _dodge_cd_t > 0.0:
		_dodge_cd_t -= delta
	if _hurt_iframes > 0.0:
		_hurt_iframes -= delta
		sprite.visible = int(_hurt_iframes * 20.0) % 2 == 0 or _hurt_iframes <= 0.0
	if _combo_reset_t > 0.0:
		_combo_reset_t -= delta
		if _combo_reset_t <= 0.0:
			_combo_index = 0
	if _dodging:
		_dodge_t -= delta
		sprite.modulate.a = 0.55
		if _dodge_t <= 0.0:
			_dodging = false
			_invulnerable = false
			sprite.modulate.a = 1.0
	if _attacking:
		_attack_t -= delta
		if _attack_t <= 0.0:
			_attacking = false
			attack_area.monitoring = false


func _start_dodge() -> void:
	_dodging = true
	_invulnerable = true
	_attacking = false
	_buffered_attack = false
	_dodge_t = dodge_duration
	_dodge_cd_t = dodge_cooldown
	SFX.play("dodge")
	CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.1, 0), 7)


func _start_attack() -> void:
	_attacking = true
	_aim_at_mouse()
	var weapon: String = GameState.equipped_weapon
	var stats: Dictionary = WEAPON_STATS[weapon]
	var hit := _combo_index % int(stats["golpes"])
	# la sombra de Ammit da fuerza (estados del corazon)
	var dano: int = int(round((stats["dano"][hit] + GameState.upgrade_effect("dano", weapon)) * GameState.heart_mod("dano", 1.0)))
	var empuje: float = stats["empuje"][hit]
	var is_finisher := weapon == "khopesh" and hit == 2
	if weapon == "baston":
		_fire_staff(dano)
		return
	_attack_t = float(stats["cooldown"]) * (1.4 if is_finisher else 1.0)
	_combo_index = hit + 1
	_combo_reset_t = 0.7
	var shape: SphereShape3D = attack_shape.shape
	shape.radius = float(stats["alcance"])
	var fv := _facing_vector()
	attack_area.position = Vector3(fv.x, 0, fv.z) * (0.9 if weapon == "khopesh" else 1.1)
	attack_area.monitoring = true
	sprite.play("%s_attack" % _facing_group())
	# pequeno paso adelante con cada golpe
	velocity += fv * (2.5 if weapon == "khopesh" else 1.0)
	SFX.play("swing_heavy" if weapon == "martillo" else "swing", 0.0, 0.1)
	_spawn_slash(fv, weapon, hit)
	await get_tree().create_timer(0.1 if weapon == "martillo" else 0.06).timeout
	if weapon == "martillo":
		_hammer_impact(fv)
	_resolve_attack_hits(dano, empuje, float(stats["aturde"]), is_finisher or weapon == "martillo")


func _fire_staff(dano: int) -> void:
	_attack_t = float(WEAPON_STATS["baston"]["cooldown"])
	sprite.play("%s_attack" % _facing_group())
	var dir := _aim_dir_to_mouse()
	SFX.play("bolt", -2.0)
	var b := StaffBolt.new()
	b.damage = dano
	b.dir = dir
	get_tree().current_scene.add_child(b)
	b.global_position = global_position + dir * 0.6 + Vector3(0, 0.9, 0)


func _aim_dir_to_mouse() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	var fv := _facing_vector()
	if using_pad:
		var a := _pad_aim()
		if a != Vector2.ZERO:
			return Vector3(a.x, 0, a.y).normalized()
		if _move_dir.length() > 0.1:
			return Vector3(_move_dir.x, 0, _move_dir.y).normalized()
		return fv
	if cam == null:
		return fv
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var rd := cam.project_ray_normal(mp)
	if absf(rd.y) < 0.0001:
		return fv
	var p := from + rd * (-from.y / rd.y)
	var d := p - global_position
	d.y = 0
	return d.normalized() if d.length() > 0.2 else fv


## Proyectil del baston: vuela recto, atraviesa hasta 2 criaturas.
class StaffBolt extends Node3D:
	var dir := Vector3.FORWARD
	var damage := 7
	var speed := 15.0
	var _life := 0.75
	var _hits: Array = []

	func _ready() -> void:
		var s := Sprite3D.new()
		s.texture = preload("res://assets/sprites/fx/bolt.png")
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.pixel_size = 0.06
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.shaded = false
		s.modulate = Color(0.6, 0.85, 1.0)
		add_child(s)
		var l := OmniLight3D.new()
		l.light_color = Color(0.55, 0.75, 1.0)
		l.light_energy = 1.5
		l.omni_range = 2.5
		add_child(l)

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		global_position += dir * speed * delta
		for e in get_tree().get_nodes_in_group("enemies"):
			if _hits.has(e):
				continue
			var d: Vector3 = e.global_position + Vector3(0, 0.8, 0) - global_position
			if d.length() < 0.9:
				_hits.append(e)
				e.take_hit(damage, dir * 2.0)
				var banner = get_tree().get_first_node_in_group("combat_banner")
				if banner:
					banner.add_hit()
				CombatFX.spawn_damage_number(get_tree().current_scene, e.global_position + Vector3(0, 1.0, 0), damage, Color(0.6, 0.85, 1.0))
				CombatFX.spawn_hit_particles(get_tree().current_scene, global_position, Color(0.6, 0.85, 1.0))
				if _hits.size() >= 2:
					queue_free()
					return


func _spawn_slash(fv: Vector3, weapon: String, hit: int) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var scale_k := 1.6 if weapon == "martillo" else (1.3 if hit == 2 else 1.0)
	pm.size = Vector2(2.6, 1.56) * scale_k
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_texture = SLASH_TEX
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.uv1_scale = Vector3(1.0 / 3.0, 1, 1)
	m.uv1_offset = Vector3(2.0 / 3.0, 0, 0)
	if weapon == "martillo":
		m.albedo_color = Color(1.0, 0.8, 0.55)
	elif hit == 1:
		m.uv1_scale.x = -1.0 / 3.0  # segundo golpe: arco espejado (reves)
		m.uv1_offset.x = 1.0
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = global_position + fv * 0.9 + Vector3(0, 0.55, 0)
	mi.rotation.y = atan2(fv.x, fv.z) + PI
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.16).set_delay(0.04)
	tw.tween_callback(mi.queue_free)


func _hammer_impact(fv: Vector3) -> void:
	var pos := global_position + fv * 1.2
	CharacterFX.dust_puff(get_tree().current_scene, pos + Vector3(0, 0.1, 0), 12, Color(0.8, 0.65, 0.45, 0.9))
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(0.08, 0.12)
	SFX.play("slam", -8.0)


## Ataque hacia la direccion del mouse (GDD 6.3 / 10), no hacia donde
## caminas: proyecta el rayo de camara sobre el plano del suelo (y=0).
func _aim_at_mouse() -> void:
	if using_pad:
		var a := _pad_aim()
		if a != Vector2.ZERO:
			_update_facing(a)
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mouse_pos)
	var ray_dir := cam.project_ray_normal(mouse_pos)
	if absf(ray_dir.y) < 0.0001:
		return
	var t := -from.y / ray_dir.y
	if t <= 0.0:
		return
	var world_point := from + ray_dir * t
	var aim := world_point - global_position
	aim.y = 0
	if aim.length() > 0.05:
		_update_facing(Vector2(aim.x, aim.z))


func _resolve_attack_hits(dano: int, empuje: float, aturde: float, heavy: bool) -> void:
	var hit_any := false
	var fx_root := get_tree().current_scene
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_hit"):
			hit_any = true
			var dir: Vector3 = (body.global_position - global_position)
			dir.y = 0
			dir = dir.normalized() if dir.length() > 0.01 else _facing_vector()
			body.take_hit(dano, dir * empuje, aturde)
			var banner = get_tree().get_first_node_in_group("combat_banner")
			if banner:
				banner.add_hit()
			CombatFX.spawn_damage_number(fx_root, body.global_position + Vector3(0, 1.0, 0), dano, Color(1.0, 0.85, 0.35) if heavy else Color.WHITE)
			CombatFX.spawn_hit_particles(fx_root, body.global_position + Vector3(0, 0.9, 0))
	if hit_any:
		_hitstop(0.05 if heavy else 0.035)
		var cam := get_viewport().get_camera_3d()
		if cam and cam.has_method("shake"):
			cam.shake(0.2 if heavy else 0.1, 0.15)


func _hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _try_interact() -> void:
	if world_builder == null:
		return
	var npc = world_builder.npc_at_world(global_position, 2.4)
	if npc:
		npc.interact()
		return
	if GameTime.is_night():
		return
	var plot := _target_plot()
	if plot == null:
		return
	match plot.state:
		FarmPlot.State.UNTILLED:
			plot.till()
			if GameState.upgrade_effect("arado_area") > 0.0:
				for p in _neighbor_plots(plot):
					if p.state == FarmPlot.State.UNTILLED:
						FarmPlot.quiet = true
						p.till()
						FarmPlot.quiet = false
			GameState.thot_once("t_sembrar", Dialogos.thot("sembrar"))
		FarmPlot.State.TILLED:
			var sid := _seed_for(plot)
			if sid == "":
				SFX.play("hit_player", -12.0)
				return
			if plot.plant(sid):
				GameState.remove_item("semilla_" + sid, 1)
				GameState.thot_once("t_regar", Dialogos.thot("regar"))
		FarmPlot.State.PLANTED:
			if plot.is_ready():
				plot.harvest()
			elif not plot.watered_today:
				plot.water()
				if GameState.upgrade_effect("riego_area") > 0.0:
					for p in _neighbor_plots(plot):
						if p.state == FarmPlot.State.PLANTED and not p.watered_today and not p.is_ready():
							p.water()
				GameState.thot_once("t_regado", Dialogos.thot("regado"))


## Parcelas pegadas a 'plot' (vasija doble y azada de bronce).
func _neighbor_plots(plot: FarmPlot) -> Array:
	var out: Array = []
	for p in world_builder.farm_plots:
		if p != plot and p.global_position.distance_to(plot.global_position) < plot.tile_size * 1.5:
			out.append(p)
	return out


func _target_plot() -> FarmPlot:
	var target_pos := global_position + _facing_vector() * 1.2
	return world_builder.plot_at_world(target_pos, interact_range)


## Semilla a usar en esta parcela: la elegida con 1/2/3 si se puede; si no
## quedan, "" (el HUD explica por que).
func _seed_for(plot: FarmPlot) -> String:
	var sid: String = GameState.selected_seed
	if GameState.seed_count(sid) <= 0:
		return ""
	if not plot.can_plant(sid):
		return ""
	return sid


## Texto de ayuda contextual para el HUD ("[E] Arar", "[E] Hablar con
## Meret"...): tutorial integrado sin muros de texto (GDD 2, pilar 2).
func get_interact_hint() -> String:
	if world_builder == null or get_tree().paused or dead:
		return ""
	var npc = world_builder.npc_at_world(global_position, 2.4)
	if npc:
		if npc.npc_id == "altar":
			return Textos.t("hint_altar")
		if npc.npc_id == "defensa":
			if GameTime.is_night():
				return ""
			return Textos.t("hint_defensa_mejorar") if npc.built != "" else Textos.t("hint_defensa")
		if npc.npc_id == "campamento":
			return Textos.t("hint_camp") if GameTime.phase == GameTime.Phase.DAY else ""
		if npc.npc_id == "shabti" or npc.npc_id == "senet":
			return Textos.t("hint_" + npc.npc_id)
		return Textos.t("hint_hablar", {"n": Textos.t("npc_" + npc.npc_id)})
	if GameTime.is_night():
		return ""
	var plot := _target_plot()
	if plot == null:
		return ""
	if plot.flooded:
		return Textos.t("hint_inundada")
	match plot.state:
		FarmPlot.State.UNTILLED:
			return Textos.t("hint_arar")
		FarmPlot.State.TILLED:
			var sid: String = GameState.selected_seed
			var nombre: String = GameState.crops.get(sid, {}).get("nombre_corto", sid)
			if GameState.seed_count(sid) <= 0:
				return Textos.t("hint_sin_semillas", {"n": nombre})
			if not plot.can_plant(sid):
				return Textos.t("hint_papiro_orilla")
			return Textos.t("hint_sembrar", {"n": nombre})
		FarmPlot.State.PLANTED:
			if plot.is_ready():
				return Textos.t("hint_cosechar")
			if not plot.watered_today:
				return Textos.t("hint_regar")
			return Textos.t("hint_regado")
	return ""


func _facing_vector() -> Vector3:
	match facing:
		"north": return Vector3(0, 0, -1)
		"south": return Vector3(0, 0, 1)
		"east": return Vector3(1, 0, 0)
		"west": return Vector3(-1, 0, 0)
	return Vector3(0, 0, 1)


func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "east" if dir.x > 0 else "west"
	else:
		facing = "south" if dir.y > 0 else "north"


func _facing_group() -> String:
	return "east" if facing == "west" else facing


func _update_animation() -> void:
	sprite.flip_h = facing == "west"
	var delta := get_physics_process_delta_time()
	_anim_t += delta
	if _attacking:
		sprite.offset.y = 0.0
		return
	var group := _facing_group()
	var hvel := Vector2(velocity.x, velocity.z).length()
	if hvel > 0.3 and not _dodging:
		sprite.play("%s_walk" % group)
		sprite.offset.y = 0.0
		# polvo a los pies cada ~2 pasos
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.32
			CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.08, 0), 3)
	else:
		sprite.play("%s_idle" % group)
		sprite.offset.y = CharacterFX.breathe_offset(_anim_t)
		_step_t = 0.0


func _cycle_amulet() -> void:
	var owned: Array = GameState.owned_amulets
	if owned.is_empty():
		return
	if GameState.equipped_amulet == "":
		GameState.equipped_amulet = owned[0]
	else:
		var idx := owned.find(GameState.equipped_amulet)
		if idx == -1 or idx == owned.size() - 1:
			GameState.equipped_amulet = ""
		else:
			GameState.equipped_amulet = owned[idx + 1]
	SFX.play("ui_select", -4.0)
	Codex.unlock("amuletos")


func _update_amulet_passive(delta: float) -> void:
	if GameState.equipped_amulet != "anj":
		return
	if GameState.health >= GameState.max_health:
		_anj_timer = 0.0
		return
	_anj_timer += delta
	if _anj_timer >= ANJ_INTERVAL:
		_anj_timer = 0.0
		GameState.heal(ANJ_HEAL)
		CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 1.0, 0), Color(0.5, 0.95, 0.5))


## Al anochecer las herramientas se transforman en armas (GDD 6.3):
## destello, particulas doradas y el sonido de transformacion.
func _on_phase_changed(phase: int) -> void:
	if phase == GameTime.Phase.NIGHT or phase == GameTime.Phase.DAWN:
		var col := Color(0.7, 0.8, 1.0) if phase == GameTime.Phase.NIGHT else Color(1.0, 0.85, 0.4)
		sprite.modulate = Color(3, 3, 3)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.5)
		for k in range(3):
			CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.6 + k * 0.4, 0), col)


func _on_health_changed(h: int, _m: int) -> void:
	if h <= 0 and not dead:
		if GameState.equipped_amulet == "escarabajo" and not GameState.escarabajo_usado_esta_noche:
			GameState.escarabajo_usado_esta_noche = true
			GameState.health = int(GameState.max_health * 0.5)
			GameState.health_changed.emit(GameState.health, GameState.max_health)
			GameState.thot(Dialogos.thot("escarabajo_uso"), true)
			_hurt_iframes = 2.0
			for k in range(4):
				CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.5 + k * 0.3, 0), Color(0.3, 0.6, 1.0))
			return
		dead = true
		_attacking = false
		sprite.modulate = Color(0.5, 0.3, 0.6)
		died.emit()
	elif h > 0 and h <= GameState.max_health * 0.3:
		GameState.thot_once("vida_baja", Dialogos.thot("vida_baja"), true)


## Devuelve el control despues de una derrota (StoryDirector).
func revive() -> void:
	dead = false
	_knock = Vector3.ZERO
	_hurt_iframes = 1.5
	sprite.modulate = Color.WHITE
	sprite.visible = true


## Favor de Maat: de noche la vida vuelve sola, poco a poco.
func _heart_regen(delta: float) -> void:
	var r := GameState.heart_mod("regen_noche", 0.0)
	if r <= 0.0 or dead or not GameTime.is_night() or GameState.health >= GameState.max_health:
		return
	_regen_acc += r * delta
	if _regen_acc >= 1.0:
		var n := int(_regen_acc)
		_regen_acc -= n
		GameState.heal(n)


func take_hit(amount: int, knockback: Vector3 = Vector3.ZERO, _stun: float = 0.0) -> void:
	if _invulnerable or _hurt_iframes > 0.0 or dead:
		return
	_hurt_iframes = 0.45
	GameState.take_damage(amount)
	_knock = knockback
	SFX.play("hit_player")
	CombatFX.spawn_damage_number(get_tree().current_scene, global_position + Vector3(0, 1.4, 0), amount, Color(1.0, 0.35, 0.3))
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(0.14, 0.15)
	sprite.modulate = Color(2.2, 1.1, 1.1)
	await get_tree().create_timer(0.1).timeout
	if not dead:
		sprite.modulate = Color(1, 1, 1)
