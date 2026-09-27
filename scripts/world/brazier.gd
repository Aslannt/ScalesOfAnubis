class_name Brazier
extends Node3D
## Brasero sagrado (GDD 6.5): quema en area a las criaturas que pasan
## cerca. De noche arde fuerte e ilumina alrededor.

const TICK := 0.5
## Numeros por nivel en data/defenses.json (set_level los aplica).
var radius: float = 1.8
var damage: int = 3
var slows := false
var level: int = 1

var _flame: AnimatedSprite3D
var _light: OmniLight3D
var _t: float = 0.0
var _tick: float = 0.0
var _ring: MeshInstance3D


func _ready() -> void:
	var stone := BuildingFactory._mat("stone")
	var bronze := BuildingFactory._solid_mat(Color(0.62, 0.4, 0.18))
	bronze.metallic = 0.5
	bronze.roughness = 0.5
	for i in range(3):
		var a := TAU / 3.0 * i
		add_child(BuildingFactory._box(Vector3(0.1, 0.8, 0.1), bronze, Vector3(cos(a) * 0.35, 0.4, sin(a) * 0.35)))
	var bowl := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.3
	cyl.height = 0.35
	bowl.mesh = cyl
	bowl.material_override = bronze
	bowl.position.y = 0.95
	add_child(bowl)
	add_child(BuildingFactory._box(Vector3(0.9, 0.1, 0.9), stone, Vector3(0, 0.05, 0)))

	_flame = AnimatedSprite3D.new()
	_flame.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_flame.pixel_size = 0.07
	_flame.shaded = false
	_flame.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_flame.position = Vector3(0, 1.55, 0)
	_flame.sprite_frames = SpritesheetLoader.build("res://assets/sprites/fx/flame.png", "res://assets/sprites/fx/flame_layout.json", 8.0)
	_flame.play("burn")
	add_child(_flame)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.25)
	_light.light_energy = 1.0
	_light.omni_range = 6.0
	_light.position.y = 1.6
	add_child(_light)

	# circulo de alcance tenue en el suelo (se ve de noche)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.06
	torus.outer_radius = radius
	torus.ring_segments = 3
	torus.rings = 32
	_ring.mesh = torus
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.55, 0.2, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = m
	_ring.position.y = -0.26
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)


func set_level(lv: int, st: Dictionary) -> void:
	level = lv
	radius = float(st.get("radio", radius))
	damage = int(st.get("dano", damage))
	slows = bool(st.get("lento", false))
	if _ring:
		var torus := _ring.mesh as TorusMesh
		torus.inner_radius = radius - 0.06
		torus.outer_radius = radius
	if _flame:
		_flame.pixel_size = 0.07 + 0.012 * (lv - 1)
		_flame.position.y = 1.55 + 0.08 * (lv - 1)
		# fuego de Ra: llama azul-blanca
		_flame.modulate = Color(0.6, 0.85, 1.6) if slows else Color.WHITE
	if _light:
		_light.omni_range = 6.0 + lv
		_light.light_color = Color(0.55, 0.75, 1.0) if slows else Color(1.0, 0.6, 0.25)
		(_ring.material_override as StandardMaterial3D).albedo_color = Color(0.5, 0.75, 1.0, 0.35) if slows else Color(1.0, 0.55, 0.2, 0.35)


func _process(delta: float) -> void:
	_t += delta
	var night := GameTime.is_night()
	var base := 2.2 if night else 0.8
	_light.light_energy = base + sin(_t * 11.0) * 0.15 + sin(_t * 23.0) * 0.08
	_ring.visible = night
	if not night:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	for e in get_tree().get_nodes_in_group("enemies"):
		var dv: Vector3 = e.global_position - global_position
		dv.y = 0
		if dv.length() <= radius:
			if slows and e.has_method("slow"):
				e.slow(1.0)
			e.take_hit(int(round(damage * (1.0 + GameState.temple_bonus("defensas")))), dv.normalized() * 1.5)
			CombatFX.spawn_hit_particles(get_tree().current_scene, e.global_position + Vector3(0, 0.5, 0), Color(0.55, 0.8, 1.0) if slows else Color(1.0, 0.55, 0.2))
