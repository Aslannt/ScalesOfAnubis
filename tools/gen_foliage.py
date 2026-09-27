"""Vegetacion con mas detalle (PROMPT_PULIDO.md punto 3 + pase de arte):
- atlas de mechones de pasto para el MultiMesh con viento
- cultivos por etapa (trigo, lino, papiro) dibujados tallo por tallo, en vez
  de bloques de color; frames de 24x32, 4 etapas por hoja.
Deterministico (semillas fijas)."""
import os
import random
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from postfx import add_outline

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT_FX = os.path.join(ROOT, "assets", "sprites", "fx")
OUT_CROPS = os.path.join(ROOT, "assets", "sprites", "crops")

FW, FH = 24, 32


def put(px, w, h, x, y, col):
    if 0 <= x < w and 0 <= y < h:
        px[x, y] = c(col) if isinstance(col, str) else col


def stalk(px, w, h, x0, y_base, height, lean, col):
    """Tallo de 1px que se inclina 'lean' pixeles en total hacia la punta."""
    pts = []
    for i in range(height):
        x = int(round(x0 + lean * (i / max(height - 1, 1)) ** 1.6))
        y = y_base - i
        put(px, w, h, x, y, col)
        pts.append((x, y))
    return pts


# ---------------- pasto ----------------
def grass_tuft(seed, flowers=None, dry=False):
    rng = random.Random(seed)
    w, h = 16, 14
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    tones = ["grass_dark", "grass", "grass_light"] if not dry else ["grass", "grass_dry", "sand_dark"]
    n = rng.randint(7, 10)
    for i in range(n):
        x0 = rng.randint(3, 12)
        hh = rng.randint(5, 12)
        lean = rng.uniform(-3.5, 3.5)
        col = tones[min(2, int(i / n * 3 + rng.random() * 0.6))]
        pts = stalk(px, w, h, x0, h - 1, hh, lean, col)
        if flowers and rng.random() < 0.35:
            fx, fy = pts[-1]
            put(px, w, h, fx, fy, flowers)
            put(px, w, h, fx + 1, fy, flowers)
            put(px, w, h, fx, fy - 1, "bone")
    return img


def make_grass_atlas():
    frames = [
        grass_tuft(1),
        grass_tuft(2),
        grass_tuft(3, flowers=(222, 120, 150, 255)),
        grass_tuft(4, flowers=(240, 205, 80, 255)),
        grass_tuft(5, dry=True),
        grass_tuft(6),
    ]
    sheet = Image.new("RGBA", (16 * len(frames), 14), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * 16, 0), f)
    path = os.path.join(OUT_FX, "grass_atlas.png")
    sheet.save(path)
    print("wrote", path, sheet.size, "frames", len(frames))


# ---------------- cultivos ----------------
def spread(rng, n, lo=2, hi=21):
    """Posiciones X repartidas parejo (con algo de azar) para que los tallos
    no se amontonen en una sola mancha."""
    step = (hi - lo) / max(n - 1, 1)
    return [int(round(lo + i * step + rng.uniform(-step * 0.35, step * 0.35))) for i in range(n)]


def darken_base(img, rows=5, mult=0.62):
    """Oscurece la base de los tallos (sombra de contacto con el suelo) en
    vez de un contorno completo, que empastaba los tallos finos."""
    px = img.load()
    w, h = img.size
    for y in range(h - rows, h):
        t = (y - (h - rows)) / rows
        m = 1.0 - (1.0 - mult) * t
        for x in range(w):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (int(r * m), int(g * m), int(b * m), a)
    return img


def mound(px, w, h):
    """Montoncito de tierra removida donde va la semilla."""
    for x in range(8, 16):
        put(px, w, h, x, h - 1, "kemet_dark")
    for x in range(9, 15):
        put(px, w, h, x, h - 2, "kemet_light")
    for x in range(10, 14):
        put(px, w, h, x, h - 3, "kemet")


def sprouts(px, w, h, rng, n, max_h, col_a, col_b):
    for i in range(n):
        x0 = 4 + int(i * 15 / max(n - 1, 1)) + rng.randint(-1, 1)
        hh = rng.randint(max(2, max_h - 3), max_h)
        stalk(px, w, h, x0, h - 1, hh, rng.uniform(-1.5, 1.5), col_a if i % 2 else col_b)
        # dos hojitas
        put(px, w, h, x0 - 1, h - hh + 1, col_b)
        put(px, w, h, x0 + 1, h - hh + 2, col_a)


