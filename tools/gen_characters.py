"""Generador procedural de sprites de personajes (bloques con proporciones
"chibi", estilo RPG top-down) a partir de la paleta fija del juego. Rectangulos
pixel-perfect + contorno y sombreado (tools/postfx.py) para que se vea como
pixel art con intencion y no como bloques planos.

Uso: python gen_characters.py
"""
import os
import sys
from PIL import Image, ImageDraw
from palette import c

sys.path.insert(0, os.path.dirname(__file__))
from postfx import finish

OUT = os.path.join("..", "assets", "sprites", "characters")
os.makedirs(OUT, exist_ok=True)

W, H = 20, 30


def new_canvas():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def rect(d, x0, y0, x1, y1, color):
    if x1 < x0 or y1 < y0:
        return
    d.rectangle([x0, y0, x1, y1], fill=c(color))


def scale_child(img, scale=0.78, bottom_margin=2):
    """Reduce el sprite y lo reancla abajo (mismo suelo que un adulto) en vez
    de intentar recalcular cada coordenada a mano."""
    w, h = img.size
    new_w, new_h = max(1, round(w * scale)), max(1, round(h * scale))
    small = img.resize((new_w, new_h), Image.NEAREST)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = (w - new_w) // 2
    y = h - new_h - bottom_margin
    canvas.paste(small, (x, y), small)
    return canvas


def draw_front_back(scheme, facing, frame_kind, frame_i):
    """facing: 'south' (de frente) o 'north' (de espaldas)."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    belly = scheme.get("belly", 0)

    bob = 0
    leg_l_dx = leg_r_dx = 0
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
    tool_color = scheme.get("tool", "bone")

    y0 = 0
    y = bob

    # piernas
    leg_bot = 27
    rect(d, 6 + leg_l_dx, 21 + y0 + y, 8 + leg_l_dx, leg_bot + y0 + y, skin)
    rect(d, 11 + leg_r_dx, 21 + y0 + y, 13 + leg_r_dx, leg_bot + y0 + y, skin)
    rect(d, 6 + leg_l_dx, leg_bot - 1 + y0 + y, 8 + leg_l_dx, leg_bot + y0 + y, "sand_dark")
    rect(d, 11 + leg_r_dx, leg_bot - 1 + y0 + y, 13 + leg_r_dx, leg_bot + y0 + y, "sand_dark")

    # brazos
    rect(d, 3 + arm_l_dx - belly, 13 + y0 + y + arm_l_dy, 5 + arm_l_dx - belly, 19 + y0 + y + arm_l_dy, skin)
    rect(d, 14 + arm_r_dx + belly, 13 + y0 + y + arm_r_dy, 16 + arm_r_dx + belly, 19 + y0 + y + arm_r_dy, skin)
    # manos
    rect(d, 3 + arm_l_dx - belly, 18 + y0 + y + arm_l_dy, 5 + arm_l_dx - belly, 19 + y0 + y + arm_l_dy, "skin_dark")
    rect(d, 14 + arm_r_dx + belly, 18 + y0 + y + arm_r_dy, 16 + arm_r_dx + belly, 19 + y0 + y + arm_r_dy, "skin_dark")

    # herramienta/arma en mano derecha
    rect(d, 15 + arm_r_dx + belly, 8 + y0 + y + arm_r_dy + tool_up, 16 + arm_r_dx + belly, 14 + y0 + y + arm_r_dy + tool_up, tool_color)

    # torso (tunica), con ancho de "panza" opcional
    rect(d, 5 - belly, 12 + y0 + y, 14 + belly, 20 + y0 + y, tunic)
    rect(d, 5 - belly, 18 + y0 + y, 14 + belly, 20 + y0 + y, tunic_d)
    if scheme.get("collar"):
        rect(d, 6 - belly, 12 + y0 + y, 13 + belly, 13 + y0 + y, accent)
    rect(d, 8, 14 + y0 + y, 11, 16 + y0 + y, accent)

    # cuello
    rect(d, 9, 10 + y0 + y, 10, 12 + y0 + y, skin)

    # cabeza
    rect(d, 6, 3 + y0 + y, 13, 10 + y0 + y, skin)

    if facing == "south":
        rect(d, 8, 6 + y0 + y, 8, 6 + y0 + y, "outline")
        rect(d, 11, 6 + y0 + y, 11, 6 + y0 + y, "outline")
        rect(d, 9, 8 + y0 + y, 10, 8 + y0 + y, "skin_dark")

    headwear = scheme.get("headwear", "none")
    if headwear == "khat":
        rect(d, 5, 1 + y0 + y, 14, 4 + y0 + y, hair)
        rect(d, 4, 3 + y0 + y, 6, 11 + y0 + y, hair)
        rect(d, 13, 3 + y0 + y, 15, 11 + y0 + y, hair)
        rect(d, 5, 3 + y0 + y, 14, 4 + y0 + y, accent)
    elif headwear == "band":
        rect(d, 5, 2 + y0 + y, 14, 4 + y0 + y, hair)
        rect(d, 5, 3 + y0 + y, 6, 9 + y0 + y, hair)
        rect(d, 13, 3 + y0 + y, 14, 9 + y0 + y, hair)
        if facing == "north":
            rect(d, 6, 3 + y0 + y, 13, 10 + y0 + y, hair)
        rect(d, 4, 4 + y0 + y, 15, 5 + y0 + y, accent)
    else:
        rect(d, 5, 2 + y0 + y, 14, 4 + y0 + y, hair)
        rect(d, 5, 3 + y0 + y, 6, 8 + y0 + y, hair)
        rect(d, 13, 3 + y0 + y, 14, 8 + y0 + y, hair)
        if facing == "north":
            rect(d, 6, 3 + y0 + y, 13, 9 + y0 + y, hair)

    return img


def draw_side(scheme, frame_kind, frame_i):
    """Vista de perfil (mirando a la derecha = este). Oeste = flip horizontal."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    belly = scheme.get("belly", 0)

    bob = 0
    leg_f_dx = leg_b_dx = 0
    arm_dy = 0
    tool_dx = tool_dy = 0

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

    y0 = 0
    y = bob
    leg_bot = 27

    rect(d, 8 + leg_b_dx, 21 + y0 + y, 10 + leg_b_dx, leg_bot + y0 + y, skin)
    rect(d, 8 + leg_b_dx, leg_bot - 1 + y0 + y, 10 + leg_b_dx, leg_bot + y0 + y, "sand_dark")

    rect(d, 6 - belly, 12 + y0 + y, 14 + belly, 20 + y0 + y, tunic)
    rect(d, 6 - belly, 18 + y0 + y, 14 + belly, 20 + y0 + y, tunic_d)
    rect(d, 9, 14 + y0 + y, 12, 16 + y0 + y, accent)

    rect(d, 12 + belly, 13 + y0 + y + arm_dy, 15 + belly, 18 + y0 + y + arm_dy, skin)
    rect(d, 14 + tool_dx + belly, 9 + y0 + y + tool_dy, 15 + tool_dx + belly, 15 + y0 + y + tool_dy, tool_color)

    rect(d, 9, 10 + y0 + y, 11, 12 + y0 + y, skin)
    rect(d, 7, 3 + y0 + y, 14, 10 + y0 + y, skin)
    rect(d, 14, 6 + y0 + y, 15, 7 + y0 + y, skin)
    rect(d, 12, 6 + y0 + y, 12, 6 + y0 + y, "outline")

    headwear = scheme.get("headwear", "none")
    if headwear == "khat":
        rect(d, 6, 2 + y0 + y, 14, 4 + y0 + y, hair)
        rect(d, 6, 3 + y0 + y, 8, 11 + y0 + y, hair)
        rect(d, 12, 2 + y0 + y, 15, 5 + y0 + y, hair)
        rect(d, 6, 3 + y0 + y, 14, 4 + y0 + y, accent)
    elif headwear == "band":
        rect(d, 6, 2 + y0 + y, 14, 4 + y0 + y, hair)
        rect(d, 6, 3 + y0 + y, 8, 9 + y0 + y, hair)
        rect(d, 6, 4 + y0 + y, 14, 5 + y0 + y, accent)
    else:
        rect(d, 6, 2 + y0 + y, 14, 4 + y0 + y, hair)
        rect(d, 6, 3 + y0 + y, 8, 9 + y0 + y, hair)

    rect(d, 11 + leg_f_dx, 21 + y0 + y, 13 + leg_f_dx, leg_bot + y0 + y, skin)
    rect(d, 11 + leg_f_dx, leg_bot - 1 + y0 + y, 13 + leg_f_dx, leg_bot + y0 + y, "sand_dark")

    return img


