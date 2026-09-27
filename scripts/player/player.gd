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

@export var speed: float = 4.2
@export var dodge_speed: float = 11.0
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
var _anim_t: float = 0.0
var _step_t: float = 0.0

const WEAPON_STATS := {
	"khopesh": {"dano": [8, 8, 13], "alcance": 1.7, "cooldown": 0.26, "golpes": 3, "empuje": [2.5, 2.5, 6.0], "aturde": 0.0, "arco": 1.0},
	"martillo": {"dano": [22], "alcance": 2.3, "cooldown": 0.7, "golpes": 1, "empuje": [7.0], "aturde": 0.9, "arco": 1.6},
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


func _physics_process(delta: float) -> void:
	_update_timers(delta)
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
		velocity.x = input_dir.x * speed + _knock.x
		velocity.z = input_dir.y * speed + _knock.z
		if input_dir.length_squared() > 0.01:
			_move_dir = input_dir
			_update_facing(input_dir)
	else:
		# pequeno avance con cada golpe, frenado rapido
		velocity.x = move_toward(velocity.x, 0, speed * delta * 6) + _knock.x * 0.2
		velocity.z = move_toward(velocity.z, 0, speed * delta * 6) + _knock.z * 0.2

	velocity.y = -9.8 if not is_on_floor() else -0.1
	move_and_slide()

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

	if Input.is_action_just_pressed("amulet"):
		_cycle_amulet()

	_update_amulet_passive(delta)
	_update_animation()


func _select_slot(i: int) -> void:
	if GameTime.is_night():
		var w := "khopesh" if i == 0 else ("martillo" if i == 1 else "")
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
	var dano: int = stats["dano"][hit]
	var empuje: float = stats["empuje"][hit]
	var is_finisher := weapon == "khopesh" and hit == 2
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
		cam.shake(0.14, 0.18)
	SFX.play("slam", -8.0)


## Ataque hacia la direccion del mouse (GDD 6.3 / 10), no hacia donde
## caminas: proyecta el rayo de camara sobre el plano del suelo (y=0).
func _aim_at_mouse() -> void:
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
			CombatFX.spawn_damage_number(fx_root, body.global_position + Vector3(0, 1.0, 0), dano, Color(1.0, 0.85, 0.35) if heavy else Color.WHITE)
			CombatFX.spawn_hit_particles(fx_root, body.global_position + Vector3(0, 0.9, 0))
	if hit_any:
		_hitstop(0.08 if heavy else 0.045)
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
				GameState.thot_once("t_regado", Dialogos.thot("regado"))


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
			return "" if (npc.built != "" or GameTime.is_night()) else Textos.t("hint_defensa")
		return Textos.t("hint_hablar", {"n": Textos.t("npc_" + npc.npc_id)})
	if GameTime.is_night():
		return ""
	var plot := _target_plot()
	if plot == null:
		return ""
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
			GameState.thot(Dialogos.thot("escarabajo_uso"))
			_hurt_iframes = 2.0
			for k in range(4):
				CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.5 + k * 0.3, 0), Color(0.3, 0.6, 1.0))
			return
		dead = true
		_attacking = false
		sprite.modulate = Color(0.5, 0.3, 0.6)
		died.emit()
	elif h > 0 and h <= GameState.max_health * 0.3:
		GameState.thot_once("vida_baja", Dialogos.thot("vida_baja"))


## Devuelve el control despues de una derrota (StoryDirector).
func revive() -> void:
	dead = false
	_knock = Vector3.ZERO
	_hurt_iframes = 1.5
	sprite.modulate = Color.WHITE
	sprite.visible = true


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
		cam.shake(0.22, 0.22)
	sprite.modulate = Color(3, 1.2, 1.2)
	await get_tree().create_timer(0.1).timeout
	if not dead:
		sprite.modulate = Color(1, 1, 1)
