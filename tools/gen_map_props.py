"""Genera un lote grande de props dispersos (punto 2 de PROMPT_PULIDO.md:
'el mapa se ve vacio y plano') y los fusiona en data/map_layout.json junto
con una franja de camino de tierra. Determinista (semilla fija) para que
el mapa no cambie entre corridas."""
import json
import os
import random

PATH = os.path.join("..", "data", "map_layout.json")

with open(PATH, encoding="utf-8") as f:
    data = json.load(f)

rng = random.Random(2024)

new_props = []


def scatter(tipo, count, x0, z0, x1, z1, avoid=None):
    n = 0
    tries = 0
    while n < count and tries < count * 20:
        tries += 1
        x = rng.uniform(x0, x1)
        z = rng.uniform(z0, z1)
        if avoid and any(ax0 <= x <= ax1 and az0 <= z <= az1 for ax0, az0, ax1, az1 in avoid):
            continue
        new_props.append({"tipo": tipo, "tile": [round(x, 2), round(z, 2)], "rot": round(rng.uniform(0, 360), 1)})
        n += 1


# --- Orilla del Nilo: juncos y papiros densos ---
scatter("reed", 14, 4.3, 0.5, 5.8, 27.5)
scatter("papyrus_plant", 10, 5.2, 1.0, 6.8, 27.0)

# --- Aldea: vida (vasijas, cestas, pasto, flores) ---
village_avoid = [(21, 6, 30, 12)]  # evitar el centro donde estan casas/templo/Meret
scatter("pottery", 5, 20.5, 2.5, 31.5, 13.5, avoid=village_avoid)
scatter("basket", 4, 20.5, 2.5, 31.5, 13.5, avoid=village_avoid)
scatter("tall_grass", 6, 20.5, 2.5, 31.5, 13.5, avoid=village_avoid)
scatter("flower", 5, 20.5, 2.5, 31.5, 13.5, avoid=village_avoid)
new_props.append({"tipo": "market_stall", "tile": [29.5, 4.5], "rot": 200})
new_props.append({"tipo": "well", "tile": [21.5, 11.5], "rot": 0})
new_props.append({"tipo": "cane_fence", "tile": [30.5, 9.0], "rot": 90})
new_props.append({"tipo": "cane_fence", "tile": [30.5, 10.8], "rot": 90})

# --- Necropolis: rocas y pasto ralo ---
necro_avoid = [(24, 18, 29, 24)]  # evitar el obelisco/tumbas centrales
scatter("rock", 4, 20.5, 15.5, 32.5, 27.5, avoid=necro_avoid)
scatter("tall_grass", 3, 20.5, 15.5, 32.5, 27.5, avoid=necro_avoid)

# --- Desierto abierto: rocas dispersas ---
scatter("rock", 5, 33.5, 0.5, 35.8, 27.5)
scatter("tall_grass", 4, 20.5, 0.5, 35.5, 1.8)

# --- Granja: flores y pasto alto bordeando los cultivos (no sobre ellos) ---
scatter("flower", 6, 7.2, 20.3, 19.0, 22.0)
scatter("tall_grass", 5, 7.2, 20.3, 19.0, 22.0)
scatter("flower", 4, 7.2, 6.2, 19.0, 7.8)

# --- Un shaduf junto al rio, cerca de la aldea/muelle ---
new_props.append({"tipo": "shaduf", "tile": [4.8, 8.5], "rot": 90})

# --- Anillo de dunas en los bordes norte/sur/este (el oeste ya es el rio) ---
for x in range(0, 37, 3):
    new_props.append({"tipo": "dune", "tile": [x + rng.uniform(-0.5, 0.5), -1.5 + rng.uniform(-0.5, 0.3)], "rot": rng.uniform(0, 360)})
    new_props.append({"tipo": "dune", "tile": [x + rng.uniform(-0.5, 0.5), 29.5 + rng.uniform(-0.3, 0.5)], "rot": rng.uniform(0, 360)})
for z in range(0, 29, 3):
    new_props.append({"tipo": "dune", "tile": [37.5 + rng.uniform(-0.3, 0.5), z + rng.uniform(-0.5, 0.5)], "rot": rng.uniform(0, 360)})

# --- Piramides lejanas mas alla del anillo de dunas, para el horizonte ---
for i in range(5):
    new_props.append({"tipo": "distant_pyramid", "tile": [14 + i * 6 + rng.uniform(-2, 2), -8 - rng.uniform(0, 4)], "rot": 0})
for i in range(4):
    new_props.append({"tipo": "distant_pyramid", "tile": [44 + rng.uniform(0, 3), 6 + i * 6 + rng.uniform(-2, 2)], "rot": 0})

data["props"].extend(new_props)

# --- Camino de tierra conectando granja -> aldea -> necropolis ---
camino_zone = {"nombre": "camino_principal", "rect": [18, 12.5, 27, 15.5], "textura": "path"}
# insertarlo cerca del final (se pinta encima) pero antes de aldea/necropolis
# para no tapar sus texturas propias; en realidad lo agregamos al final para
# que gane la franja de camino sobre el pasto/arena de alrededor.
data["zones"].append(camino_zone)

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"props agregados: {len(new_props)}; total props: {len(data['props'])}")
