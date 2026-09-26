"""Fondo pixelado para la pantalla de titulo (480x270)."""
import os
from PIL import Image, ImageDraw
from palette import c

W, H = 480, 270
img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
d = ImageDraw.Draw(img)

top = (26, 27, 58)
mid = (120, 60, 90)
bot = (232, 140, 60)
for y in range(H):
    if y < H * 0.55:
        t = y / (H * 0.55)
        col = tuple(int(top[i] + (mid[i] - top[i]) * t) for i in range(3))
    else:
        t = (y - H * 0.55) / (H * 0.45)
        col = tuple(int(mid[i] + (bot[i] - mid[i]) * t) for i in range(3))
    d.line([(0, y), (W, y)], fill=col + (255,))

import random
rng = random.Random(7)
for _ in range(80):
    x = rng.randint(0, W - 1)
    y = rng.randint(0, int(H * 0.4))
    if rng.random() < 0.5:
        d.point((x, y), fill=c("moon_silver"))

d.ellipse([360, 20, 410, 70], fill=c("moon_silver"))

horizon = int(H * 0.72)
d.rectangle([0, horizon, W, H], fill=c("sand_dark"))
d.rectangle([0, horizon, W, horizon + 3], fill=c("sand"))

def pyramid(cx, base_w, height, color):
    d.polygon([(cx - base_w // 2, horizon), (cx + base_w // 2, horizon), (cx, horizon - height)], fill=color)

pyramid(120, 140, 100, c("anubis_black"))
pyramid(230, 190, 140, (30, 24, 26, 255))
pyramid(340, 110, 80, c("anubis_black"))

for i, x in enumerate([60, 100, 300, 330, 360]):
    d.rectangle([x, horizon - 40, x + 6, horizon], fill=c("anubis_black"))

img.save(os.path.join("..", "assets", "textures", "title_bg.png"))
print("wrote title_bg.png")
