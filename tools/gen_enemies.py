"""Genera sprites de enemigos (sombras, crias de Ammit) y de Thot (companero)."""
import os
import sys
from PIL import Image, ImageDraw
from palette import c

sys.path.insert(0, os.path.dirname(__file__))
from postfx import finish
from pixel_draw import save_layout

OUT_E = os.path.join("..", "assets", "sprites", "enemies")
OUT_C = os.path.join("..", "assets", "sprites", "companion")
os.makedirs(OUT_E, exist_ok=True)
os.makedirs(OUT_C, exist_ok=True)

W, H = 20, 24


def canvas():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def rect(d, x0, y0, x1, y1, color):
    d.rectangle([x0, y0, x1, y1], fill=c(color))


def ellipse(d, x0, y0, x1, y1, color):
    d.ellipse([x0, y0, x1, y1], fill=c(color))


def draw_sombra(frame_kind, i, facing="south"):
    """Sombra: mancha oscura fluida con ojos violetas brillantes."""
    img = canvas()
    d = ImageDraw.Draw(img)
    bob = 0
    squash = 0
    if frame_kind == "idle":
        bob = [0, 1][i % 2]
    elif frame_kind == "move":
        pattern = [0, 1, 2, 1]
        step = pattern[i % 4]
        bob = [0, -1, 0, -1][i % 4]
        squash = [0, 1, 0, -1][i % 4]
    y = bob
    # cuerpo (silueta ondulante)
    ellipse(d, 3, 10 + y - squash, 17, 22 + y + squash, "anubis_black")
    ellipse(d, 4, 6 + y, 16, 16 + y, "night_violet")
    ellipse(d, 5, 8 + y, 15, 15 + y, "anubis_black")
    # ojos
    ex = [6, 12] if facing != "west" else [6, 12]
    rect(d, ex[0], 10 + y, ex[0] + 1, 11 + y, "fire_yellow")
    rect(d, ex[1], 10 + y, ex[1] + 1, 11 + y, "fire_yellow")
    return img


def draw_cria(frame_kind, i):
    """Cria de Ammit: pequena, hocico de cocodrilo, rapida."""
    img = canvas()
    d = ImageDraw.Draw(img)
    bob = 0
    leg_dx = 0
    if frame_kind == "idle":
        bob = [0, 1][i % 2]
    elif frame_kind == "move":
        pattern = [0, 1, 2, 1]
        step = pattern[i % 4]
        bob = [0, 1, 0, 1][i % 4]
        leg_dx = [-1, 0, 1, 0][i % 4]
    y = bob
    # cola
    rect(d, 14, 15 + y, 18, 17 + y, "nile_green_dark")
    # cuerpo (hipopotamo/leon mezcla, tonos tierra-verde)
    rect(d, 5, 11 + y, 15, 18 + y, "nile_green_dark")
    rect(d, 5, 16 + y, 15, 18 + y, "ochre_dark")
    # patas
    rect(d, 6 + leg_dx, 18 + y, 8 + leg_dx, 21 + y, "ochre_dark")
    rect(d, 12 - leg_dx, 18 + y, 14 - leg_dx, 21 + y, "ochre_dark")
    # cabeza / hocico cocodrilo
    rect(d, 1, 10 + y, 7, 14 + y, "nile_green_dark")
    rect(d, 0, 11 + y, 3, 13 + y, "nile_green")
    rect(d, 4, 9 + y, 5, 9 + y, "fire_yellow")
    return img