def wheat(stage, rng):
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    px = img.load()
    w, h = FW, FH
    if stage == 0:
        mound(px, w, h)
        put(px, w, h, 12, h - 4, "grass")
        put(px, w, h, 12, h - 5, "grass_light")
    elif stage == 1:
        sprouts(px, w, h, rng, 5, 8, "grass", "grass_light")
    elif stage == 2:
        for i, x0 in enumerate(spread(rng, 8, 3, 20)):
            hh = rng.randint(13, 19)
            stalk(px, w, h, x0, h - 1, hh, rng.uniform(-2, 2), "grass" if i % 2 else "grass_light")
    else:
        for i, x0 in enumerate(spread(rng, 7, 3, 20)):
            hh = rng.randint(19, 26)
            lean = rng.uniform(-3, 3)
            pts = stalk(px, w, h, x0, h - 1, hh, lean, "gold_dark" if i % 3 else "ochre")
            tx, ty = pts[-1]
            # espiga: 5 px de grano con barbas
            for k in range(5):
                put(px, w, h, tx, ty + k, "gold" if k % 2 else "sand_light")
                put(px, w, h, tx + (1 if k % 2 else -1), ty + k, "gold_dark")
            put(px, w, h, tx, ty - 1, "sand_light")
            put(px, w, h, tx + 1, ty - 2, "bone_dark")
    return img


def lino(stage, rng):
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    px = img.load()
    w, h = FW, FH
    if stage == 0:
        mound(px, w, h)
        put(px, w, h, 11, h - 4, "grass_light")
    elif stage == 1:
        sprouts(px, w, h, rng, 6, 7, "nile_green", "grass_light")
    elif stage == 2:
        for i, x0 in enumerate(spread(rng, 8, 3, 20)):
            stalk(px, w, h, x0, h - 1, rng.randint(12, 18), rng.uniform(-1.5, 1.5), "nile_green" if i % 2 else "grass")
    else:
        for i, x0 in enumerate(spread(rng, 7, 3, 20)):
            pts = stalk(px, w, h, x0, h - 1, rng.randint(18, 25), rng.uniform(-2, 2), "nile_green_dark" if i % 2 else "nile_green")
            tx, ty = pts[-1]
            # flor azul de lino: cruz de 5 px con centro claro
            for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                put(px, w, h, tx + dx, ty + dy, "lapis" if (dx or dy) else "moon_silver")
            if rng.random() < 0.5:
                put(px, w, h, tx + 1, ty - 1, "turquoise")
    return img


def papiro(stage, rng):
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    px = img.load()
    w, h = FW, FH
    if stage == 0:
        mound(px, w, h)
        put(px, w, h, 12, h - 4, "nile_green")
        put(px, w, h, 12, h - 5, "nile_green")
    elif stage == 1:
        sprouts(px, w, h, rng, 4, 10, "nile_green_dark", "nile_green")
    elif stage == 2:
        for i, x0 in enumerate(spread(rng, 5, 4, 19)):
            pts = stalk(px, w, h, x0, h - 1, rng.randint(14, 20), rng.uniform(-1, 1), "nile_green_dark")
            tx, ty = pts[-1]
            for dx in (-1, 0, 1):
                put(px, w, h, tx + dx, ty - 1, "grass")
    else:
        heads = []
        for i, x0 in enumerate(spread(rng, 4, 5, 18)):
            pts = stalk(px, w, h, x0, h - 1, rng.randint(20, 27), rng.uniform(-2, 2), "nile_green_dark")
            heads.append(pts[-1])
        # penacho en sombrilla: rayos finos que caen
        for tx, ty in heads:
            for k in range(-4, 5):
                length = 4 - abs(k) // 2
                for j in range(length):
                    put(px, w, h, tx + k, ty - 2 + abs(k) // 2 + j // 2, "grass_light" if j == 0 else "grass")
            put(px, w, h, tx, ty - 3, "grass_dry")
    return img


def make_crop(name, fn, seed):
    frames = []
    for stage in range(4):
        rng = random.Random(seed * 10 + stage)
        img = fn(stage, rng)
        frames.append(darken_base(img))
    sheet = Image.new("RGBA", (FW * 4, FH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FW, 0), f)
    path = os.path.join(OUT_CROPS, name + ".png")
    sheet.save(path)
    print("wrote", path, sheet.size)


if __name__ == "__main__":
    make_grass_atlas()
    make_crop("trigo", wheat, 1)
    make_crop("lino", lino, 2)
    make_crop("papiro", papiro, 3)
