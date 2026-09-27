"""Retratos de dialogo con expresiones (fase 4: "retratos con varias
emociones"). Cada personaje se dibuja a 50x50 (el tamano exacto del marco
del cuadro de dialogo, asi cada pixel se ve nitido) con rasgos egipcios:
ojos delineados con kohl, cejas marcadas, pelucas y tocados.

Expresiones: normal, feliz, triste, sorpresa, enojo (Thot: normal, habla,
sarcasmo, sorpresa). Salen como assets/sprites/portraits/<id>.png (normal)
y <id>_<expresion>.png. En los dialogos: "Meret (triste): texto".
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from postfx import add_outline

OUT = os.environ.get("PORTRAIT_OUT") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "portraits")
S = 50
EXPRS = ["normal", "feliz", "triste", "sorpresa", "enojo"]


class Canvas:
    def __init__(self):
        self.img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        self.px = self.img.load()

    def p(self, x, y, col):
        if 0 <= x < S and 0 <= y < S:
            self.px[x, y] = c(col) if isinstance(col, str) else col

    def rect(self, x0, y0, x1, y1, col):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.p(x, y, col)

    def ellipse(self, cx, cy, rx, ry, col, only=None):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    if only is None or only(x, y):
                        self.p(x, y, col)

    def hline(self, x0, x1, y, col):
        for x in range(x0, x1 + 1):
            self.p(x, y, col)

    def get(self, x, y):
        return self.px[x, y]


# ------------------------------------------------------------ rasgos
def face(cv, cx, top, rx, ry, skin="skin", shade="skin_dark", light="skin_light"):
    cy = top + ry
    cv.ellipse(cx, cy, rx, ry, skin)
    # sombra del lado derecho (luz desde la izquierda) y mejilla iluminada
    cv.ellipse(cx, cy, rx, ry, shade, only=lambda x, y: x >= cx + rx * 0.55)
    cv.ellipse(cx - rx * 0.5, cy + 2, 1.6, 1.0, light)
    # menton mas marcado
    cv.hline(cx - 3, cx + 2, int(cy + ry) - 1, shade)
    return cy


def eyes(cv, cx, y, expr, spread=5, big=False):
    for side in (-1, 1):
        ex = cx + side * spread
        if expr == "feliz":
            # ojos cerrados de alegria (arco hacia arriba) con kohl
            cv.hline(ex - 1, ex + 1, y, "outline")
            cv.p(ex - 2, y + 1, "outline")
            cv.p(ex + 2, y + 1, "outline")
            cv.p(ex + side * 3, y + 1, "outline")
            continue
        top = y - (1 if expr == "sorpresa" else 0)
        lid = 1 if expr == "enojo" else 0
        # parpado superior con kohl que se alarga hacia la sien
        cv.hline(ex - 2, ex + 2, top + lid, "outline")
        cv.p(ex + side * 3, top + lid + (0 if expr == "triste" else 0), "outline")
        cv.p(ex + side * 4, top + lid + (1 if expr != "sorpresa" else 0), "outline")
        rows = 2 if (big or expr == "sorpresa") else 1
        for r in range(rows):
            yy = top + 1 + lid + r
            cv.p(ex - 2, yy, "bone")
            cv.p(ex + 2, yy, "bone")
            cv.p(ex - 1, yy, "bone")
            cv.p(ex + 1, yy, "bone")
            cv.p(ex, yy, "hair")
        if expr != "sorpresa":
            cv.p(ex - side, top + 1 + lid, "hair")  # pupila de 2px mirando al centro
        if expr == "triste":
            cv.p(ex, top + 2 + lid, "hair")
        # linea de kohl inferior
        cv.hline(ex - 1, ex + 1, top + 2 + lid + (rows - 1), "skin_dark")


def brows(cv, cx, y, expr, spread=5, col="hair", thick=1):
    for side in (-1, 1):
        ex = cx + side * spread
        inner, outer = 0, 0
        if expr == "triste":
            inner, outer = -1, 1
        elif expr == "enojo":
            inner, outer = 1, -1
        elif expr == "sorpresa":
            inner, outer = -2, -2
        elif expr == "feliz":
            inner, outer = -1, -1
        for i, x in enumerate(range(ex - 2, ex + 3)):
            # interior = hacia el centro de la cara
            t = (x - ex) * side  # -2 (interior) .. 2 (exterior)
            dy = inner if t < 0 else (outer if t > 0 else (inner + outer) // 2)
            for k in range(thick):
                cv.p(x, y + dy + k, col)


def mouth(cv, cx, y, expr, lip="red_dark"):
    if expr == "feliz":
        cv.p(cx - 3, y - 1, lip)
        cv.p(cx + 3, y - 1, lip)
        cv.hline(cx - 2, cx + 2, y, lip)
        cv.hline(cx - 1, cx + 1, y + 1, "bone")
    elif expr == "triste":
        cv.hline(cx - 1, cx + 1, y, lip)
        cv.p(cx - 2, y + 1, lip)
        cv.p(cx + 2, y + 1, lip)
    elif expr == "sorpresa":
        cv.rect(cx - 1, y - 1, cx + 1, y + 1, lip)
        cv.p(cx, y, "outline")
    elif expr == "enojo":
        cv.hline(cx - 2, cx + 2, y, lip)
        cv.p(cx - 3, y + 1, lip)
        cv.p(cx + 3, y + 1, lip)
    else:
        cv.hline(cx - 2, cx + 1, y, lip)
        cv.p(cx + 2, y - 1, "skin_dark")


def nose(cv, cx, y):
    cv.p(cx + 1, y, "skin_dark")
    cv.p(cx + 1, y + 1, "skin_dark")
    cv.p(cx, y + 2, "skin_dark")


def shoulders(cv, cx, y, col="linen", shade="linen_dark", w=19):
    cv.ellipse(cx, y + 10, w, 11, col, only=lambda x, yy: yy >= y)
    cv.ellipse(cx, y + 10, w, 11, shade, only=lambda x, yy: yy >= y and x >= cx + w * 0.55)


def neck(cv, cx, y0, y1, w=4):
    cv.rect(cx - w, y0, cx + w, y1, "skin")
    cv.rect(cx + w - 1, y0, cx + w, y1, "skin_dark")


def collar(cv, cx, y, bands, w=15):
    # usekh: collar ancho de bandas concentricas
    for i, col in enumerate(bands):
        cv.ellipse(cx, y - 2, w - i * 0.0 + 1, 5 + i * 2, col, only=lambda x, yy, i=i, y=y: yy >= y - 1 + i * 2 and yy <= y + i * 2)


def finish(cv, name):
    img = add_outline(cv.img)
    img.save(os.path.join(OUT, name))
    return img


# ------------------------------------------------------------ personajes
def meret(expr):
    cv = Canvas()
    cx, top = 24, 9
    # peluca negra lisa hasta los hombros, con reflejos azulados
    cv.rect(cx - 13, top + 2, cx + 13, top + 33, "hair")
    cv.ellipse(cx, top + 6, 13, 8, "hair")
    for x in (cx - 11, cx - 8, cx + 8, cx + 11):
        for y in range(top + 8, top + 32, 2):
            cv.p(x, y, "lapis_dark")
    shoulders(cv, cx, 38, "linen", "linen_dark")
    neck(cv, cx, top + 24, 40)
    cy = face(cv, cx, top + 3, 9, 12)
    # flequillo recto
    cv.rect(cx - 9, top + 3, cx + 9, top + 6, "hair")
    # banda dorada y pluma de Maat
    cv.hline(cx - 10, cx + 10, top + 6, "gold")
    cv.hline(cx - 10, cx + 10, top + 7, "gold_dark")
    cv.p(cx, top + 6, "turquoise")
    for y in range(top - 8, top + 6):
        w = 1 if y < top - 5 else 2
        for x in range(cx + 7, cx + 7 + w + 1):
            cv.p(x, y, "bone")
        cv.p(cx + 8, y, "bone_dark")
    eyes(cv, cx, top + 11, expr, spread=4)
    brows(cv, cx, top + 9, expr, spread=4)
    nose(cv, cx, top + 14)
    mouth(cv, cx, top + 19, expr, lip="red_accent")
    # collar usekh
    for i, col in enumerate(["gold", "turquoise", "lapis", "gold"]):
        cv.ellipse(cx, 38, 13 - i * 0.5, 3 + i * 2, col, only=lambda x, y, i=i: y >= 38 + i * 2 - 1 and y <= 38 + i * 2)
    return cv


def ptahmose(expr):
    cv = Canvas()
    cx, top = 24, 9
    shoulders(cv, cx, 37, "linen", "linen_dark", w=21)
    # tunica a rayas rojas
    for y in range(38, 50, 3):
        cv.ellipse(cx, 47, 21, 11, "red_accent", only=lambda x, yy, y=y: yy == y)
    neck(cv, cx, top + 24, 39, w=5)
    # tocado khat azul (bolsa de tela) por detras
    cv.ellipse(cx, top + 10, 13, 12, "lapis")
    cv.rect(cx - 13, top + 10, cx + 13, top + 26, "lapis")
    cv.rect(cx + 8, top + 10, cx + 13, top + 26, "lapis_dark")
    cy = face(cv, cx, top + 4, 10, 12)
    # cachetes redondos
    cv.ellipse(cx - 6, top + 18, 2, 1.5, "skin_light")
    cv.ellipse(cx + 6, top + 18, 2, 1.5, "skin")
    # borde del tocado sobre la frente
    cv.rect(cx - 11, top + 3, cx + 11, top + 6, "lapis")
    cv.hline(cx - 11, cx + 11, top + 7, "bone")
    cv.hline(cx - 11, cx + 11, top + 8, "lapis_dark")
    # arete de oro
    cv.p(cx + 11, top + 17, "gold")
    cv.p(cx + 11, top + 18, "gold_dark")
    eyes(cv, cx, top + 12, expr, spread=4)
    brows(cv, cx, top + 10, expr, spread=4, thick=2)
    nose(cv, cx, top + 15)
    cv.p(cx - 1, top + 17, "skin_dark")
    mouth(cv, cx, top + 20, expr)
    return cv


def iry(expr):
    cv = Canvas()
    cx, top = 24, 13
    shoulders(cv, cx, 40, "skin", "skin_dark", w=15)
    neck(cv, cx, top + 20, 41, w=3)
    cy = face(cv, cx, top, 9, 11)
    # cabeza rapada (sombra de pelo) y mechon de la juventud a un lado
    cv.ellipse(cx, top + 4, 9, 5, "skin_dark", only=lambda x, y: y <= top + 4)
    for y in range(top + 3, top + 20):
        cv.p(cx - 10, y, "hair")
        cv.p(cx - 11, y + 1, "hair")
    cv.p(cx - 10, top + 21, "gold")
    cv.p(cx - 11, top + 21, "gold")
    eyes(cv, cx, top + 9, expr, spread=4, big=True)
    brows(cv, cx, top + 6, expr, spread=4)
    nose(cv, cx, top + 13)
    mouth(cv, cx, top + 17, expr)
    # amuleto al cuello
    cv.hline(cx - 5, cx + 5, 42, "linen_dark")
    cv.rect(cx - 1, 43, cx + 1, 45, "turquoise")
    return cv


def nakht(expr):
    cv = Canvas()
    cx, top = 24, 10
    shoulders(cv, cx, 38, "skin", "skin_dark", w=20)
    neck(cv, cx, top + 24, 40, w=5)
    cy = face(cv, cx, top + 2, 10, 13)
    # pelo corto negro y cinta de lino
    cv.ellipse(cx, top + 5, 11, 6, "hair", only=lambda x, y: y <= top + 6)
    cv.rect(cx - 11, top + 4, cx - 9, top + 12, "hair")
    cv.rect(cx + 9, top + 4, cx + 11, top + 12, "hair")
    cv.hline(cx - 11, cx + 11, top + 7, "linen")
    cv.hline(cx - 11, cx + 11, top + 8, "linen_dark")
    eyes(cv, cx, top + 12, expr, spread=4)
    brows(cv, cx, top + 10, expr, spread=4)
    nose(cv, cx, top + 15)
    mouth(cv, cx, top + 20, expr)
    # cicatriz tenue: volvio de la muerte
    cv.p(cx - 7, top + 14, "skin_dark")
    cv.p(cx - 6, top + 15, "skin_dark")
    return cv


def thot(expr):
    """Ibis de perfil mirando a la derecha: cabeza y cuello negros, pico
    largo y curvo, disco lunar plateado y su paleta de escriba."""
    from PIL import ImageDraw
    cv = Canvas()
    d = ImageDraw.Draw(cv.img)
    # cuerpo blanco con puntas de ala negras
    cv.ellipse(18, 47, 15, 9, "bone")
    cv.ellipse(18, 47, 15, 9, "bone_dark", only=lambda x, y: x >= 26)
    cv.ellipse(6, 45, 5, 4, "anubis_black", only=lambda x, y: x <= 6)
    # cuello curvo (de la cabeza al pecho)
    for i in range(16):
        t = i / 15.0
        x = 18 - 3 * t + 2 * t * t
        y = 24 + 15 * t
        cv.ellipse(x, y, 3.2 + t * 1.2, 1.2, "anubis_black")
    # cabeza
    cv.ellipse(20, 20, 6.5, 5.5, "anubis_black")
    cv.ellipse(18, 18, 2.5, 1.5, (58, 50, 46, 255))  # brillo
    # disco lunar con creciente dorado
    cv.ellipse(17, 7, 5.5, 5.5, "moon_silver")
    cv.ellipse(19, 7, 4.5, 4.5, "bone", only=lambda x, y: x >= 18)
    cv.ellipse(17, 12, 6, 1.6, "gold", only=lambda x, y: y >= 12)
    # pico largo y curvo, trazo continuo
    open_ = 2 if expr in ("habla", "sorpresa") else 0
    top = [(25, 19), (30, 20), (34, 22), (38, 25), (41, 29), (43, 33), (44, 37)]
    bot = [(25, 22), (30, 23 + open_), (34, 25 + open_), (37, 28 + open_ // 2), (40, 31), (42, 35), (43, 37)]
    black = c("anubis_black")
    d.line(top, fill=black, width=2)
    d.line(bot, fill=black, width=2)
    if open_:
        d.polygon(top[:4] + bot[:4][::-1], fill=(128, 50, 42, 255))
        d.line(top[:4], fill=black, width=2)
        d.line(bot[:4], fill=black, width=2)
    else:
        d.polygon(top + bot[::-1], fill=black)
    d.line([(26, 20), (31, 21)], fill=(70, 62, 58, 255), width=1)
    # ojo
    ex, ey = 21, 19
    if expr == "sarcasmo":
        cv.hline(ex - 1, ex + 1, ey, "bone_dark")
        cv.hline(ex - 2, ex + 1, ey - 2, "moon_silver")
        cv.p(ex + 2, ey - 3, "moon_silver")
    else:
        cv.rect(ex - 1, ey - 1, ex + 1, ey + 1, "bone")
        cv.p(ex, ey, "red_dark")
        if expr == "sorpresa":
            cv.rect(ex - 1, ey - 1, ex + 1, ey + 1, "bone")
            cv.p(ex, ey, "anubis_black")
            cv.p(ex - 2, ey - 3, "moon_silver")
            cv.p(ex, ey - 4, "moon_silver")
    # paleta de escriba colgada al pecho
    cv.rect(24, 40, 30, 43, "gold_dark")
    cv.rect(25, 41, 29, 42, "gold")
    cv.p(26, 41, "red_accent")
    cv.p(28, 41, "anubis_black")
    return cv


def contact_sheet(rows):
    W = len(EXPRS) * (S + 4) + 4
    sheet = Image.new("RGBA", (W, len(rows) * (S + 4) + 4), (70, 48, 34, 255))
    for r, imgs in enumerate(rows):
        for i, im in enumerate(imgs):
            sheet.alpha_composite(im, (4 + i * (S + 4), 4 + r * (S + 4)))
    return sheet


if __name__ == "__main__":
    rows = []
    for name, fn in (("meret", meret), ("ptahmose", ptahmose), ("iry", iry), ("player", nakht)):
        row = []
        for e in EXPRS:
            img = finish(fn(e), name + ".png" if e == "normal" else "%s_%s.png" % (name, e))
            row.append(img)
        rows.append(row)
    row = []
    for e in ["normal", "habla", "sarcasmo", "sorpresa"]:
        row.append(finish(thot(e), "thot.png" if e == "normal" else "thot_%s.png" % e))
    rows.append(row)
    if "--sheet" in sys.argv:
        big = contact_sheet(rows)
        big = big.resize((big.width * 3, big.height * 3), Image.NEAREST)
        big.save(sys.argv[sys.argv.index("--sheet") + 1])
    print("retratos ok")
