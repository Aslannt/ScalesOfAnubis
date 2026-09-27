# PROGRESS — Scales of Anubis (demo)

_Última actualización: sesión en la nube (Linux), 2026-09-27 (ronda 3)._

## Léeme primero
La demo está **completa de principio a fin**: intro en el Duat → 3 días y 3
noches → Heraldo de Ammit → pesaje final → recuerdo del ba → pantalla de
gracias. Todo lo que pedían `CLAUDE_NUBE.md` y `PROMPT_PULIDO.md` está hecho,
y también la lista extra de `CLAUDE.md` (combate, claridad, mapa,
cayado/bastón, muro de adobe, mando y guardado).

**Mira primero la carpeta [`capturas_finales/`](capturas_finales/)** (31
capturas a 1920×1080, se ven bien desde el celular en GitHub).

Cada decisión que tomé sin poder preguntarte está en `DECISIONES.md`.

## Ronda 3 (lo último que reportaste)
Detalle en `DECISIONES.md` → "Tercera ronda":
- **Congelado en la noche 2**: redes de seguridad contra pausas huérfanas y
  un desatascador si te quedas pegado; prueba automática nueva.
- **Sacudidas "desde la aldea"**: eran las defensas matando criaturas
  lejos; ya no sacuden. Golpes y martillo más suaves.
- **Enemigos y Heraldo trabados**: ahora usan navmesh y rodean casas y
  tumbas. El Heraldo pega un poco menos.
- **Thot**: habla mucho menos y con calma, se ve su nombre, abre el pico al
  hablar y tiene un porqué: Anubis lo manda a anotar todo lo que hagas
  para el pesaje final. Al amanecer ves "Thot anotó:" con tus actos.
- **Defensas con progreso**: explicación antes de comprar, 3 niveles por
  tipo, lo futuro aparece como "???" hasta su día, y puedes mejorar o
  cambiar una defensa ya construida (te devuelven la mitad).
- **Cada noche más difícil**: criaturas con más vida, daño y velocidad.
- **Cultivos**: crecen poco a poco después de regar, no de golpe.
- **Casas y pirámide**: techo plano egipcio, variaciones por casa;
  pirámide escalonada con bloques y sombreado por cara.
- **Mundo vivo**: aldeanos que pasean y te miran, gatos, gansos del Nilo,
  humo de fogones, y los edificios se vuelven translúcidos si te tapan.

## Ronda 2 (después de que la probaste)
Arreglé todo lo que reportaste. Detalle en `DECISIONES.md` → "Segunda ronda":
- **Música**: no sonaba por un bug (loop de largo cero). Ahora hay un
  soundtrack adaptativo "tipo Balatro" egipcio que sube de intensidad del día
  a la noche sin cortarse, y no se detiene en los diálogos.
- **Caída del mapa por el sur**: arreglada (muros invisibles en los bordes).
- **Cultivos robados de la nada**: ahora las crías tardan 5 s con barra roja,
  "!", alarma, aviso de Thot y flecha en el borde de pantalla.
- **Historia**: intro nueva que explica todo en simple, panel de OBJETIVOS,
  "!" sobre los aldeanos con algo nuevo, balanza con número.
- **Más divertido**: monedas al matar, carteles de oleada, combo, embestidas,
  campamento para saltar al atardecer, ofrendas, 5 shabtis escondidos y la
  misión de Iry.
- **Casas y pirámides** con techo, bordes y bloques.
- **Intro animada**: tarjetas con paralaje, balanza que oscila de verdad,
  sello de "¡EMPATE!", Anubis que respira, Thot que llega volando.

Para traer los cambios, en Git Bash:
```
cd ~/Projects/ScalesOfAnubis
git checkout -- "*.import"
git pull
```
(la segunda línea descarta los `.import` que Godot reescribe solo al
abrir el proyecto; si no hay, no hace nada). Te recomiendo **Nueva partida** para ver
todo desde el principio (el guardado viejo también carga).

## Cómo jugar
1. Abre el proyecto con **Godot 4.7.2** y exporta el `.exe` con el preset
   que ya existe: *Proyecto → Exportar… → Windows Desktop → Exportar
   proyecto* (sale en `build/ScalesOfAnubis.exe`). En la nube lo exporté y
   funciona, pero `build/` no se sube a git (pesa ~110 MB).
