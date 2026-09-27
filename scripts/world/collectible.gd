class_name Collectible
extends Node3D
## Objeto brillante que se recoge con E: shabtis escondidos por el mapa y la
## ficha de senet que perdio Iry. Da algo que explorar de dia (pedido de
## Deivid: "no tenia cosas que hacer").

var npc_id: String = "shabti"   # "shabti" | "senet"
var _sprite: Sprite3D
var _t := 0.0
var _light: OmniLight3D


func _ready() -> void:
	add_to_group("collectibles")
	_sprite = Sprite3D.new()
	_sprite.texture = load("res://assets/sprites/icons/%s.png" % npc_id)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.pixel_size = 0.045
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.shaded = false
	_sprite.position.y = 0.55
	add_child(_sprite)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.5, 0.9, 1.0) if npc_id == "shabti" else Color(1.0, 0.9, 0.6)
	_light.light_energy = 0.9
	_light.omni_range = 2.2
	_light.position.y = 0.6
	add_child(_light)
	CharacterFX.add_blob_shadow(self, 0.2)
	_t = randf() * 5.0


func _process(delta: float) -> void:
	_t += delta
	visible = is_available()
	_sprite.position.y = 0.55 + sin(_t * 2.5) * 0.08
	_light.light_energy = 0.7 + 0.35 * sin(_t * 4.0)
	# destellos ocasionales para que se note de lejos
	if visible and fmod(_t, 1.6) < delta:
		CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.8, 0), _light.light_color)


func is_available() -> bool:
	if npc_id == "senet":
		return GameState.tutorial.get("iry_senet", "") == "pedido"
	return true


func interact() -> void:
	if not is_available():
		return
	SFX.play("coin")
	CombatFX.spawn_hit_particles(get_tree().current_scene, global_position + Vector3(0, 0.6, 0), Color(1.0, 0.9, 0.5))
	if npc_id == "shabti":
		GameState.tutorial["shabtis"] = int(GameState.tutorial.get("shabtis", 0)) + 1
		GameState.tutorial["shabti_" + str(get_index())] = true
		GameState.add_deben(8)
		Codex.unlock("shabti")
		var n: int = GameState.tutorial["shabtis"]
		if n >= 5:
			GameState.add_deben(20)
			GameState.shift_heart(-3.0, "shabtis")
			GameState.thot(Dialogos.thot("shabtis_todos"), true)
		else:
			GameState.thot(Dialogos.thot("shabti").replace("{n}", str(n)), true)
	else:
		GameState.tutorial["iry_senet"] = "encontrado"
		Codex.unlock("senet")
		GameState.thot(Dialogos.thot("senet_encontrado"), true)
	queue_free()


## Al cargar partida: los shabtis ya recogidos no reaparecen.
func already_taken() -> bool:
	return npc_id == "shabti" and GameState.tutorial.get("shabti_" + str(get_index()), false)
