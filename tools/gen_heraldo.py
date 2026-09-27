"""Heraldo de Ammit (jefe, GDD 6.4): bestia con cabeza de cocodrilo, parte
delantera de leon y trasera de hipopotamo, como su ama. Vista lateral
mirando a la derecha (en el juego se espeja con flip_h).
Animaciones: idle(2) walk(4) windup(2) charge(2) roar(2) slam(2) hurt(1)."""
import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from postfx import add_outline
from pixel_draw import save, save_layout

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "enemies")
W, H = 72, 52

HIPPO = (112, 90, 116, 255)
HIPPO_D = (78, 60, 84, 255)
HIPPO_L = (146, 120, 146, 255)
LION = (201, 138, 52, 255)
LION_D = (150, 96, 34, 255)
MANE = (120, 62, 30, 255)
MANE_D = (84, 40, 22, 255)
CROC = (70, 118, 64, 255)
CROC_D = (44, 80, 44, 255)
CROC_L = (120, 160, 90, 255)
TOOTH = (242, 230, 201, 255)
EYE = (250, 200, 90, 255)
CLAW = (230, 214, 175, 255)


def leg(d, x, y_top, y_bot, col, dark, paw=None):
    d.rectangle([x, y_top, x + 5, y_bot], fill=col)
    d.rectangle([x + 4, y_top, x + 5, y_bot], fill=dark)
    if paw:
        d.rectangle([x - 1, y_bot - 1, x + 6, y_bot], fill=dark)
        for k in (0, 2, 4):
            d.point((x + k + 1, y_bot + 1), fill=paw)


def beast(pose="idle", i=0):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    base = 49  # linea de suelo (pies)
    bob = 0
    lift_front = 0     # cuanto se levanta la parte delantera (slam)
    head_dy = 0
    jaw_open = 0
    stride = [0, 0, 0, 0]  # desplazamiento de cada pata (tras, tras, del, del)
    lean = 0
    if pose == "idle":
        bob = i % 2
    elif pose == "walk":
        stride = [[2, -2, -2, 2], [0, 0, 0, 0], [-2, 2, 2, -2], [0, 0, 0, 0]][i % 4]
        bob = [0, 1, 0, 1][i % 4]
    elif pose == "windup":
        bob = 3
        head_dy = 3
        lean = -3
        jaw_open = 1 + i
    elif pose == "charge":
        lean = 4
        head_dy = 2
        stride = [[3, -3, 3, -3], [-3, 3, -3, 3]][i % 2]
        jaw_open = 3
    elif pose == "roar":
        head_dy = -4
        jaw_open = 5 + i * 2
        bob = -1
    elif pose == "slam":
        if i == 0:
            lift_front = 9
            head_dy = -2
            jaw_open = 3
        else:
            bob = 3
            head_dy = 4
            jaw_open = 2
    elif pose == "hurt":
        bob = 1
        head_dy = -2
        jaw_open = 4
        lean = -2

    y = bob
    fx = lean  # desplazamiento horizontal de la parte delantera

    # --- patas traseras (hipopotamo: cortas y gruesas) ---
    leg(d, 11 + stride[0], 36 + y, base, HIPPO_D, (60, 46, 66, 255))
    leg(d, 23 + stride[1], 37 + y, base, HIPPO, HIPPO_D)
    # --- cuarto trasero de hipopotamo ---
    d.ellipse([4, 17 + y, 38, 44 + y], fill=HIPPO)
    d.ellipse([7, 30 + y, 36, 44 + y], fill=HIPPO_D)       # panza en sombra
    d.ellipse([9, 19 + y, 26, 27 + y], fill=HIPPO_L)       # brillo en el lomo
    d.line([(4, 28 + y), (1, 31 + y)], fill=HIPPO_D)        # colita
    d.point((0, 32 + y), fill=HIPPO_D)
    # --- patas delanteras (leon, con garras) ---
    fy = y - lift_front
    leg(d, 36 + fx + stride[2], 34 + fy, base - (lift_front // 2), LION_D, MANE_D, CLAW)
    leg(d, 47 + fx + stride[3], 34 + fy, base - (lift_front // 2), LION, LION_D, CLAW)
    # --- torso de leon ---
    d.ellipse([27 + fx, 15 + fy, 56 + fx, 40 + fy], fill=LION)
    d.ellipse([30 + fx, 28 + fy, 54 + fx, 40 + fy], fill=LION_D)
    # --- melena ---
    d.ellipse([40 + fx, 5 + fy, 62 + fx, 34 + fy], fill=MANE)
    for k in range(6):
        yy = 7 + k * 4 + fy
        d.line([(41 + fx, yy), (37 + fx, yy + 2)], fill=MANE_D)
    d.ellipse([46 + fx, 9 + fy, 60 + fx, 28 + fy], fill=MANE_D)
    # --- cabeza de cocodrilo (hocico largo) ---
    hx = 52 + fx
    hy = 12 + fy + head_dy
    # craneo
    d.polygon([(hx, hy), (hx + 8, hy - 3), (hx + 12, hy), (hx + 12, hy + 7), (hx, hy + 9)], fill=CROC)
    # hocico superior
    d.polygon([(hx + 10, hy + 1), (W - 1, hy + 3), (W - 1, hy + 6), (hx + 10, hy + 7)], fill=CROC)
    d.line([(hx + 10, hy + 1), (W - 2, hy + 3)], fill=CROC_L)
    # escamas en el lomo del hocico
    for k in range(hx + 12, W - 3, 3):
        d.point((k, hy + 2), fill=CROC_D)
    # mandibula inferior (se abre)
    jy = hy + 7 + jaw_open
    d.polygon([(hx + 2, hy + 8), (hx + 10, hy + 8), (W - 3, jy), (W - 3, jy + 3), (hx + 4, hy + 12)], fill=CROC_D)
    # boca abierta: interior oscuro y dientes
    if jaw_open > 0:
        d.polygon([(hx + 10, hy + 7), (W - 2, hy + 6), (W - 3, jy)], fill=(96, 24, 20, 255))
    for k in range(hx + 12, W - 2, 3):
        d.point((k, hy + 7), fill=TOOTH)
        d.point((k + 1, jy - (0 if jaw_open else 1)), fill=TOOTH)
    # ojo con brillo amarillo y ceja
    d.rectangle([hx + 6, hy + 1, hx + 8, hy + 3], fill=EYE)
    d.point((hx + 8, hy + 2), fill=c("anubis_black"))
    d.line([(hx + 5, hy), (hx + 9, hy - 1)], fill=CROC_D)
    # collar de oro de heraldo
    d.line([(44 + fx, 30 + fy), (52 + fx, 36 + fy)], fill=c("gold"))
    d.line([(44 + fx, 31 + fy), (52 + fx, 37 + fy)], fill=c("gold_dark"))
    return add_outline(img, (18, 10, 14, 255))


ANIMS = [("idle", 2), ("walk", 4), ("windup", 2), ("charge", 2), ("roar", 2), ("slam", 2), ("hurt", 1)]

if __name__ == "__main__":
    frames, names = [], []
    for anim, n in ANIMS:
        for i in range(n):
            frames.append(beast(anim, i))
            names.append(f"{anim}_{i}")
    sheet = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
    for k, f in enumerate(frames):
        sheet.paste(f, (k * W, 0), f)
    save(sheet, os.path.join(OUT, "heraldo.png"))
    save_layout(os.path.join(OUT, "heraldo_layout.json"), W, H, names)
