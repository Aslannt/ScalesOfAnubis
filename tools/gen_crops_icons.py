"""Genera sprites de cultivos por etapa (billboards) e iconos de UI/inventario."""
import os
from PIL import Image, ImageDraw
from palette import c

OUT_CROPS = os.path.join("..", "assets", "sprites", "crops")
OUT_ICONS = os.path.join("..", "assets", "sprites", "icons")
os.makedirs(OUT_CROPS, exist_ok=True)
os.makedirs(OUT_ICONS, exist_ok=True)

W, H = 16, 20


def canvas(w=W, h=H):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(d, x0, y0, x1, y1, color):
    d.rectangle([x0, y0, x1, y1], fill=c(color))


def draw_wheat(stage):
    img = canvas()
    d = ImageDraw.Draw(img)
    if stage == 0:  # semilla / brote diminuto
        rect(d, 7, 17, 8, 19, "nile_green_dark")
    elif stage == 1:  # brote
        rect(d, 7, 12, 8, 19, "nile_green")
        rect(d, 6, 10, 9, 12, "nile_green")
    elif stage == 2:  # creciendo
        for x in (5, 8, 11):
            rect(d, x, 8, x + 1, 19, "nile_green")
        rect(d, 4, 6, 12, 9, "nile_green_dark")
    else:  # listo (dorado)
        for x in (5, 8, 11):
            rect(d, x, 6, x + 1, 19, "gold_dark")
        rect(d, 4, 3, 12, 8, "gold")
        rect(d, 5, 2, 11, 4, "sand_light")
    return img


def draw_lino(stage):
    img = canvas()
    d = ImageDraw.Draw(img)
    if stage == 0:
        rect(d, 7, 17, 8, 19, "nile_green_dark")
    elif stage == 1:
        rect(d, 7, 13, 8, 19, "nile_green")
    elif stage == 2:
        for x in (6, 9):
            rect(d, x, 9, x + 1, 19, "nile_green")
        rect(d, 5, 8, 10, 10, "nile_green")
    else:
        for x in (5, 8, 10):
            rect(d, x, 5, x + 1, 19, "nile_green_dark")
        rect(d, 4, 2, 12, 6, "lapis")
        rect(d, 5, 2, 6, 3, "turquoise")
        rect(d, 9, 3, 10, 4, "turquoise")
    return img


def draw_papiro(stage):
    img = canvas()
    d = ImageDraw.Draw(img)
    if stage == 0:
        rect(d, 7, 17, 8, 19, "turquoise_dark")
    elif stage == 1:
        rect(d, 7, 12, 8, 19, "turquoise_dark")
    elif stage == 2:
        for x in (5, 7, 9, 11):
            rect(d, x, 7, x + 1, 19, "turquoise_dark")
    else:
        for x in (4, 6, 8, 10, 12):
            rect(d, x, 5, x + 1, 19, "turquoise_dark")
        d.polygon([(2, 5), (14, 5), (8, 0)], fill=c("nile_green"))
        d.polygon([(3, 6), (13, 6), (8, 2)], fill=c("nile_green_dark"))
    return img


CROPS = {"trigo": draw_wheat, "lino": draw_lino, "papiro": draw_papiro}


def build_crops():
    for name, fn in CROPS.items():
        frames = [fn(s) for s in range(4)]
        sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
        for i, im in enumerate(frames):
            sheet.paste(im, (i * W, 0), im)
        path = os.path.join(OUT_CROPS, f"{name}.png")
        sheet.save(path)
        print("wrote", path, sheet.size)


# ---------------- Iconos ----------------
ICON = 16


def icon_canvas():
    return Image.new("RGBA", (ICON, ICON), (0, 0, 0, 0))


def draw_deben():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([2, 2, 13, 13], fill=c("gold_dark"))
    d.ellipse([3, 3, 12, 12], fill=c("gold"))
    d.ellipse([5, 5, 10, 10], fill=c("gold_dark"))
    return img


def draw_heart():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([3, 4, 6, 7], fill=c("red_accent"))
    d.rectangle([9, 4, 12, 7], fill=c("red_accent"))
    d.polygon([(2, 6), (13, 6), (7, 14)], fill=c("red_accent"))
    d.rectangle([6, 6, 9, 8], fill=c("red_dark"))
    return img


def draw_feather():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(8, 1), (11, 6), (8, 15), (5, 6)], fill=c("bone"))
    d.rectangle([7, 1, 8, 15], fill=c("bone_dark"))
    return img


def draw_hoe():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([7, 2, 8, 13], fill=c("ochre_dark"))
    d.rectangle([3, 12, 12, 14], fill=c("bone_dark"))
    return img


def draw_watering_can():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([4, 6, 11, 12], fill=c("turquoise_dark"))
    d.rectangle([10, 4, 14, 6], fill=c("turquoise_dark"))
    d.rectangle([2, 8, 4, 9], fill=c("turquoise_dark"))
    return img


def draw_sickle():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([7, 8, 8, 14], fill=c("ochre_dark"))
    d.arc([2, 1, 13, 12], start=0, end=270, fill=c("bone"), width=2)
    return img


def draw_khopesh():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([7, 8, 8, 14], fill=c("ochre_dark"))
    d.polygon([(8, 1), (13, 4), (11, 9), (7, 8)], fill=c("moon_silver"))
    return img


def draw_hammer():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([7, 5, 8, 14], fill=c("ochre_dark"))
    d.rectangle([3, 1, 13, 6], fill=c("bone_dark"))
    return img


def draw_anj():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([5, 1, 11, 7], fill=(0, 0, 0, 0))
    d.arc([5, 1, 11, 7], start=0, end=360, fill=c("gold"), width=2)
    d.rectangle([7, 6, 8, 14], fill=c("gold"))
    d.rectangle([4, 8, 11, 9], fill=c("gold"))
    return img


def draw_scarab():
    img = icon_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([3, 4, 12, 12], fill=c("turquoise"))
    d.ellipse([4, 5, 11, 11], fill=c("turquoise_dark"))
    d.rectangle([7, 2, 8, 5], fill=c("turquoise"))
    return img


ICONS = {
    "deben": draw_deben, "heart": draw_heart, "feather": draw_feather,
    "hoe": draw_hoe, "watering_can": draw_watering_can, "sickle": draw_sickle,
    "khopesh": draw_khopesh, "hammer": draw_hammer,
    "anj": draw_anj, "scarab": draw_scarab,
}


def build_icons():
    for name, fn in ICONS.items():
        img = fn()
        path = os.path.join(OUT_ICONS, f"{name}.png")
        img.save(path)
        print("wrote", path, img.size)


if __name__ == "__main__":
    build_crops()
    build_icons()
