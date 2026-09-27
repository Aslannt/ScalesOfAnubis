# PROGRESS — Scales of Anubis (demo)

_Última actualización: sesión en la nube (Linux), 2026-09-27 (ronda 4, por fases)._

## Léeme primero
La demo está **completa de principio a fin**: intro en el Duat → 3 días y 3
noches → Heraldo de Ammit → pesaje final → recuerdo del ba → pantalla de
gracias. Después del final se puede **seguir jugando en modo libre** con
las estaciones del Nilo. Todo lo que pedían `CLAUDE_NUBE.md` y
`PROMPT_PULIDO.md` está hecho, y también la lista extra de `CLAUDE.md`.
El juego está completo en **español e inglés**.

**Mira primero la carpeta [`capturas_finales/`](capturas_finales/)** (44
capturas a 1920×1080, se ven bien desde el celular en GitHub).

Cada decisión que tomé sin poder preguntarte está en `DECISIONES.md`.

## Ronda 4: todo lo que le faltaba, por fases
Me pediste hacer todo lo que te dije que le faltaba al juego, dividido en
fases. Cada fase terminó con pruebas y commit. Detalle y decisiones en
`DECISIONES.md` → "Cuarta ronda".
1. **La balanza cambia cómo juegas.** Con el corazón liviano (*Favor de
   Maat*) te curas de noche, Ptahmose paga más y tus cultivos a veces crecen
   un día extra. Con el corazón pesado (*Sombra* y *Hambre de Ammit*) pegas
   mucho más fuerte y matar te cura, pero vienen más criaturas... y el
   pesaje final se acerca. El borde de la pantalla se tiñe según el estado.
2. **Metas largas.** Restaura el **templo de Maat** en 4 partes hablando con
   Meret (cada parte se ve en el mundo y da una bendición para siempre).
   **Mejoras de herramientas** en la tienda de Ptahmose (vasija doble y
   azada de bronce que trabajan en área, armas mejoradas). **Amistad**: una
   charla y un regalo por día; cada aldeano tiene 3 niveles con escenas que
   cuentan su secreto y una recompensa (Iry termina regando tus cultivos).
3. **Estaciones del Nilo y modo libre.** Al terminar la demo, [E] en la
   pantalla de gracias (o *Continuar* en el menú) sigue desde el día 4:
   Shemu (cosecha), Akhet (la crecida cubre la orilla, riega todo y las
   crías salen del río) y Peret (siembra). El Heraldo vuelve al final de
   cada estación, más fuerte.
4. **Personajes.** Retratos nuevos con expresiones (feliz, triste,
   sorpresa, enojo). Thot con personalidad: comentarios sarcásticos pocos y
   espaciados, y cada amanecer un recuerdo suyo con mitos reales que, poco
   a poco, explican por qué tu balanza dudó.
5. **Combate con más peso.** Martillo y cayado tienen su propia animación,
   sonidos por arma, enemigos que se aplastan y se deshacen en humo,
   vibración del mando y borde rojo que late con la vida baja.
6. **Música.** El groove que te gustó sigue igual; se suma una capa por
   estación (arpa, riq y palmas, agua) y jingles para el amanecer y los
   logros.
7. **Opciones e inglés.** Las opciones se guardan (volúmenes, pantalla
   completa, vibración, sacudida, destellos, texto rápido) y todo el juego
   está en inglés (Opciones → Idioma).
8. **Pruebas y playtest.** El juego guarda un registro de cada partida para
   ver dónde se trabó quien juega; `PLAYTEST.md` explica cómo probarlo con
   amigos y `bash tools/correr_pruebas.sh` corre las 8 pruebas.

## Ronda 3
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

Duración aproximada de la demo: 16–20 minutos (día de 3 min, noche de
1 min 40 s). El modo libre no tiene fin.

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
- **Siempre disponible**: charlar y regalar a los aldeanos (E sobre ellos
  cuando no tienen "!"), restaurar el templo con Meret, mejoras con
  Ptahmose, ofrendas en el altar.

## Modo libre (después del final)
- Ciclo de estaciones de 3 días: **Shemu** (días 4–6), **Akhet** (7–9),
  **Peret** (10–12) y vuelve a empezar.
- La última noche de cada estación vuelve el **Heraldo**, con más vida
  cada vez. Las noches traen más criaturas cada día.
- Metas: completar el templo (4 partes) y la amistad con los tres aldeanos.
- Se guarda al empezar cada día, igual que la demo.

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
  - `tools/tests/test_audio.tscn` — la música suena, hace loop y las capas
    de las estaciones están sincronizadas.
  - `tools/tests/test_sistemas.tscn` — estados del corazón, templo, mejoras,
    amistad, estaciones, inundación e idioma inglés.
  - `tools/tests/test_libre.tscn` — modo libre del día 4 al 7 (regreso del
    Heraldo, llegada de Akhet).
  - Todas juntas: `bash tools/correr_pruebas.sh`.
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
- El congelamiento de la noche 2 no lo pude reproducir; quedó cubierto con
  redes de seguridad, pero si vuelve a pasar dime qué estabas haciendo.
- El guardado es al empezar cada día: si sales a mitad del día, retomas
  desde su comienzo.

- Los números nuevos (estados del corazón, precios del templo y mejoras,
  oleadas del modo libre) están calculados, no jugados por personas:
  seguramente hay que ajustarlos después de tus primeras partidas.
- El inglés lo traduje yo; conviene que lo lea alguien nativo antes de
  publicarlo.

## Próximos pasos recomendados
1. **Hacer playtests** con 3–5 personas siguiendo `PLAYTEST.md` y mandarme
   sus notas y los registros de `playtest/`. Es lo que más va a mejorar el
   juego ahora.
2. Ajustar balance con esos datos. Todo está en JSON: `data/heart_states.json`,
   `data/temple.json`, `data/upgrades.json`, `data/friendship.json`,
   `data/seasons.json`, `data/defenses.json`, `data/waves.json`.
3. **Arte hecho a mano** (el mayor salto de calidad posible): un pixel
   artist para personajes, retratos y animaciones. Los sprites generados
   sirven de guía de tamaños y paleta.
4. **Música grabada o compuesta por una persona**, usando las capas actuales
   como maqueta (mismo tempo y estructura por capas).
5. Hacer una "rebanada vertical" de 30–45 minutos con ese arte y esa música
   para mostrar el juego o buscar financiamiento.

## Estructura
- `scenes/` escenas (`world/Farm.tscn`, `ui/Main.tscn`, `story/Intro|Final`,
  enemigos, jugador).
- `scripts/` código por área (`autoload/`, `world/`, `ui/`, `enemies/`,
  `npc/`, `player/`, `fx/`, `story/`).
- `data/` todo el contenido: mapa, oleadas, cultivos, diálogos, textos,
  códice, estados del corazón, templo, mejoras, amistad, estaciones;
  `data/i18n/` las traducciones.
- `assets/` arte, shaders y audio, **todo generado por los scripts de
  `tools/`** (Python + Pillow + numpy). Ver `CREDITS.md`.
- `tools/` generadores de arte y audio, capturas y pruebas.