2. O dale a **Play (F5)** en el editor: arranca en el menú principal.
3. **Nueva partida** empieza con la intro (Esc la salta). **Continuar**
   aparece si hay una partida guardada.

Duración aproximada: 16–20 minutos (día de 3 min, noche de 1 min 40 s).

## Controles
| Acción | Teclado y mouse | Mando |
|---|---|---|
| Moverse | WASD | Stick izq. / cruceta |
| Descansar hasta el atardecer | E en el campamento (junto al campo) | A |
| Interactuar (arar, sembrar, regar, cosechar, hablar, construir) | **E** | A |
| Atacar (de noche, hacia el mouse) | Clic izq. | X o gatillo der. |
| Apuntar | Mouse | Stick der. |
| Esquivar | Espacio | B o gatillo izq. |
| Semilla (de día) / arma (de noche) | 1 / 2 / 3 o rueda | LB / RB |
| Amuleto | Q | Y |
| Códice (Libro de los Muertos) | Tab | Back |
| Pausa | Esc | Start |

Armas de noche: **1 khopesh** (combo de 3 golpes, el tercero pega más),
**2 martillo** (lento, en área, aturde), **3 bastón** (proyectil de energía).
Semillas de día: **1 trigo** (1 día), **2 lino** (2 días), **3 papiro**
(2 días, solo en la orilla).

## La demo, día por día
- **Intro**: la balanza duda y queda exacta; Anubis te devuelve a la vida;
  Thot se une.
- **Día 1**: Thot te enseña con comentarios cortos (sin pausar): moverte,
  arar, sembrar, regar. La pista "[E] …" abajo dice siempre qué hace la E.
  Conoce a Meret (pide 3 manojos de **lino**), Ptahmose (compra cosechas,
  vende semillas, cuenta rumores con mitología real) e Iry.
- **Noche 1**: pocas sombras desde el desierto y la necrópolis. Flechas en
  el borde de la pantalla indican de dónde vienen.
- **Amanecer**: resumen (criaturas vencidas, cultivos perdidos, cambio en
  la balanza). Autoguardado.
- **Defensas** (pedestales junto al campo y la aldea, E de día): el día 1
  hay muro de adobe (bloquea) y brasero (quema en área); el día 2 se revela
  la estatua de chacal (dispara) y los niveles 2; el día 3 los niveles 3.
  E sobre una defensa construida para mejorarla o cambiarla.
- **Día 2**: cosecha y vende; mejora tus defensas. **Decisión 1**: el
  altar del templo no tiene vigilancia.
- **Noche 2 — Decisión 2**: sombras van a saquear la aldea mientras crías
  atacan tus cultivos. No hay menú: la decisión es adónde vas. Meret
  reacciona al día siguiente.
- **Día 3**: Meret te da el **escarabajo del corazón** (revive una vez por
  noche). Entrégale el lino. Iry dice algo inquietante.
- **Noche 3**: oleadas y el **Heraldo de Ammit** (embestida con aviso en el
  suelo, rugido que invoca crías, golpe de área, segunda fase al 50 %).
  Pégale fuerte justo después de una embestida.
- **Final**: pesaje con tu peso real, recuerdo del ba, gracias (con tus
  estadísticas y decisiones).
- **Derrota**: Anubis te devuelve a la granja (pierdes deben y amanece); si
  caes ante el jefe, reintentas la pelea.

## Qué se hizo en esta sesión (resumen; detalle en `DECISIONES.md`)
**Bugs que encontraste jugando**
- Diálogo en bucle: arreglado y cubierto por una prueba automatizada.
- Sonidos fuertes: efectos a −12 dBFS, arar rehecho como golpe de tierra,
  variación de tono aleatoria, música un poco por encima.

**PROMPT_PULIDO.md (terminado)**: pirámides lejanas con suelo y sombreado;
viento en toda la vegetación; Nilo animado con espuma; sombras de nubes;
polvo, luciérnagas, hojas, ibis y peces; sombra/respiración/polvo en los
personajes; HUD nuevo (vida con marco, panel de fase, slots con íconos,
inventario, pista contextual); Thot detrás y arriba del jugador; menú
animado; cielo diurno cálido. Bug de fondo: la noche quedaba roja por la
luz ambiental tomada del cielo (se actualiza con retraso); ahora es un color
propio por fase.

