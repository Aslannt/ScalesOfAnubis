"""Paleta fija de Scales of Anubis. Toda la generacion de arte usa estos colores
para que el juego se vea coherente. Ver GDD.md seccion 8 (Direccion de arte).
"""

PALETTE = {
    # Arena / desierto
    "sand_light": (232, 201, 155, 255),
    "sand": (217, 177, 113, 255),
    "sand_dark": (168, 128, 78, 255),
    # Ocre / tierra
    "ochre": (201, 127, 42, 255),
    "ochre_dark": (143, 90, 30, 255),
    "soil": (94, 61, 38, 255),
    "soil_dark": (61, 38, 22, 255),
    "soil_wet": (56, 42, 30, 255),
    # Oro
    "gold": (232, 185, 35, 255),
    "gold_dark": (163, 121, 20, 255),
    # Turquesa
    "turquoise": (47, 168, 154, 255),
    "turquoise_dark": (29, 110, 102, 255),
    # Lapislazuli
    "lapis": (42, 75, 141, 255),
    "lapis_dark": (27, 47, 92, 255),
    # Verde del Nilo
    "nile_green": (62, 122, 76, 255),
    "nile_green_dark": (36, 81, 47, 255),
    "nile_water": (41, 98, 105, 255),
    "nile_water_dark": (24, 66, 72, 255),
    # Negro de Anubis / neutros
    "anubis_black": (20, 16, 15, 255),
    "outline": (24, 18, 16, 255),
    "bone": (242, 230, 201, 255),
    "bone_dark": (196, 178, 140, 255),
    # Piel / cabello
    "skin": (196, 138, 85, 255),
    "skin_dark": (140, 92, 54, 255),
    "skin_light": (222, 172, 122, 255),
    "hair": (35, 26, 22, 255),
    # Telas
    "linen": (230, 214, 175, 255),
    "linen_dark": (188, 168, 126, 255),
    "red_accent": (178, 58, 46, 255),
    "red_dark": (110, 32, 24, 255),
    # Noche
    "night_blue": (26, 27, 58, 255),
    "night_blue_dark": (15, 16, 36, 255),
    "night_violet": (46, 31, 78, 255),
    "fire_orange": (242, 135, 46, 255),
    "fire_yellow": (250, 200, 90, 255),
    "moon_silver": (201, 214, 232, 255),
    # Transparente
    "none": (0, 0, 0, 0),
}


def c(name):
    return PALETTE[name]
