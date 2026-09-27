"""Soundtrack adaptativo "estilo Balatro", pero egipcio (pedido de Deivid).
Lo que lo hace adictivo y aqui se imita:
- groove constante a tempo medio (104 bpm) con bajo que "camina"
- acordes cortos de piano electrico a contratiempo
- un gancho melodico de 4 compases que se repite con variaciones
- sintes levemente desafinados con vibrato y "wobble" de cinta (el tono
  entero ondula despacio, como un casete)
Sabor egipcio: escala hijaz sobre D (D Eb F# G A Bb C), darbuka, sistro,
ney sintetico. Todo por sintesis propia (numpy).

Capas del MISMO largo y tempo (se reproducen juntas y el juego sube/baja su
volumen, asi la musica nunca se corta al cambiar de fase):
  groove_base.wav   bajo + acordes + percusion suave      (siempre)
  groove_dia.wav    gancho en sinte calido                  (dia)
  groove_noche.wav  darbuka fuerte + gancho en lengueta + bordon (noche)
Aparte: titulo.wav (version lounge) y jefe.wav (version rapida y furiosa).
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio", "music")
BPM = 104
BEAT = 60.0 / BPM
BARS = 32
ROOT = 146.83  # D3
HIJAZ = [0, 1, 4, 5, 7, 8, 10]  # D Eb F# G A Bb C


def note_hz(semi, octave=0):
    return ROOT * 2 ** ((semi + 12 * octave) / 12.0)


def deg(d, octave=0):
    o, i = divmod(d, 7)
    return note_hz(HIJAZ[i], octave + o)


def save(path, x, peak_db=-6.0):
    x = np.asarray(x, dtype=np.float64)
    p = np.max(np.abs(x))
    if p > 1e-9:
        x = x / p * 10 ** (peak_db / 20)
    k = min(len(x), 400)
    x[-k:] += (x[0] - x[-1]) * np.linspace(0, 1, k) ** 2
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", os.path.basename(path), f"{len(x)/SR:.1f}s")


class Track:
    def __init__(self, bars, bpm):
        self.beat = 60.0 / bpm
        self.n = int(round(SR * self.beat * 4 * bars))
        self.buf = np.zeros(self.n)
        # wobble de cinta comun a todo lo melodico (+-14 cents, ~0.23 Hz),
        # con frecuencia entera de ciclos para que el loop cierre perfecto
        t = np.arange(self.n) / SR
        cycles = max(1, round(0.23 * self.n / SR))
        self.wobble = 2 ** (0.14 / 12 * np.sin(2 * np.pi * cycles * t / (self.n / SR)))

    def add(self, sig, t_beats, gain=1.0):
        i = int(round(t_beats * self.beat * SR)) % self.n
        sig = sig * gain
        end = i + len(sig)
        if end <= self.n:
            self.buf[i:end] += sig
        else:
            k = self.n - i
            self.buf[i:] += sig[:k]
            self.buf[:len(sig) - k] += sig[k:]


def env_adsr(n, a, d, s, r):
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    sus = max(0, n - a - d - r)
    e = np.concatenate([np.linspace(0, 1, max(a, 1)), np.linspace(1, s, max(d, 1)), np.full(sus, s), np.linspace(s, 0, max(r, 1))])
    return np.pad(e, (0, max(0, n - len(e))))[:n]


def lp(x, a):
    """Pasa-bajos de un polo (a en 0..1, mas chico = mas oscuro)."""
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc)
        y[i] = acc
    return y


def lp_fast(x, width):
    return np.convolve(x, np.ones(width) / width, mode="same")


# ------------------------------------------------------------ instrumentos
def bass(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * freq * t
    s = np.sin(ph) + 0.35 * np.sin(2 * ph) + 0.15 * np.sign(np.sin(ph)) * 0.5
    return s * env_adsr(n, 0.004, 0.12, 0.55, 0.05)


def epiano(freqs, dur):
    """Acorde de piano electrico (FM 1:1 con indice que decae)."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    idx = 2.2 * np.exp(-t * 14)
    for f in freqs:
        out += np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * t))
    return out / len(freqs) * env_adsr(n, 0.003, 0.18, 0.25, 0.06)


def pluck(freq, dur, bright=0.5, seed=0):
    rng = np.random.RandomState(seed)
    n = int(dur * SR)
    per = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, per)
    out = np.zeros(n)
    dec = 0.994 + bright * 0.004
    for i in range(n):
        j = i % per
        out[i] = buf[j]
        buf[j] = dec * 0.5 * (buf[j] + buf[(j + 1) % per])
    return out * np.exp(-np.linspace(0, 2.5, n))


