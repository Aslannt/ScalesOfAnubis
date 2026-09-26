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
- Todos los SFX (`assets/audio/sfx/`) y los loops musicales de día/noche/jefe
  (`assets/audio/music/`) son **síntesis propia** generada con
  `tools/gen_sfx.py` y `tools/gen_music.py` (numpy → WAV, ondas
  cuadradas/sierra/seno con envolventes ADSR, estilo sfxr). No se usó audio
  de terceros.

## Fuentes
- **Silkscreen** (Jason Kottke), licencia SIL Open Font License 1.1
  (`assets/fonts/OFL.txt`). Descargada del repositorio oficial de Google
  Fonts (github.com/google/fonts, carpeta `ofl/silkscreen`). Cubre los
  caracteres del español (áéíóúñ¿¡). Usada como fuente por defecto de toda
  la interfaz (`project.godot` → `gui/theme/custom_font`).

## Software usado para generar contenido
- Python 3.12, Pillow, numpy (generación de sprites y texturas).
