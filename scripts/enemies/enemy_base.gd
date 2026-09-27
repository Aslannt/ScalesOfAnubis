class_name EnemyBase
extends CharacterBody3D
## Base para las criaturas de Ammit (GDD 6.4). Sombra y Cria heredan de esta.
## - Persiguen a su objetivo con separacion entre ellas (no se apilan).
## - Antes de golpear hacen un aviso visible (se tinen de rojo y se agachan):
##   el jugador puede leer el golpe y esquivar (GDD 6.3).
## - Empuje real que decae (antes duraba un solo frame) y aturdimiento.
## - group_id "aldea": van al centro de la aldea y la saquean si nadie las
##   detiene (decision moral 2, GDD 6.7). Si el jugador se acerca, pelean.

@export var max_health: int = 20
@export var speed: float = 2.0
@export var contact_damage: int = 8
@export var contact_range: float = 1.3
@export var contact_cooldown: float = 1.0
@export var windup_time: float = 0.35
@export var sheet_path: String = ""
@export var layout_path: String = ""
@export var idle_anim: String = "idle"
@export var move_anim: String = "move"
@export var shadow_radius: float = 0.5
@export var coin_value: int = 2
## Embestida corta: a media distancia se preparan (rojo) y se lanzan.
@export var can_lunge: bool = false
var _lunge_cd: float = 2.0
var _lunge_t: float = 0.0
var _lunge_dir := Vector3.ZERO
var _lunge_windup: float = -1.0

var group_id: String = ""
var health: int
var target: Node3D = null
var _contact_t: float = 0.0
var _knock := Vector3.ZERO
var _stun_t: float = 0.0
var _windup_t: float = -1.0
var _spawn_t: float = 0.6
var _dead := false
var _village_tick: float = 0.0
var _base_sprite_y: float = 0.0

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	CharacterFX.add_blob_shadow(self, shadow_radius)
	if sheet_path != "":
		sprite.sprite_frames = SpritesheetLoader.build(sheet_path, layout_path, 6.0)
		sprite.play(idle_anim)
	_base_sprite_y = sprite.position.y
	# aparicion: brota del suelo con un remolino oscuro
	sprite.position.y = _base_sprite_y - 1.0
	sprite.modulate = Color(0.3, 0.2, 0.5, 0.0)
	var tw := create_tween()
	tw.tween_property(sprite, "position:y", _base_sprite_y, _spawn_t).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "modulate", Color.WHITE, _spawn_t)
	CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.1, 0), 10, Color(0.35, 0.2, 0.55, 0.9))


func _physics_process(delta: float) -> void:
	_contact_t = maxf(0.0, _contact_t - delta)
	_knock = _knock.move_toward(Vector3.ZERO, 14.0 * delta)
	if _spawn_t > 0.0:
		_spawn_t -= delta
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if _stun_t > 0.0:
		_stun_t -= delta
		velocity = Vector3(_knock.x, -0.1, _knock.z)
		move_and_slide()
		sprite.play(idle_anim)
		return

	target = _choose_target()
	var move := Vector3.ZERO
	if can_lunge and _update_lunge(delta):
		return
	if _windup_t >= 0.0:
		_windup_t -= delta
		if _windup_t < 0.0:
			_strike()
	elif target:
		var dir: Vector3 = target.global_position - global_position
		dir.y = 0
		var stop := _stop_distance()
		if dir.length() > stop:
			move = dir.normalized() * speed
			sprite.flip_h = dir.x < 0
		move += _separation() * speed * 0.8
	if move.length() > 0.1:
		sprite.play(move_anim)
	else:
		sprite.play(idle_anim)
	velocity.x = move.x + _knock.x
	velocity.z = move.z + _knock.z
	velocity.y = -9.8 if not is_on_floor() else -0.1
	move_and_slide()
	_check_contact(delta)


## Maneja la embestida; devuelve true si este frame la controla.
func _update_lunge(delta: float) -> bool:
	_lunge_cd -= delta
	if _lunge_t > 0.0:
		_lunge_t -= delta
		velocity = _lunge_dir * 9.0 + Vector3(0, -0.1, 0)
		move_and_slide()
		if target and target.has_method("take_hit") and _contact_t <= 0.0 and global_position.distance_to(target.global_position) < contact_range:
			target.take_hit(contact_damage, _lunge_dir * 4.0)
			_contact_t = contact_cooldown
		if _lunge_t <= 0.0:
			sprite.modulate = Color.WHITE
			sprite.scale = Vector3.ONE
		return true
	if _lunge_windup >= 0.0:
		_lunge_windup -= delta
		velocity = Vector3(0, -0.1, 0)
		move_and_slide()
		if _lunge_windup < 0.0:
			_lunge_t = 0.28
			SFX.play("dodge", -6.0)
			CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.1, 0), 4, Color(0.3, 0.2, 0.4, 0.9))
		return true
	if target and target.is_in_group("player") and _lunge_cd <= 0.0 and _windup_t < 0.0:
		var d := target.global_position - global_position
		d.y = 0
		if d.length() > 2.2 and d.length() < 4.5:
			_lunge_cd = randf_range(3.0, 4.5)
			_lunge_windup = 0.45
			_lunge_dir = d.normalized()
			sprite.flip_h = d.x < 0
			sprite.modulate = Color(1.9, 0.5, 0.45)
			create_tween().tween_property(sprite, "scale", Vector3(1.2, 0.8, 1.0), 0.35)
			return true
	return false


