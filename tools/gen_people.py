"""Pase de arte de personajes (M9): sprites 24x32 con 4 direcciones y
animaciones idle(2) / caminar(4) / atacar(3), mismo formato de layout que
antes (south/north/east; west = east espejado en el juego).

Cada personaje se describe con un 'spec' (piel, peinado, ropa, accesorios)
y un dibujante comun arma el cuerpo pixel por pixel. Fidelidad egipcia:
- Nakht: campesino, torso descubierto, shendyt (faldellin de lino) y
  cinturon; al atacar empuna un khopesh de bronce.
- Meret: sacerdotisa de Maat: peluca negra con cinta dorada y una pluma de
  avestruz (simbolo de Maat), vestido de lino, collar usekh.
- Ptahmose: comerciante: panza, tunica a rayas, pañuelo en la cabeza,
  bolsa al hombro.
- Iry: nino con la cabeza rapada y el 'mechon de la juventud' al costado,
  como se peinaba a los ninos en el antiguo Egipto.
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from pixel_draw import save, save_layout

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "characters")
W, H = 24, 32
OUTLINE = (40, 26, 22, 255)


def rgb(v):
    return v if isinstance(v, tuple) else c(v)


def shade(col, k):
    col = rgb(col)
    return tuple(max(0, min(255, int(ch * k))) for ch in col[:3]) + (255,)


class Canvas:
    def __init__(self):
        self.img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        self.px = self.img.load()

    def p(self, x, y, col):
        if 0 <= x < W and 0 <= y < H and col is not None:
            self.px[x, y] = rgb(col)

    def r(self, x0, y0, x1, y1, col):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self.p(x, y, col)

    def hline(self, x0, x1, y, col):
        self.r(x0, y, x1, y, col)

    def outline(self):
        src = self.img.copy().load()
        for y in range(H):
            for x in range(W):
                if src[x, y][3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and src[nx, ny][3] != 0:
                        self.px[x, y] = OUTLINE
                        break
        return self.img


# ------------------------------------------------------------ specs
SPECS = {
    "player": {
        "skin": (190, 128, 78, 255), "hair": (34, 24, 20, 255), "hair_style": "short",
        "top": None, "kilt": "linen", "belt": (150, 60, 40, 255), "collar": None,
        "weapon": True,
    },
    "meret": {
        "skin": (150, 96, 58, 255), "hair": (22, 18, 26, 255), "hair_style": "wig",
        "band": "gold", "feather": True, "top": "linen", "dress": True, "kilt": "linen",
        "belt": (178, 58, 46, 255), "collar": ["turquoise", "gold", "lapis"],
    },
    "ptahmose": {
        "skin": (176, 116, 70, 255), "hair": (40, 30, 24, 255), "hair_style": "wrap",
        "wrap": (46, 80, 140, 255), "top": "stripes", "stripes": [(178, 58, 46, 255), (230, 214, 175, 255)],
        "kilt": "stripes", "belt": (201, 127, 42, 255), "collar": ["gold"], "belly": True, "bag": True,
    },
    "iry": {
        "skin": (204, 146, 94, 255), "hair": (34, 24, 20, 255), "hair_style": "sidelock",
        "top": None, "kilt": "linen", "belt": None, "collar": None, "child": True,
    },
}


def cloth(name, y=0, x=0, spec=None):
    if name == "linen":
        return rgb("linen")
    if name == "stripes":
        s = spec["stripes"]
        return s[(y // 2) % len(s)]
    return rgb(name)


# arma que se dibuja en los cuadros de ataque: khopesh (attack), martillo
# (hammer) o cayado/baston de Heka (staff). Fase 5: antes las tres armas
# mostraban el khopesh.
WEAPON = "khopesh"
WEAPON_OF = {"attack": "khopesh", "hammer": "martillo", "staff": "baston"}


def _hammer(cv, handle, head):
    """Mango (lista de puntos) y cabeza de piedra (x0, y0, x1, y1)."""
    for (x, y) in handle:
        cv.p(x, y, "ochre_dark")
    x0, y0, x1, y1 = head
    cv.r(x0, y0, x1, y1, "bone_dark")
    cv.hline(x0, x1, y0, "bone")
    cv.r(x1, y0, x1, y1, (130, 118, 96, 255))
    cv.hline(x0, x1, y1, (120, 108, 88, 255))


def _staff(cv, pts, glow=False):
    """Cayado: puntos del mango (el ultimo es la punta de turquesa)."""
    for (x, y) in pts[:-1]:
        cv.p(x, y, "ochre")
    tx, ty = pts[-1]
    cv.p(tx, ty, "turquoise")
    if glow:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cv.p(tx + dx, ty + dy, "fire_yellow")
        cv.p(tx, ty, "bone")


def _line(a, b):
    """Puntos de una linea de pixeles de a a b."""
    (x0, y0), (x1, y1) = a, b
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    return [(round(x0 + (x1 - x0) * k / n), round(y0 + (y1 - y0) * k / n)) for k in range(n + 1)]


# ------------------------------------------------------------- dibujo
def draw(spec, facing, anim, i):
    global WEAPON
    WEAPON = WEAPON_OF.get(anim, "khopesh")
    if anim in ("hammer", "staff"):
        anim = "attack"
    cv = Canvas()
    child = spec.get("child", False)
    skin = spec["skin"]
    skin_d = shade(skin, 0.76)
    skin_l = shade(skin, 1.12)
    hair = spec["hair"]
    # --- parametros de animacion ---
    bob = 0
    legs = (0, 0)  # (izq, der) desplazamiento vertical del pie (-1 = levantado)
    stride = 0     # vista lateral: -1/0/1
    arm_swing = 0
    atk = -1
    if anim == "idle":
        bob = i % 2
    elif anim == "walk":
        stride = [2, 0, -2, 0][i % 4]
        bob = [0, 1, 0, 1][i % 4]
        legs = [(-1, 0), (0, 0), (0, -1), (0, 0)][i % 4]
        arm_swing = stride // 2 if stride else 0
    elif anim == "attack":
        atk = i
    top = 2 + bob + (5 if child else 0)  # fila superior de la cabeza
    body = top + 10                        # hombros
    kilt_y = body + (5 if child else 7)
    leg_y = kilt_y + (4 if child else 6)
    foot_y = 30

    if facing in ("south", "north"):
        _front(cv, spec, facing, top, body, kilt_y, leg_y, foot_y, legs, arm_swing, atk, skin, skin_d, skin_l, hair, child)
    else:
        _side(cv, spec, top, body, kilt_y, leg_y, foot_y, stride, arm_swing, atk, skin, skin_d, skin_l, hair, child)
    return cv.outline()


def _legs_front(cv, leg_y, foot_y, legs, skin, skin_d, child):
    for k, lx in enumerate((8, 13)):
        dy = legs[k]
        cv.r(lx, leg_y, lx + 2, foot_y - 1 + dy, skin)
        cv.r(lx + 2, leg_y, lx + 2, foot_y - 1 + dy, skin_d)
        # sandalia
        cv.r(lx - (1 if k == 0 else 0), foot_y + dy, lx + 2 + (1 if k == 1 else 0), foot_y + dy, "ochre_dark")


def _head_front(cv, spec, facing, top, skin, skin_d, skin_l, hair):
    t = top
    rows = [(9, 14), (8, 15), (7, 16), (7, 16), (7, 16), (7, 16), (7, 16), (8, 15), (9, 14)]
    for k, (a, b) in enumerate(rows):
        cv.hline(a, b, t + k, skin)
    # sombreado del lado derecho y luz del izquierdo
    for k in range(2, 8):
        cv.p(16 if k < 7 else 15, t + k, skin_d)
        cv.p(8, t + k, skin_l) if k in (3, 4) else None
    style = spec["hair_style"]
    if facing == "south":
        # ojos con kohl, nariz, boca
        cv.p(9, t + 5, OUTLINE); cv.p(10, t + 5, (24, 18, 18, 255))
        cv.p(13, t + 5, (24, 18, 18, 255)); cv.p(14, t + 5, OUTLINE)
        cv.p(10, t + 4, shade(hair, 1.2)); cv.p(13, t + 4, shade(hair, 1.2))
        cv.p(12, t + 6, skin_d)
        cv.hline(11, 12, t + 7, shade(skin, 0.6))
    else:
        # de espaldas: toda la cabeza es pelo salvo que sea rapada
        if style in ("sidelock",):
            for k, (a, b) in enumerate(rows):
                cv.hline(a, b, t + k, shade(skin, 0.9))
            cv.p(9, t + 1, skin_l)
    _hair_front(cv, spec, facing, t, hair)


def _hair_front(cv, spec, facing, t, hair):
    style = spec["hair_style"]
    hl = shade(hair, 1.6)
    back = facing == "north"
    if style == "short":
        cv.hline(9, 14, t - 1, hair)
        cv.hline(8, 15, t, hair)
        cv.hline(7, 16, t + 1, hair)
        cv.p(7, t + 2, hair); cv.p(16, t + 2, hair)
        cv.p(7, t + 3, hair); cv.p(16, t + 3, hair)
        cv.hline(10, 12, t, hl)
        if back:
            cv.r(7, t + 2, 16, t + 6, hair)
            cv.hline(8, 15, t + 7, hair)
    elif style == "wig":
        cv.hline(9, 14, t - 1, hair)
        cv.hline(7, 16, t, hair)
        cv.r(6, t + 1, 17, t + 2, hair)
        cv.r(6, t + 3, 7, t + 10, hair)
        cv.r(16, t + 3, 17, t + 10, hair)
        cv.hline(10, 13, t, hl)
        band = spec.get("band")
        if band:
            cv.hline(6, 17, t + 2, band)
        if back:
            cv.r(6, t + 1, 17, t + 10, hair)
            if band:
                cv.hline(6, 17, t + 2, band)
        if spec.get("feather"):
            # pluma de Maat en la cinta, del lado izquierdo
            for k in range(6):
                cv.p(15 + (1 if k < 2 else 0), t - 5 + k, "bone")
            cv.p(15, t - 1, "bone_dark")
            cv.p(16, t - 6, "bone")
    elif style == "wrap":
        wrap = spec["wrap"]
        cv.hline(9, 14, t - 1, wrap)
        cv.hline(7, 16, t, wrap)
        cv.r(7, t + 1, 16, t + 2, wrap)
        cv.hline(7, 16, t + 2, shade(wrap, 0.7))
        cv.r(16, t + 3, 17, t + 7, wrap)  # faldon del panuelo
        cv.hline(10, 13, t, shade(wrap, 1.3))
        if back:
            cv.r(7, t + 1, 16, t + 8, wrap)
    elif style == "sidelock":
        # cabeza rapada (tono piel apenas mas oscuro) + mechon lateral trenzado
        side = 16 if not back else 7
        for k in range(8):
            cv.p(side + (1 if not back else -1) * 0, t + 1 + k, hair)
            cv.p(side + (1 if not back else -1), t + 2 + k, hair if k % 2 == 0 else shade(hair, 1.5))
        cv.hline(10, 13, t, shade(hair, 0.0) if False else None)


def _front(cv, spec, facing, top, body, kilt_y, leg_y, foot_y, legs, arm_swing, atk, skin, skin_d, skin_l, hair, child):
    back = facing == "north"
    _legs_front(cv, leg_y, foot_y, legs, skin, skin_d, child)
    # --- faldellin / vestido ---
    dress = spec.get("dress", False)
    kilt_bottom = leg_y + (5 if dress else 0)
    for y in range(kilt_y, kilt_bottom + 1):
        flare = 1 if y >= kilt_bottom - 1 else 0
        col = cloth(spec["kilt"], y, spec=spec)
        cv.hline(7 - flare, 16 + flare, y, col)
        cv.p(16 + flare, y, shade(col, 0.8))
    if not back and not dress:
        cv.r(12, kilt_y + 1, 12, kilt_bottom, shade(cloth(spec["kilt"], kilt_y, spec=spec), 0.82))  # pliegue
    # --- torso ---
    belly = spec.get("belly", False)
    for y in range(body, kilt_y):
        w = 1 if (belly and y >= body + 3) else 0
        if spec.get("top"):
            col = cloth(spec["top"], y, spec=spec)
        else:
            col = skin
        cv.hline(7 - w, 16 + w, y, col)
        cv.p(16 + w, y, shade(col, 0.8))
    cv.hline(6, 17, body, spec.get("top") and cloth(spec["top"], body, spec=spec) or skin)  # hombros
    if not spec.get("top") and not back:
        # pecho y abdomen marcados con sombra suave
        cv.hline(9, 10, body + 3, skin_d); cv.hline(13, 14, body + 3, skin_d)
        cv.p(11, body + 5, skin_d); cv.p(12, body + 5, skin_d)
    # cinturon
    if spec.get("belt"):
        cv.hline(7, 16, kilt_y, spec["belt"])
        if not back:
            cv.p(12, kilt_y, "gold")
    # collar usekh
    if spec.get("collar") and not back:
        for k, col in enumerate(spec["collar"]):
            cv.hline(8 + k // 2, 15 - k // 2, body + k, col)
    # bolsa (Ptahmose)
    if spec.get("bag"):
        cv.r(3 if not back else 17, kilt_y - 2, 6 if not back else 20, kilt_y + 2, "ochre_dark")
        cv.hline(3 if not back else 17, 6 if not back else 20, kilt_y - 2, "ochre")
        for k in range(0, 7):
            cv.p(7 + k if not back else 16 - k, body + k - 1, "soil")
    # --- brazos ---
    arm_top = body + 1
    arm_len = 6 if child else 8
    la = -arm_swing
    ra = arm_swing
    cv.r(5, arm_top + max(0, la), 6, arm_top + arm_len + la, skin)
    cv.p(5, arm_top + arm_len + la + 1, skin_l)
    if atk < 0:
        cv.r(17, arm_top + max(0, ra), 18, arm_top + arm_len + ra, skin_d)
        cv.p(18, arm_top + arm_len + ra + 1, skin)
    else:
        _attack_arm_front(cv, atk, arm_top, skin, skin_d, back)
    # --- cabeza ---
    _head_front(cv, spec, facing, top, skin, skin_d, skin_l, hair)


def _khopesh(cv, pts):
    """Hoja de khopesh: lista de puntos (hoja), mango al inicio."""
    for k, (x, y) in enumerate(pts):
        if k < 2:
            cv.p(x, y, "ochre_dark")  # mango
        else:
            cv.p(x, y, "gold" if k % 3 else "sand_light")


def _attack_arm_front(cv, atk, arm_top, skin, skin_d, back):
    if WEAPON == "martillo":
        if atk == 0:   # martillo en alto, sobre la cabeza
            cv.r(17, arm_top - 4, 18, arm_top + 1, skin_d)
            _hammer(cv, _line((18, arm_top - 5), (18, arm_top - 9)), (15, arm_top - 13, 21, arm_top - 10))
        elif atk == 1:  # bajando
            cv.r(17, arm_top + 1, 20, arm_top + 2, skin_d)
            _hammer(cv, _line((20, arm_top + 1), (21, arm_top - 3)), (19, arm_top - 7, 23, arm_top - 4))
        else:           # golpe contra el suelo
            cv.r(16, arm_top + 4, 17, arm_top + 8, skin_d)
            _hammer(cv, _line((16, arm_top + 9), (15, arm_top + 12)), (11, arm_top + 13, 17, arm_top + 16))
        return
    if WEAPON == "baston":
        if atk == 0:   # cayado atras, cargando
            cv.r(17, arm_top, 18, arm_top + 4, skin_d)
            _staff(cv, _line((17, arm_top + 9), (21, arm_top - 9)))
        elif atk == 1:  # estocada: la punta brilla
            cv.r(17, arm_top + 2, 20, arm_top + 3, skin_d)
            _staff(cv, _line((14, arm_top + 4), (23, arm_top + 1)), glow=True)
        else:
            cv.r(17, arm_top + 2, 18, arm_top + 6, skin_d)
            _staff(cv, _line((19, arm_top + 12), (19, arm_top - 8)))
        return
    if atk == 0:   # brazo arriba, hoja hacia atras
        cv.r(17, arm_top - 4, 18, arm_top + 1, skin_d)
        _khopesh(cv, [(18, arm_top - 5), (18, arm_top - 6), (19, arm_top - 7), (20, arm_top - 8), (21, arm_top - 9), (21, arm_top - 10), (20, arm_top - 11)])
    elif atk == 1:  # brazo extendido, hoja horizontal
        cv.r(17, arm_top + 2, 20, arm_top + 3, skin_d)
        _khopesh(cv, [(21, arm_top + 2), (22, arm_top + 2), (23, arm_top + 1), (23, arm_top), (23, arm_top - 1), (22, arm_top - 2)])
    else:           # seguimiento hacia abajo
        cv.r(16, arm_top + 5, 17, arm_top + 9, skin_d)
        _khopesh(cv, [(16, arm_top + 10), (15, arm_top + 11), (14, arm_top + 12), (13, arm_top + 13), (12, arm_top + 13), (11, arm_top + 12)])


def _side(cv, spec, top, body, kilt_y, leg_y, foot_y, stride, arm_swing, atk, skin, skin_d, skin_l, hair, child):
    # piernas: la de atras mas oscura
    back_leg = 10 - stride
    front_leg = 11 + stride
    cv.r(back_leg, leg_y, back_leg + 2, foot_y - 1, skin_d)
    cv.hline(back_leg, back_leg + 3, foot_y, "ochre_dark")
    cv.r(front_leg, leg_y, front_leg + 2, foot_y - 1, skin)
    cv.hline(front_leg, front_leg + 3, foot_y, "ochre_dark")
    # faldellin / vestido
    dress = spec.get("dress", False)
    kilt_bottom = leg_y + (5 if dress else 0)
    for y in range(kilt_y, kilt_bottom + 1):
        col = cloth(spec["kilt"], y, spec=spec)
        ext = 1 if y >= kilt_y + 2 else 0
        cv.hline(8, 15 + ext, y, col)
        cv.p(8, y, shade(col, 0.8))
    # torso
    belly = spec.get("belly", False)
    for y in range(body, kilt_y):
        col = cloth(spec["top"], y, spec=spec) if spec.get("top") else skin
        w = 1 if (belly and y >= body + 3) else 0
        cv.hline(9, 14 + w, y, col)
        cv.p(9, y, shade(col, 0.8))
    if spec.get("belt"):
        cv.hline(8, 15, kilt_y, spec["belt"])
    if spec.get("collar"):
        for k, col in enumerate(spec["collar"]):
            cv.hline(10, 14, body + k, col)
    if spec.get("bag"):
        cv.r(6, kilt_y - 2, 9, kilt_y + 2, "ochre_dark")
        cv.hline(6, 9, kilt_y - 2, "ochre")
    # cabeza de perfil
    t = top
    rows = [(10, 14), (9, 15), (9, 15), (9, 16), (9, 16), (9, 17), (9, 16), (10, 15), (11, 14)]
    for k, (a, b) in enumerate(rows):
        cv.hline(a, b, t + k, skin)
    cv.p(17, t + 5, skin_d)                       # nariz
    cv.p(15, t + 4, OUTLINE); cv.p(16, t + 4, (24, 18, 18, 255))  # ojo con kohl
    cv.p(15, t + 7, shade(skin, 0.6))             # boca
    cv.p(11, t + 4, skin_d)                       # oreja
    style = spec["hair_style"]
    if style == "short":
        cv.hline(10, 14, t - 1, hair)
        cv.hline(9, 15, t, hair)
        cv.r(9, t + 1, 12, t + 3, hair)
        cv.r(9, t + 4, 10, t + 6, hair)
        cv.hline(11, 14, t, shade(hair, 1.6))
    elif style == "wig":
        cv.hline(10, 14, t - 1, hair)
        cv.hline(8, 15, t, hair)
        cv.r(7, t + 1, 13, t + 2, hair)
        cv.r(7, t + 3, 11, t + 10, hair)
        if spec.get("band"):
            cv.hline(7, 15, t + 2, spec["band"])
        if spec.get("feather"):
            for k in range(6):
                cv.p(9 - (1 if k < 2 else 0), t - 5 + k, "bone")
    elif style == "wrap":
        wrap = spec["wrap"]
        cv.hline(10, 14, t - 1, wrap)
        cv.hline(8, 15, t, wrap)
        cv.r(8, t + 1, 13, t + 2, wrap)
        cv.r(7, t + 3, 10, t + 8, wrap)
    elif style == "sidelock":
        cv.hline(10, 14, t, shade(skin, 0.9))
        for k in range(8):
            cv.p(10, t + 2 + k, hair if k % 2 == 0 else shade(hair, 1.5))
            cv.p(9, t + 3 + k, hair)
    # brazo (el cercano)
    arm_top = body + 1
    arm_len = 6 if child else 8
    if atk < 0:
        dx = arm_swing
        for k in range(arm_len):
            cv.r(12 + (dx if k > arm_len // 2 else 0), arm_top + k, 13 + (dx if k > arm_len // 2 else 0), arm_top + k, skin)
        cv.p(12 + dx, arm_top + arm_len, skin_l)
        cv.p(13 + dx, arm_top + arm_len, skin_l)
    elif WEAPON == "martillo":
        if atk == 0:
            cv.r(10, arm_top - 4, 11, arm_top + 1, skin)
            _hammer(cv, _line((10, arm_top - 5), (9, arm_top - 9)), (5, arm_top - 13, 11, arm_top - 10))
        elif atk == 1:
            cv.r(13, arm_top, 17, arm_top + 1, skin)
            _hammer(cv, _line((18, arm_top), (20, arm_top - 2)), (19, arm_top - 6, 23, arm_top - 2))
        else:
            cv.r(13, arm_top + 3, 15, arm_top + 6, skin)
            _hammer(cv, _line((16, arm_top + 7), (18, arm_top + 10)), (17, arm_top + 11, 23, arm_top + 14))
    elif WEAPON == "baston":
        if atk == 0:
            cv.r(10, arm_top - 2, 11, arm_top + 2, skin)
            _staff(cv, _line((13, arm_top + 8), (6, arm_top - 9)))
        elif atk == 1:
            cv.r(13, arm_top + 1, 17, arm_top + 2, skin)
            _staff(cv, _line((11, arm_top + 2), (23, arm_top + 1)), glow=True)
        else:
            cv.r(13, arm_top + 2, 15, arm_top + 4, skin)
            _staff(cv, _line((16, arm_top + 11), (16, arm_top - 8)))
    elif atk == 0:
        cv.r(10, arm_top - 4, 11, arm_top + 1, skin)
        _khopesh(cv, [(10, arm_top - 5), (10, arm_top - 6), (9, arm_top - 7), (8, arm_top - 8), (7, arm_top - 9), (6, arm_top - 9), (5, arm_top - 8)])
    elif atk == 1:
        cv.r(13, arm_top + 1, 17, arm_top + 2, skin)
        _khopesh(cv, [(18, arm_top + 1), (19, arm_top + 1), (20, arm_top), (21, arm_top), (22, arm_top - 1), (23, arm_top - 2), (23, arm_top - 3)])
    else:
        cv.r(13, arm_top + 3, 15, arm_top + 6, skin)
        _khopesh(cv, [(16, arm_top + 7), (17, arm_top + 8), (18, arm_top + 9), (19, arm_top + 10), (20, arm_top + 11), (21, arm_top + 11), (22, arm_top + 10)])


ORDER = []
for facing in ("south", "north", "east"):
    for anim, n in (("idle", 2), ("walk", 4), ("attack", 3), ("hammer", 3), ("staff", 3)):
        for i in range(n):
            ORDER.append((facing, anim, i))


def build(name):
    spec = SPECS[name]
    frames, names = [], []
    for facing, anim, i in ORDER:
        if anim in ("hammer", "staff") and not spec.get("weapon"):
            continue
        a = anim if (anim not in ("attack", "hammer", "staff") or spec.get("weapon")) else "idle"
        frames.append(draw(spec, facing, a, i % 2 if a == "idle" else i))
        names.append(f"{facing}_{anim}_{i}")
    sheet = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
    for k, f in enumerate(frames):
        sheet.paste(f, (k * W, 0), f)
    save(sheet, os.path.join(OUT, name + ".png"))
    save_layout(os.path.join(OUT, name + "_layout.json"), W, H, names)


if __name__ == "__main__":
    for n in SPECS:
        build(n)
