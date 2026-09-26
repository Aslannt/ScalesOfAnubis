class_name EnemyBase
extends CharacterBody3D
## Base para las criaturas de Ammit (GDD 6.4). Sombra y Cria heredan de esta.

@export var max_health: int = 20
@export var speed: float = 2.0
@export var contact_damage: int = 8
@export var contact_range: float = 1.3
@export var contact_cooldown: float = 1.0
@export var sheet_path: String = ""
@export var layout_path: String = ""
@export var idle_anim: String = "idle"
@export var move_anim: String = "move"

var health: int
var _contact_t: float = 0.0
var target: Node3D = null

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	if sheet_path != "":
		sprite.sprite_frames = SpritesheetLoader.build(sheet_path, layout_path, 6.0)
		sprite.play(idle_anim)


func _physics_process(delta: float) -> void:
	_contact_t = maxf(0.0, _contact_t - delta)
	target = _choose_target()

	if target:
		var dir: Vector3 = target.global_position - global_position
		dir.y = 0
		if dir.length() > 0.05:
			velocity.x = dir.normalized().x * speed
			velocity.z = dir.normalized().z * speed
			sprite.flip_h = dir.x < 0
			sprite.play(move_anim)
		else:
			velocity.x = 0
			velocity.z = 0
			sprite.play(idle_anim)
	else:
		velocity.x = 0
		velocity.z = 0
		sprite.play(idle_anim)

	velocity.y = -9.8 if not is_on_floor() else -0.1
	move_and_slide()
	_check_contact()


func _choose_target() -> Node3D:
	return get_tree().get_first_node_in_group("player")


func _check_contact() -> void:
	if target == null or _contact_t > 0.0:
		return
	if global_position.distance_to(target.global_position) > contact_range:
		return
	if target.has_method("take_hit"):
		var kb: Vector3 = (target.global_position - global_position)
		kb.y = 0
		kb = kb.normalized() * 3.0 if kb.length() > 0.01 else Vector3.ZERO
		target.take_hit(contact_damage, kb)
		_contact_t = contact_cooldown
	elif target.has_method("damage"):
		target.damage()
		_contact_t = contact_cooldown


func take_hit(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	health -= amount
	velocity += knockback
	SFX.play("hit_enemy")
	if sprite:
		sprite.modulate = Color(3, 3, 3)
		await get_tree().create_timer(0.06).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1)
	if health <= 0:
		die()


func die() -> void:
	GameState.enemies_defeated_tonight += 1
	Codex.unlock("ammit")
	SFX.play("enemy_death")
	queue_free()
