"""Iconos de HUD redibujados a mano en 16x16 (PROMPT_PULIDO.md punto 5):
los anteriores eran demasiado toscos para leerse como slots. Incluye iconos
nuevos de fase del dia (sol, luna, amanecer, atardecer) y de cultivos para
el inventario."""
import math
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import c
from pixel_draw import grid_to_image, save

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "icons")

CMAP = {
    "k": "outline", "g": "gold", "G": "gold_dark", "s": "moon_silver", "S": "bone_dark",
    "w": "bone", "b": "lapis", "B": "lapis_dark", "t": "turquoise", "T": "turquoise_dark",
    "r": "red_accent", "R": "red_dark", "o": "ochre", "O": "ochre_dark", "h": "sand_light",
    "H": "sand", "n": "grass_light", "N": "grass_dark", "l": "linen", "L": "linen_dark",
    "y": "fire_yellow", "f": "fire_orange", "c": "soil", "m": "nile_green",
}

ICONS = {
    "anj": [
        "................",
        "......kkkk......",
        ".....kggggk.....",
        "....kgGkkGgk....",
        "....kgk..kgk....",
        "....kgk..kgk....",
        ".....kgGGgk.....",
        "..kkkkkggkkkkk..",
        "..kgggggggggGk..",
        "..kGGGGggGGGGk..",
        "..kkkkkggkkkkk..",
        "......kggk......",
        "......kggk......",
        "......kgGk......",
        "......kgGk......",
        "......kkkk......",
    ],
    "scarab": [
        "................",
        "......k..k......",
        ".....k.kk.k.....",
        "......kggk......",
        ".....kbggbk.....",
        "..k.kbbbbbbk.k..",
        "...kbtbBBbtbk...",
        "..kbbtbBBbtbbk..",
        ".k.kbbbBBbbbk.k.",
        "...kbtbBBbtbk...",
        "..kbbtbBBbtbbk..",
        ".k.kbbbBBbbbk.k.",
        "....kbBBBBbk....",
        ".....kbBBbk.....",
        "......kkkk......",
        "................",
    ],
    "khopesh": [
        "................",
        "..........kkk...",
        ".........kssSk..",
        "........kssk.kk.",
        ".......kssk..kSk",
        "......kssk....kk",
        ".....kssk.......",
        "....kssk........",
        "...kssk.........",
        "..kGGk..........",
        ".kgGk...........",
        ".kgk............",
        "kgGk............",
        "kGk.............",
        "kk..............",
        "................",
    ],
    "hammer": [
        "................",
        "...kkkkkkkkk....",
        "..kSSSSSSSSSk...",
        "..kSwwwwwwwSk...",
        "..kSSSgggSSSk...",
        "..kSSSSSSSSSk...",
        "...kkkkOokkk....",
        ".......kOok.....",
        ".......kOok.....",
        "......kOok......",
        "......kOok......",
        "......kGgk......",
        ".....kOok.......",
        ".....kOok.......",
        ".....kkkk.......",
        "................",
    ],
    "hoe": [
        "................",
        ".kkkk...........",
        "kGggGk..........",
        "kGggGk..........",
        ".kGGkk..........",
        "..kkOkk.........",
        ".....kOk........",
        "......kOk.......",
        ".......kOk......",
        "........kOk.....",
        ".........kOk....",
        "..........kOk...",
        "...........kOk..",
        "............kOk.",
        ".............kk.",
        "................",
    ],
    "sickle": [
        "................",
        ".......kkkk.....",
        ".....kkssssk....",
        "....kssk..kSk...",
        "...ksk.....kk...",
        "...ksk..........",
        "...ksk..........",
        "...kssk.........",
        "....kssk........",
        ".....kssk.......",
        "......kkOk......",
        ".......kOOk.....",
        "........kOOk....",
        ".........kOk....",
        "..........kk....",
        "................",
    ],
    "watering_can": [
        "................",
        ".....kkkkk......",
        ".....kHHHk......",
        "......kok.......",
        "....kkoookk.....",
        "...kooOOoook....",
        "..koOhhOOoook...",
        "..koOhOOOOOok...",
        "..kooOtttOOok...",
        "..koootttOOok...",
        "...kooOOOOok....",
        "....kkOOOkk.....",
        "......kkk.......",
        "................",
        "................",
        "................",
    ],
    "heart": [
        "................",
        "................",
        "..kkk....kkk....",
        ".krrrk..krrrk...",
        "krwrrrkkrrrrRk..",
        "krwrrrrrrrrrRk..",
        "krrrrrrrrrrrRk..",
        "krrrrrrrrrrRRk..",
        ".krrrrrrrrRRk...",
        "..krrrrrrRRk....",
        "...krrrrRRk.....",
        "....krrRRk......",
        ".....krRk.......",
        "......kk........",
        "................",
        "................",
    ],
    "feather": [
        "......kk........",
        ".....kwwk.......",
        "....kwwwwk......",
        "....kwwlwk......",
        "...kwwwlwwk.....",
        "...kwwwlwwk.....",
        "...kwwwlwwk.....",
        "...kwwlwwwk.....",
        "...kwwlwwk......",
        "...kwwlwwk......",
        "....kwlwk.......",
        "....kwlwk.......",
        ".....klk........",
        ".....kLk........",
        ".....kLk........",
        "......k.........",
    ],
    "deben": [
        "................",
        "................",
        "................",
        ".....kkkkkk.....",
        "...kkooooookk...",
        "..koohhooooook..",
        ".kohkkkkkkkkook.",
        ".kok........kok.",
        ".kok........kok.",
        ".kOOkkkkkkkkOOk.",
        "..kOOOooooOOOk..",
        "...kkOOOOOOkk...",
        ".....kkkkkk.....",
        "................",
        "................",
        "................",
    ],
    "item_trigo": [
        "................",
        "...g..g.g..g....",
        "...gG.gGgg.gG...",
        "....gGgGggGg....",
        "....GgGgGgGG....",
        ".....GgGgGG.....",
        "......GGGG......",
        "......kOOk......",
        "......kffk......",
        "......OkkO......",
        ".....OO..OO.....",
        "....OO....OO....",
        "...OO......OO...",
        "................",
        "................",
        "................",
    ],
    "item_lino": [
        "................",
        "...bb.....bb....",
        "..bwbb...bwbb...",
        "...bb..bb.bb....",
        "....m.bwbb.m....",
        "....m..bb..m....",
        ".....m.m..m.....",
        ".....m.m.m......",
        "......mmm.......",
        "......mmm.......",
        ".......m........",
        "......NNN.......",
        "................",
        "................",
        "................",
        "................",
    ],
    "item_papiro": [
        "................",
        "..n.n.n..n.n.n..",
        "...nnn.nn.nnn...",
        "....nnnnnnnn....",
        ".....NnnnnN.....",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        "......NNNN......",
        ".....NNNNNN.....",
        "................",
        "................",
        "................",
        "................",
    ],
    "staff": [
        "...........kk...",
        "..........kssk..",
        ".........ksyysk.",
        ".........ksyysk.",
        "..........kssk..",
        ".........kOkk...",
        "........kOk.....",
        ".......kOk......",
        "......kOk.......",
        ".....kgGk.......",
        "....kOk.........",
        "...kOk..........",
        "..kOk...........",
        ".kOk............",
        ".kk.............",
        "................",
    ],
    "shabti": [
        "......kkkk......",
        ".....ktttTk.....",
        "....ktTkkTTk....",
        "....ktkwwkTk....",
        "....ktkkkkTk....",
        ".....kttTTk.....",
        "....ktgggGTk....",
        "....kttTTTTk....",
        "....ktkTkTTk....",
        "....kttTTTTk....",
        "....ktkTkTTk....",
        "....kttTTTTk....",
        ".....ktTTTk.....",
        ".....ktTTTk.....",
        "......kkkk......",
        "................",
    ],
    "senet": [
        "................",
        "................",
        "......kkkk......",
        ".....kwwwSk.....",
        "......kwSk......",
        "......kwSk......",
        ".....kwwSSk.....",
        "....kwwwSSSk....",
        "....kwwwSSSk....",
        "....kSSSSSSk....",
        ".....kkkkkk.....",
        "................",
        "................",
        "................",
        "................",
        "................",
    ],
    "camp": [
        "................",
        ".......kk.......",
        "......kLLk......",
        ".....kLlLLk.....",
        "....kLllLLLk....",
        "...kLllkkLLLk...",
        "..kLllkoOkLLLk..",
        ".kLlllkOOkLLLLk.",
        "kkkkkkkkkkkkkkkk",
        "................",
        "....kyk..kfk....",
        "...kyfykkfyfk...",
        "...kkOOkkOOkk...",
        "................",
        "................",
        "................",
    ],
    "wall": [
        "................",
        "................",
        "..kkkkkkkkkkkk..",
        ".kHHhHHHHhHHHHk.",
        ".kHHHHkHHHHkHHk.",
        ".kkkkkkkkkkkkkk.",
        ".kHhHHHkHHhHHHk.",
        ".kHHHkHHHHHkHHk.",
        ".kkkkkkkkkkkkkk.",
        ".kHHHHhHHkHHhHk.",
        ".kHkHHHHHHHkHHk.",
        ".kkkkkkkkkkkkkk.",
        "................",
        "................",
        "................",
        "................",
    ],
}


