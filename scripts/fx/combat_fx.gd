class_name CombatFX
extends RefCounted
## Feedback de combate (GDD 6.3): numero de dano flotante y particulas de
## impacto. El hit-stop y la sacudida de camara viven en quien golpea
## (player.gd) porque necesitan el CameraRig y el Engine.time_scale.

static var _spark_mat: StandardMaterial3D = null


static func _get_spark_material() -> StandardMaterial3D:
	if _spark_mat == null:
		_spark_mat = StandardMaterial3D.new()
		_spark_mat.albedo_color = Color(1.0, 0.95, 0.7)
		_spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _spark_mat


static func spawn_damage_number(root: Node, world_pos: Vector3, amount: int, color: Color = Color(1, 1, 1)) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.font_size = 48
	label.outline_size = 10
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.01
	root.add_child(label)
	label.global_position = world_pos + Vector3(randf_range(-0.2, 0.2), 0.3, randf_range(-0.2, 0.2))

	var tw := label.create_tween()
	tw.tween_property(label, "position:y", label.position.y + 0.9, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.25)
	tw.tween_callback(label.queue_free)


static func spawn_hit_particles(root: Node, world_pos: Vector3, color: Color = Color(1.0, 0.95, 0.7)) -> void:
	var p := CPUParticles3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.1, 0.1)
	p.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	p.amount = 10
	p.lifetime = 0.35
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.gravity = Vector3(0, -9.0, 0)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.2
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.1
	root.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
