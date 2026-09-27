"""Horizonte del mapa (PROMPT_PULIDO.md punto 2, pendiente "piramides
lejanas"): quita las piramides sueltas de los props y escribe una seccion
"horizonte" idempotente en data/map_layout.json con grupos de piramides
lejanas (estilo Guiza) y un plano de desierto exterior, para que el borde del
mundo nunca muestre vacio. Se puede correr las veces que haga falta."""
import json
import os

PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "map_layout.json")

with open(PATH, encoding="utf-8") as f:
    data = json.load(f)

data["props"] = [p for p in data["props"] if p["tipo"] != "distant_pyramid"]

# tile = coordenadas de tile (pueden quedar fuera del mapa jugable);
# size = lado de la base en metros; cap = piramidion dorado en la punta.
pyramids = [
    # trio al norte-noreste, detras de la aldea (el que mas se ve)
    {"tile": [27, -26], "size": 34, "cap": True},
    {"tile": [37, -30], "size": 28, "cap": False},
    {"tile": [45, -27], "size": 16, "cap": False},
    # una lejana al noroeste, al otro lado del Nilo
    {"tile": [4, -34], "size": 22, "cap": False},
    # al este, mas alla del desierto
    {"tile": [62, 4], "size": 26, "cap": True},
    {"tile": [66, 16], "size": 18, "cap": False},
    # al sur, detras de la necropolis
    {"tile": [30, 52], "size": 24, "cap": False},
]

data["horizonte"] = {
    "suelo_exterior": {"textura": "sand", "tamano_m": 520, "repeticiones": 130},
    "piramides": pyramids,
}

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
print("horizonte:", len(pyramids), "piramides")
