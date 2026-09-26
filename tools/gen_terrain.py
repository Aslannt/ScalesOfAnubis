"""Genera texturas pixeladas tileables para el terreno y edificios low-poly."""
import os
import numpy as np
from PIL import Image
from palette import c

OUT = os.path.join("..", "assets", "textures")
os.makedirs(OUT, exist_ok=True)

SIZE = 48


def _blob(px, size, cx, cy, w, h, color):
    """Pinta un blob rectangular pequeno con wraparound (para que el tile
    siga siendo perfectamente seamless al repetirse)."""
    for oy in range(h):
        for ox in range(w):
            x = (cx + ox) % size
            y = (cy + oy) % size
            px[x, y] = color


def speckle(base, dark, light, seed, density=0.10, size=SIZE):
    """Ruido en 'grumos' (blobs de 2x2/3x2) en vez de grano fino uniforme:
    se lee mas como tierra/arena pintada a mano y menos como estatica."""
    rng = np.random.RandomState(seed)
    img = Image.new("RGBA", (size, size), c(base))
    px = img.load()
    n_blobs = int(size * size * density / 4)
    for _ in range(n_blobs):
        cx, cy = rng.randint(0, size), rng.randint(0, size)
        w = rng.choice([1, 2, 2, 3])
        h = rng.choice([1, 2, 2])
        color = c(dark) if rng.random() < 0.5 else c(light)
        _blob(px, size, cx, cy, int(w), int(h), color)
    return img


def grid_lines(img, color, step=8):
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if x % step == 0 or y % step == 0:
                pass
    return img


def make_sand():
    return speckle("sand", "sand_dark", "sand_light", seed=1, density=0.18)


def make_grass():
    return speckle("nile_green", "nile_green_dark", "sand_light", seed=2, density=0.14)


def make_soil_dry():
    img = speckle("soil", "soil_dark", "ochre", seed=3, density=0.16)
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            if y % 8 in (0, 1):
                r, g, b, a = px[x, y]
                px[x, y] = (max(r - 20, 0), max(g - 20, 0), max(b - 20, 0), a)
    return img


def make_soil_wet():
    img = speckle("soil_wet", "soil_dark", "soil", seed=4, density=0.10)
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            if y % 8 in (0, 1):
                r, g, b, a = px[x, y]
                px[x, y] = (max(r - 15, 0), max(g - 15, 0), max(b - 15, 0), a)
    return img


def make_path():
    return speckle("sand_dark", "ochre_dark", "sand", seed=5, density=0.15)


def make_water():
    rng = np.random.RandomState(6)
    img = Image.new("RGBA", (SIZE, SIZE), c("nile_water"))
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            wave = (x + y * 2) % 8
            if wave < 2:
                px[x, y] = c("nile_water_dark")
            elif wave == 2 and rng.random() < 0.3:
                px[x, y] = c("turquoise")
    return img


def make_adobe():
    img = Image.new("RGBA", (SIZE, SIZE), c("ochre"))
    px = img.load()
    brick_w, brick_h = 8, 4
    for y in range(SIZE):
        for x in range(SIZE):
            offset = brick_w // 2 if (y // brick_h) % 2 == 1 else 0
            bx = (x + offset) % brick_w
            by = y % brick_h
            if bx == 0 or by == 0:
                px[x, y] = c("ochre_dark")
    rng = np.random.RandomState(7)
    for y in range(SIZE):
        for x in range(SIZE):
            if px[x, y] == c("ochre") and rng.random() < 0.06:
                px[x, y] = c("sand")
    return img


def make_stone():
    img = speckle("bone_dark", "sand_dark", "bone", seed=8, density=0.12)
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            if x % 16 == 0 or y % 12 == 0:
                r, g, b, a = px[x, y]
                px[x, y] = (max(r - 30, 0), max(g - 30, 0), max(b - 30, 0), a)
    return img


def make_wood():
    img = Image.new("RGBA", (SIZE, SIZE), c("ochre_dark"))
    px = img.load()
    rng = np.random.RandomState(9)
    for y in range(SIZE):
        for x in range(SIZE):
            band = (x // 4) % 2
            base = "ochre_dark" if band == 0 else "soil"
            px[x, y] = c(base)
            if rng.random() < 0.08:
                px[x, y] = c("soil_dark")
    return img


def make_wall_papyrus():
    img = speckle("linen", "linen_dark", "bone", seed=10, density=0.10)
    px = img.load()
    for y in range(SIZE):
        if y % 6 == 0:
            for x in range(SIZE):
                r, g, b, a = px[x, y]
                px[x, y] = (max(r - 15, 0), max(g - 15, 0), max(b - 15, 0), a)
    return img


def make_necropolis_sand():
    return speckle("sand_dark", "anubis_black", "bone_dark", seed=11, density=0.08)


TEXTURES = {
    "sand": make_sand,
    "grass_nile": make_grass,
    "soil_dry": make_soil_dry,
    "soil_wet": make_soil_wet,
    "path": make_path,
    "water": make_water,
    "adobe": make_adobe,
    "stone": make_stone,
    "wood": make_wood,
    "wall_papyrus": make_wall_papyrus,
    "necropolis_sand": make_necropolis_sand,
}

if __name__ == "__main__":
    for name, fn in TEXTURES.items():
        img = fn()
        path = os.path.join(OUT, f"{name}.png")
        img.save(path)
        print("wrote", path, img.size)
