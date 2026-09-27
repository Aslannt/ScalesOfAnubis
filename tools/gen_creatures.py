"""Pase de arte (M9) de las criaturas y de Thot:
- Sombra (sheut sin dueno): capucha de humo con ojos ambar y jirones que
  ondean en la base.
- Cria de Ammit: version pequena de su ama: hocico de cocodrilo, melena de
  leon, ancas de hipopotamo.
- Thot: ibis de perfil (cuerpo blanco, cabeza y cuello negros, pico largo
  curvo), paleta de escriba colgada al cuello y disco lunar sobre la cabeza.
"""
import math
import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from postfx import add_outline
from pixel_draw import save, save_layout

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")


def strip(frames):
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for k, f in enumerate(frames):
        s.paste(f, (k * w, 0), f)
    return s


# ---------------------------------------------------------------- sombra
def sombra(anim, i):
    w, h = 24, 28
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    core = (18, 14, 26, 255)
    mid = (40, 26, 62, 255)
    rim = (86, 58, 132, 255)
    bob = [0, 1][i % 2] if anim == "idle" else [0, -1, 0, -1][i % 4]
    lean = 0 if anim == "idle" else [1, 1, 0, 0][i % 4]
    phase = i * 1.6
    for y in range(h):
        yy = y - bob
        for x in range(w):
            # silueta: cabeza redonda arriba, cuerpo que se ensancha, base en jirones
            cx = 11.5 + lean * (yy / h)
            if yy < 3:
                continue
            if yy < 12:
                r = math.sqrt(max(0.0, 20 - (yy - 8) ** 2 * 0.9)) + 1.0
            else:
                r = 5.0 + (yy - 12) * 0.28
            dx = abs(x - cx)
            if dx > r:
                continue
            if yy > 21:
                # jirones: tres puntas que ondean
                wave = math.sin(x * 1.3 + phase) * 1.6
                if yy > 24 + wave - (0 if int(x) % 5 in (1, 2) else 2):
                    continue
            col = core if dx < r - 2 else mid
            if dx >= r - 0.9 and x < cx:
                col = rim
            px[x, y] = col
    d = ImageDraw.Draw(img)
    # interior de la capucha y ojos ambar
    ey = 8 + bob
    d.ellipse([7 + lean, ey - 3, 16 + lean, ey + 3], fill=(8, 6, 12, 255))
    d.rectangle([9 + lean, ey, 10 + lean, ey], fill=c("fire_yellow"))
    d.rectangle([13 + lean, ey, 14 + lean, ey], fill=c("fire_yellow"))
    d.point((9 + lean, ey - 1), fill=c("fire_orange"))
    d.point((14 + lean, ey - 1), fill=c("fire_orange"))
    return add_outline(img, (12, 8, 18, 255))


# ------------------------------------------------------------------ cria
def cria(anim, i):
    w, h = 24, 20
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    HIP, HIP_D = (112, 90, 116, 255), (78, 60, 84, 255)
    LION, LION_D = (201, 138, 52, 255), (150, 96, 34, 255)
    MANE = (120, 62, 30, 255)
    CROC, CROC_D = (70, 118, 64, 255), (44, 80, 44, 255)
    bob = [0, 1][i % 2] if anim == "idle" else [0, 1, 0, 1][i % 4]
    st = [0, 0, 0, 0] if anim == "idle" else [[1, -1, -1, 1], [0, 0, 0, 0], [-1, 1, 1, -1], [0, 0, 0, 0]][i % 4]
    y = bob
    # patas
    for k, (lx, col) in enumerate(((4, HIP_D), (8, HIP), (12, LION_D), (15, LION))):
        d.rectangle([lx + st[k], 14 + y, lx + 1 + st[k], 18], fill=col)
    # ancas de hipopotamo
    d.ellipse([1, 6 + y, 12, 16 + y], fill=HIP)
    d.ellipse([3, 11 + y, 11, 16 + y], fill=HIP_D)
    d.point((1, 10 + y), fill=HIP_D)
    # delantera de leon + melena
    d.ellipse([9, 6 + y, 17, 15 + y], fill=LION)
    d.ellipse([12, 3 + y, 18, 12 + y], fill=MANE)
    # cabeza de cocodrilo
    d.polygon([(16, 5 + y), (19, 4 + y), (23, 6 + y), (23, 8 + y), (16, 9 + y)], fill=CROC)
    d.line([(17, 8 + y), (22, 8 + y)], fill=CROC_D)
    for x in (18, 20, 22):
        d.point((x, 8 + y), fill=c("bone"))
    d.point((18, 5 + y), fill=c("fire_yellow"))
    return add_outline(img, (18, 10, 14, 255))


