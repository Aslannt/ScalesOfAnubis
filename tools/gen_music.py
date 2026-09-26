"""Loops musicales simples generados por sintesis (escala menor de sabor
'oriental' con segunda aumentada, para la sensacion egipcia que pide el GDD).
No es una composicion elaborada, pero es 100% propia y da ambiente por fase."""
import os
import numpy as np
import wave

SR = 22050
OUT = os.path.join("..", "assets", "audio", "music")
os.makedirs(OUT, exist_ok=True)

# Escala "egipcia" (doble menor armonica): tonica, 2m, 3M, 4, 5, b6, 7M
ROOT = 220.0  # A3
SCALE_RATIOS = [1.0, 9/8, 5/4, 4/3, 3/2, 8/5, 15/8]


def save_wav(path, samples):
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", path, f"{len(samples)/SR:.1f}s")


def note(freq, dur, vol=0.3, harmonics=(1.0, 0.5, 0.25)):
    t = np.linspace(0, dur, int(SR * dur), endpoint=False)
    sig = np.zeros_like(t)
    for i, h in enumerate(harmonics):
        sig += h * np.sin(2 * np.pi * freq * (i + 1) * t)
    fade = min(0.05, dur * 0.3)
    n_fade = int(fade * SR)
    env = np.ones_like(t)
    env[:n_fade] = np.linspace(0, 1, n_fade)
    env[-n_fade:] = np.linspace(1, 0, n_fade)
    return sig * env * vol


def silence(dur):
    return np.zeros(int(SR * dur))


def build_loop(pattern, note_dur, vol=0.3, harmonics=(1.0, 0.5, 0.25)):
    """pattern: lista de indices de escala (o None = silencio)."""
    chunks = []
    for idx in pattern:
        if idx is None:
            chunks.append(silence(note_dur))
        else:
            octave, degree = idx
            freq = ROOT * SCALE_RATIOS[degree % len(SCALE_RATIOS)] * (2 ** octave)
            chunks.append(note(freq, note_dur, vol, harmonics))
    return np.concatenate(chunks)


def day_theme():
    melody = [(1, 0), (1, 2), (1, 4), (1, 2), (1, 0), None, (1, 4), (1, 5),
              (1, 4), (1, 2), (1, 0), None, (1, 2), (1, 4), (1, 2), None]
    bass = [(0, 0)] * 8 + [(0, 3)] * 8
    m = build_loop(melody, 0.4, vol=0.22, harmonics=(1.0, 0.3))
    b = build_loop(bass, 0.4, vol=0.18, harmonics=(1.0, 0.6, 0.3))
    mixed = m + b
    save_wav(os.path.join(OUT, "dia.wav"), mixed)


def night_theme():
    melody = [(1, 0), None, (1, 1), (1, 0), None, (1, 5), (1, 0), None,
              (1, 3), None, (1, 1), (1, 0), None, (1, 5), (1, 6), None]
    bass = [(-1, 0)] * 16
    m = build_loop(melody, 0.5, vol=0.2, harmonics=(1.0, 0.4, 0.2))
    b = build_loop(bass, 0.5, vol=0.24, harmonics=(1.0, 0.7, 0.5, 0.3))
    mixed = m + b
    save_wav(os.path.join(OUT, "noche.wav"), mixed)


def boss_theme():
    melody = [(1, 0), (1, 1), (1, 0), (1, 6), (1, 0), (1, 1), (1, 3), (1, 6)]
    bass = [(-1, 0), (-1, 0), (-1, 1), (-1, 1)] * 2
    m = build_loop(melody, 0.28, vol=0.26, harmonics=(1.0, 0.5, 0.3, 0.15))
    b = build_loop(bass, 0.28, vol=0.3, harmonics=(1.0, 0.8, 0.5))
    mixed = m + b
    save_wav(os.path.join(OUT, "jefe.wav"), mixed)


if __name__ == "__main__":
    day_theme()
    night_theme()
    boss_theme()
