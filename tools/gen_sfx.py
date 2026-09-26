"""Genera SFX cortos estilo sfxr por sintesis (numpy -> WAV). Nada de audio de
terceros: todo generado por script segun pide CLAUDE.md.
"""
import os
import numpy as np
import wave

SR = 22050
OUT = os.path.join("..", "assets", "audio", "sfx")
os.makedirs(OUT, exist_ok=True)


def save_wav(path, samples):
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


def till():
    s = mix(
        noise(0.12, attack=0.001, decay=0.05, sustain=0.3, release=0.06),
        tone(150, 90, 0.1, "square", attack=0.001, decay=0.04, sustain=0.2, release=0.05) * 0.5,
    )
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


if __name__ == "__main__":
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
