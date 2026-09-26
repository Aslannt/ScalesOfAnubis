# Decisiones tomadas de forma autónoma

Registro de decisiones de diseño/técnicas tomadas sin poder preguntar, con su razón.
Basadas en el GDD y en lo más razonable para una demo pulida y jugable.

## Alcance de la sesión nocturna
Con el tiempo disponible es más realista y más fiel a la regla "mejor corto y pulido
que mucho a medias" enfocarse en dejar sólido el **loop central**: mundo + movimiento +
ciclo día/noche + granja + combate básico (M0–M4), con arte propio desde el minuto uno
(nunca cubos grises), en vez de repartir el esfuerzo entre los 11 hitos y dejar todo a medias.
Los hitos M5–M11 (corazón/progresión, aldea con diálogos, códice, jefe, pase de arte final,
audio completo, export .exe) quedan documentados en PROGRESS.md como próximos pasos
recomendados, con la base técnica ya lista para construirlos encima.

## Resolución y look pixelado
- Viewport base 480×270, escalado con `stretch mode = viewport`, `aspect = keep`.
- Filtro `nearest` en todas las texturas (import preset + materiales).
- Motivo: es la resolución que da un pixel art nítido y coherente en pantallas 16:9
  modernas sin distorsión, y es la que sugiere el GDD como primera opción.

## Cámara
- Cámara 3D en perspectiva, en diagonal alta detrás del jugador (estilo Octopath/Cult of
  the Lamb), con suavizado (lerp) al seguir. Perspectiva en vez de ortográfica porque el
  GDD pide "perspectiva suave" explícitamente.

## Personajes y criaturas
- `AnimatedSprite3D` con `billboard = enabled` para personajes/enemigos (sprites 2D en
  mundo 3D), generados como spritesheets con Python + Pillow desde una paleta fija
  (`tools/palette.py`). 4 direcciones (N/S/E/O) con idle/caminar/atacar donde aplique.

## Terreno y edificios
- Geometría low-poly construida con `MeshInstance3D` (primitivas y mallas simples
  generadas por script) más texturas pixeladas propias, en vez de CSG en el editor,
  para poder versionar el mapa como código y regenerarlo fácilmente.

## Moneda y textos
- Todos los textos del juego centralizados en `data/textos_es.json` (o recursos de
  traducción de Godot) para poder traducir después, tal como pide CLAUDE.md.

## Controles de granja simplificados
- La tecla **E** hace todo el ciclo de la parcela de forma contextual: si
  está sin trabajar la ara, si está arada la siembra (trigo, o papiro si es
  parcela de orilla), si está lista la cosecha, si está plantada y sin regar
  la riega. No hay selección manual de semilla ni economía de compra de
  semillas con Ptahmose en esta demo, y **lino queda fuera de lo plantable**
  por el jugador (motivo: implementar selección de semilla + tienda +
  inventario de semillas en una sola noche hubiera dejado ese sistema a
  medias, contra la regla de "mejor corto y pulido"). Los slots de
  herramienta 1/2/3 quedan reservados para las armas nocturnas
  (khopesh/martillo); de día no cambian nada todavía.
- Es la simplificación de mayor impacto que tomé. Con más tiempo, lo primero
  que ampliaría es esto: semillas comprables, selección de cultivo al
  sembrar, y lino jugable.

## Herramientas
- Godot 4.7.2 (estable, vía winget) — última estable disponible al momento de empezar.
- Generación de sprites: Python 3.12 + Pillow + numpy (ya presentes/instalados).
- Audio: síntesis propia con Python (numpy → WAV) estilo sfxr, sin dependencias de pago.

## Herramienta de captura visual (obligatoria desde PROMPT_PULIDO.md)
- `tools/capture.gd`/`capture.tscn` cargan Farm.tscn de verdad (con ventana,
  sin `--headless`), teletransportan al jugador a 8 puntos del mapa (granja,
  aldea, necrópolis, orilla, vista general) fijando la fase del día, y
  guardan PNG en `shots/` (fuera de git). `capture_menu.tscn` hace lo mismo
  con el menú principal. A partir de ahora, todo cambio visual se verifica
  así antes de commitear — el chequeo headless sigue para errores de script,
  pero ya no es la única verificación.
- La primera tanda de capturas confirmó un bug real de fondo, no solo cosas
  "feas": el crossfade día/noche interpola a lo largo de **toda** la fase
  (hasta 150s de día, 100s de noche) en vez de una transición corta, así
  que "noche" se veía con los colores de "atardecer" (rojo/naranja) durante
  buena parte de la noche real jugada, no rojo por error de paleta sino por
  velocidad de transición. Se corrige en el punto 4 del pase de pulido.

## Exportación a Windows
- Instalé las plantillas de exportación oficiales de Godot 4.7.2 (descarga
  desde GitHub Releases del propio motor, gratis) y armé un
  `export_presets.cfg` mínimo para "Windows Desktop" (arquitectura x86_64,
  PCK embebido). `build/ScalesOfAnubis.exe` queda commiteado fuera de git
  (`.gitignore`) porque es un binario de ~100MB regenerable con
  `godot --headless --export-release "Windows Desktop" build/ScalesOfAnubis.exe`;
  lo importante es que el archivo exista en el disco para que abras el
  juego mañana con doble clic, no que viva en el historial de git.
