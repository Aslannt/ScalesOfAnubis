"""Musica propia por sintesis (M10, GDD 9): loops largos y sin cortes.
Instrumentos sintetizados con numpy:
- arpa: cuerda pulsada Karplus-Strong
- ney (flauta de cana): seno con vibrato, armonicos suaves y soplo
- darbuka/tar: 'doum' grave y 'tek' agudo (ruido filtrado + tono)
- sistro: sonajero de metal (ruido agudo con ecos)
- bordon: quinta grave sostenida
Escala doble armonica (hijaz con 7M), la sonoridad "egipcia/oriental" que
pide CLAUDE.md. Todo deterministico. Se escribe a assets/audio/music/.
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio", "music")
os.makedirs(OUT, exist_ok=True)

# La musica queda un poco por encima de los efectos (SFX a -12 dBFS de pico,
# ver gen_sfx.py): pico de -6 dBFS, que por ser continua se oye como fondo.
PEAK_DBFS = -6.0

# doble armonica sobre D: D Eb F# G A Bb C#
SCALE = [0, 1, 4, 5, 7, 8, 11]
ROOT_HZ = 146.83  # D3


def hz(degree, octave=0):
    o, d = divmod(degree, 7)
    return ROOT_HZ * 2 ** ((SCALE[d] + 12 * (o + octave)) / 12.0)


def save_wav(path, samples, peak_dbfs=PEAK_DBFS):
    samples = np.asarray(samples, dtype=np.float64)
    peak = np.max(np.abs(samples))
    if peak > 1e-9:
        samples = samples / peak * (10.0 ** (peak_dbfs / 20.0))
    # cierre del loop sin clic: rampa corta que lleva el ultimo tramo al
    # valor de la primera muestra
    k = min(len(samples), 400)
    samples[-k:] += (samples[0] - samples[-1]) * np.linspace(0.0, 1.0, k) ** 2
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", path, f"{len(samples)/SR:.1f}s")


def place(buf, sig, t):
    """Suma sig en buf a partir del segundo t, con vuelta al inicio (loop
    perfecto: las colas que pasan del final suenan al principio)."""
    i = int(t * SR) % len(buf)
    n = len(sig)
    end = i + n
    if end <= len(buf):
        buf[i:end] += sig
    else:
        k = len(buf) - i
        buf[i:] += sig[:k]
        rest = sig[k:]
        while len(rest) > 0:
            m = min(len(rest), len(buf))
            buf[:m] += rest[:m]
            rest = rest[m:]


# ---------------------------------------------------------- instrumentos
def harp(freq, dur=2.2, bright=0.5, rng=None):
    rng = rng or np.random.RandomState(0)
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, period)
    out = np.zeros(n)
    decay = 0.996 - (1 - bright) * 0.004
    for i in range(n):
        out[i] = buf[i % period]
        j = (i + 1) % period
        buf[i % period] = decay * 0.5 * (buf[i % period] + buf[j])
    env = np.minimum(1.0, np.linspace(0, 40, n)) * np.exp(-np.linspace(0, 3.0, n))
    return out * env


def ney(freq, dur, vib=5.5, breath=0.08, rng=None):
    rng = rng or np.random.RandomState(1)
    t = np.arange(int(SR * dur)) / SR
    v = 1 + 0.012 * np.sin(2 * np.pi * vib * t) * np.minimum(1, t / 0.4)
    ph = 2 * np.pi * freq * np.cumsum(v) / SR
    sig = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.1 * np.sin(3 * ph)
    noise = rng.uniform(-1, 1, len(t))
    noise = np.convolve(noise, np.ones(6) / 6, mode="same")
    att = min(0.12, dur * 0.3)
    env = np.minimum(1, t / att) * np.minimum(1, (dur - t) / min(0.25, dur * 0.4))
    return (sig + noise * breath * 4) * np.clip(env, 0, 1)


def reed(freq, dur, rng=None):
    """Instrumento de lengueta nasal (para la noche): sierra filtrada."""
    t = np.arange(int(SR * dur)) / SR
    v = 1 + 0.008 * np.sin(2 * np.pi * 6 * t)
    ph = freq * np.cumsum(v) / SR
    saw = 2 * (ph % 1.0) - 1
    saw = np.convolve(saw, np.ones(5) / 5, mode="same")
    env = np.minimum(1, t / 0.05) * np.minimum(1, (dur - t) / 0.15)
    return saw * np.clip(env, 0, 1)


def doum(amp=1.0):
    t = np.arange(int(SR * 0.45)) / SR
    f = 90 * np.exp(-t * 6) + 55
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)
    return s * amp


def tek(amp=0.6, rng=None):
    rng = rng or np.random.RandomState(2)
    t = np.arange(int(SR * 0.09)) / SR
    n = rng.uniform(-1, 1, len(t))
    n = n - np.convolve(n, np.ones(4) / 4, mode="same")  # pasa-altos
    return (n * 0.8 + np.sin(2 * np.pi * 820 * t) * 0.4) * np.exp(-t * 55) * amp


def sistrum(amp=0.35, rng=None):
    rng = rng or np.random.RandomState(3)
    out = np.zeros(int(SR * 0.4))
    for k in range(3):
        t = np.arange(int(SR * 0.12)) / SR
        n = rng.uniform(-1, 1, len(t))
        n = n - np.convolve(n, np.ones(3) / 3, mode="same")
        ring = np.sin(2 * np.pi * 3400 * t) * 0.3 + np.sin(2 * np.pi * 5100 * t) * 0.2
        s = (n + ring) * np.exp(-t * 30) * amp * (0.8 ** k)
        i = int(k * 0.06 * SR)
        out[i:i + len(s)] += s
    return out


def drone(freqs, length, amp=0.18):
    t = np.arange(length) / SR
    s = np.zeros(length)
    for f in freqs:
        # frecuencias ajustadas para que el loop cierre sin clic
        cycles = round(f * length / SR)
        ff = cycles * SR / length
        s += np.sin(2 * np.pi * ff * t) + 0.3 * np.sin(4 * np.pi * ff * t)
    lfo_c = max(1, round(0.1 * length / SR))
    lfo = 0.8 + 0.2 * np.sin(2 * np.pi * lfo_c * t / (length / SR))
    return s * amp * lfo / len(freqs)


def echo(buf, delay_s, fb, mix):
    """Eco circular (el loop sigue perfecto)."""
    d = int(delay_s * SR)
    out = buf.copy()
    tap = buf.copy()
    for k in range(4):
        tap = np.roll(tap, d) * fb
        out += tap * mix
    return out


# ---------------------------------------------------------- piezas
def day_theme():
    bpm = 84
    beat = 60 / bpm
    bars = 24  # 4/4
    length = int(SR * beat * 4 * bars)
    buf = np.zeros(length)
    rng = np.random.RandomState(10)
    buf += drone([hz(0, -1), hz(4, -1)], length, amp=0.10)
    # arpa: arpegios que cambian cada 4 compases (I - iv - I - bVI - I - V)
    prog = [0, 3, 0, 5, 0, 4]
    for bar in range(bars):
        root = prog[(bar // 4) % len(prog)]
        pattern = [0, 2, 4, 7, 4, 2, 0, 4]
        for k, deg in enumerate(pattern):
            t = (bar * 4 + k * 0.5) * beat
            f = hz(root + deg, 0)
            place(buf, harp(f, 1.6, bright=0.6, rng=rng) * 0.22, t)
    # ney: melodia en frases, respirando entre frases
    phrases = [
        [(4, 1.5), (5, 0.5), (4, 1.0), (2, 1.0), (1, 2.0), (0, 2.0)],
        [(0, 1.0), (1, 0.5), (2, 0.5), (4, 2.0), (5, 1.0), (4, 1.0), (2, 2.0)],
        [(7, 1.5), (6, 0.5), (5, 1.0), (4, 1.0), (5, 1.0), (4, 1.0), (2, 2.0)],
        [(4, 1.0), (2, 1.0), (1, 1.0), (2, 1.0), (1, 2.0), (0, 2.0)],
    ]
    t = 8 * beat
    for rep in range(2):
        for ph in phrases:
            for deg, d in ph:
                place(buf, ney(hz(deg, 1), d * beat * 0.98, rng=rng) * 0.16, t)
                t += d * beat
            t += 0 * beat
    # percusion suave: doum en 1, tek en 2.5 y 4
    for bar in range(bars):
        b0 = bar * 4 * beat
        place(buf, doum(0.5), b0)
        place(buf, tek(0.18, rng), b0 + 1.5 * beat)
        place(buf, tek(0.14, rng), b0 + 3 * beat)
        if bar % 2 == 1:
            place(buf, doum(0.35), b0 + 2.5 * beat)
        if bar % 4 == 3:
            place(buf, sistrum(0.18, rng), b0 + 3.5 * beat)
    buf = echo(buf, beat * 0.75, 0.35, 0.3)
    save_wav(os.path.join(OUT, "dia.wav"), buf)


def night_theme():
    bpm = 96
    beat = 60 / bpm
    bars = 24
    length = int(SR * beat * 4 * bars)
    buf = np.zeros(length)
    rng = np.random.RandomState(20)
    buf += drone([hz(0, -2), hz(0, -1), hz(1, -1)], length, amp=0.16)
    # ostinato grave de arpa oscura
    ost = [0, 1, 0, 4, 0, 1, 5, 4]
    for bar in range(bars):
        for k, deg in enumerate(ost):
            place(buf, harp(hz(deg, -1), 1.2, bright=0.3, rng=rng) * 0.25, (bar * 4 + k * 0.5) * beat)
    # lengueta nasal: motivo tenso que sube
    motif = [(0, 1), (1, 1), (0, 0.5), (1, 0.5), (4, 1), (5, 2), (4, 1), (1, 1), (0, 2), (None, 2)]
    t = 4 * beat
    while t < length / SR - 6 * beat:
        for deg, d in motif:
            if deg is not None:
                place(buf, reed(hz(deg, 1), d * beat * 0.95, rng) * 0.1, t)
            t += d * beat
    # percusion marcada: maqsum (doum tek - tek doum - tek -)
    for bar in range(bars):
        b0 = bar * 4 * beat
        for pos, kind in ((0, "D"), (1, "T"), (1.5, "T"), (2, "D"), (3, "T"), (3.5, "t")):
            if kind == "D":
                place(buf, doum(0.9), b0 + pos * beat)
            else:
                place(buf, tek(0.4 if kind == "T" else 0.22, rng), b0 + pos * beat)
        if bar % 2 == 1:
            place(buf, sistrum(0.3, rng), b0 + 3.5 * beat)
    buf = echo(buf, beat * 0.5, 0.3, 0.25)
    save_wav(os.path.join(OUT, "noche.wav"), buf)


def boss_theme():
    bpm = 132
    beat = 60 / bpm
    bars = 16
    length = int(SR * beat * 4 * bars)
    buf = np.zeros(length)
    rng = np.random.RandomState(30)
    buf += drone([hz(0, -2), hz(1, -2)], length, amp=0.2)
    # riff agresivo de lengueta + arpa doblando
    riff = [0, 1, 0, 1, 4, 5, 4, 1, 0, 1, 0, 6, 5, 4, 1, 0]
    for bar in range(bars):
        up = 1 if (bar // 4) % 2 == 1 else 0
        for k, deg in enumerate(riff[(bar % 2) * 8:(bar % 2) * 8 + 8]):
            t = (bar * 4 + k * 0.5) * beat
            place(buf, reed(hz(deg + up, 0), beat * 0.45, rng) * 0.14, t)
            place(buf, harp(hz(deg + up, -1), 0.6, bright=0.4, rng=rng) * 0.16, t)
    # tambores de guerra
    for bar in range(bars):
        b0 = bar * 4 * beat
        for pos in (0, 0.75, 1.5, 2, 2.5, 3, 3.25, 3.5):
            place(buf, doum(1.0 if pos in (0, 2) else 0.6), b0 + pos * beat)
        for pos in (1, 3):
            place(buf, tek(0.55, rng), b0 + pos * beat)
        place(buf, sistrum(0.25, rng), b0 + 3.75 * beat)
    buf = echo(buf, beat * 0.25, 0.25, 0.2)
    save_wav(os.path.join(OUT, "jefe.wav"), buf)


def title_theme():
    """Tema del menu, la intro y el final: lento, sin tambores."""
    bpm = 66
    beat = 60 / bpm
    bars = 16
    length = int(SR * beat * 4 * bars)
    buf = np.zeros(length)
    rng = np.random.RandomState(50)
    buf += drone([hz(0, -2), hz(4, -2), hz(0, -1)], length, amp=0.14)
    for bar in range(bars):
        root = [0, 0, 5, 4][(bar // 2) % 4]
        for k, deg in enumerate([0, 4, 7, 9]):
            place(buf, harp(hz(root + deg, -1), 2.5, bright=0.5, rng=rng) * 0.2, (bar * 4 + k) * beat)
    melody = [(4, 3), (5, 1), (4, 2), (2, 2), (1, 4), (None, 4), (2, 2), (4, 2), (5, 2), (7, 2), (5, 4), (None, 4),
              (7, 3), (6, 1), (5, 2), (4, 2), (2, 4), (None, 4), (1, 2), (2, 2), (1, 2), (0, 2), (0, 4), (None, 4)]
    t = 4 * beat
    for deg, d in melody:
        if deg is not None and t + d * beat < length / SR:
            place(buf, ney(hz(deg, 1), d * beat * 0.97, vib=4.5, rng=rng) * 0.14, t)
        t += d * beat
    buf = echo(buf, beat, 0.4, 0.35)
    save_wav(os.path.join(OUT, "titulo.wav"), buf)


def _lp(sig, n):
    k = np.ones(n) / n
    # convolucion circular para mantener el loop
    ext = np.concatenate([sig[-n:], sig, sig[:n]])
    return np.convolve(ext, k, mode="same")[n:-n]


def ambience_day():
    """Viento suave, rumor del Nilo y pajaros ocasionales (20 s en loop)."""
    length = SR * 20
    rng = np.random.RandomState(40)
    t = np.arange(length) / SR
    wind = _lp(rng.uniform(-1, 1, length), 40) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 10.0)) * 3.0
    river = _lp(rng.uniform(-1, 1, length), 8) * 0.5
    buf = wind + river
    for k in range(9):
        t0 = rng.uniform(0, 19)
        f0 = rng.uniform(2200, 3600)
        n = int(SR * rng.uniform(0.08, 0.16))
        tt = np.arange(n) / SR
        chirp = np.sin(2 * np.pi * np.cumsum(f0 + 1400 * np.sin(np.pi * tt / tt[-1])) / SR) * np.sin(np.pi * tt / tt[-1])
        for rep in range(rng.randint(1, 4)):
            place(buf, chirp * 0.35, t0 + rep * 0.18)
    save_wav(os.path.join(OUT, "amb_dia.wav"), buf, peak_dbfs=-15.0)


def ambience_night():
    """Grillos, viento bajo y algun graznido lejano (20 s en loop)."""
    length = SR * 20
    rng = np.random.RandomState(41)
    t = np.arange(length) / SR
    wind = _lp(rng.uniform(-1, 1, length), 60) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 20.0)) * 3.0
    buf = wind
    for g in range(3):
        f = 4300 + g * 350
        rate = 16 + g * 3
        period = rng.uniform(0.6, 1.1)
        for k in range(int(20 / period)):
            t0 = k * period + rng.uniform(0, 0.1)
            n = int(SR * 0.18)
            tt = np.arange(n) / SR
            pulse = (np.sin(2 * np.pi * rate * tt) > 0.3).astype(float)
            chirp = np.sin(2 * np.pi * f * tt) * pulse * np.sin(np.pi * tt / tt[-1])
            place(buf, chirp * 0.12, t0)
    save_wav(os.path.join(OUT, "amb_noche.wav"), buf, peak_dbfs=-15.0)


if __name__ == "__main__":
    title_theme()
    ambience_day()
    ambience_night()
    day_theme()
    night_theme()
    boss_theme()
