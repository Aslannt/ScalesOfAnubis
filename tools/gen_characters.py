"""Generador procedural de sprites de personajes (bloques con proporciones "chibi",
estilo RPG top-down clasico) a partir de la paleta fija del juego. Dibuja con
rectangulos pixel-perfect (sin antialiasing) para lograr pixel art limpio y
coherente sin depender de arte dibujado a mano.

Uso: python gen_characters.py
"""
import os
from PIL import Image, ImageDraw
from palette import c

OUT = os.path.join("..", "assets", "sprites", "characters")
os.makedirs(OUT, exist_ok=True)

W, H = 20, 30


def new_canvas():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def rect(d, x0, y0, x1, y1, color):
    d.rectangle([x0, y0, x1, y1], fill=c(color))


def draw_front_back(scheme, facing, frame_kind, frame_i):
    """facing: 'south' (de frente) o 'north' (de espaldas)."""
    img = new_canvas()
    d = ImageDraw.Draw(img)

    bob = 0
    leg_l_dx = leg_r_dx = 0
    leg_l_dy = leg_r_dy = 0
    arm_l_dy = arm_r_dy = 0
    arm_l_dx = arm_r_dx = 0
    tool_up = 0

    if frame_kind == "idle":
        bob = [0, 1][frame_i % 2]
    elif frame_kind == "walk":
        pattern = [0, 1, 2, 1]
        step = pattern[frame_i % 4]
        bob = [0, 1, 0, 1][frame_i % 4]
        if step == 0:
            leg_l_dx, leg_r_dx = -1, 1
            arm_l_dx, arm_r_dx = 1, -1
        elif step == 2:
            leg_l_dx, leg_r_dx = 1, -1
            arm_l_dx, arm_r_dx = -1, 1
    elif frame_kind == "attack":
        if frame_i == 0:
            arm_r_dy = -4
            tool_up = -3
        elif frame_i == 1:
            arm_r_dy = 2
            arm_r_dx = 2
            tool_up = 4
        else:
            arm_r_dy = 0

    skin = scheme["skin"]
    hair = scheme["hair"]
    tunic = scheme["tunic"]
    tunic_d = scheme["tunic_dark"]
    accent = scheme["accent"]

    y = bob

    # piernas (detras del torso)
    rect(d, 6 + leg_l_dx, 21 + y, 8 + leg_l_dx, 27 + y, skin)
    rect(d, 11 + leg_r_dx, 21 + y, 13 + leg_r_dx, 27 + y, skin)
    rect(d, 6 + leg_l_dx, 26 + y, 8 + leg_l_dx, 27 + y, tunic_d)
    rect(d, 11 + leg_r_dx, 26 + y, 13 + leg_r_dx, 27 + y, tunic_d)

    # brazos (detras del torso, se ven a los lados)
    rect(d, 3 + arm_l_dx, 13 + y + arm_l_dy, 5 + arm_l_dx, 19 + y + arm_l_dy, skin)
    rect(d, 14 + arm_r_dx, 13 + y + arm_r_dy, 16 + arm_r_dx, 19 + y + arm_r_dy, skin)

    # herramienta/arma en mano derecha
    tool_color = scheme.get("tool", "bone")
    rect(d, 15 + arm_r_dx, 8 + y + arm_r_dy + tool_up, 16 + arm_r_dx, 14 + y + arm_r_dy + tool_up, tool_color)

    # torso (tunica)
    rect(d, 5, 12 + y, 14, 20 + y, tunic)
    rect(d, 5, 18 + y, 14, 20 + y, tunic_d)
    rect(d, 8, 14 + y, 11, 16 + y, accent)

    # cuello
    rect(d, 9, 10 + y, 10, 12 + y, skin)

    # cabeza
    rect(d, 6, 3 + y, 13, 10 + y, skin)

    if facing == "south":
        rect(d, 8, 6 + y, 8, 6 + y, "outline")
        rect(d, 11, 6 + y, 11, 6 + y, "outline")
        rect(d, 8, 8 + y, 11, 8 + y, "skin_dark")
    # cabello
    rect(d, 5, 2 + y, 14, 4 + y, hair)
    rect(d, 5, 3 + y, 6, 8 + y, hair)
    rect(d, 13, 3 + y, 14, 8 + y, hair)
    if facing == "north":
        rect(d, 6, 3 + y, 13, 9 + y, hair)

    return img


