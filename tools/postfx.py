"""Post-proceso aplicado a todos los sprites generados para que se vean con
mas intencion: contorno oscuro (legibilidad clasica de pixel art) + sombreado
direccional simple (falso volumen) sin tener que rediseñar cada forma."""
from PIL import Image


def add_outline(img: Image.Image, color=(20, 16, 15, 255)) -> Image.Image:
    """Agrega un contorno de 1px alrededor de la silueta (8 direcciones)."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            has_neighbor = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0:
                    has_neighbor = True
                    break
            if has_neighbor:
                dst[x, y] = color
    return out


def shade_vertical(img: Image.Image, top_mult=1.12, bottom_mult=0.82) -> Image.Image:
    """Oscurece progresivamente hacia abajo y aclara un poco arriba, como si
    hubiera una luz cenital suave. Solo afecta pixeles opacos."""
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        mult = top_mult + (bottom_mult - top_mult) * t
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (
                min(255, int(r * mult)),
                min(255, int(g * mult)),
                min(255, int(b * mult)),
                a,
            )
    return img


def finish(img: Image.Image, outline_color=(20, 16, 15, 255)) -> Image.Image:
    img = shade_vertical(img)
    img = add_outline(img, outline_color)
    return img
