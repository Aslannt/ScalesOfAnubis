"""Sprites de efectos: llama de brasero/antorcha (animada) y una chispa de
impacto simple, para dar vida a la noche (GDD 8: luz calida de braseros)."""
import os
import sys
from PIL import Image, ImageDraw
from palette import c

sys.path.insert(0, os.path.dirname(__file__))
from postfx import add_outline

OUT = os.path.join("..", "assets", "sprites", "fx")
os.makedirs(OUT, exist_ok=True)

W, H = 12, 16


def canvas():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def draw_flame(i):
    img = canvas()
    d = ImageDraw.Draw(img)
    sway = [0, 1, 0, -1][i % 4]
    d.polygon([(6 + sway, 0), (10, 9), (6, 16), (2, 9)], fill=c("fire_orange"))
    d.polygon([(6 + sway, 3), (9, 10), (6, 15), (3, 10)], fill=c("fire_yellow"))
    d.polygon([(6, 6), (7, 11), (6, 14), (5, 11)], fill=c("bone"))
    return add_outline(img, (60, 20, 5, 255))


def build_flame():
    frames = [draw_flame(i) for i in range(4)]
    sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, im in enumerate(frames):
        sheet.paste(im, (i * W, 0), im)
    sheet.save(os.path.join(OUT, "flame.png"))
    with open(os.path.join(OUT, "flame_layout.txt"), "w") as f:
        f.write(f"frame_w={W} frame_h={H}\n" + "\n".join(f"burn_{i}" for i in range(4)))
    print("wrote flame.png", sheet.size)


def draw_grass_tuft(variant):
    img = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    blades = [(4, 11, 4, 4), (6, 11, 5, 2), (8, 11, 8, 5), (3, 11, 2, 6)]
    if variant == 1:
        blades = [(3, 11, 3, 3), (5, 11, 6, 1), (7, 11, 7, 4), (9, 11, 9, 7)]
    for x0, y0, x1, y1 in blades:
        d.line([(x0, y0), (x1, y1)], fill=c("nile_green_dark"), width=1)
        d.line([(x0, y0), (x1, y1 - 1)], fill=c("nile_green"), width=1)
    return img


def build_grass_tufts():
    out_dir = os.path.join("..", "assets", "sprites", "fx")
    for v in range(2):
        img = draw_grass_tuft(v)
        img.save(os.path.join(out_dir, f"grass_tuft_{v}.png"))
        print("wrote", f"grass_tuft_{v}.png", img.size)


if __name__ == "__main__":
    build_flame()
    build_grass_tufts()