func _stop_distance() -> float:
	if target and target.is_in_group("village_center"):
		return 1.5
	return contact_range * 0.7


## Empuje suave para que no se apilen en el mismo punto.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self:
			continue
		var d: Vector3 = global_position - e.global_position
		d.y = 0
		var l := d.length()
		if l < 1.1 and l > 0.001:
			push += d / l * (1.1 - l)
	return push


func _choose_target() -> Node3D:
	var player := get_tree().get_first_node_in_group("player")
	if group_id == "aldea":
		var center := get_tree().get_first_node_in_group("village_center")
		if player and global_position.distance_to(player.global_position) < 5.0:
			return player
		return center
	return player


func _check_contact(delta: float) -> void:
	if target == null:
		return
	if target.is_in_group("village_center"):
		if global_position.distance_to(target.global_position) < 3.0:
			_village_tick += delta
			if _village_tick >= 1.0:
				_village_tick = 0.0
				GameState.damage_village(1)
				CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.8, 0), 5, Color(1.0, 0.5, 0.2, 0.9))
		return
	if _contact_t > 0.0 or _windup_t >= 0.0:
		return
	if global_position.distance_to(target.global_position) > contact_range:
		return
	# aviso del golpe: se tine de rojo y se agacha un instante
	_windup_t = windup_time
	sprite.modulate = Color(1.8, 0.5, 0.45)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector3(1.15, 0.85, 1.0), windup_time * 0.8)


func _strike() -> void:
	sprite.modulate = Color.WHITE
	create_tween().tween_property(sprite, "scale", Vector3.ONE, 0.1)
	_contact_t = contact_cooldown
	if target == null or _dead:
		return
	if global_position.distance_to(target.global_position) > contact_range * 1.25:
		return  # el jugador esquivo o se alejo a tiempo
	if target.has_method("take_hit"):
		var kb: Vector3 = (target.global_position - global_position)
		kb.y = 0
		kb = kb.normalized() * 3.0 if kb.length() > 0.01 else Vector3.ZERO
		target.take_hit(contact_damage, kb)
	elif target.has_method("damage"):
		target.damage()


func take_hit(amount: int, knockback: Vector3 = Vector3.ZERO, stun: float = 0.0) -> void:
	if _dead:
		return
	health -= amount
	_knock = knockback
	_stun_t = maxf(_stun_t, stun)
	# un golpe interrumpe el aviso de ataque y la embestida
	if _lunge_windup >= 0.0 or _lunge_t > 0.0:
		_lunge_windup = -1.0
		_lunge_t = 0.0
		sprite.scale = Vector3.ONE
	if _windup_t >= 0.0:
		_windup_t = -1.0
		_contact_t = contact_cooldown * 0.5
		sprite.scale = Vector3.ONE
	SFX.play("hit_enemy")
	if sprite:
		sprite.modulate = Color(4, 4, 4)
		await get_tree().create_timer(0.07).timeout
		if is_instance_valid(sprite) and not _dead:
			sprite.modulate = Color(1, 1, 1)
	if health <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	GameState.enemies_defeated_tonight += 1
	GameState.total_enemies_defeated += 1
	if group_id == "aldea":
		GameState.village_kills += 1
	if GameState.total_enemies_defeated == 1:
		GameState.thot_once("primer_kill", Dialogos.thot("primer_kill"))
	Codex.unlock("ammit")
	SFX.play("enemy_death")
	CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.6, 0), Color(0.5, 0.3, 0.7))
	CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.3, 0), 8, Color(0.25, 0.15, 0.35, 0.9))
	CoinPickup.burst(get_tree().current_scene, global_position, coin_value)
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	var cam := get_viewport().get_camera_3d()
	if pl and cam and cam.has_method("shake") and pl.global_position.distance_to(global_position) < 4.0:
		cam.shake(0.06, 0.1)
	_fade_out()


## Desaparece sin contar como derrotado (al amanecer vuelven al Duat).
func vanish() -> void:
	if _dead:
		return
	_dead = true
	_fade_out()


func _fade_out() -> void:
	set_physics_process(false)
	set_process(false)
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemies")
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(0.4, 0.2, 0.6, 0.0), 0.35)
	tw.parallel().tween_property(sprite, "position:y", sprite.position.y + 0.5, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_free)
