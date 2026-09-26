"""Recorta un retrato (idle de frente) de cada hoja de personaje ya generada,
para mostrarlo en la caja de dialogo."""
import os
from PIL import Image

OUT = os.path.join("..", "assets", "sprites", "portraits")
os.makedirs(OUT, exist_ok=True)

CHAR_W, CHAR_H = 20, 30
COMP_W, COMP_H = 20, 24


def crop_character(name):
    path = os.path.join("..", "assets", "sprites", "characters", f"{name}.png")
    img = Image.open(path)
    frame = img.crop((0, 0, CHAR_W, CHAR_H))
    frame = frame.resize((CHAR_W * 5, CHAR_H * 5), Image.NEAREST)
    frame.save(os.path.join(OUT, f"{name}.png"))
    print("wrote", f"{name}.png", frame.size)


def crop_thot():
    path = os.path.join("..", "assets", "sprites", "companion", "thot.png")
    img = Image.open(path)
    frame = img.crop((0, 0, COMP_W, COMP_H))
    frame = frame.resize((COMP_W * 5, COMP_H * 5), Image.NEAREST)
    frame.save(os.path.join(OUT, "thot.png"))
    print("wrote thot.png", frame.size)


def crop_codex_icons():
    """Iconos de una sola etapa/frame para el codice (evita mostrar la hoja
    de sprites entera encogida, que se veia como ruido)."""
    icons_out = os.path.join("..", "assets", "sprites", "icons")

    sombra = Image.open(os.path.join("..", "assets", "sprites", "enemies", "sombra.png"))
    frame = sombra.crop((0, 0, 20, 24)).resize((20 * 4, 24 * 4), Image.NEAREST)
    frame.save(os.path.join(icons_out, "codex_sombra.png"))

    heraldo = Image.open(os.path.join("..", "assets", "sprites", "enemies", "heraldo.png"))
    frame = heraldo.crop((0, 0, 48, 48)).resize((48 * 2, 48 * 2), Image.NEAREST)
    frame.save(os.path.join(icons_out, "codex_heraldo.png"))

    for crop_name in ["trigo", "papiro"]:
        img = Image.open(os.path.join("..", "assets", "sprites", "crops", f"{crop_name}.png"))
        frame = img.crop((16 * 3, 0, 16 * 4, 20)).resize((16 * 5, 20 * 5), Image.NEAREST)
        frame.save(os.path.join(icons_out, f"codex_{crop_name}.png"))

    print("wrote codex icons")


if __name__ == "__main__":
    for n in ["player", "meret", "ptahmose", "iry"]:
        crop_character(n)
    crop_thot()
    crop_codex_icons()
