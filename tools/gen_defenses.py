"""Sprites de defensas (GDD 6.5): estatua de chacal de Anubis echado sobre
su pedestal (como la de la tumba de Tutankamon) con ojos que brillan al
disparar, y el proyectil dorado. Pixel art por geometria, paleta fija."""
import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from postfx import add_outline
from pixel_draw import save, save_layout

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "fx")


def jackal(eyes_on):
    w, h = 32, 32
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    black, dark = c("anubis_black"), (44, 38, 44, 255)
    # pedestal (cofre dorado y negro)
    d.rectangle([3, 22, 28, 31], fill=c("anubis_black"))
    d.rectangle([3, 22, 28, 23], fill=c("gold"))
    d.rectangle([3, 30, 28, 31], fill=c("gold_dark"))
    for x in range(6, 27, 5):
        d.rectangle([x, 25, x + 1, 28], fill=c("gold_dark"))
    # cuerpo echado
    d.polygon([(6, 21), (8, 15), (18, 14), (24, 16), (26, 21)], fill=black)
    d.rectangle([5, 19, 27, 21], fill=black)
    # patas delanteras extendidas
    d.rectangle([20, 19, 30, 21], fill=dark)
    d.point((30, 20), fill=black)
    # cuello y cabeza
    d.polygon([(19, 16), (21, 8), (25, 7), (26, 13), (23, 17)], fill=black)
    d.polygon([(24, 8), (30, 11), (30, 12), (25, 12)], fill=black)  # hocico largo
    # orejas altas y puntiagudas
    d.polygon([(21, 8), (21, 1), (23, 7)], fill=black)
    d.polygon([(23, 7), (25, 1), (25, 8)], fill=dark)
    # collar y cinta dorados
    d.line([(20, 13), (24, 15)], fill=c("gold"))
    d.line([(21, 4), (21, 6)], fill=c("gold_dark"))
    # cola
    d.line([(6, 20), (3, 21)], fill=black)
    # brillo en el lomo
    d.line([(10, 15), (17, 14)], fill=(80, 70, 90, 255))
    # ojo
    d.point((25, 9), fill=c("fire_yellow") if eyes_on else c("gold_dark"))
    if eyes_on:
        d.point((26, 9), fill=c("bone"))
    return add_outline(img, (12, 10, 12, 255))


def bolt():
    img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 6, 6], fill=c("gold"))
    d.ellipse([2, 2, 5, 5], fill=c("fire_yellow"))
    d.point((3, 3), fill=c("bone"))
    return img


if __name__ == "__main__":
    sheet = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    sheet.paste(jackal(False), (0, 0))
    sheet.paste(jackal(True), (32, 0))
    save(sheet, os.path.join(OUT, "jackal_statue.png"))
    save_layout(os.path.join(OUT, "jackal_statue_layout.json"), 32, 32, ["idle_0", "fire_0"])
    save(bolt(), os.path.join(OUT, "bolt.png"))


def slash(frame):
    """Arco de corte visto desde arriba (se pega al suelo en el juego)."""
    import math
    w, h = 40, 24
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx, cy = 20, 22
    span = [0.55, 0.85, 1.0][frame]
    for y in range(h):
        for x in range(w):
            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy)
            ang = math.atan2(-dy, dx)  # 0 = derecha, pi = izquierda
            if ang < 0:
                continue
            t = ang / math.pi
            if t > span:
                continue
            thick = 2.0 + 3.5 * math.sin(t / max(span, 0.01) * math.pi)
            if 20 - thick <= r <= 20:
                edge = r > 20 - 1.2
                col = (255, 250, 230, 255) if edge else (250, 205, 90, 200)
                px[x, y] = col
    return img


if __name__ == "__main__":
    frames = [slash(i) for i in range(3)]
    sheet = Image.new("RGBA", (40 * 3, 24), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * 40, 0), f)
    save(sheet, os.path.join(OUT, "slash.png"))