**Hitos del GDD**: decisión moral 2, defensas (+ muro), Heraldo de Ammit,
estructura completa de 3 días con intro y final, semillas y lino plantable,
combate pulido (avisos de golpe enemigo, empuje real, i-frames, combo,
aturdimiento, indicadores fuera de pantalla), derrota.

**Pase de arte (M9)**: personajes redibujados con rasgos egipcios (Meret
con la pluma de Maat, Iry con el mechón de la juventud, Ptahmose con túnica a
rayas), criaturas, Thot como ibis con paleta de escriba, Heraldo nuevo,
retratos, íconos 16×16, cultivos tallo a tallo, casas de adobe, templo con
pilono, necrópolis con mastabas y pirámide escalonada, códice como papiro.

**Audio (M10)**: música nueva de 30–70 s (arpa, ney, darbuka, sistro,
bordón) para título, día, noche y jefe; ambientes de día y de noche.

**Extras**: bastón, muro de adobe, soporte de mando, guardado.

## Cómo verifiqué (en la nube)
- **Capturas con ventana en Forward+** (Vulkan por software, el mismo
  renderer de tu PC) antes de cada commit visual; animaciones comprobadas
  con 3–4 frames seguidos. Script: `tools/capture.gd` (+ `capture_menu`,
  `capture_story`). Salen en `shots/` (fuera de git).
- **Pruebas automatizadas** (todas pasan, también dentro del juego
  **exportado**):
  - `tools/tests/test_dialogue.tscn` — hablar con los 3 NPC y salir.
  - `tools/tests/test_demo.tscn` — los 3 días completos: granja, compra y
    venta, defensas, bastón, noches, ambas decisiones, Meret, jefe, derrota
    y final.
  - `tools/tests/test_story.tscn` — intro y final hasta "gracias".
  - `tools/tests/test_save.tscn` — guardar y continuar.
  - `tools/tests/test_robustez.tscn` — pausas huérfanas, desatascar al
    jugador, criaturas que rodean el templo.
  - `tools/tests/test_audio.tscn` — la música suena y hace loop.
  - Correr: `godot --headless --path . res://tools/tests/test_demo.tscn`
    o, con un build exportado: `juego.exe -- --autotest=demo`.

## Problemas conocidos
- **No pude escuchar el audio** (la nube no tiene parlantes): verifiqué
  niveles, loops sin clic y espectrogramas. Si algo suena raro, los
  parámetros están al inicio de cada función de `tools/gen_music.py` y
  `tools/gen_sfx.py`.
- En la nube la GPU es por software: la iluminación exacta (SSAO, glow) en
  tu RTX puede verse algo distinta a las capturas, aunque el renderer es el
  mismo.
- El sprite de ataque muestra el khopesh con las tres armas (el arco o el
  proyectil sí cambian según el arma).
- El congelamiento de la noche 2 no lo pude reproducir; quedó cubierto con
  redes de seguridad, pero si vuelve a pasar dime qué estabas haciendo.
- El guardado es al empezar cada día: si sales a mitad del día, retomas
  desde su comienzo.

## Próximos pasos recomendados
1. Jugarla entera en tu PC y ajustar números de balance (vida del jefe en
   `scenes/enemies/Heraldo.tscn`, oleadas en `data/waves.json`, precios en
   `data/crops.json` y `scripts/world/defense_spot.gd`, duración del día en
   `scripts/autoload/game_time.gd`).
2. Escuchar la música y los efectos y retocar lo que no guste.
3. Sprites de ataque distintos para martillo y bastón.
4. Traducción al inglés: los textos ya están centralizados en
   `data/textos_es.json`, `data/dialogues.json` y `data/codex.json`.

## Estructura
- `scenes/` escenas (`world/Farm.tscn`, `ui/Main.tscn`, `story/Intro|Final`,
  enemigos, jugador).
- `scripts/` código por área (`autoload/`, `world/`, `ui/`, `enemies/`,
  `npc/`, `player/`, `fx/`, `story/`).
- `data/` todo el contenido: mapa, oleadas, cultivos, diálogos, textos,
  códice.
- `assets/` arte, shaders y audio, **todo generado por los scripts de
  `tools/`** (Python + Pillow + numpy). Ver `CREDITS.md`.
- `tools/` generadores de arte y audio, capturas y pruebas.