def draw_side(scheme, frame_kind, frame_i):
    """Vista de perfil (mirando a la derecha = este). Oeste = flip horizontal."""
    img = new_canvas()
    d = ImageDraw.Draw(img)

    bob = 0
    leg_f_dx = leg_b_dx = 0
    arm_dy = 0
    tool_dx = tool_dy = 0
    tool_ang = 0

    if frame_kind == "idle":
        bob = [0, 1][frame_i % 2]
    elif frame_kind == "walk":
        pattern = [0, 1, 2, 1]
        step = pattern[frame_i % 4]
        bob = [0, 1, 0, 1][frame_i % 4]
        if step == 0:
            leg_f_dx, leg_b_dx = 2, -2
        elif step == 2:
            leg_f_dx, leg_b_dx = -2, 2
    elif frame_kind == "attack":
        if frame_i == 0:
            tool_dx, tool_dy = -2, -5
        elif frame_i == 1:
            tool_dx, tool_dy = 5, 1
        else:
            tool_dx, tool_dy = 1, 0

    skin = scheme["skin"]
    hair = scheme["hair"]
    tunic = scheme["tunic"]
    tunic_d = scheme["tunic_dark"]
    accent = scheme["accent"]
    tool_color = scheme.get("tool", "bone")

    y = bob
    # pierna trasera
    rect(d, 8 + leg_b_dx, 21 + y, 10 + leg_b_dx, 27 + y, skin)
    rect(d, 8 + leg_b_dx, 26 + y, 10 + leg_b_dx, 27 + y, tunic_d)
    # torso
    rect(d, 6, 12 + y, 14, 20 + y, tunic)
    rect(d, 6, 18 + y, 14, 20 + y, tunic_d)
    rect(d, 9, 14 + y, 12, 16 + y, accent)
    # brazo (con herramienta)
    rect(d, 12, 13 + y + arm_dy, 15, 18 + y + arm_dy, skin)
    rect(d, 14 + tool_dx, 9 + y + tool_dy, 15 + tool_dx, 15 + y + tool_dy, tool_color)
    # cuello + cabeza (perfil: frente saliente a la derecha)
    rect(d, 9, 10 + y, 11, 12 + y, skin)
    rect(d, 7, 3 + y, 14, 10 + y, skin)
    rect(d, 14, 6 + y, 15, 7 + y, skin)  # nariz
    rect(d, 12, 6 + y, 12, 6 + y, "outline")  # ojo
    # cabello
    rect(d, 6, 2 + y, 14, 4 + y, hair)
    rect(d, 6, 3 + y, 8, 9 + y, hair)
    # pierna delantera (encima)
    rect(d, 11 + leg_f_dx, 21 + y, 13 + leg_f_dx, 27 + y, skin)
    rect(d, 11 + leg_f_dx, 26 + y, 13 + leg_f_dx, 27 + y, tunic_d)

    return img


SCHEMES = {
    "player": dict(skin="skin", hair="hair", tunic="linen", tunic_dark="linen_dark",
                   accent="red_accent", tool="bone"),
    "meret": dict(skin="skin_dark", hair="anubis_black", tunic="turquoise", tunic_dark="turquoise_dark",
                  accent="gold", tool="gold"),
    "ptahmose": dict(skin="skin", hair="anubis_black", tunic="ochre", tunic_dark="ochre_dark",
                     accent="lapis", tool="bone"),
    "iry": dict(skin="skin_light", hair="hair", tunic="sand", tunic_dark="sand_dark",
                accent="nile_green", tool="bone"),
}


def build_spritesheet(name, scheme):
    frames = []
    layout = []
    specs = [
        ("south", "idle", 2), ("south", "walk", 4), ("south", "attack", 3),
        ("north", "idle", 2), ("north", "walk", 4), ("north", "attack", 3),
        ("east", "idle", 2), ("east", "walk", 4), ("east", "attack", 3),
    ]
    for facing, kind, n in specs:
        for i in range(n):
            if facing == "east":
                img = draw_side(scheme, kind, i)
            else:
                img = draw_front_back(scheme, facing, kind, i)
            frames.append(img)
            layout.append(f"{facing}_{kind}_{i}")

    sheet_w = W * len(frames)
    sheet = Image.new("RGBA", (sheet_w, H), (0, 0, 0, 0))
    for i, im in enumerate(frames):
        sheet.paste(im, (i * W, 0), im)
    path = os.path.join(OUT, f"{name}.png")
    sheet.save(path)
    print("wrote", path, sheet.size, "frames:", len(frames))
    with open(os.path.join(OUT, f"{name}_layout.txt"), "w") as f:
        f.write(f"frame_w={W} frame_h={H}\n")
        f.write("\n".join(layout))


if __name__ == "__main__":
    for name, scheme in SCHEMES.items():
        build_spritesheet(name, scheme)
