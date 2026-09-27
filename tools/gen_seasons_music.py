"""Musica de las estaciones del Nilo y jingles (fase 6).

Capas extra del MISMO largo y tempo que groove_*.wav (32 compases a 104 bpm,
hijaz sobre D), asi el MusicDirector las suma encima del groove sin cortes:
  estacion_peret.wav  arpa egipcia (Karplus-Strong con cuerpo) en arpegios:
                      la tierra que brota
  estacion_shemu.wav  riq (pandero de sonajas), palmas y ney con adornos:
                      fiesta de la cosecha
  estacion_akhet.wav  pad de agua que crece y baja, gotas pulsadas y ney
                      grave de notas largas: la crecida
Jingles cortos (sin loop, van al bus de efectos):
  jingle_amanecer.wav  arpa que sube (resumen del amanecer)
  jingle_logro.wav     arpegio brillante + sistro (amistad, templo, mejora)
  jingle_estacion.wav  frase de ney (cambio de estacion)

Instrumentos nuevos, mas organicos que los de gen_groove.py:
- arpa: Karplus-Strong con filtro de dos puntos, ataque de "pellizco" y
  resonancia de cuerpo (pasa-banda suave)
- ney: flauta de cana con aire (ruido filtrado), vibrato que entra tarde y
  armonicos impares suaves
- riq: sonajas metalicas (senos inarmonicos agudos con caida rapida)
"""
import os
import sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_groove as g  # mismas constantes, escala y utilidades

SR = g.SR
MUSIC = g.OUT
SFX = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio", "sfx")


# ------------------------------------------------------------ instrumentos
def harp(freq, dur, bright=0.55, seed=0):
    rng = np.random.RandomState(seed)
    n = int(dur * SR)
    per = max(2, int(round(SR / freq)))
    buf = rng.uniform(-1, 1, per) * np.hanning(per) * 1.6
    out = np.zeros(n)
    loss = 0.996 + bright * 0.003
    prev = 0.0
    for i in range(n):
        j = i % per
        v = buf[j]
        out[i] = v
        # promedio de dos puntos con algo de memoria: cuerda de tripa, calida
        nv = loss * (0.5 * v + 0.5 * buf[(j + 1) % per])
        nv = 0.8 * nv + 0.2 * prev
        prev = nv
        buf[j] = nv
    t = np.arange(n) / SR
    pinch = np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t * 40) * 0.25
    body = g.lp_fast(out, 3)
    return (body + pinch) * np.minimum(t / 0.004, 1.0)


def ney(freq, dur, breath=0.28, vib_depth=0.007):
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + vib_depth * np.sin(2 * np.pi * 5.1 * t) * np.clip((t - 0.25) / 0.4, 0, 1)
    ph = 2 * np.pi * np.cumsum(freq * vib) / SR
    tone = np.sin(ph) + 0.22 * np.sin(3 * ph) + 0.08 * np.sin(5 * ph) + 0.1 * np.sin(2 * ph)
    rng = np.random.RandomState(int(freq))
    # aire: ruido lento modulado por la propia nota -> banda estrecha
    # alrededor de la fundamental (soplido de cana, no siseo)
    air = g.lp_fast(rng.uniform(-1, 1, n), 24) * np.sin(ph) * 3.0
    chiff = rng.uniform(-1, 1, n) * np.exp(-t * 30) * 0.15  # golpe de aire al empezar
    env = g.env_adsr(n, 0.09, 0.1, 0.8, min(0.2, dur * 0.3))
    return (tone * 0.8 + air * breath + g.lp_fast(chiff, 6)) * env


def riq(seed=0, dur=0.25):
    rng = np.random.RandomState(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for f in rng.uniform(3500, 9500, 7):
        out += np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28))
    hiss = rng.uniform(-1, 1, n)
    hiss = hiss - g.lp_fast(hiss, 3)
    return (out / 7 * 0.6 + hiss * 0.4) * np.exp(-t * 22)


def clap(seed=0):
    rng = np.random.RandomState(seed + 50)
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    x = rng.uniform(-1, 1, n)
    x = g.lp_fast(x, 2) - g.lp_fast(x, 12)
    env = np.exp(-t * 35) + 0.5 * np.exp(-np.abs(t - 0.012) * 300)
    return x * env


def pad(freqs, n, lfo_cycles, phase=0.0):
    """Pad de agua: senos con ciclos enteros (loop perfecto) y oleaje lento."""
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k, f in enumerate(freqs):
        cyc = round(f * n / SR)
        ff = cyc * SR / n
        out += np.sin(2 * np.pi * ff * t) + 0.3 * np.sin(2 * np.pi * 2 * ff * t)
    lfo = 0.55 + 0.45 * np.sin(2 * np.pi * lfo_cycles * t / (n / SR) + phase)
    return out / len(freqs) * lfo


# ------------------------------------------------------------ capas
def peret_layer(tr, bars):
    # arpa en arpegios que suben y bajan sobre el acorde de cada compas
    for bar in range(bars):
        c = g.chord_for(bar)
        pattern = (0, 2, 4, 7, 9, 7, 4, 2) if bar % 2 == 0 else (0, 4, 7, 11, 7, 4, 2, 4)
        for k, dd in enumerate(pattern):
            tr.add(harp(g.deg(c + dd, 0), 0.9, 0.5, seed=bar * 11 + k), bar * 4 + k * 0.5, 0.16)
    # cada 8 compases, una respuesta aguda del arpa
    for bar in range(3, bars, 8):
        for k, dd in enumerate((7, 8, 9, 11, 9)):
            tr.add(harp(g.deg(dd, 1), 1.2, 0.7, seed=900 + bar + k), bar * 4 + 2 + k * 0.25, 0.1)


