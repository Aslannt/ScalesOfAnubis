"""Arte de la intro y el final (GDD 7): busto de Anubis, balanza grande del
pesaje del corazon, y la vineta del primer recuerdo del ba (un nino junto
al rio que se parece a Iry), en tonos sepia."""
import math
import os
import random
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from postfx import add_outline
from pixel_draw import save

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "story")
OUT_P = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "portraits")

BLACK = (22, 18, 24, 255)
BLACK_HI = (58, 52, 70, 255)
GOLD = c("gold")
GOLD_D = c("gold_dark")
LAPIS = c("lapis")
TURQ = c("turquoise")


def anubis_bust(size=64):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # peluca con franjas (lappets) detras de la cabeza
    for i, y in enumerate(range(22, 54, 3)):
        col = LAPIS if i % 2 == 0 else GOLD
        d.rectangle([15, y, 25, y + 2], fill=col)
    # hombros
    d.polygon([(4, 63), (60, 63), (52, 50), (12, 50)], fill=BLACK)
    # collar usekh: bandas concentricas
    for r, col in ((20, GOLD), (17, LAPIS), (14, TURQ), (11, GOLD_D), (8, GOLD)):
        d.pieslice([32 - r - 6, 44 - r, 32 + r + 6, 44 + r], 0, 180, fill=col)
    # cuello
    d.rectangle([26, 34, 37, 46], fill=BLACK)
    # cabeza
    d.ellipse([20, 15, 43, 39], fill=BLACK)
    # hocico largo de chacal
    d.polygon([(37, 22), (59, 29), (60, 33), (56, 35), (39, 38)], fill=BLACK)
    d.point((60, 31), fill=BLACK_HI)
    # orejas altas
    d.polygon([(22, 19), (25, 0), (31, 16)], fill=BLACK)
    d.polygon([(30, 16), (36, 1), (39, 19)], fill=BLACK)
    d.line([(25, 4), (27, 15)], fill=GOLD_D)
    d.line([(35, 5), (35, 16)], fill=GOLD_D)
    # brillo en la frente y el hocico (volumen)
    d.line([(27, 17), (36, 17)], fill=BLACK_HI)
    d.line([(40, 24), (55, 29)], fill=BLACK_HI)
    # ojo con kohl dorado
    d.polygon([(38, 24), (43, 23), (46, 25), (41, 27)], fill=GOLD)
    d.point((42, 25), fill=(10, 8, 10, 255))
    d.line([(46, 25), (49, 26)], fill=GOLD_D)
    # boca
    d.line([(46, 34), (56, 33)], fill=(80, 30, 30, 255))
    # banda dorada en la frente
    d.line([(21, 22), (34, 20)], fill=GOLD)
    return add_outline(img, (8, 6, 10, 255))


def big_scale(tilt=0.0):
    """Balanza del juicio 128x96: pilar con pluma de Maat en la punta, viga,
    dos platos. tilt en grados (positivo = baja el lado del corazon)."""
    w, h = 128, 96
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = 64
    # base y pilar
    d.polygon([(cx - 22, 95), (cx + 22, 95), (cx + 14, 86), (cx - 14, 86)], fill=GOLD_D)
    d.rectangle([cx - 3, 20, cx + 3, 86], fill=GOLD)
    d.rectangle([cx + 1, 20, cx + 3, 86], fill=GOLD_D)
    # viga
    a = math.radians(tilt)
    L = 50
    lx, ly = cx - L * math.cos(a), 22 + L * math.sin(a)
    rx, ry = cx + L * math.cos(a), 22 - L * math.sin(a)
    d.line([(lx, ly), (rx, ry)], fill=GOLD, width=3)
    d.ellipse([cx - 5, 17, cx + 5, 27], fill=GOLD)
    # cuerdas y platos
    for (px, py) in ((lx, ly), (rx, ry)):
        d.line([(px, py), (px - 10, py + 26)], fill=GOLD_D)
        d.line([(px, py), (px + 10, py + 26)], fill=GOLD_D)
        d.chord([px - 14, py + 20, px + 14, py + 34], 0, 180, fill=GOLD)
        d.line([(px - 14, py + 27), (px + 14, py + 27)], fill=GOLD_D)
    # pluma de Maat en la punta del pilar
    d.ellipse([cx - 3, 4, cx + 3, 18], fill=c("bone"))
    d.line([(cx, 4), (cx, 19)], fill=c("linen_dark"))
    return add_outline(img, (20, 12, 8, 255)), (lx, ly + 20), (rx, ry + 20)