def lead_line(track, notes, voice="synth", gain=1.0, octave=1, glide=0.03):
    """Linea melodica continua con glide entre notas.
    notes: lista de (inicio_en_beats, duracion_en_beats, grado | None)."""
    n = track.n
    freq = np.zeros(n)
    amp = np.zeros(n)
    for st, du, d in notes:
        if d is None:
            continue
        i0 = int(st * track.beat * SR)
        i1 = int((st + du) * track.beat * SR)
        f = deg(d, octave)
        seg = i1 - i0
        prev = freq[i0 - 1] if i0 > 0 and freq[i0 - 1] > 0 else f
        g = min(seg, int(glide * SR))
        fr = np.full(seg, f)
        if g > 0:
            fr[:g] = np.linspace(prev, f, g)
        idx = np.arange(i0, i1) % n
        freq[idx] = fr
        a = env_adsr(seg, 0.01, 0.08, 0.8, min(0.08, du * track.beat * 0.3))
        amp[idx] = np.maximum(amp[idx], a)
    t = np.arange(n) / SR
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t)
    f = freq * track.wobble * vib
    f[f <= 0] = 1.0
    ph = np.cumsum(f) / SR
    if voice == "synth":
        # dos sierras desafinadas (+-9 cents) + cuadrada suave: calido y "barato"
        d = 2 ** (9 / 1200)
        saw1 = 2 * ((ph * d) % 1.0) - 1
        saw2 = 2 * ((ph / d) % 1.0) - 1
        sq = np.sign(np.sin(2 * np.pi * ph)) * 0.3
        s = lp_fast(saw1 + saw2 + sq, 9)
    else:  # "reed": lengueta nasal (mizmar sintetico)
        saw = 2 * (ph % 1.0) - 1
        s = lp_fast(saw, 4) + 0.4 * np.sin(2 * np.pi * 2 * ph)
    track.buf += s * amp * gain


def kick():
    t = np.arange(int(SR * 0.3)) / SR
    f = 110 * np.exp(-t * 30) + 45
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 12)


def snap(seed=1):
    rng = np.random.RandomState(seed)
    t = np.arange(int(SR * 0.12)) / SR
    nz = rng.uniform(-1, 1, len(t))
    nz = nz - lp_fast(nz, 6)
    return (nz * 0.8 + np.sin(2 * np.pi * 330 * t) * 0.4) * np.exp(-t * 35)


def shaker(seed=2):
    rng = np.random.RandomState(seed)
    t = np.arange(int(SR * 0.06)) / SR
    nz = rng.uniform(-1, 1, len(t))
    nz = nz - lp_fast(nz, 3)
    return nz * np.exp(-t * 60)


def doum():
    t = np.arange(int(SR * 0.4)) / SR
    f = 95 * np.exp(-t * 7) + 58
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)


def tek(seed=3):
    rng = np.random.RandomState(seed)
    t = np.arange(int(SR * 0.08)) / SR
    nz = rng.uniform(-1, 1, len(t))
    nz = nz - lp_fast(nz, 4)
    return (nz * 0.7 + np.sin(2 * np.pi * 900 * t) * 0.5) * np.exp(-t * 55)


def sistrum(seed=4):
    rng = np.random.RandomState(seed)
    out = np.zeros(int(SR * 0.35))
    for k in range(3):
        t = np.arange(int(SR * 0.1)) / SR
        nz = rng.uniform(-1, 1, len(t))
        nz = nz - lp_fast(nz, 3)
        s = (nz + np.sin(2 * np.pi * 3600 * t) * 0.3) * np.exp(-t * 32) * 0.8 ** k
        i = int(k * 0.05 * SR)
        out[i:i + len(s)] += s
    return out


# --------------------------------------------------------------- armonia
# acordes (grados de la escala para la triada) por compas, forma A A B A'
PROG_A = [0, 3, 1, 0]   # D - G - Eb - D     (hijaz: I - iv - bII - I)
PROG_B = [3, 6, 1, 4]   # G - C - Eb - A
FORM = PROG_A * 2 + PROG_B + PROG_A  # 16 compases; se repite 2 veces = 32


def chord_for(bar):
    return FORM[bar % len(FORM)]


def triad(root_deg, octave=0):
    return [deg(root_deg, octave), deg(root_deg + 2, octave), deg(root_deg + 4, octave)]


# el gancho: 4 compases en corcheas (grado, duracion en beats)
HOOK = [
    (4, 1.0), (2, 0.5), (3, 0.5), (4, 1.0), (5, 0.5), (4, 0.5),
    (3, 0.5), (2, 0.5), (1, 1.0), (2, 1.0), (None, 1.0),
    (1, 0.5), (2, 0.5), (3, 1.0), (2, 0.5), (1, 0.5), (0, 1.0), (1, 0.5), (2, 0.5),
    (0, 2.0), (None, 2.0),
]
HOOK_B = [
    (7, 1.0), (6, 0.5), (5, 0.5), (4, 1.0), (5, 1.0),
    (6, 0.5), (5, 0.5), (4, 0.5), (3, 0.5), (4, 2.0),
    (3, 0.5), (4, 0.5), (5, 1.0), (4, 0.5), (3, 0.5), (2, 1.0), (1, 1.0),
    (2, 1.0), (1, 1.0), (0, 2.0),
]