def draw_heraldo(frame_kind, i):
    """Heraldo de Ammit (jefe): grande, cabeza cocodrilo, melena de leon, cuerpo de hipopotamo."""
    W2, H2 = 48, 48
    img = Image.new("RGBA", (W2, H2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bob = 0
    if frame_kind == "idle":
        bob = [0, 1][i % 2]
    elif frame_kind == "attack":
        bob = [0, -2, 1][i % 3]
    y = bob
    # cuerpo hipopotamo
    d.ellipse([6, 20 + y, 42, 44 + y], fill=c("ochre_dark"))
    d.ellipse([8, 22 + y, 40, 40 + y], fill=c("sand_dark"))
    # melena leon
    d.ellipse([2, 8 + y, 30, 30 + y], fill=c("gold_dark"))
    # cabeza cocodrilo
    d.rectangle([2, 14 + y, 24, 26 + y], fill=c("nile_green_dark"))
    d.rectangle([0, 17 + y, 8, 22 + y], fill=c("nile_green"))
    # ojos
    d.rectangle([16, 16 + y, 18, 18 + y], fill=c("fire_yellow"))
    d.rectangle([20, 16 + y, 22, 18 + y], fill=c("fire_yellow"))
    # patas
    d.rectangle([10, 40 + y, 16, 46 + y], fill=c("ochre_dark"))
    d.rectangle([30, 40 + y, 36, 46 + y], fill=c("ochre_dark"))
    return img


def draw_thot(frame_kind, i):
    """Thot: ibis pequeno blanco/negro con disco lunar."""
    img = canvas()
    d = ImageDraw.Draw(img)
    bob = 0
    wing = 0
    if frame_kind == "idle":
        bob = [0, 1][i % 2]
    elif frame_kind == "fly":
        pattern = [0, 1, 2, 1]
        bob = [0, -2, 0, -2][i % 4]
        wing = pattern[i % 4]
    y = bob
    # disco lunar
    d.ellipse([7, 1 + y, 13, 7 + y], fill=c("moon_silver"))
    # cuerpo
    d.ellipse([4, 10 + y, 16, 20 + y], fill=c("bone"))
    # alas
    wing_y = [0, -2, -1, -2][wing] if frame_kind == "fly" else 0
    d.polygon([(4, 12 + y), (0, 8 + y + wing_y), (6, 16 + y)], fill=c("anubis_black"))
    d.polygon([(16, 12 + y), (20, 8 + y + wing_y), (14, 16 + y)], fill=c("anubis_black"))
    # cabeza y pico curvo (ibis)
    d.ellipse([6, 6 + y, 12, 12 + y], fill=c("anubis_black"))
    d.rectangle([2, 9 + y, 7, 10 + y], fill=c("anubis_black"))
    d.rectangle([1, 10 + y, 4, 11 + y], fill=c("anubis_black"))
    # patas
    d.rectangle([8, 19 + y, 9, 22 + y], fill=c("ochre"))
    d.rectangle([11, 19 + y, 12, 22 + y], fill=c("ochre"))
    return img


def hstrip(imgs):
    w, h = imgs[0].size
    sheet = Image.new("RGBA", (w * len(imgs), h), (0, 0, 0, 0))
    for i, im in enumerate(imgs):
        sheet.paste(im, (i * w, 0), im)
    return sheet


def build_sombra():
    frames, layout = [], []
    for kind, n in [("idle", 2), ("move", 4)]:
        for i in range(n):
            frames.append(finish(draw_sombra(kind, i)))
            layout.append(f"{kind}_{i}")
    sheet = hstrip(frames)
    sheet.save(os.path.join(OUT_E, "sombra.png"))
    save_layout(os.path.join(OUT_E, "sombra_layout.json"), W, H, layout)
    print("sombra ok", sheet.size)


def build_cria():
    frames, layout = [], []
    for kind, n in [("idle", 2), ("move", 4)]:
        for i in range(n):
            frames.append(finish(draw_cria(kind, i)))
            layout.append(f"{kind}_{i}")
    sheet = hstrip(frames)
    sheet.save(os.path.join(OUT_E, "cria.png"))
    save_layout(os.path.join(OUT_E, "cria_layout.json"), W, H, layout)
    print("cria ok", sheet.size)


def build_heraldo():
    frames, layout = [], []
    for kind, n in [("idle", 2), ("attack", 3)]:
        for i in range(n):
            frames.append(finish(draw_heraldo(kind, i)))
            layout.append(f"{kind}_{i}")
    sheet = hstrip(frames)
    sheet.save(os.path.join(OUT_E, "heraldo.png"))
    save_layout(os.path.join(OUT_E, "heraldo_layout.json"), 48, 48, layout)
    print("heraldo ok", sheet.size)


def build_thot():
    frames, layout = [], []
    for kind, n in [("idle", 2), ("fly", 4)]:
        for i in range(n):
            frames.append(finish(draw_thot(kind, i)))
            layout.append(f"{kind}_{i}")
    sheet = hstrip(frames)
    sheet.save(os.path.join(OUT_C, "thot.png"))
    save_layout(os.path.join(OUT_C, "thot_layout.json"), W, H, layout)
    print("thot ok", sheet.size)


if __name__ == "__main__":
    # OBSOLETO: sombra, cria y Thot ahora salen de tools/gen_creatures.py y el
    # Heraldo de tools/gen_heraldo.py (pase de arte M9). No se ejecuta para
    # no pisar los sprites nuevos.
    print("usar tools/gen_creatures.py y tools/gen_heraldo.py")