# ------------------------------------------------------------------ thot
def thot(anim, i):
    w, h = 24, 24
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    WHITE, WHITE_D = c("bone"), c("bone_dark")
    BLACK = (22, 18, 20, 255)
    bob = [0, 1][i % 2] if anim == "idle" else [0, -1, -1, 0][i % 4]
    y = bob
    # disco lunar sobre la cabeza (con creciente)
    d.ellipse([14, 0 + y, 19, 5 + y], fill=c("gold_dark"))
    d.ellipse([15, 1 + y, 18, 4 + y], fill=c("moon_silver"))
    d.point((16, 2 + y), fill=(240, 246, 255, 255))
    # patas finas (una sola, recogida: el contorno engrosaba dos patas)
    d.line([(12, 17 + y), (11, 19 + y)], fill=(90, 70, 60, 255))
    # cola negra
    d.polygon([(3, 13 + y), (8, 12 + y), (8, 15 + y)], fill=BLACK)
    # cuerpo blanco
    d.ellipse([6, 10 + y, 16, 17 + y], fill=WHITE)
    d.ellipse([7, 14 + y, 15, 17 + y], fill=WHITE_D)
    # cuello y cabeza negros
    d.line([(14, 11 + y), (16, 8 + y)], fill=BLACK, width=2)
    d.ellipse([15, 5 + y, 19, 9 + y], fill=BLACK)
    # pico largo curvo hacia abajo
    for k, (bx, by) in enumerate(((19, 7), (20, 8), (21, 9), (22, 10), (22, 11), (23, 12))):
        d.point((bx, by + y), fill=(70, 60, 58, 255))
    d.point((17, 6 + y), fill=c("fire_yellow"))  # ojo
    # paleta de escriba colgada del cuello
    d.line([(15, 10 + y), (15, 12 + y)], fill=c("soil"))
    d.rectangle([13, 12 + y, 17, 14 + y], fill=c("sand_light"))
    d.point((14, 13 + y), fill=c("red_accent"))
    d.point((16, 13 + y), fill=BLACK)
    # alas
    if anim == "idle":
        d.polygon([(7, 11 + y), (13, 11 + y), (9, 15 + y)], fill=WHITE_D)
        d.line([(7, 13 + y), (10, 15 + y)], fill=BLACK)
    else:
        f = i % 4
        tip_y = [2, 6, 13, 6][f]
        d.polygon([(8, 11 + y), (13, 11 + y), (6, tip_y + y), (4, tip_y + 1 + y)], fill=WHITE)
        d.line([(4, tip_y + 1 + y), (6, tip_y + y)], fill=BLACK)
        d.point((5, tip_y + y), fill=BLACK)
    return add_outline(img, (16, 12, 14, 255))


if __name__ == "__main__":
    fr, nm = [], []
    for anim, n in (("idle", 2), ("move", 4)):
        for i in range(n):
            fr.append(sombra(anim, i)); nm.append(f"{anim}_{i}")
    save(strip(fr), os.path.join(ROOT, "enemies", "sombra.png"))
    save_layout(os.path.join(ROOT, "enemies", "sombra_layout.json"), 24, 28, nm)
    fr, nm = [], []
    for anim, n in (("idle", 2), ("move", 4)):
        for i in range(n):
            fr.append(cria(anim, i)); nm.append(f"{anim}_{i}")
    save(strip(fr), os.path.join(ROOT, "enemies", "cria.png"))
    save_layout(os.path.join(ROOT, "enemies", "cria_layout.json"), 24, 20, nm)
    fr, nm = [], []
    for anim, n in (("idle", 2), ("fly", 4)):
        for i in range(n):
            fr.append(thot(anim, i)); nm.append(f"{anim}_{i}")
    save(strip(fr), os.path.join(ROOT, "companion", "thot.png"))
    save_layout(os.path.join(ROOT, "companion", "thot_layout.json"), 24, 24, nm)
