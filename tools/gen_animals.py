"""Animales de la aldea (tercera ronda, "que se sienta vivo el mundo"):
gato egipcio (mau, arena con manchas) y ganso del Nilo. Vista lateral
mirando a la derecha; Godot los espeja con flip_h. Paleta fija."""
import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from postfx import add_outline
from pixel_draw import hstrip, save, save_layout

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "fx")


def px(d, x, y, col):
    d.point((x, y), fill=c(col))


def cat(pose, f):
    """16x12. pose: sit | walk. f: frame."""
    img = Image.new("RGBA", (16, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body, dark, light = "ochre", "ochre_dark", "sand_light"
    if pose == "sit":
        # cuerpo sentado, erguido
        d.ellipse((5, 4, 11, 11), fill=c(body))
        d.rectangle((6, 9, 10, 10), fill=c(body))
        d.line((7, 6, 7, 10), fill=c(light))  # pecho claro
        # cabeza
        d.ellipse((8, 1, 13, 5), fill=c(body))
        px(d, 9, 0, body); px(d, 12, 0, body)  # orejas
        px(d, 9, 1, dark); px(d, 12, 1, dark)
        px(d, 11, 3, "nile_green_light")  # ojo
        px(d, 13, 4, dark)
        # patas delanteras
        d.line((9, 8, 9, 11), fill=c(light)); d.line((10, 8, 10, 11), fill=c(body))
        # cola: se mueve con el frame
        tail = [(4, 10), (3, 10), (2, 9), (2, 8)] if f == 0 else [(4, 10), (3, 11), (2, 11), (1, 10)]
        for (x, y) in tail:
            px(d, x, y, dark)
        # manchas
        px(d, 6, 6, dark); px(d, 8, 8, dark); px(d, 6, 9, dark)
    else:
        # cuerpo alargado caminando
        d.ellipse((2, 4, 12, 8), fill=c(body))
        d.ellipse((10, 2, 15, 6), fill=c(body))
        px(d, 11, 1, body); px(d, 14, 1, body)
        px(d, 11, 2, dark); px(d, 14, 2, dark)
        px(d, 13, 4, "nile_green_light")
        px(d, 15, 5, dark)
        # patas: dos pares alternando
        legs = [(3, 5), (10, 12)] if f % 2 == 0 else [(4, 4), (11, 11)]
        off = [0, 1, 0, -1][f]
        for (a, b) in legs:
            d.line((a + off, 8, a, 11), fill=c(body))
            d.line((b - off, 8, b, 11), fill=c(body))
        # cola en alto con la punta oscura
        for (x, y) in [(2, 5), (1, 4), (1, 3), (0, 2)]:
            px(d, x, y, dark)
        px(d, 5, 5, dark); px(d, 8, 6, dark); px(d, 6, 7, dark)
        d.line((5, 8, 10, 8), fill=c(light))
    return add_outline(img)


def goose(pose, f):
    """14x12. Ganso del Nilo: pecho canela, parche castano en el ojo,
    alas con blanco y verde. pose: idle | peck | walk."""
    img = Image.new("RGBA", (14, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((2, 5, 11, 10), fill=c("sand_dark"))
    d.ellipse((3, 5, 9, 8), fill=c("linen_dark"))
    d.line((4, 7, 8, 7), fill=c("nile_green_dark"))  # franja del ala
    px(d, 2, 6, "bone"); px(d, 1, 6, "anubis_black")  # cola
    if pose == "peck":
        d.line((10, 7, 12, 9), fill=c("linen"))
        d.rectangle((11, 9, 12, 10), fill=c("linen"))
        px(d, 12, 9, "red_dark")
        px(d, 13, 10, "fire_orange")
    else:
        d.line((10, 6, 10, 2), fill=c("linen"))
        d.ellipse((9, 0, 12, 3), fill=c("linen"))
        px(d, 11, 1, "red_dark")  # parche del ojo
        px(d, 13, 2, "fire_orange"); px(d, 12, 2, "fire_orange")
    # patas
    if pose == "walk":
        a, b = (5, 7) if f == 0 else (6, 6)
        d.line((a, 10, a - (1 if f == 0 else 0), 11), fill=c("fire_orange"))
        d.line((b + 2, 10, b + 2 + (1 if f == 0 else 0), 11), fill=c("fire_orange"))
    else:
        px(d, 6, 11, "fire_orange"); px(d, 8, 11, "fire_orange")
        px(d, 6, 10, "fire_orange"); px(d, 8, 10, "fire_orange")
    return add_outline(img)


if __name__ == "__main__":
    frames = [cat("sit", 0), cat("sit", 1)] + [cat("walk", i) for i in range(4)]
    save(hstrip(frames), os.path.join(OUT, "cat.png"))
    save_layout(os.path.join(OUT, "cat_layout.json"), 16, 12, ["sit_0", "sit_1", "walk_0", "walk_1", "walk_2", "walk_3"])
    frames = [goose("idle", 0), goose("peck", 0), goose("walk", 0), goose("walk", 1)]
    save(hstrip(frames), os.path.join(OUT, "goose.png"))
    save_layout(os.path.join(OUT, "goose_layout.json"), 14, 12, ["idle_0", "peck_0", "walk_0", "walk_1"])
    print("animales ok")
