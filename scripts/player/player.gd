class_name Player
extends CharacterBody3D
## Controlador del jugador: movimiento top-down, granja (tecla E, contextual)
## y combate nocturno (clic para atacar con el arma equipada, espacio esquiva).
## Ver GDD 6.2 (granja) y 6.3 (combate).

signal died()

@export var speed: float = 4.2
@export var dodge_speed: float = 11.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.7
@export var interact_range: float = 2.2

var facing: String = "south"
var _move_dir := Vector2.ZERO
var _dodging := false
var _dodge_t := 0.0
var _dodge_cd_t := 0.0
var _invulnerable := false
var _attacking := false
var _attack_t := 0.0
var _combo_index := 0

var _anj_timer: float = 0.0
const ANJ_INTERVAL := 6.0
const ANJ_HEAL := 15

var world_builder: WorldBuilder = null
var _anim_t: float = 0.0
var _step_t: float = 0.0

const WEAPON_STATS := {
	"khopesh": {"dano": 8, "alcance": 1.6, "cooldown": 0.28, "golpes": 3, "empuje": 1.5},
	"martillo": {"dano": 20, "alcance": 2.0, "cooldown": 0.75, "golpes": 1, "empuje": 4.0},
}

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


func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if _dodging:
		velocity = Vector3(_move_dir.x, 0, _move_dir.y) * dodge_speed
	elif not _attacking:
		var input_dir := Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.y * speed
		if input_dir.length_squared() > 0.01:
			_move_dir = input_dir
			_update_facing(input_dir)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 4)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 4)

	velocity.y = -9.8 if not is_on_floor() else -0.1
	move_and_slide()

	if Input.is_action_just_pressed("dodge") and not _dodging and _dodge_cd_t <= 0.0 and _move_dir.length_squared() > 0.01:
		_start_dodge()

	var input_locked := GameState.player_input_locked()
	if not input_locked and Input.is_action_just_pressed("attack") and GameTime.is_night() and not _attacking and not _dodging:
		_start_attack()

	if not input_locked and Input.is_action_just_pressed("interact"):
		_try_interact()

	if Input.is_action_just_pressed("tool_1"):
		GameState.equipped_weapon = "khopesh"
	if Input.is_action_just_pressed("tool_2"):
		GameState.equipped_weapon = "martillo"

	if Input.is_action_just_pressed("amulet"):
		_cycle_amulet()

	_update_amulet_passive(delta)
	_update_animation()


func _update_timers(delta: float) -> void:
	if _dodge_cd_t > 0.0:
		_dodge_cd_t -= delta
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
	_dodge_t = dodge_duration
	_dodge_cd_t = dodge_cooldown
	SFX.play("dodge")
	CharacterFX.dust_puff(get_tree().current_scene, global_position + Vector3(0, 0.1, 0), 7)


func _start_attack() -> void:
	_attacking = true
	_aim_at_mouse()
	var stats: Dictionary = WEAPON_STATS[GameState.equipped_weapon]
	_attack_t = float(stats["cooldown"])
	_combo_index = (_combo_index + 1) % int(stats["golpes"])
	var shape: SphereShape3D = attack_shape.shape
	shape.radius = float(stats["alcance"])
	attack_area.position = Vector3(_facing_vector().x, 0, _facing_vector().z) * 0.8
	attack_area.monitoring = true
	sprite.play("%s_attack" % _facing_group())
	await get_tree().create_timer(0.08).timeout
	_resolve_attack_hits(stats)


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


func _resolve_attack_hits(stats: Dictionary) -> void:
	var hit_any := false
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_hit"):
			hit_any = true
			var dir: Vector3 = (body.global_position - global_position)
			dir.y = 0
			dir = dir.normalized() if dir.length() > 0.01 else _facing_vector()
			body.take_hit(int(stats["dano"]), dir * float(stats["empuje"]))
			var fx_root := get_tree().current_scene
			CombatFX.spawn_damage_number(fx_root, body.global_position + Vector3(0, 1.0, 0), int(stats["dano"]))
			CombatFX.spawn_hit_particles(fx_root, body.global_position + Vector3(0, 0.9, 0))
	if hit_any:
		_hitstop(0.05)
		var cam := get_viewport().get_camera_3d()
		if cam and cam.has_method("shake"):
			cam.shake(0.12, 0.15)


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
		FarmPlot.State.TILLED:
			plot.plant(_seed_for(plot))
		FarmPlot.State.PLANTED:
			if plot.is_ready():
				plot.harvest()
			elif not plot.watered_today:
				plot.water()


func _target_plot() -> FarmPlot:
	var target_pos := global_position + _facing_vector() * 1.2
	return world_builder.plot_at_world(target_pos, interact_range)


func _seed_for(plot: FarmPlot) -> String:
	return "papiro" if plot.is_orilla else "trigo"


## Texto de ayuda contextual para el HUD ("[E] Arar", "[E] Hablar con
## Meret"...): tutorial integrado sin muros de texto (GDD 2, pilar 2).
func get_interact_hint() -> String:
	if world_builder == null or get_tree().paused:
		return ""
	var npc = world_builder.npc_at_world(global_position, 2.4)
	if npc:
		if npc.npc_id == "altar":
			return Textos.t("hint_altar")
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
			var sid := _seed_for(plot)
			return Textos.t("hint_sembrar", {"n": GameState.crops.get(sid, {}).get("nombre_corto", sid.capitalize())})
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


func _on_health_changed(h: int, _m: int) -> void:
	if h <= 0:
		if GameState.equipped_amulet == "escarabajo" and not GameState.escarabajo_usado_esta_noche:
			GameState.escarabajo_usado_esta_noche = true
			GameState.health = int(GameState.max_health * 0.5)
			GameState.health_changed.emit(GameState.health, GameState.max_health)
			return
		died.emit()


func take_hit(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	if _invulnerable:
		return
	GameState.take_damage(amount)
	velocity += knockback
	SFX.play("hit_player")
	CombatFX.spawn_damage_number(get_tree().current_scene, global_position + Vector3(0, 1.4, 0), amount, Color(1.0, 0.35, 0.3))
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(0.2, 0.2)
	sprite.modulate = Color(3, 3, 3)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color(1, 1, 1)
