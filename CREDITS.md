# Créditos y licencias

## Motor
- [Godot Engine 4.7.2](https://godotengine.org/) — MIT License.

## Arte
- Todos los sprites de personajes, enemigos, iconos, cultivos y texturas de
  terreno/edificios en `assets/` son **generados por scripts propios**
  (`tools/*.py`, Python + Pillow + numpy) usando la paleta fija definida en
  `tools/palette.py`. No se usó arte de terceros.
- Geometría 3D low-poly (casas, templo, obelisco, tumbas, muelle, columnas,
  rocas, palmeras) generada por código en `scripts/world/building_factory.gd`.

## Audio
- Todos los SFX (`assets/audio/sfx/`) y la música (`assets/audio/music/`:
  título, día, noche, jefe y ambientes de día/noche) son **síntesis propia**
  generada con `tools/gen_sfx.py`, `tools/gen_groove.py` (soundtrack
  adaptativo en capas) y `tools/gen_music.py` (ambientes) (numpy → WAV):
  arpa por Karplus-Strong, flauta ney con vibrato y soplo, darbuka (doum/tek),
  sistro, bordón, grillos, viento y pájaros sintetizados. Escala doble
  armónica. No se usó audio de terceros.
- Capas de las estaciones del Nilo y jingles (`tools/gen_seasons_music.py`):
  arpa con cuerpo, ney con aire, riq, palmas y pads de agua, todo sintetizado.
- Retratos con expresiones (`tools/gen_portraits_hd.py`), animales de la aldea
  (`tools/gen_animals.py`) y ataques de martillo y cayado del jugador
  (`tools/gen_people.py`): pixel art generado por script con la paleta fija.

## Fuentes
- **Silkscreen** (Jason Kottke), licencia SIL Open Font License 1.1
  (`assets/fonts/OFL.txt`). Descargada del repositorio oficial de Google
  Fonts (github.com/google/fonts, carpeta `ofl/silkscreen`). Cubre los
  caracteres del español (áéíóúñ¿¡). Usada como fuente por defecto de toda
  la interfaz (`project.godot` → `gui/theme/custom_font`).

## Software usado para generar contenido
- Python 3.12, Pillow, numpy (generación de sprites y texturas).
