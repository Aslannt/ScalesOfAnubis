"""Sprites de la balanza del corazon (GDD 6.1): viga que se inclina + pivote fijo."""
import os
from PIL import Image, ImageDraw
from palette import c

OUT = os.path.join("..", "assets", "sprites", "icons")
os.makedirs(OUT, exist_ok=True)


def beam():
    W, H = 64, 10
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 3, W - 1, 6], fill=c("gold_dark"))
    d.rectangle([0, 3, W - 1, 4], fill=c("gold"))
    d.rectangle([W // 2 - 2, 0, W // 2 + 1, 9], fill=c("gold"))
    for x in (3, W - 4):
        d.line([(x, 6), (x, 9)], fill=c("gold_dark"), width=1)
    img.save(os.path.join(OUT, "balanza_viga.png"))
    print("wrote balanza_viga.png", img.size)


def pivote():
    W, H = 16, 20
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(8, 0), (14, 18), (2, 18)], fill=c("gold_dark"))
    d.polygon([(8, 0), (11, 18), (5, 18)], fill=c("gold"))
    d.rectangle([2, 17, 14, 19], fill=c("ochre_dark"))
    img.save(os.path.join(OUT, "balanza_pivote.png"))
    print("wrote balanza_pivote.png", img.size)


if __name__ == "__main__":
    beam()
    pivote()