def ray_icon(kind):
    """Sol / luna / amanecer / atardecer dibujados por geometria."""
    s = 16
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    px = img.load()
    cx, cy = 7.5, 7.5
    horizon = 11 if kind in ("dawn", "dusk") else 99
    if kind in ("dawn", "dusk"):
        cy = 11.0
    for y in range(s):
        for x in range(s):
            if y > horizon:
                continue
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            if kind == "moon":
                d2 = math.hypot(x - 10.0, y - 5.5)
                if d <= 6.2 and d2 > 5.0:
                    px[x, y] = c("moon_silver") if d < 5.2 else c("outline")
                elif d <= 6.2 and d2 <= 5.0 and d2 > 4.2:
                    pass
                continue
            core = 4.2
            if d <= core:
                inner = "fire_yellow" if kind == "sun" else "fire_orange"
                px[x, y] = c(inner) if d < core - 1.2 else c("gold_dark")
            elif d <= core + 1.0:
                px[x, y] = c("outline")
            else:
                ang = math.atan2(dy, dx)
                if 5.5 < d < 7.6 and (math.cos(ang * 8) > 0.72):
                    px[x, y] = c("gold") if kind == "sun" else c("fire_orange")
    if kind in ("dawn", "dusk"):
        for x in range(1, 15):
            px[x, 12] = c("outline")
            px[x, 13] = c("sand_dark")
    if kind == "moon":
        for (x, y) in ((13, 2), (2, 12), (14, 11)):
            px[x, y] = c("bone")
    return img


if __name__ == "__main__":
    for name, grid in ICONS.items():
        save(grid_to_image(grid, CMAP), os.path.join(OUT, name + ".png"))
    for k in ("sun", "moon", "dawn", "dusk"):
        save(ray_icon(k), os.path.join(OUT, "phase_" + k + ".png"))