def ba_memory():
    """Vineta 192x108 en sepia: el Nilo, juncos, un nino con papiro."""
    w, h = 192, 108
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    sep = [(52, 36, 24), (96, 70, 44), (150, 116, 76), (206, 170, 120), (238, 214, 170)]
    for y in range(h):
        t = y / h
        k = 4 if t < 0.25 else (3 if t < 0.5 else 2)
        d.line([(0, y), (w, y)], fill=sep[k] + (255,))
    # sol bajo
    d.ellipse([130, 18, 158, 46], fill=sep[4] + (255,))
    # orilla lejana y rio
    d.rectangle([0, 52, w, 60], fill=sep[2] + (255,))
    d.rectangle([0, 60, w, 80], fill=sep[3] + (255,))
    rng = random.Random(4)
    for k in range(30):
        x = rng.randint(0, w - 8)
        y = rng.randint(62, 78)
        d.line([(x, y), (x + rng.randint(3, 9), y)], fill=sep[4] + (255,))
    # orilla cercana
    d.rectangle([0, 80, w, h], fill=sep[1] + (255,))
    # juncos
    for k in range(26):
        x = rng.randint(0, w)
        hh = rng.randint(10, 26)
        d.line([(x, 82), (x + rng.randint(-2, 2), 82 - hh)], fill=sep[0] + (255,))
    # palmera
    d.line([(24, 82), (30, 30)], fill=sep[0] + (255,), width=2)
    for a in range(7):
        ang = a / 7 * math.tau
        for j in range(16):
            x = 30 + math.cos(ang) * j
            y = 30 + math.sin(ang) * j * 0.4 + j * j * 0.05
            d.point((int(x), int(y)), fill=sep[0] + (255,))
    # nino (como Iry: pelo corto, tunica), dibujado en chico y ampliado x2
    kid = Image.new("RGBA", (20, 36), (0, 0, 0, 0))
    k = ImageDraw.Draw(kid)
    S = lambda i: sep[i] + (255,)
    k.rectangle([5, 14, 11, 26], fill=S(3))          # tunica
    k.line([(5, 17), (11, 17)], fill=S(2))           # cinturon
    k.rectangle([6, 27, 7, 32], fill=S(1))           # piernas
    k.rectangle([9, 27, 10, 32], fill=S(1))
    k.ellipse([4, 5, 12, 14], fill=S(2))             # cara
    k.rectangle([4, 4, 12, 7], fill=S(0))            # pelo corto
    k.point((10, 9), fill=S(0))                      # ojo (mira hacia ti)
    k.line([(9, 12), (11, 12)], fill=S(1))           # sonrisa
    k.line([(12, 18), (14, 19)], fill=S(2))          # brazo
    k.line([(14, 19), (18, 2)], fill=S(0))           # tallo de papiro
    for j in range(-3, 4):
        k.line([(18, 2), (18 + j, 0)], fill=S(0))
    kid = add_outline(kid, sep[0] + (255,))
    kid = kid.resize((40, 72), Image.NEAREST)
    img.alpha_composite(kid, (86, 30))
    # vineta: bordes oscuros
    px = img.load()
    for y in range(h):
        for x in range(w):
            dx = (x - w / 2) / (w / 2)
            dy = (y - h / 2) / (h / 2)
            v = dx * dx + dy * dy
            if v > 0.55:
                k = min(1.0, (v - 0.55) * 1.6)
                r, g, b, a = px[x, y]
                px[x, y] = (int(r * (1 - k)), int(g * (1 - k)), int(b * (1 - k)), 255)
    return img


if __name__ == "__main__":
    bust = anubis_bust()
    save(bust, os.path.join(OUT, "anubis_bust.png"))
    save(bust.resize((100, 100), Image.NEAREST), os.path.join(OUT_P, "anubis.png"))
    icons = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "icons")
    heart = Image.open(os.path.join(icons, "heart.png")).convert("RGBA")
    feather = Image.open(os.path.join(icons, "feather.png")).convert("RGBA")
    for i, tilt in enumerate((-8, 0, 8)):
        img, lp, rp = big_scale(tilt)
        img.alpha_composite(heart, (int(lp[0]) - 8, int(lp[1]) - 12))
        img.alpha_composite(feather, (int(rp[0]) - 8, int(rp[1]) - 15))
        save(img, os.path.join(OUT, f"scale_{i}.png"))
    save(ba_memory(), os.path.join(OUT, "ba_memory.png"))
