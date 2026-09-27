class_name VillageLife
extends Node3D
## Vida de la aldea (tercera ronda: "hacen falta animaciones y que se
## sienta vivo el mundo"):
## - gatos (mau egipcio) que pasean, se sientan y se apartan del jugador
## - gansos del Nilo en la orilla que picotean y huyen si corres hacia ellos
## - humo de los fogones en algunas casas
## - edificios que se vuelven translucidos cuando tapan al jugador
## Las posiciones de los animales salen de data/map_layout.json -> "animales".

const CAT_SHEET := "res://assets/sprites/fx/cat.png"
const CAT_LAYOUT := "res://assets/sprites/fx/cat_layout.json"
const GOOSE_SHEET := "res://assets/sprites/fx/goose.png"
const GOOSE_LAYOUT := "res://assets/sprites/fx/goose_layout.json"
const DOT_TEX := preload("res://assets/sprites/fx/dot.png")

var player: Node3D
var world_builder: WorldBuilder
var _occluders: Array = []  # [nodo, radio, [GeometryInstance3D...], alfa actual]
var _smokes: Array[GPUParticles3D] = []


func setup(p: Node3D, wb: WorldBuilder, animals: Array) -> void:
	player = p
	world_builder = wb
	for a in animals:
		var tt: Array = a.get("tile", [0, 0])
		var pos: Vector3 = wb._tile_to_world(float(tt[0]), float(tt[1]))
		var n := int(a.get("n", 1))
		for i in range(n):
			var an := Animal.new()
			an.kind = String(a.get("tipo", "gato"))
			an.home = pos + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
			an.radius = float(a.get("radio", 3.0))
			an.life = self
			add_child(an)
			an.global_position = an.home
	_collect_occluders.call_deferred()
	GameTime.phase_changed.connect(_on_phase)


func _collect_occluders() -> void:
	var i := 0
	for o in get_tree().get_nodes_in_group("occluders"):
		var geoms: Array = []
		var aabb := AABB()
		var first := true
		for g in o.find_children("*", "GeometryInstance3D", true, false):
			if g is Torch or g.get_parent() is Torch:
				continue
			geoms.append(g)
			var gb: AABB = (g as VisualInstance3D).get_aabb()
			gb = (g as Node3D).transform * gb
			aabb = gb if first else aabb.merge(gb)
			first = false
		var r := maxf(aabb.size.x, aabb.size.z) * 0.5 * maxf(o.scale.x, o.scale.z)
		_occluders.append([o, r, geoms, 1.0, aabb.size.y * o.scale.y])
		# humo de fogon en una de cada tres casas
		if o.name.begins_with("CasaAdobe") and i % 3 == 0:
			_add_smoke(o)
		i += 1
	_on_phase(GameTime.phase)


func _add_smoke(house: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.15
	pm.direction = Vector3(0.3, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.35
	pm.initial_velocity_max = 0.55
	pm.gravity = Vector3(0.12, 0.05, 0)
	pm.scale_min = 1.0
	pm.scale_max = 1.6
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(1, 2.2))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var grad := Gradient.new()
	grad.set_color(0, Color(0.85, 0.82, 0.78, 0.5))
	grad.set_color(1, Color(0.7, 0.68, 0.66, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.28, 0.28)
	var m := StandardMaterial3D.new()
	m.albedo_texture = DOT_TEX
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	quad.material = m
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	house.add_child(p)
	p.position = Vector3(1.1, 2.6, 0.9)
	_smokes.append(p)


func _on_phase(phase: int) -> void:
	# de noche no se cocina: sin humo
	for s in _smokes:
		if is_instance_valid(s):
			s.emitting = phase != GameTime.Phase.NIGHT


func _process(delta: float) -> void:
	if player == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var a := cam.global_position
	var b := player.global_position + Vector3(0, 0.8, 0)
	var ab := b - a
	for o in _occluders:
		var node: Node3D = o[0]
		if not is_instance_valid(node):
			continue
		var c := node.global_position + Vector3(0, float(o[4]) * 0.4, 0)
		var t := clampf((c - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var closest := a + ab * t
		var hidden := t > 0.05 and t < 0.97 and Vector2(closest.x - c.x, closest.z - c.z).length() < float(o[1]) * 0.85 and node.global_position.z > player.global_position.z - 0.5
		var goal := 0.62 if hidden else 0.0
		var cur: float = o[3]
		if absf(cur - goal) > 0.01:
			cur = move_toward(cur, goal, delta * 3.0)
			o[3] = cur
			for g in o[2]:
				if is_instance_valid(g):
					(g as GeometryInstance3D).transparency = cur


## Gato o ganso que pasea cerca de su casa.
class Animal extends Node3D:
	var kind := "gato"
	var home := Vector3.ZERO
	var radius := 3.0
	var life: VillageLife
	var _sprite: AnimatedSprite3D
	var _goal := Vector3.ZERO
	var _wait := 1.0
	var _speed := 1.0
	var _flee := 0.0
	var _t := 0.0

	func _ready() -> void:
		_sprite = AnimatedSprite3D.new()
		var cat := kind == "gato"
		_sprite.sprite_frames = SpritesheetLoader.build(
			VillageLife.CAT_SHEET if cat else VillageLife.GOOSE_SHEET,
			VillageLife.CAT_LAYOUT if cat else VillageLife.GOOSE_LAYOUT, 6.0)
		_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		_sprite.pixel_size = 0.052 if cat else 0.058
		_sprite.shaded = true
		_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		_sprite.position.y = 0.27
		add_child(_sprite)
		_sprite.play("sit" if cat else "idle")
		CharacterFX.add_blob_shadow(self, 0.28)
		_speed = 1.1 if cat else 0.8
		_wait = randf_range(0.5, 4.0)
		_goal = home
		_t = randf() * 5.0

	func _process(delta: float) -> void:
		_t += delta
		var night := GameTime.is_night()
		# de noche los gansos duermen fuera de la vista y los gatos cazan
		if kind != "gato":
			visible = not night
			if night:
				return
		var p := life.player
		if p and _flee <= 0.0:
			var dp := global_position - p.global_position
			dp.y = 0
			if dp.length() < (2.2 if kind == "gato" else 3.0) and (p.get("velocity") == null or (p.velocity as Vector3).length() > 2.0):
				# se aparta del jugador que viene corriendo
				_goal = global_position + dp.normalized() * 2.5
				_flee = 1.2
				if kind != "gato":
					SFX.play("dialogue_blip", -14.0, 0.0)
		_flee = maxf(0.0, _flee - delta)
		var to := _goal - global_position
		to.y = 0
		if to.length() > 0.15:
			var sp := _speed * (2.2 if _flee > 0.0 else 1.0)
			global_position += to.normalized() * minf(sp * delta, to.length())
			_sprite.flip_h = to.x < 0
			_sprite.play("walk")
			_sprite.speed_scale = 1.8 if _flee > 0.0 else 1.0
		else:
			_sprite.speed_scale = 1.0
			_wait -= delta
			if kind == "gato":
				_sprite.play("sit")
			else:
				_sprite.play("peck" if fmod(_t, 3.0) < 0.6 else "idle")
			if _wait <= 0.0:
				_wait = randf_range(2.0, 6.0)
				var ang := randf() * TAU
				_goal = home + Vector3(cos(ang), 0, sin(ang)) * randf_range(0.5, radius)
