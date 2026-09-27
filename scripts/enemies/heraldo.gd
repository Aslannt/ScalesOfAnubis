class_name Heraldo
extends EnemyBase
## Heraldo de Ammit, jefe de la noche 3 (GDD 6.4): embestida con aviso,
## rugido que invoca crias y golpe de area. Barra de vida grande con nombre
## (la dibuja el HUD al recibir NightDirector.boss_spawned). Retiene la
## noche hasta morir (GameTime.hold_night).

signal health_changed_boss(hp: int, max_hp: int)
signal defeated()

enum S { INTRO, CHASE, CHARGE_WINDUP, CHARGE, RECOVER, ROAR, SLAM_WINDUP, SLAM }

const CHARGE_SPEED := 13.0
const CHARGE_TIME := 1.1
const CHARGE_DAMAGE := 22
const SLAM_RADIUS := 3.4
const SLAM_DAMAGE := 18
const MAX_CRIAS := 6

var state: S = S.INTRO
var _state_t: float = 0.0
var _decide_t: float = 2.5
var _roar_t: float = 10.0
var _charge_dir := Vector3.ZERO
var _charge_hit := false
var _telegraph: MeshInstance3D = null
var _enraged := false
var _intro_done := false


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	_spawn_t = 1.2
	_enter(S.INTRO)


func _enter(s: S) -> void:
	state = s
	_state_t = 0.0
	_clear_telegraph()
	match s:
		S.INTRO:
			sprite.play("roar")
		S.CHASE:
			sprite.play("walk")
		S.CHARGE_WINDUP:
			sprite.play("windup")
			var p := _player()
			_charge_dir = (p.global_position - global_position) if p else Vector3.RIGHT
			_charge_dir.y = 0
			_charge_dir = _charge_dir.normalized()
			sprite.flip_h = _charge_dir.x < 0
			_telegraph = _make_telegraph_line(_charge_dir, CHARGE_SPEED * CHARGE_TIME)
			SFX.play("charge_windup")
		S.CHARGE:
			sprite.play("charge")
			_charge_hit = false
			SFX.play("charge")
		S.RECOVER:
			sprite.play("idle")
		S.ROAR:
			sprite.play("roar")
			SFX.play("roar")
			_shake(0.25, 0.6)
			GameState.thot_once("jefe_rugido", Dialogos.thot("jefe_rugido"))
		S.SLAM_WINDUP:
			sprite.play("slam")
			sprite.frame = 0
			sprite.pause()
			_telegraph = _make_telegraph_circle(SLAM_RADIUS)
			SFX.play("charge_windup", 2.0)
		S.SLAM:
			sprite.frame = 1
			_do_slam()


func _windup_time() -> float:
	return 0.7 if _enraged else 0.95


func _physics_process(delta: float) -> void:
	_knock = _knock.move_toward(Vector3.ZERO, 20.0 * delta)
	_contact_t = maxf(0.0, _contact_t - delta)
	_state_t += delta
	if _spawn_t > 0.0:
		_spawn_t -= delta
		return
	var p := _player()
	var move := Vector3.ZERO
	match state:
		S.INTRO:
			if not _intro_done:
				_intro_done = true
				SFX.play("roar")
				_shake(0.3, 0.8)
				GameState.thot(Dialogos.thot("jefe"))
			if _state_t > 1.4:
				_enter(S.CHASE)
		S.CHASE:
			if p:
				var dir := p.global_position - global_position
				dir.y = 0
				if dir.length() > 2.0:
					move = dir.normalized() * (speed * (1.3 if _enraged else 1.0))
				sprite.flip_h = dir.x < 0
				_touch_damage(p)
			_decide_t -= delta
			_roar_t -= delta
			if _decide_t <= 0.0 and p:
				_decide_t = randf_range(1.8, 2.8) * (0.75 if _enraged else 1.0)
				var dist := global_position.distance_to(p.global_position)
				if _roar_t <= 0.0 and _count_crias() < MAX_CRIAS:
					_roar_t = randf_range(11.0, 15.0)
					_enter(S.ROAR)
				elif dist < 4.0:
					_enter(S.SLAM_WINDUP)
				elif dist > 5.5 or randf() < 0.5:
					_enter(S.CHARGE_WINDUP)
		S.CHARGE_WINDUP:
			# tiembla antes de salir disparado
			sprite.position.x = sin(_state_t * 60.0) * 0.05
			if _state_t >= _windup_time():
				sprite.position.x = 0
				_enter(S.CHARGE)
		S.CHARGE:
			move = _charge_dir * CHARGE_SPEED
			if not _charge_hit and p and global_position.distance_to(p.global_position) < 2.3:
				_charge_hit = true
				p.take_hit(CHARGE_DAMAGE, _charge_dir * 8.0)
			if int(_state_t * 12.0) % 2 == 0:
				CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.2, 0), 3)
			if _state_t >= CHARGE_TIME or (_state_t > 0.2 and get_slide_collision_count() > 0 and velocity.length() < 2.0):
				_shake(0.15, 0.25)
				_enter(S.RECOVER)
		S.RECOVER:
			if _state_t >= 1.1:
				_enter(S.CHASE)
		S.ROAR:
			if _state_t > 0.5 and _state_t - get_physics_process_delta_time() <= 0.5:
				_summon()
			if _state_t >= 1.5:
				_enter(S.CHASE)
		S.SLAM_WINDUP:
			if _telegraph:
				var k := clampf(_state_t / _windup_time(), 0.0, 1.0)
				_telegraph.scale = Vector3(k, 1, k)
			if _state_t >= _windup_time():
				_enter(S.SLAM)
		S.SLAM:
			if _state_t >= 0.9:
				_enter(S.CHASE)
	velocity.x = move.x + _knock.x
	velocity.z = move.z + _knock.z
	velocity.y = -9.8 if not is_on_floor() else -0.1
	move_and_slide()


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player")


