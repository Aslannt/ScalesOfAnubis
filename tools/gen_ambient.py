"""Sprites de ambiente (PROMPT_PULIDO.md punto 3): ibis en vuelo, pez que
salta del Nilo, sombra circular bajo los personajes, hoja que vuela, punto
de luz para polvo/luciernagas."""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from pixel_draw import grid_to_image, hstrip, save, save_layout

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "fx")

# Ibis sagrado (animal de Thot): cuerpo blanco, cabeza/cuello y puntas de
# alas negras, pico curvo. Vista lateral en vuelo, 3 frames de aleteo.
IBIS_MAP = {"w": "bone", "g": "bone_dark", "k": "anubis_black", "o": "outline"}
IBIS = [
    [  # alas arriba
        "......k.........",
        ".....kwk........",
        "....kwwk........",
        "...kwwgk........",
        "..kwwwwk......k.",
        "kkwwwwwwwwwkkk.k",
        "...ggwwwwwgk....",
        "......kk........",
        "................",
        "................",
    ],
    [  # alas medio
        "................",
        "................",
        "................",
        "................",
        "..............k.",
        "kkkwwwwwwwwkkk.k",
        ".kwwwwwwwwgk....",
        "......kk........",
        "................",
        "................",
    ],
    [  # alas abajo
        "................",
        "................",
        "................",
        "................",
        "..............k.",
        "..kwwwwwwwwkkk.k",
        "...kwwwwwwgk....",
        "....kwwgk.......",
        ".....kwk........",
        "......k.........",
    ],
]

FISH_MAP = {"s": "moon_silver", "d": "bone_dark", "t": "turquoise_dark", "k": "outline", "e": "anubis_black"}
FISH = [
    [
        "..kkkkk...",
        ".ksssssk.k",
        "kseddssskk",
        ".kttttttk.",
        "..kkkkk..k",
        "..........",
    ],
    [
        "..kkkkk...",
        ".ksssssk..",
        "ksedsssskk",
        ".kttttttk.",
        "..kkkkk.kk",
        "..........",
    ],
]


def blob_shadow():
    """Elipse con 3 niveles de alfa (escalonada, sin degradado suave)."""
    w, h = 20, 10
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx, cy = (w - 1) / 2, (h - 1) / 2
    for y in range(h):
        for x in range(w):
            d = ((x - cx) / (w / 2)) ** 2 + ((y - cy) / (h / 2)) ** 2
            if d < 0.35:
                a = 120
            elif d < 0.7:
                a = 90
            elif d < 1.0:
                a = 50
            else:
                continue
            px[x, y] = (10, 8, 16, a)
    return img


def dot():
    img = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
    px = img.load()
    for x, y in ((1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3)):
        px[x, y] = (255, 255, 255, 255 if (x in (1, 2) and y in (1, 2)) else 150)
    return img


def leaf():
    return grid_to_image([
        "..gg",
        ".gGg",
        "gGg.",
        "gg..",
    ], {"g": "grass", "G": "grass_light"})


if __name__ == "__main__":
    frames = [grid_to_image(g, IBIS_MAP) for g in IBIS]
    save(hstrip(frames), os.path.join(OUT, "ibis.png"))
    save_layout(os.path.join(OUT, "ibis_layout.json"), 16, 10, ["fly_0", "fly_1", "fly_2"])
    frames = [grid_to_image(g, FISH_MAP) for g in FISH]
    save(hstrip(frames), os.path.join(OUT, "fish.png"))
    save_layout(os.path.join(OUT, "fish_layout.json"), 10, 6, ["jump_0", "jump_1"])
    save(blob_shadow(), os.path.join(OUT, "blob_shadow.png"))
    save(dot(), os.path.join(OUT, "dot.png"))
    save(leaf(), os.path.join(OUT, "leaf.png"))