def shemu_layer(tr, bars):
    for bar in range(bars):
        b0 = bar * 4
        # riq: corcheas con acento en el contratiempo
        for k in range(8):
            tr.add(riq(bar * 8 + k, 0.18), b0 + k * 0.5, 0.1 if k % 2 == 0 else 0.16)
        # palmas del festival en 2 y 4 (y una sincopa)
        tr.add(clap(bar), b0 + 1, 0.3)
        tr.add(clap(bar + 3), b0 + 3, 0.3)
        if bar % 2 == 1:
            tr.add(clap(bar + 9), b0 + 3.5, 0.2)
    # ney con adornos: responde al gancho en los compases pares de cada bloque
    phrase = [(4, 0.5), (5, 0.25), (4, 0.25), (2, 1.0), (3, 0.5), (2, 0.5), (1, 1.0)]
    for block in range(bars // 4):
        t0 = block * 16 + 8
        t = t0
        for d, du in phrase:
            tr.add(ney(g.deg(d, 1), du * tr.beat * 1.05), t, 0.12)
            t += du


def akhet_layer(tr, bars):
    n = tr.n
    # agua que crece y baja: dos pads en contrafase
    tr.buf += pad([g.deg(0, -1), g.deg(4, -1), g.deg(7, -1)], n, 4) * 0.09
    tr.buf += pad([g.deg(2, 0), g.deg(6, -1)], n, 3, phase=np.pi) * 0.05
    # gotas: pulsos de arpa muy agudos y espaciados
    rng = np.random.RandomState(21)
    for bar in range(bars):
        for k in range(2):
            pos = bar * 4 + rng.choice([0.5, 1.25, 2.0, 2.75, 3.5])
            tr.add(harp(g.deg(int(rng.choice([7, 9, 11, 14])), 1), 0.5, 0.9, seed=bar * 3 + k), pos, 0.07)
    # ney grave de notas largas, una frase cada 8 compases
    for bar in range(0, bars, 8):
        for k, (d, du) in enumerate(((0, 6), (1, 2), (0, 4), (-3, 4))):
            tr.add(ney(g.deg(d, 0), du * tr.beat, breath=0.35, vib_depth=0.005), bar * 4 + sum(x[1] for x in ((0, 6), (1, 2), (0, 4), (-3, 4))[:k]), 0.1)


# ------------------------------------------------------------ jingles
def save_jingle(name, x, peak_db=-10.0):
    x = np.asarray(x, dtype=np.float64)
    fade = int(0.05 * SR)
    x[-fade:] *= np.linspace(1, 0, fade)
    p = np.max(np.abs(x))
    x = x / p * 10 ** (peak_db / 20)
    import wave
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(SFX, name + ".wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", name)


def place(buf, sig, t):
    i = int(t * SR)
    end = min(len(buf), i + len(sig))
    buf[i:end] += sig[:end - i]


def jingles():
    # amanecer: arpa que sube por el acorde de D (hijaz) y se queda sonando
    out = np.zeros(int(3.2 * SR))
    for k, dd in enumerate((0, 2, 4, 7, 9, 11, 14)):
        place(out, harp(g.deg(dd, 0), 2.4, 0.6, seed=k), k * 0.13)
    save_jingle("jingle_amanecer", out)
    # logro: arpegio brillante rapido + sistro
    out = np.zeros(int(2.0 * SR))
    for k, dd in enumerate((4, 7, 9, 11, 14)):
        place(out, harp(g.deg(dd, 1), 1.4, 0.8, seed=40 + k), k * 0.07)
    place(out, g.sistrum(3) * 0.8, 0.35)
    place(out, g.epiano([g.deg(14, 1), g.deg(18, 1)], 1.2) * 0.5, 0.35)
    save_jingle("jingle_logro", out)
    # estacion: frase de ney sobre un bordon
    out = np.zeros(int(3.6 * SR))
    t = 0.0
    for d, du in ((4, 0.35), (5, 0.2), (4, 0.2), (2, 0.6), (1, 0.35), (0, 1.4)):
        place(out, ney(g.deg(d, 1), du + 0.15), t)
        t += du
    tt = np.arange(len(out)) / SR
    out += np.sin(2 * np.pi * g.deg(0, -1) * tt) * 0.15 * np.minimum(tt / 0.4, 1.0)
    save_jingle("jingle_estacion", out)


def main():
    loudest = None
    tracks = {}
    for name, fn in (("estacion_peret", peret_layer), ("estacion_shemu", shemu_layer), ("estacion_akhet", akhet_layer)):
        tr = g.Track(g.BARS, g.BPM)
        fn(tr, g.BARS)
        tracks[name] = tr
    # misma ganancia que el groove: se miden contra la mezcla base+dia
    ref = g.Track(g.BARS, g.BPM)
    g.base_layer(ref, g.BARS)
    d = g.Track(g.BARS, g.BPM)
    g.day_layer(d, g.BARS)
    for name, tr in tracks.items():
        loud = np.max(np.abs(ref.buf + d.buf + tr.buf))
        gain = 10 ** (-3 / 20) / loud
        x = np.tanh(tr.buf * gain * 1.2) / 1.2
        import wave
        pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
        with wave.open(os.path.join(MUSIC, name + ".wav"), "w") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        print("wrote", name, f"{len(x)/SR:.1f}s")
    jingles()


if __name__ == "__main__":
    main()
