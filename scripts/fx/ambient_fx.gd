class_name AmbientFX
extends Node3D
## Ambiente vivo alrededor del jugador (PROMPT_PULIDO.md punto 3):
## - polvo/arena flotando de dia, luciernagas de noche, hojas que vuelan
## - ibis cruzando el cielo de vez en cuando (de dia)
## - peces que saltan en el Nilo cuando el jugador esta cerca de la orilla
## Todo sigue al jugador para no gastar particulas en zonas que no se ven.

const IBIS_SHEET := "res://assets/sprites/fx/ibis.png"
const IBIS_LAYOUT := "res://assets/sprites/fx/ibis_layout.json"
const FISH_SHEET := "res://assets/sprites/fx/fish.png"
const FISH_LAYOUT := "res://assets/sprites/fx/fish_layout.json"
const DOT_TEX := preload("res://assets/sprites/fx/dot.png")
const LEAF_TEX := preload("res://assets/sprites/fx/leaf.png")

var target: Node3D = null
## X de mundo de la orilla del Nilo y rango de agua (lo fija farm.gd).
var river_shore_x: float = -26.0
var river_min_x: float = -36.0

var _dust: GPUParticles3D
var _fireflies: GPUParticles3D
var _leaves: GPUParticles3D
var _bird_t: float = 6.0
var _fish_t: float = 4.0
var _ibis_frames: SpriteFrames
var _fish_frames: SpriteFrames


func _ready() -> void:
	_ibis_frames = SpritesheetLoader.build(IBIS_SHEET, IBIS_LAYOUT, 7.0)
	_fish_frames = SpritesheetLoader.build(FISH_SHEET, FISH_LAYOUT, 6.0)
	_dust = _make_particles(DOT_TEX, 45, 7.0, Vector3(11, 1.6, 8), Color(1.0, 0.9, 0.7, 0.55), 0.07, false)
	_dust.position = Vector3(0, 1.2, 0)
	_fireflies = _make_particles(DOT_TEX, 34, 6.0, Vector3(10, 1.0, 8), Color(0.85, 1.0, 0.45, 1.0), 0.08, true)
	_fireflies.position = Vector3(0, 0.9, 0)
	_leaves = _make_particles(LEAF_TEX, 5, 6.0, Vector3(10, 1.5, 7), Color(1, 1, 1, 1), 0.14, false)
	_leaves.position = Vector3(-4, 2.2, 0)
	var lpm: ParticleProcessMaterial = _leaves.process_material
	lpm.gravity = Vector3(0.8, -0.35, 0)
	lpm.angular_velocity_min = -180.0
	lpm.angular_velocity_max = 180.0
	GameTime.phase_changed.connect(_on_phase)
	_on_phase(GameTime.phase)


func _make_particles(tex: Texture2D, amount: int, lifetime: float, box: Vector3, color: Color, size: float, glow: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.local_coords = false
	p.visibility_aabb = AABB(-box * 1.5, box * 3.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = Vector3(1, 0.2, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3(0.12, 0.02, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 3.0
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.15
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	grad.colors = PackedColorArray([Color(color, 0.0), color, color, Color(color, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	if glow:
		mat.emission_enabled = true
		mat.emission = Color(0.8, 1.0, 0.4)
		mat.emission_energy_multiplier = 2.5
	mesh.material = mat
	p.draw_pass_1 = mesh
	add_child(p)
	return p


func set_target(node: Node3D) -> void:
	target = node


func _on_phase(phase: int) -> void:
	var night := phase == GameTime.Phase.NIGHT
	_dust.emitting = not night
	_leaves.emitting = phase == GameTime.Phase.DAY or phase == GameTime.Phase.DAWN
	_fireflies.emitting = night or phase == GameTime.Phase.DUSK


func _process(delta: float) -> void:
	if target == null:
		return
	global_position = target.global_position
	if GameTime.phase == GameTime.Phase.DAY or GameTime.phase == GameTime.Phase.DAWN:
		_bird_t -= delta
		if _bird_t <= 0.0:
			_bird_t = randf_range(14.0, 26.0)
			_spawn_flock()
	_fish_t -= delta
	if _fish_t <= 0.0:
		_fish_t = randf_range(5.0, 11.0)
		if not GameTime.is_night() and target.global_position.x - river_shore_x < 16.0:
			_spawn_fish()


## Bandada de 3-5 ibis cruzando la vista de izquierda a derecha, en V.
func _spawn_flock() -> void:
	var n := randi_range(3, 5)
	var base := target.global_position + Vector3(-16.0, randf_range(2.6, 3.2), randf_range(-3.5, -1.0))
	var speed := randf_range(3.2, 4.2)
	for i in range(n):
		var bird := AnimatedSprite3D.new()
		bird.sprite_frames = _ibis_frames
		bird.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bird.pixel_size = 0.06
		bird.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bird.shaded = false
		bird.modulate = Color(0.95, 0.93, 0.9)
		get_parent().add_child(bird)
		var row := int((i + 1) / 2)
		var side := 1.0 if i % 2 == 0 else -1.0
		bird.global_position = base + Vector3(-row * 0.9, row * 0.25 * side, row * 0.8 * side)
		bird.play("fly")
		bird.frame = randi() % 3
		var dist := 34.0
		var tw := bird.create_tween()
		tw.tween_property(bird, "global_position", bird.global_position + Vector3(dist, randf_range(-0.5, 1.0), -2.0), dist / speed)
		tw.tween_callback(bird.queue_free)


## Pez que salta del agua en arco, con salpicadura al salir y al entrar.
func _spawn_fish() -> void:
	var x := randf_range(river_min_x + 3.0, river_shore_x - 1.5)
	var z := target.global_position.z + randf_range(-7.0, 2.0)
	var start := Vector3(x, 0.05, z)
	var fish := AnimatedSprite3D.new()
	fish.sprite_frames = _fish_frames
	fish.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fish.pixel_size = 0.07
	fish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	fish.shaded = true
	get_parent().add_child(fish)
	fish.global_position = start
	fish.play("jump")
	var dir := 1.0 if randf() < 0.5 else -1.0
	fish.flip_h = dir < 0
	_splash(start)
	var dur := 0.7
	var tw := fish.create_tween()
	tw.tween_method(func(t: float):
		fish.global_position = start + Vector3(dir * 1.1 * t, sin(t * PI) * 0.9, 0)
		fish.rotation.z = lerpf(0.6, -0.6, t) * dir
	, 0.0, 1.0, dur)
	tw.tween_callback(func(): _splash(fish.global_position))
	tw.tween_callback(fish.queue_free)


func _splash(pos: Vector3) -> void:
	CharacterFX.dust_puff(get_parent(), pos + Vector3(0, 0.05, 0), 6, Color(0.85, 0.95, 0.95, 0.9))
