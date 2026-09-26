class_name Torch
extends Node3D
## Antorcha/brasero con llama animada y luz calida parpadeante (GDD 8: "luz
## calida de braseros" de noche). Se puede colgar de un edificio o plantar
## sola (ver BuildingFactory).

var _light: OmniLight3D
var _t: float = 0.0
var _flicker_seed: float


func _ready() -> void:
	_flicker_seed = randf() * 100.0

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.12, 0.6, 0.12)
	post.mesh = post_mesh
	post.material_override = BuildingFactory._mat("wood")
	post.position = Vector3(0, 0.3, 0)
	add_child(post)

	var bowl := MeshInstance3D.new()
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 0.18
	bowl_mesh.bottom_radius = 0.1
	bowl_mesh.height = 0.14
	bowl.mesh = bowl_mesh
	bowl.material_override = BuildingFactory._mat("stone")
	bowl.position = Vector3(0, 0.62, 0)
	add_child(bowl)

	var flame := AnimatedSprite3D.new()
	flame.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flame.pixel_size = 0.03
	flame.shaded = false
	flame.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	flame.position = Vector3(0, 0.76, 0)
	add_child(flame)
	flame.sprite_frames = SpritesheetLoader.build(
		"res://assets/sprites/fx/flame.png", "res://assets/sprites/fx/flame_layout.json", 6.0)
	flame.play("burn")

	_light = OmniLight3D.new()
	_light.light_color = Color(0.98, 0.62, 0.28)
	_light.light_energy = 1.4
	_light.omni_range = 5.0
	_light.position = Vector3(0, 0.8, 0)
	_light.shadow_enabled = false
	add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	_light.light_energy = 1.3 + sin((_t + _flicker_seed) * 9.0) * 0.12 + sin((_t + _flicker_seed) * 21.0) * 0.06