SCHEMES = {
    "player": dict(skin="skin", hair="hair", tunic="linen", tunic_dark="linen_dark",
                   accent="red_accent", tool="bone", headwear="none"),
    "meret": dict(skin="skin_dark", hair="anubis_black", tunic="turquoise", tunic_dark="turquoise_dark",
                  accent="gold", tool="gold", headwear="band", collar=True),
    "ptahmose": dict(skin="skin", hair="anubis_black", tunic="ochre", tunic_dark="ochre_dark",
                     accent="lapis", tool="bone", headwear="khat", belly=1),
    "iry": dict(skin="skin_light", hair="hair", tunic="sand", tunic_dark="sand_dark",
                accent="nile_green", tool="bone", headwear="none", child=True),
}


def build_spritesheet(name, scheme):
    frames = []
    layout = []
    specs = [
        ("south", "idle", 2), ("south", "walk", 4), ("south", "attack", 3),
        ("north", "idle", 2), ("north", "walk", 4), ("north", "attack", 3),
        ("east", "idle", 2), ("east", "walk", 4), ("east", "attack", 3),
    ]
    is_child = scheme.get("child", False)
    for facing, kind, n in specs:
        for i in range(n):
            if facing == "east":
                img = draw_side(scheme, kind, i)
            else:
                img = draw_front_back(scheme, facing, kind, i)
            if is_child:
                img = scale_child(img)
            img = finish(img)
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