def hook_notes(bars, swing=0.12):
    """Gancho a lo largo de toda la pieza con swing en las corcheas."""
    notes = []
    for block in range(bars // 4):
        section = (block % 4)
        phrase = HOOK_B if section == 2 else HOOK
        t = block * 16.0
        for d, du in phrase:
            st = t
            if (t * 2) % 2 == 1:  # corchea a contratiempo: swing
                st += swing
            notes.append((st, du, d))
            t += du
    return notes


def base_layer(tr, bars, perc=1.0):
    for bar in range(bars):
        b0 = bar * 4
        c = chord_for(bar)
        r = deg(c, -1)
        fifth = deg(c + 4, -1)
        # bajo caminante: 1 . 5 8 | 1 . b7 5
        for pos, f, du in ((0, r, 0.9), (1.5, fifth, 0.45), (2, r * 2, 0.45), (3, r, 0.5), (3.5, fifth, 0.45)):
            tr.add(bass(f, du * tr.beat), b0 + pos, 0.55)
        # acordes cortos a contratiempo
        ch = triad(c, 0)
        for pos in (0.5, 1.5, 2.5, 3.5):
            tr.add(epiano(ch, 0.28 * tr.beat * 4 / 4) * tr.wobble[0], b0 + pos + 0.06, 0.2)
        # percusion suave
        tr.add(kick(), b0, 0.5 * perc)
        tr.add(kick(), b0 + 2.5, 0.35 * perc)
        tr.add(snap(bar), b0 + 1, 0.22 * perc)
        tr.add(snap(bar + 7), b0 + 3, 0.22 * perc)
        for k in range(8):
            tr.add(shaker(k), b0 + k * 0.5 + (0.1 if k % 2 else 0), 0.08 * perc)


def night_layer(tr, bars):
    t = np.arange(tr.n) / SR
    # bordon grave (quinta) con ciclos enteros para el loop
    for f in (deg(0, -2), deg(4, -2)):
        cyc = round(f * tr.n / SR)
        ff = cyc * SR / tr.n
        tr.buf += np.sin(2 * np.pi * ff * t) * 0.06
    # darbuka maqsum + sistro
    for bar in range(bars):
        b0 = bar * 4
        for pos, k in ((0, "D"), (1, "T"), (1.5, "T"), (2, "D"), (3, "T"), (3.5, "t"), (3.75, "t")):
            if k == "D":
                tr.add(doum(), b0 + pos, 0.55)
            else:
                tr.add(tek(bar * 7 + int(pos * 4)), b0 + pos, 0.3 if k == "T" else 0.16)
        if bar % 2 == 1:
            tr.add(sistrum(bar), b0 + 3.5, 0.25)
        # arpegio pulsado (oud) que empuja
        c = chord_for(bar)
        for k, dd in enumerate((0, 2, 4, 7, 4, 2, 0, 2)):
            tr.add(pluck(deg(c + dd, 0), 0.4, 0.4, seed=bar * 8 + k), b0 + k * 0.5, 0.12)
    lead_line(tr, [(s + 0.0, d, g) for s, d, g in hook_notes(bars, 0.1)], voice="reed", gain=0.13, octave=1)


def day_layer(tr, bars):
    lead_line(tr, hook_notes(bars), voice="synth", gain=0.12, octave=1)
    # campanitas de adorno cada 8 compases
    for bar in range(0, bars, 8):
        for k, dd in enumerate((7, 9, 11)):
            tr.add(epiano([deg(dd, 1)], 0.6), bar * 4 + 3 + k * 0.33, 0.12)


def main():
    os.makedirs(OUT, exist_ok=True)
    base = Track(BARS, BPM)
    base_layer(base, BARS)
    day = Track(BARS, BPM)
    day_layer(day, BARS)
    night = Track(BARS, BPM)
    night_layer(night, BARS)
    # normalizar las capas con la MISMA ganancia (para que la mezcla en el
    # juego conserve el balance): se calcula sobre la mezcla mas fuerte
    loudest = np.max(np.abs(base.buf + day.buf + night.buf))
    g = 10 ** (-3 / 20) / loudest
    for name, tr in (("groove_base", base), ("groove_dia", day), ("groove_noche", night)):
        x = np.tanh(tr.buf * g * 1.2) / 1.2  # saturacion suave, "caliente"
        pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
        with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        print("wrote", name, f"{len(x)/SR:.1f}s")

    # titulo: version lounge (sin percusion fuerte, mas lenta)
    tt = Track(16, 88)
    base_layer(tt, 16, perc=0.35)
    lead_line(tt, hook_notes(16, 0.15), voice="synth", gain=0.11, octave=1)
    save(os.path.join(OUT, "titulo.wav"), tt.buf, peak_db=-4.0)

    # jefe: el mismo gancho, rapido, con darbuka y lengueta furiosa
    bj = Track(16, 132)
    base_layer(bj, 16, perc=1.4)
    night_layer(bj, 16)
    lead_line(bj, hook_notes(16, 0.05), voice="synth", gain=0.08, octave=2)
    save(os.path.join(OUT, "jefe.wav"), np.tanh(bj.buf * 1.3), peak_db=-4.0)


if __name__ == "__main__":
    main()
