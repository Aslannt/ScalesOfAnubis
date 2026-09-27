"""Genera texturas pixeladas tileables para el terreno y edificios low-poly."""
import os
import numpy as np
from PIL import Image
from palette import c

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "textures")
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


def _seamless_noise_field(seed, size=SIZE, low_res=6):
    """Campo de ruido suave (0..1) y perfectamente tileable: genera una
    grilla de baja resolucion, la mosaiquea 3x3 y la escala con interpolacion
    bicubica, recortando el tile central. Da 'manchas' organicas en vez de
    grano de television."""
    rng = np.random.RandomState(seed)
    low = (rng.random((low_res, low_res)) * 255).astype(np.uint8)
    low_img = Image.fromarray(low, mode="L")
    tiled = Image.new("L", (low_res * 3, low_res * 3))
    for ty in range(3):
        for tx in range(3):
            tiled.paste(low_img, (tx * low_res, ty * low_res))
    big = tiled.resize((size * 3, size * 3), Image.BICUBIC)
    center = big.crop((size, size, size * 2, size * 2))
    return np.asarray(center).astype(np.float32) / 255.0


def organic_patches(tones, seed, size=SIZE, low_res=6):
    """Mezcla 2-4 tonos CERCANOS entre si en manchas suaves y grandes (sin
    puntos sueltos de alto contraste). `tones` son nombres de paleta,
    ordenados de mas oscuro a mas claro."""
    field = _seamless_noise_field(seed, size, low_res)
    n = len(tones)
    colors = [np.array(c(t)[:3], dtype=np.float32) for t in tones]
    out = np.zeros((size, size, 3), dtype=np.float32)
    scaled = field * (n - 1)
    idx = np.clip(scaled.astype(int), 0, n - 2)
    frac = scaled - idx
    for y in range(size):
        for x in range(size):
            i = idx[y, x]
            t = frac[y, x]
            out[y, x] = colors[i] * (1 - t) + colors[i + 1] * t
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            r, g, b = out[y, x]
            px[x, y] = (int(r), int(g), int(b), 255)
    return img


def add_sparse_detail(img, color, seed, count=14, blob_w=(1, 2), blob_h=(1, 2)):
    """Unos pocos blobs chiquitos de detalle (piedritas, briznas, ceniza),
    bien espaciados: da textura sin volver a la estatica de TV."""
    rng = np.random.RandomState(seed + 500)
    size = img.size[0]
    px = img.load()
    col = c(color)
    for _ in range(count):
        cx, cy = rng.randint(0, size), rng.randint(0, size)
        w = rng.randint(blob_w[0], blob_w[1] + 1)
        h = rng.randint(blob_h[0], blob_h[1] + 1)
        _blob(px, size, cx, cy, w, h, col)
    return img


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
    img = organic_patches(["sand_dark", "sand", "sand_light"], seed=1)
    img = add_sparse_detail(img, "sand_dark", seed=1, count=10)
    return img


def make_grass():
    # verde calido de pasto (antes nile_green: se veia menta/turquesa)
    img = organic_patches(["grass_dark", "grass", "grass_light"], seed=2)
    img = add_sparse_detail(img, "grass_dark", seed=2, count=16, blob_w=(1, 1), blob_h=(2, 3))
    img = add_sparse_detail(img, "grass_dry", seed=9, count=6, blob_w=(1, 2), blob_h=(1, 1))
    return img


