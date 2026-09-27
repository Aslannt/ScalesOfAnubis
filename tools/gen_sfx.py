"""Genera SFX cortos estilo sfxr por sintesis (numpy -> WAV). Nada de audio de
terceros: todo generado por script segun pide CLAUDE.md.
"""
import os
import numpy as np
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio", "sfx")
os.makedirs(OUT, exist_ok=True)

# Mezcla: todos los efectos se normalizan a un pico de -12 dBFS (antes iban
# al 100%, 32767, y sonaban demasiado fuertes: reporte de Deivid). La musica
# queda un poco por encima (ver gen_music.py).
PEAK_DBFS = -12.0


def save_wav(path, samples, peak_dbfs=PEAK_DBFS):
    samples = np.asarray(samples, dtype=np.float64)
    peak = np.max(np.abs(samples))
    if peak > 1e-9:
        samples = samples / peak * (10.0 ** (peak_dbfs / 20.0))
    # micro-fundido al final para que ningun efecto termine con un "clic"
    n_tail = min(len(samples), int(SR * 0.004))
    if n_tail > 1:
        samples[-n_tail:] *= np.linspace(1.0, 0.0, n_tail)
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", path, f"{len(samples)/SR:.2f}s")


def t_array(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def envelope(n, attack=0.01, decay=0.1, sustain=0.6, release=0.1):
    total = n / SR
    a = int(attack * SR)
    d = int(decay * SR)
    r = int(release * SR)
    s = max(n - a - d - r, 0)
    env = np.concatenate([
        np.linspace(0, 1, max(a, 1)),
        np.linspace(1, sustain, max(d, 1)),
        np.full(s, sustain),
        np.linspace(sustain, 0, max(r, 1)),
    ])
    if len(env) < n:
        env = np.pad(env, (0, n - len(env)))
    return env[:n]


def tone(freq_start, freq_end, dur, wave_type="square", **env_kw):
    t = t_array(dur)
    freq = np.linspace(freq_start, freq_end, len(t))
    phase = np.cumsum(freq) / SR
    if wave_type == "square":
        sig = np.sign(np.sin(2 * np.pi * phase))
    elif wave_type == "saw":
        sig = 2 * (phase % 1.0) - 1
    elif wave_type == "sine":
        sig = np.sin(2 * np.pi * phase)
    else:
        sig = np.sign(np.sin(2 * np.pi * phase))
    env = envelope(len(t), **env_kw)
    return sig * env


def noise(dur, **env_kw):
    n = int(SR * dur)
    rng = np.random.RandomState(0)
    sig = rng.uniform(-1, 1, n)
    env = envelope(n, **env_kw)
    return sig * env


def mix(*sigs):
    n = max(len(s) for s in sigs)
    out = np.zeros(n)
    for s in sigs:
        out[:len(s)] += s
    return out / max(1, len(sigs)) * 1.4


def hit_enemy():
    s = mix(
        tone(320, 120, 0.10, "square", attack=0.001, decay=0.05, sustain=0.3, release=0.05),
        noise(0.06, attack=0.001, decay=0.02, sustain=0.2, release=0.03) * 0.6,
    )
    save_wav(os.path.join(OUT, "hit_enemy.wav"), s)


def hit_player():
    s = tone(160, 60, 0.18, "saw", attack=0.001, decay=0.08, sustain=0.4, release=0.08)
    save_wav(os.path.join(OUT, "hit_player.wav"), s)


def enemy_death():
    s = tone(400, 40, 0.35, "square", attack=0.001, decay=0.15, sustain=0.2, release=0.15)
    save_wav(os.path.join(OUT, "enemy_death.wav"), s)


def lowpass(sig, width):
    """Filtro pasa-bajos barato (media movil): quita el siseo del ruido."""
    k = np.ones(width) / width
    return np.convolve(sig, k, mode="same")


def till():
    # Golpe de tierra grave y corto (antes era casi todo ruido blanco y
    # molestaba al arar varias parcelas seguidas).
    thump = tone(115, 42, 0.16, "sine", attack=0.002, decay=0.06, sustain=0.25, release=0.08)
    body = tone(230, 80, 0.07, "sine", attack=0.001, decay=0.03, sustain=0.2, release=0.03) * 0.35
    dirt = lowpass(noise(0.10, attack=0.001, decay=0.04, sustain=0.15, release=0.05), 18) * 1.6
    s = mix(thump, body, dirt)
    save_wav(os.path.join(OUT, "till.wav"), s)


def water():
    s = noise(0.28, attack=0.02, decay=0.1, sustain=0.5, release=0.12)
    t = t_array(0.28)
    s *= (1.0 + 0.3 * np.sin(2 * np.pi * 14 * t))
    save_wav(os.path.join(OUT, "water.wav"), s)


def harvest():
    s = mix(
        tone(700, 900, 0.08, "square", attack=0.001, decay=0.03, sustain=0.3, release=0.04),
        tone(1000, 1200, 0.1, "sine", attack=0.02, decay=0.04, sustain=0.2, release=0.06),
    )
    save_wav(os.path.join(OUT, "harvest.wav"), s)


def ui_select():
    s = tone(500, 700, 0.06, "square", attack=0.001, decay=0.02, sustain=0.4, release=0.03)
    save_wav(os.path.join(OUT, "ui_select.wav"), s)


def dusk_transform():
    s = tone(200, 900, 0.6, "saw", attack=0.05, decay=0.2, sustain=0.6, release=0.2)
    save_wav(os.path.join(OUT, "dusk_transform.wav"), s)


def coin():
    s = mix(
        tone(880, 1100, 0.09, "square", attack=0.001, decay=0.03, sustain=0.4, release=0.05),
        tone(1320, 1500, 0.09, "square", attack=0.02, decay=0.03, sustain=0.3, release=0.05),
    )
    save_wav(os.path.join(OUT, "coin.wav"), s)


def heart_shift():
    s = tone(300, 500, 0.4, "sine", attack=0.02, decay=0.1, sustain=0.5, release=0.2)
    save_wav(os.path.join(OUT, "heart_shift.wav"), s)


def dodge():
    s = tone(600, 200, 0.15, "sine", attack=0.001, decay=0.05, sustain=0.3, release=0.08)
    save_wav(os.path.join(OUT, "dodge.wav"), s)


def dialogue_blip():
    s = tone(440, 460, 0.04, "square", attack=0.001, decay=0.01, sustain=0.5, release=0.02)
    save_wav(os.path.join(OUT, "dialogue_blip.wav"), s)


def plant():
    # semilla que entra en la tierra: "pop" suave y breve
    s = mix(
        tone(260, 420, 0.07, "sine", attack=0.002, decay=0.03, sustain=0.3, release=0.03),
        lowpass(noise(0.05, attack=0.001, decay=0.02, sustain=0.1, release=0.02), 10) * 0.8,
    )
    save_wav(os.path.join(OUT, "plant.wav"), s)


def swing():
    # tajo de khopesh: silbido de aire filtrado que baja de tono
    n = noise(0.14, attack=0.005, decay=0.06, sustain=0.3, release=0.06)
    t = t_array(0.14)
    s = lowpass(n, 3) * (0.6 + 0.4 * np.sin(2 * np.pi * 30 * t)) + tone(900, 300, 0.14, "sine", attack=0.005, decay=0.05, sustain=0.2, release=0.06) * 0.25
    save_wav(os.path.join(OUT, "swing.wav"), s)


def swing_heavy():
    n = lowpass(noise(0.25, attack=0.02, decay=0.1, sustain=0.3, release=0.1), 8)
    s = mix(n * 1.4, tone(260, 90, 0.25, "sine", attack=0.01, decay=0.1, sustain=0.3, release=0.1) * 0.6)
    save_wav(os.path.join(OUT, "swing_heavy.wav"), s)


def slam():
    # golpe contra el suelo: grave largo + crujido
    s = mix(
        tone(90, 30, 0.5, "sine", attack=0.002, decay=0.2, sustain=0.3, release=0.25),
        lowpass(noise(0.3, attack=0.001, decay=0.1, sustain=0.2, release=0.15), 12) * 1.5,
        tone(180, 60, 0.18, "square", attack=0.001, decay=0.06, sustain=0.2, release=0.08) * 0.3,
    )
    save_wav(os.path.join(OUT, "slam.wav"), s)


def roar():
    # rugido del Heraldo: sierra grave con vibrato + ruido rasposo
    t = t_array(1.1)
    vib = np.sin(2 * np.pi * 7 * t) * 12
    freq = np.linspace(120, 70, len(t)) + vib
    phase = np.cumsum(freq) / SR
    saw = (2 * (phase % 1.0) - 1) * envelope(len(t), attack=0.08, decay=0.3, sustain=0.6, release=0.4)
    rasp = lowpass(noise(1.1, attack=0.08, decay=0.3, sustain=0.5, release=0.4), 6) * (0.5 + 0.5 * np.sin(2 * np.pi * 23 * t))
    s = mix(lowpass(saw, 4), rasp * 1.2, tone(60, 45, 1.1, "sine", attack=0.1, decay=0.3, sustain=0.6, release=0.4) * 0.8)
    save_wav(os.path.join(OUT, "roar.wav"), s)


def charge_windup():
    s = tone(80, 220, 0.6, "saw", attack=0.05, decay=0.2, sustain=0.6, release=0.1)
    save_wav(os.path.join(OUT, "charge_windup.wav"), lowpass(s, 5))


def charge():
    s = mix(lowpass(noise(0.5, attack=0.01, decay=0.2, sustain=0.5, release=0.2), 5) * 1.3,
            tone(140, 70, 0.5, "square", attack=0.01, decay=0.2, sustain=0.4, release=0.2) * 0.3)
    save_wav(os.path.join(OUT, "charge.wav"), s)


def build():
    # piedra que se asienta + campanita dorada
    s = mix(
        tone(140, 60, 0.2, "sine", attack=0.002, decay=0.08, sustain=0.3, release=0.1),
        lowpass(noise(0.15, attack=0.001, decay=0.05, sustain=0.2, release=0.08), 8),
    )
    bell = mix(tone(988, 988, 0.5, "sine", attack=0.002, decay=0.2, sustain=0.2, release=0.25),
               tone(1480, 1480, 0.4, "sine", attack=0.002, decay=0.15, sustain=0.1, release=0.2) * 0.5)
    out = np.zeros(int(SR * 0.7))
    out[:len(s)] += s
    out[int(SR * 0.15):int(SR * 0.15) + len(bell)] += bell * 0.6
    save_wav(os.path.join(OUT, "build.wav"), out)


def bolt():
    s = mix(tone(1200, 500, 0.18, "sine", attack=0.002, decay=0.06, sustain=0.3, release=0.08),
            tone(1800, 900, 0.12, "square", attack=0.002, decay=0.04, sustain=0.2, release=0.05) * 0.2)
    save_wav(os.path.join(OUT, "bolt.wav"), s)


def alarm():
    # dos golpes de sistro y un tono de cuerno: urgente sin ser estridente
    out = np.zeros(int(SR * 0.6))
    for k, f in enumerate((660, 880)):
        tn = tone(f, f, 0.12, "square", attack=0.002, decay=0.04, sustain=0.5, release=0.05) * 0.6
        n = lowpass(noise(0.1, attack=0.001, decay=0.03, sustain=0.2, release=0.05), 2) * 0.4
        i = int(k * 0.16 * SR)
        out[i:i + len(tn)] += tn
        out[i:i + len(n)] += n
    horn = tone(220, 210, 0.3, "saw", attack=0.02, decay=0.1, sustain=0.5, release=0.1)
    i = int(0.3 * SR)
    out[i:i + len(horn)] += lowpass(horn, 6) * 0.7
    save_wav(os.path.join(OUT, "alarm.wav"), out)


def crop_lost():
    s = mix(tone(420, 90, 0.35, "saw", attack=0.002, decay=0.15, sustain=0.3, release=0.15),
            lowpass(noise(0.25, attack=0.001, decay=0.1, sustain=0.3, release=0.1), 4))
    save_wav(os.path.join(OUT, "crop_lost.wav"), lowpass(s, 3))


def drum_hit():
    # golpe de tambor grande + sistro: anuncio de oleada
    t = t_array(0.9)
    f = 70 * np.exp(-t * 5) + 45
    boom = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 4)
    rng = np.random.RandomState(9)
    n = rng.uniform(-1, 1, len(t))
    n = (n - lowpass(n, 3)) * np.exp(-t * 18) * 0.25
    save_wav(os.path.join(OUT, "drum_hit.wav"), boom + n, peak_dbfs=-9.0)


if __name__ == "__main__":
    for fn in (drum_hit, alarm, crop_lost, swing, swing_heavy, slam, roar, charge_windup, charge, build, bolt):
        fn()
    plant()
    hit_enemy()
    hit_player()
    enemy_death()
    till()
    water()
    harvest()
    ui_select()
    dusk_transform()
    coin()
    heart_shift()
    dodge()
    dialogue_blip()
