class_name CharacterFX
extends RefCounted
## Detalles que dan vida a cualquier personaje (PROMPT_PULIDO.md punto 3):
## sombra circular bajo el sprite, respiracion en idle (bob de 1px) y
## polvo al caminar.

const SHADOW_TEX := preload("res://assets/sprites/fx/blob_shadow.png")
static var _shadow_mat: StandardMaterial3D = null
static var _dust_mat: StandardMaterial3D = null


## Sombra ovalada pegada al suelo. `radius` en metros (ancho total = 2r).
static func add_blob_shadow(parent: Node3D, radius: float = 0.45, height: float = 0.03) -> MeshInstance3D:
	if _shadow_mat == null:
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.albedo_texture = SHADOW_TEX
		_shadow_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.render_priority = -1
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius)
	mi.mesh = plane
	mi.material_override = _shadow_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, height, 0)
	mi.name = "SombraCircular"
	parent.add_child(mi)
	return mi


## Respiracion: devuelve el offset vertical (en pixeles del sprite) para un
## AnimatedSprite3D en idle. Escalonado a 0/1 px para mantener el pixel art.
static func breathe_offset(t: float, speed: float = 2.2) -> float:
	return 1.0 if sin(t * speed) > 0.2 else 0.0


## Nubecita de polvo a los pies (al caminar o esquivar).
static func dust_puff(root: Node, world_pos: Vector3, amount: int = 4, color: Color = Color(0.78, 0.68, 0.5, 0.8)) -> void:
	if _dust_mat == null:
		_dust_mat = StandardMaterial3D.new()
		_dust_mat.albedo_texture = preload("res://assets/sprites/fx/dot.png")
		_dust_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_dust_mat.vertex_color_use_as_albedo = true
	var p := CPUParticles3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.14, 0.14)
	p.mesh = mesh
	p.material_override = _dust_mat
	p.amount = amount
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.gravity = Vector3(0, 0.4, 0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.8
	p.damping_min = 1.5
	p.damping_max = 2.5
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var grad := Gradient.new()
	grad.set_color(0, color)
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = grad
	root.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
