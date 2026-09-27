"""Retratos de dialogo (busto) recortados de los sprites del pase de arte:
cabeza y hombros del frame de frente, ampliados x5 sin suavizado."""
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
OUT = os.path.join(ROOT, "portraits")


def bust(sheet_path, frame_w, out_name, size=20):
    img = Image.open(sheet_path).convert("RGBA").crop((0, 0, frame_w, 32))
    bbox = img.getbbox()
    top = bbox[1]
    x0 = (frame_w - size) // 2
    crop = img.crop((x0, top, x0 + size, top + size))
    crop = crop.resize((size * 5, size * 5), Image.NEAREST)
    crop.save(os.path.join(OUT, out_name))
    print("wrote", out_name, crop.size)


if __name__ == "__main__":
    for n in ("player", "meret", "ptahmose", "iry"):
        bust(os.path.join(ROOT, "characters", n + ".png"), 24, n + ".png")
    t = Image.open(os.path.join(ROOT, "companion", "thot.png")).convert("RGBA").crop((0, 0, 24, 24))
    t.resize((96, 96), Image.NEAREST).save(os.path.join(OUT, "thot.png"))
    print("wrote thot.png")
