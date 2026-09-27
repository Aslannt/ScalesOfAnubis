extends Node
## Reproductor de efectos de sonido cortos (generados por tools/gen_sfx.py).
## Uso: SFX.play("hit_enemy")

const DIR := "res://assets/audio/sfx/"
var _cache: Dictionary = {}

const NOMBRES := [
	"hit_enemy", "hit_player", "enemy_death", "till", "water", "harvest",
	"ui_select", "dusk_transform", "coin", "heart_shift", "dodge", "dialogue_blip", "plant",
	"swing", "swing_heavy", "slam", "roar", "charge_windup", "charge", "build", "bolt", "alarm", "crop_lost", "drum_hit",
]


func _ready() -> void:
	for n in NOMBRES:
		var stream: AudioStream = load(DIR + n + ".wav")
		if stream:
			_cache[n] = stream


## Variacion aleatoria de tono (+-6%) para que los efectos repetidos (arar
## una fila de parcelas, golpes seguidos) no suenen a la misma grabacion.
const PITCH_VARIATION := 0.06


func play(nombre: String, volume_db: float = 0.0, pitch_variation: float = PITCH_VARIATION) -> void:
	if not _cache.has(nombre):
		return
	var p := AudioStreamPlayer.new()
	p.stream = _cache[nombre]
	p.bus = "SFX"
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