def _furrows(img, ridge=18, groove=-26, period=8):
    """Surcos horizontales: una fila clara (lomo) y dos oscuras (surco)."""
    px = img.load()
    for y in range(SIZE):
        k = y % period
        delta = ridge if k == 0 else (groove if k in (period // 2, period // 2 + 1) else 0)
        if delta == 0:
            continue
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            px[x, y] = (max(0, min(255, r + delta)), max(0, min(255, g + delta)), max(0, min(255, b + delta)), a)
    return img


def make_field():
    """Tierra negra del Nilo sin arar (Kemet): el campo se lee como campo de
    cultivo y no como un piso de baldosas verdes."""
    img = organic_patches(["kemet_dark", "kemet", "kemet_light"], seed=12)
    img = add_sparse_detail(img, "grass", seed=12, count=7, blob_w=(1, 1), blob_h=(1, 2))
    img = add_sparse_detail(img, "kemet_light", seed=13, count=10)
    return img


def make_soil_dry():
    img = organic_patches(["kemet_dark", "kemet", "soil"], seed=3)
    return _furrows(img)


def make_soil_wet():
    img = organic_patches(["soil_wet", "kemet_dark", "soil_wet"], seed=4)
    return _furrows(img, ridge=12, groove=-18)


def make_path():
    img = organic_patches(["ochre_dark", "sand_dark", "sand"], seed=5)
    img = add_sparse_detail(img, "ochre_dark", seed=5, count=10)
    return img


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


def make_plot_marker():
    """Marco de parcela sin arar (PROMPT_PULIDO.md punto 2): para que se
    note que es tierra de cultivo aunque el jugador todavia no haya arado."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    # lomo de tierra (bordo de riego) entre parcelas, claro y semitransparente
    r, g, b, _ = c("kemet_light")
    border_col = (r, g, b, 150)
    inset = 0
    thick = 2
    for y in range(SIZE):
        for x in range(SIZE):
            on_border = (
                (inset <= x < inset + thick or SIZE - inset - thick <= x < SIZE - inset)
                and inset <= y < SIZE - inset
            ) or (
                (inset <= y < inset + thick or SIZE - inset - thick <= y < SIZE - inset)
                and inset <= x < SIZE - inset
            )
            if on_border:
                px[x, y] = border_col
    return img


def make_necropolis_sand():
    img = organic_patches(["soil_dark", "sand_dark", "bone_dark"], seed=11)
    img = add_sparse_detail(img, "anubis_black", seed=11, count=8)
    return img


def make_plaster():
    """Revoque de barro claro de las casas de adobe (lo tipico en las aldeas
    del Nilo): manchas suaves, un par de ladrillos asomando donde se cayo el
    revoque, y unas grietas finas."""
    img = organic_patches(["sand_dark", "sand", "sand_light"], seed=21, low_res=5)
    px = img.load()
    rng = np.random.RandomState(21)
    for _ in range(3):
        bx, by = rng.randint(0, SIZE - 12), rng.randint(0, SIZE - 8)
        for row in range(2):
            for col in range(2):
                x0 = bx + col * 6 + (3 if row % 2 else 0)
                y0 = by + row * 4
                for y in range(y0, y0 + 3):
                    for x in range(x0, x0 + 5):
                        px[x % SIZE, y % SIZE] = c("ochre") if (x + y) % 5 else c("ochre_dark")
    for _ in range(4):
        x, y = rng.randint(0, SIZE), rng.randint(0, SIZE)
        for k in range(rng.randint(3, 7)):
            x += rng.choice([-1, 0, 1])
            y += 1
            r, g, b, a = px[x % SIZE, y % SIZE]
            px[x % SIZE, y % SIZE] = (int(r * 0.8), int(g * 0.8), int(b * 0.8), a)
    return img


def make_palm_mat():
    """Estera de hojas de palma para toldos y techos: tiras tejidas."""
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    base = np.array(c("grass_dry")[:3], dtype=float)
    for y in range(SIZE):
        for x in range(SIZE):
            band = (x // 4 + y // 4) % 2
            k = 1.0 if band else 0.82
            if (x % 4 == 0) or (y % 4 == 0 and band):
                k *= 0.78
            col = base * k
            px[x, y] = (int(col[0]), int(col[1]), int(col[2]), 255)
    return img


def make_roof_mud():
    """Techo de barro apisonado con paja: mas oscuro que las paredes, asi
    desde la camara alta se distingue el techo del muro."""
    img = organic_patches(["ochre_dark", "soil", "ochre_dark"], seed=31, low_res=5)
    px = img.load()
    rng = np.random.RandomState(31)
    for _ in range(40):
        x, y = rng.randint(0, SIZE), rng.randint(0, SIZE)
        for k in range(rng.randint(2, 5)):
            px[(x + k) % SIZE, y] = c("grass_dry")
    return img


def make_thatch():
    """Techo de hojas de palma: capas horizontales solapadas."""
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    rng = np.random.RandomState(33)
    base = [c("grass_dry"), c("ochre"), c("sand_dark")]
    for y in range(SIZE):
        row = (y // 6) % 3
        for x in range(SIZE):
            col = base[row]
            k = 1.0 - (y % 6) * 0.07
            if (x + (y // 6) * 3) % 5 == 0:
                k *= 0.8
            if rng.random() < 0.05:
                k *= 0.85
            px[x, y] = (int(col[0] * k), int(col[1] * k), int(col[2] * k), 255)
    return img


def make_pyramid_stone():
    """Hiladas de bloques de caliza para las piramides."""
    img = organic_patches(["sand_dark", "sand", "sand_light"], seed=35, low_res=4)
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            course = y // 6
            joint_x = (x + (course % 2) * 8) % 16 == 0
            if y % 6 == 0 or joint_x:
                r, g, b, a = px[x, y]
                px[x, y] = (int(r * 0.72), int(g * 0.72), int(b * 0.72), a)
    return img


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
    "plot_marker": make_plot_marker,
    "field": make_field,
    "plaster": make_plaster,
    "palm_mat": make_palm_mat,
    "roof_mud": make_roof_mud,
    "thatch": make_thatch,
    "pyramid_stone": make_pyramid_stone,
}

if __name__ == "__main__":
    for name, fn in TEXTURES.items():
        img = fn()
        path = os.path.join(OUT, f"{name}.png")
        img.save(path)
        print("wrote", path, img.size)
