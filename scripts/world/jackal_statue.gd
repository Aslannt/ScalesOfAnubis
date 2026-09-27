class_name JackalStatue
extends Node3D
## Estatua de chacal (GDD 6.5): de noche dispara proyectiles dorados a las
## criaturas cercanas. Los ojos brillan al disparar.

const RANGE := 8.0
const COOLDOWN := 1.3
const DAMAGE := 6

var _sprite: AnimatedSprite3D
var _cd: float = 0.5
var _light: OmniLight3D


func _ready() -> void:
	_sprite = AnimatedSprite3D.new()
	_sprite.sprite_frames = SpritesheetLoader.build("res://assets/sprites/fx/jackal_statue.png", "res://assets/sprites/fx/jackal_statue_layout.json", 1.0)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.pixel_size = 0.05
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.shaded = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.position.y = 0.8
	_sprite.play("idle")
	add_child(_sprite)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.8, 0.35)
	_light.light_energy = 0.0
	_light.omni_range = 3.0
	_light.position = Vector3(0.4, 1.3, 0.2)
	add_child(_light)


func _process(delta: float) -> void:
	if not GameTime.is_night():
		return
	_cd -= delta
	if _cd > 0.0:
		return
	var best: Node3D = null
	var best_d := RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		var dd: float = global_position.distance_to(e.global_position)
		if dd < best_d:
			best_d = dd
			best = e
	if best == null:
		_cd = 0.25
		return
	_cd = COOLDOWN
	_fire(best)


func _fire(enemy: Node3D) -> void:
	_sprite.play("fire")
	_sprite.flip_h = enemy.global_position.x < global_position.x
	_light.light_energy = 2.0
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", 0.0, 0.4)
	tw.tween_callback(func(): _sprite.play("idle"))
	SFX.play("bolt", -4.0)
	var bolt := Bolt.new()
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + Vector3(0.5 * (-1.0 if _sprite.flip_h else 1.0), 1.25, 0)
	bolt.target = enemy
	bolt.damage = DAMAGE


class Bolt extends Node3D:
	var target: Node3D
	var damage: int = 6
	var speed: float = 12.0
	var _life: float = 1.5

	func _ready() -> void:
		var s := Sprite3D.new()
		s.texture = preload("res://assets/sprites/fx/bolt.png")
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.pixel_size = 0.05
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.shaded = false
		add_child(s)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.35)
		l.light_energy = 1.2
		l.omni_range = 2.0
		add_child(l)

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0 or not is_instance_valid(target) or not target.is_in_group("enemies"):
			queue_free()
			return
		var aim := target.global_position + Vector3(0, 0.6, 0)
		var dir := aim - global_position
		if dir.length() < 0.4:
			var kb := dir.normalized() * 2.0
			kb.y = 0
			target.take_hit(damage, kb)
			CombatFX.spawn_hit_particles(get_tree().current_scene, global_position, Color(1.0, 0.85, 0.4))
			queue_free()
			return
		global_position += dir.normalized() * speed * delta
