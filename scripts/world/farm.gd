extends Node3D
## Escena principal de juego: arma el mundo, coloca al jugador y engancha la
## camara y el director de oleadas nocturnas.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

@onready var world_builder: WorldBuilder = $WorldBuilder
@onready var camera_rig: Camera3D = $CameraRig


func _ready() -> void:
	world_builder.build()

	var player := PLAYER_SCENE.instantiate()
	player.world_builder = world_builder
	add_child(player)
	player.global_position = world_builder.player_spawn_world + Vector3(0, 0.2, 0)

	camera_rig.current = true
	camera_rig.set_target(player)

	var thot := ThotCompanion.new()
	add_child(thot)
	thot.set_target(player)

	var ambient := AmbientFX.new()
	ambient.name = "AmbientFX"
	ambient.river_shore_x = world_builder.river_shore_x
	ambient.river_min_x = world_builder.river_min_x
	add_child(ambient)
	ambient.set_target(player)
