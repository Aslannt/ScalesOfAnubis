"""Pantalla de titulo en capas (PROMPT_PULIDO.md punto 7): cielo con
degradado en bandas, luna con halo, piramides con sombreado de un lado,
dunas en varias capas y palmeras. Las estrellas, nubes y arena al viento se
animan en Godot (scripts/ui/main_menu.gd), por eso van en capas separadas.
Salida en assets/textures/title_*.png (480x270)."""
import math
import os
import random
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "textures")
W, H = 480, 270
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def banded_gradient(stops, bands=18):
    """Degradado vertical en bandas con tramado Bayer (look pixel art)."""
    img = Image.new("RGBA", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                lt = (t - stops[i][0]) / (stops[i + 1][0] - stops[i][0])
                a, b = stops[i][1], stops[i + 1][1]
                break
        for x in range(W):
            q = lt * bands + BAYER[y % 4][x % 4] / 16.0 - 0.5
            qt = max(0.0, min(1.0, round(q) / bands))
            px[x, y] = lerp(a, b, qt) + (255,)
    return img


def sky():
    img = banded_gradient([
        (0.0, (12, 12, 34)),
        (0.35, (38, 30, 78)),
        (0.58, (112, 56, 96)),
        (0.72, (214, 112, 70)),
        (1.0, (246, 170, 90)),
    ])
    return img


def moon():
    """Luna con halo escalonado (se anima el halo en Godot)."""
    s = 64
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    px = img.load()
    cx = cy = (s - 1) / 2
    for y in range(s):
        for x in range(s):
            d = math.hypot(x - cx, y - cy)
            if d <= 13:
                base = c("moon_silver")
                # manchas (mares lunares)
                if math.hypot(x - cx + 4, y - cy + 3) < 4 or math.hypot(x - cx - 5, y - cy - 4) < 3:
                    base = c("bone_dark")
                # sombreado del lado derecho
                if x - cx > 7 - (y - cy) * 0.2:
                    base = tuple(int(v * 0.85) for v in base[:3]) + (255,)
                px[x, y] = base
            elif d <= 18:
                px[x, y] = (220, 225, 255, 40)
            elif d <= 26:
                px[x, y] = (200, 210, 255, 18)
    return img


def pyramid(d, cx, base_w, height, horizon, lit, shade, edge):
    apex = (cx, horizon - height)
    left = (cx - base_w // 2, horizon)
    right = (cx + base_w // 2, horizon)
    mid = (cx + base_w // 8, horizon)  # arista visible corrida a la derecha
    d.polygon([left, apex, mid], fill=lit)
    d.polygon([mid, apex, right], fill=shade)
    d.line([apex, mid], fill=edge)
    # hiladas de bloques (lineas horizontales tenues en la cara iluminada)
    for k in range(1, height // 6):
        y = horizon - k * 6
        t = (horizon - y) / height
        xl = int(left[0] + (apex[0] - left[0]) * t)
        xm = int(mid[0] + (apex[0] - mid[0]) * t)
        d.line([(xl + 1, y), (xm - 1, y)], fill=tuple(max(0, v - 10) for v in lit[:3]))


def far_layer():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    horizon = 196
    # dunas lejanas violetas
    for x in range(W):
        y = horizon - 6 + int(5 * math.sin(x * 0.02) + 3 * math.sin(x * 0.051 + 1.0))
        d.line([(x, y), (x, H)], fill=(92, 58, 88, 255))
    pyramid(d, 140, 150, 82, horizon + 2, (150, 92, 96, 255), (74, 44, 70, 255), (190, 120, 100, 255))
    pyramid(d, 268, 190, 108, horizon + 4, (170, 102, 98, 255), (82, 48, 74, 255), (214, 140, 108, 255))
    pyramid(d, 388, 110, 62, horizon + 2, (140, 86, 92, 255), (70, 42, 68, 255), (180, 112, 96, 255))
    # piramidion dorado en la grande, con destello
    d.polygon([(268 - 6, horizon + 4 - 108 + 12), (268, horizon + 4 - 108), (268 + 6 - 1, horizon + 4 - 108 + 12)], fill=c("gold"))
    return img


def near_layer():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(3)
    # duna media
    for x in range(W):
        y = 204 + int(8 * math.sin(x * 0.013 + 2.0) + 4 * math.sin(x * 0.037))
        d.line([(x, y), (x, H)], fill=(168, 104, 74, 255))
        d.point((x, y), fill=(222, 150, 96, 255))
    # duna cercana con ondas de arena
    for x in range(W):
        y = 228 + int(10 * math.sin(x * 0.009 + 0.5) + 3 * math.sin(x * 0.05))
        d.line([(x, y), (x, H)], fill=(196, 138, 84, 255))
        d.point((x, y), fill=(236, 178, 110, 255))
        d.point((x, y + 1), fill=(226, 164, 100, 255))
    for k in range(40):
        x = rng.randint(0, W - 20)
        y = rng.randint(236, H - 4)
        d.line([(x, y), (x + rng.randint(6, 16), y)], fill=(170, 116, 72, 255))
    # palmeras en silueta a los lados
    for (px_, base, hh, lean) in ((22, 250, 70, 6), (48, 256, 54, -4), (452, 252, 66, -7)):
        pts = []
        for i in range(hh):
            t = i / hh
            x = px_ + lean * t * t
            y = base - i
            d.line([(int(x) - 1, y), (int(x) + 1, y)], fill=(34, 22, 30, 255))
            pts.append((x, y))
        tx, ty = pts[-1]
        for a in range(8):
            ang = a / 8 * math.tau + 0.2
            length = 20 + (a % 3) * 3
            for j in range(length):
                fx = tx + math.cos(ang) * j
                fy = ty + math.sin(ang) * j * 0.35 + (j * j) * 0.04
                thick = 2 if j < length * 0.7 else 1
                d.rectangle([int(fx), int(fy), int(fx) + 1, int(fy) + thick - 1], fill=(30, 20, 28, 255))
                # foliolos colgando
                if j % 3 == 0 and j > 3:
                    d.line([(int(fx), int(fy) + 1), (int(fx) + (1 if math.cos(ang) > 0 else -1), int(fy) + 3)], fill=(30, 20, 28, 255))
    return img


def cloud():
    img = Image.new("RGBA", (140, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(11)
    for k in range(9):
        x = rng.randint(0, 100)
        w = rng.randint(24, 50)
        y = rng.randint(3, 10)
        d.ellipse([x, y, x + w, y + rng.randint(5, 8)], fill=(150, 90, 120, 150))
    for k in range(6):
        x = rng.randint(10, 100)
        d.line([(x, 5), (x + rng.randint(10, 30), 5)], fill=(236, 150, 120, 150))
    return img


if __name__ == "__main__":
    for name, fn in (("title_sky", sky), ("title_moon", moon), ("title_far", far_layer),
                     ("title_near", near_layer), ("title_cloud", cloud)):
        im = fn()
        im.save(os.path.join(OUT, name + ".png"))
        print("wrote", name, im.size)
    # compuesto de referencia (se sigue usando como fondo de respaldo)
    comp = sky()
    for n in ("title_far", "title_near"):
        layer = Image.open(os.path.join(OUT, n + ".png"))
        comp.alpha_composite(layer)
    comp.save(os.path.join(OUT, "title_bg.png"))
