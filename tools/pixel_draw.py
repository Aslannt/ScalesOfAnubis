"""Utilidades para dibujar pixel art a partir de grids de texto (ASCII-art) usando
una paleta fija. Cada grid es una lista de strings de igual largo; cada caracter
mapea a un color via un dict {char: color_name_en_paleta}.
"""
from PIL import Image
from palette import c


def grid_to_image(grid, cmap, scale=1, flip_x=False):
    rows = [row for row in grid if row != "" or True]
    h = len(rows)
    w = len(rows[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        assert len(row) == w, f"fila {y} largo {len(row)} != {w}: {row!r}"
        for x, ch in enumerate(row):
            if ch == "." or ch == " ":
                continue
            color_name = cmap[ch]
            px[x, y] = c(color_name)
    if flip_x:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    if scale != 1:
        img = img.resize((w * scale, h * scale), Image.NEAREST)
    return img


def hstrip(images):
    """Une una lista de imagenes del mismo tamano en una sola tira horizontal
    (spritesheet), util para SpriteFrames."""
    w, h = images[0].size
    sheet = Image.new("RGBA", (w * len(images), h), (0, 0, 0, 0))
    for i, im in enumerate(images):
        sheet.paste(im, (i * w, 0), im)
    return sheet


def save(img, path):
    img.save(path)
    print("wrote", path, img.size)