func _touch_damage(p: Node3D) -> void:
	if _contact_t > 0.0:
		return
	if global_position.distance_to(p.global_position) < contact_range:
		var kb := p.global_position - global_position
		kb.y = 0
		p.take_hit(contact_damage, kb.normalized() * 5.0)
		_contact_t = contact_cooldown


func _do_slam() -> void:
	SFX.play("slam")
	_shake(0.45, 0.5)
	var root := get_tree().current_scene
	for k in range(3):
		CharacterFX.dust_puff(root, global_position + Vector3(cos(k * 2.1) * 1.5, 0.2, sin(k * 2.1) * 1.5), 10, Color(0.8, 0.6, 0.4, 0.9))
	_shockwave_ring()
	var p := _player()
	if p and global_position.distance_to(p.global_position) <= SLAM_RADIUS:
		var kb := p.global_position - global_position
		kb.y = 0
		p.take_hit(SLAM_DAMAGE, kb.normalized() * 7.0)


func _summon() -> void:
	var nd = get_tree().get_first_node_in_group("night_director")
	if nd == null:
		return
	var n := 3 if _enraged else 2
	for i in range(n):
		var a := TAU * i / n + randf() * 0.5
		nd.spawn("cria", "", "", global_position + Vector3(cos(a) * 2.5, 0, sin(a) * 2.5))


func _count_crias() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Cria:
			n += 1
	return n


func take_hit(amount: int, knockback: Vector3 = Vector3.ZERO, _stun: float = 0.0) -> void:
	if _dead or state == S.INTRO:
		return
	# mas dano si le pegas mientras se recupera de la embestida (ventana)
	if state == S.RECOVER:
		amount = int(amount * 1.5)
	health -= amount
	_knock = knockback * 0.15
	health_changed_boss.emit(maxi(health, 0), max_health)
	SFX.play("hit_enemy", 2.0)
	sprite.modulate = Color(4, 4, 4)
	get_tree().create_timer(0.06).timeout.connect(func():
		if is_instance_valid(sprite) and not _dead:
			sprite.modulate = Color(1.4, 0.8, 0.8) if _enraged else Color.WHITE)
	if not _enraged and health <= max_health / 2:
		_enraged = true
		GameState.thot(Dialogos.thot("jefe_mitad"))
		_roar_t = 0.0
		_decide_t = 0.3
	if health <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	_clear_telegraph()
	GameState.total_enemies_defeated += 1
	GameState.enemies_defeated_tonight += 1
	GameState.boss_defeated = true
	Codex.unlock("heraldo")
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemies")
	set_physics_process(false)
	sprite.play("hurt")
	SFX.play("roar", -2.0)
	_shake(0.5, 1.2)
	Engine.time_scale = 0.3
	var root := get_tree().current_scene
	for k in range(6):
		get_tree().create_timer(k * 0.12, true, false, true).timeout.connect(func():
			if not is_instance_valid(self):
				return
			CombatFX.spawn_hit_particles(root, global_position + Vector3(randf_range(-1.5, 1.5), randf_range(0.5, 2.5), 0), Color(0.6, 0.3, 0.8))
			CharacterFX.dust_puff(root, global_position + Vector3(randf_range(-1.5, 1.5), 0.4, randf_range(-1, 1)), 8, Color(0.3, 0.15, 0.4, 0.9)))
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		Engine.time_scale = 1.0
		GameState.thot(Dialogos.thot("jefe_muerto"))
		defeated.emit())
	tw.tween_property(sprite, "modulate", Color(0.5, 0.2, 0.7, 0.0), 1.2)
	tw.parallel().tween_property(sprite, "position:y", sprite.position.y + 1.0, 1.2)
	tw.tween_callback(queue_free)


func vanish() -> void:
	pass  # el jefe no se va con el amanecer: la noche lo espera


## Reintento tras una derrota del jugador: vida llena, sin avisos colgando.
func reset_for_retry(pos: Vector3) -> void:
	health = max_health
	_enraged = false
	sprite.modulate = Color.WHITE
	sprite.position.x = 0
	global_position = pos
	health_changed_boss.emit(health, max_health)
	_decide_t = 2.5
	_roar_t = 10.0
	_enter(S.CHASE)


func _exit_tree() -> void:
	_clear_telegraph()


# --------------------------------------------------------- telegrafos
func _telegraph_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.3, 0.15, 0.25)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = false
	return m


func _make_telegraph_line(dir: Vector3, length: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.4, length)
	mi.mesh = pm
	mi.material_override = _telegraph_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = global_position + dir * (length * 0.5) + Vector3(0, 0.05, 0)
	mi.rotation.y = atan2(dir.x, dir.z)
	var tw := mi.create_tween().set_loops()
	tw.tween_property(mi.material_override, "albedo_color:a", 0.45, 0.15)
	tw.tween_property(mi.material_override, "albedo_color:a", 0.18, 0.15)
	return mi


func _make_telegraph_circle(radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.02
	cm.radial_segments = 32
	mi.mesh = cm
	mi.material_override = _telegraph_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.05, 0)
	mi.scale = Vector3(0.05, 1, 0.05)
	return mi


func _clear_telegraph() -> void:
	if _telegraph and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null


func _shockwave_ring() -> void:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 3
	mi.mesh = torus
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.85, 0.6, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	get_tree().current_scene.add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.1, 0)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(SLAM_RADIUS, 1, SLAM_RADIUS), 0.3).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(mi.queue_free)


func _shake(amount: float, dur: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(amount, dur)
