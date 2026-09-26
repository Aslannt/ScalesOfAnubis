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
		"res://assets/sprites/characters/player_layout.txt")
	sprite.sprite_frames = frames
	sprite.play("south_idle")
	attack_area.monitoring = false
	GameState.health_changed.connect(_on_health_changed)


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

	if Input.is_action_just_pressed("attack") and GameTime.is_night() and not _attacking and not _dodging:
		_start_attack()

	if Input.is_action_just_pressed("interact"):
		_try_farm_interact()

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
		if _dodge_t <= 0.0:
			_dodging = false
			_invulnerable = false
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


func _start_attack() -> void:
	_attacking = true
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


func _resolve_attack_hits(stats: Dictionary) -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_hit"):
			var dir: Vector3 = (body.global_position - global_position)
			dir.y = 0
			dir = dir.normalized() if dir.length() > 0.01 else _facing_vector()
			body.take_hit(int(stats["dano"]), dir * float(stats["empuje"]))


func _try_farm_interact() -> void:
	if GameTime.is_night():
		return
	if world_builder == null:
		return
	var target_pos := global_position + _facing_vector() * 1.2
	var plot: FarmPlot = world_builder.plot_at_world(target_pos, interact_range)
	if plot == null:
		return
	match plot.state:
		FarmPlot.State.UNTILLED:
			plot.till()
		FarmPlot.State.TILLED:
			plot.plant("papiro" if plot.is_orilla else "trigo")
		FarmPlot.State.PLANTED:
			if plot.is_ready():
				plot.harvest()
			elif not plot.watered_today:
				plot.water()


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
	if _attacking:
		return
	var group := _facing_group()
	if velocity.length() > 0.3 and not _dodging:
		sprite.play("%s_walk" % group)
	else:
		sprite.play("%s_idle" % group)


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
	sprite.modulate = Color(3, 3, 3)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color(1, 1, 1)
