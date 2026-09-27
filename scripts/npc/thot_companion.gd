class_name ThotCompanion
extends Node3D
## Thot te sigue todo el tiempo (GDD 4): "de noche el disco brilla e ilumina
## alrededor del jugador". Companero visual, sin dialogo propio en la demo
## (sus lineas aparecen dentro de las conversaciones, ver data/dialogues.json).

@export var follow_distance: float = 0.9
@export var lag: float = 3.0
@export var bob_speed: float = 3.0
@export var bob_height: float = 0.12

var target: Node3D = null
var sprite: AnimatedSprite3D
var _moon_light: OmniLight3D
var _t: float = 0.0
var _orbit_angle: float = 0.0


func _ready() -> void:
	sprite = AnimatedSprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.05
	sprite.shaded = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	sprite.sprite_frames = SpritesheetLoader.build(
		"res://assets/sprites/companion/thot.png",
		"res://assets/sprites/companion/thot_layout.json", 5.0)
	sprite.play("idle")

	_moon_light = OmniLight3D.new()
	_moon_light.light_color = Color(0.75, 0.82, 0.95)
	_moon_light.light_energy = 0.0
	_moon_light.omni_range = 4.5
	_moon_light.shadow_enabled = false
	_moon_light.position = Vector3(0, 0.3, 0)
	add_child(_moon_light)

	GameTime.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(GameTime.phase)
	_shadow = CharacterFX.add_blob_shadow(self, 0.25)
	_shadow.top_level = true
	# cartel con su nombre mientras habla (Deivid: "ni me aprendi su nombre")
	_nameplate = Label3D.new()
	_nameplate.text = Textos.t("nombre_thot").to_upper()
	_nameplate.font_size = 40
	_nameplate.outline_size = 10
	_nameplate.modulate = Color(0.98, 0.8, 0.35, 0.0)
	_nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nameplate.no_depth_test = true
	_nameplate.pixel_size = 0.01
	_nameplate.position.y = 0.95
	add_child(_nameplate)
	var bark = get_tree().get_first_node_in_group("thot_bark")
	if bark:
		bark.speaking.connect(_on_speaking)


var _nameplate: Label3D
var _talking := false


func _on_speaking(active: bool) -> void:
	_talking = active
	create_tween().tween_property(_nameplate, "modulate:a", 1.0 if active else 0.0, 0.25)
	if active:
		# el disco lunar destella al empezar a hablar
		var e := _moon_light.light_energy
		_moon_light.light_energy = e + 1.2
		create_tween().tween_property(_moon_light, "light_energy", e, 0.5)


var _shadow: MeshInstance3D = null


func set_target(node: Node3D) -> void:
	target = node
	if target:
		_orbit_angle = randf() * TAU
		global_position = target.global_position + Vector3(0, 1.75, -0.8)


func _on_phase_changed(phase: int) -> void:
	var tw := create_tween()
	var goal := 1.1 if phase == GameTime.Phase.NIGHT else 0.0
	tw.tween_property(_moon_light, "light_energy", goal, 1.5)


func _process(delta: float) -> void:
	if target == null:
		return
	_t += delta
	_orbit_angle += delta * 0.45
	# PROMPT_PULIDO.md punto 6: Thot va DETRAS y ARRIBA del jugador (z
	# negativa = mas lejos de la camara), nunca delante tapandolo. Solo se
	# balancea de lado a lado detras del hombro.
	var desired := target.global_position + Vector3(
		sin(_orbit_angle) * follow_distance,
		1.75 + sin(_t * bob_speed) * bob_height,
		-0.75 - absf(cos(_orbit_angle)) * 0.25
	)
	var moving := global_position.distance_to(desired) > 0.08
	global_position = global_position.lerp(desired, clampf(lag * delta, 0.0, 1.0))
	var bark = get_tree().get_first_node_in_group("thot_bark")
	if _talking and bark and bark.is_speaking():
		sprite.play("talk")
	else:
		sprite.play("fly" if moving else "idle")
	sprite.flip_h = global_position.x > target.global_position.x
	# sombra en el suelo (Thot flota)
	if _shadow:
		_shadow.global_position = Vector3(global_position.x, 0.035, global_position.z)
