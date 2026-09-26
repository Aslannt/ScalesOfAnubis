extends Node
## Reproductor de efectos de sonido cortos (generados por tools/gen_sfx.py).
## Uso: SFX.play("hit_enemy")

const DIR := "res://assets/audio/sfx/"
var _cache: Dictionary = {}

const NOMBRES := [
	"hit_enemy", "hit_player", "enemy_death", "till", "water", "harvest",
	"ui_select", "dusk_transform", "coin", "heart_shift", "dodge", "dialogue_blip",
]


func _ready() -> void:
	for n in NOMBRES:
		var stream: AudioStream = load(DIR + n + ".wav")
		if stream:
			_cache[n] = stream


func play(nombre: String, volume_db: float = 0.0) -> void:
	if not _cache.has(nombre):
		return
	var p := AudioStreamPlayer.new()
	p.stream = _cache[nombre]
	p.bus = "SFX"
	p.volume_db = volume_db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
