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

## Bug critico encontrado por Deivid probando el .exe: personaje invisible
- Reporte real: "no veo ni siquiera al personaje" al abrir el .exe exportado.
- Causa raiz confirmada (no adivinada): lancé el .exe real con
  PowerShell redirigiendo stdout/stderr a un log, y encontré miles de
  `ERROR: SpritesheetLoader: no se pudo cargar ... _layout.txt` — **todos**
  los personajes, enemigos, NPCs y hasta las antorchas fallaban en
  silencio. `SpritesheetLoader.build()` devolvía un `SpriteFrames` vacío
  sin ninguna animación, así que el `AnimatedSprite3D` no renderizaba nada.
- El motivo: los `_layout.txt` (un archivo de texto plano junto a cada hoja
  de sprites, con el ancho/alto de frame y el orden de animaciones) NO se
  empaquetan en un build `--export-release` con `export_filter=all_resources`
  tal como yo lo configuré — a diferencia de los `.json` de `data/`, que sí
  se empaquetan siempre (se demuestra porque los textos en español SÍ
  aparecían bien en el HUD, prueba de que `data/textos_es.json` cargó ok).
  Nunca había verificado el juego EXPORTADO cargando la escena real de
  juego con logs — solo lo probaba headless corriendo desde el código
  fuente, que sí encuentra los `.txt` sin problema (por eso nunca until
  ahora había señales de este bug).
- Arreglo: `scripts/util/spritesheet_loader.gd` ahora lee un `.json`
  (`{"frame_w":W,"frame_h":H,"frames":[...]}`) en vez de un `.txt` con
  formato casero. Los 3 generadores Python (`gen_characters.py`,
  `gen_enemies.py`, `gen_fx.py`) escriben `.json` vía el helper
  `pixel_draw.save_layout()`. Todas las referencias en `.gd`/`.tscn`
  actualizadas de `_layout.txt` a `_layout.json`. Los `.txt` viejos se
  borraron.
- Verificado relanzando el .exe real (no solo headless) con stdout/stderr
  redirigidos a archivo: el log de errores quedó completamente vacío
  (antes tenía miles de líneas de error). Este es el chequeo que voy a
  repetir de ahora en más antes de decir "arreglado" en algo que toque
  como se cargan assets: `--export-release` + relanzar el .exe real +
  mirar el log, no solo correr desde el código fuente.
- Nota para mí: evité seguir automatizando clicks/teclas sobre la ventana
  real del juego vía PowerShell — es impreciso (el foco de ventana no
  se roba de forma confiable por políticas de Windows) y en un intento
  de simular Alt+Tab terminé mandando un Escape que probablemente pausó
  el juego de Deivid mientras lo probaba él mismo. No volver a hacerlo
  mientras el usuario esté probando en vivo.

## Punto 2 (parcial): mapa con props, camino, dunas y parcelas visibles
- `tools/gen_map_props.py` esparce 125 props deterministas (junco/papiro
  denso en la orilla, vasijas/cestas/pasto/flores en la aldea, puesto de
  mercado + pozo + cercas, rocas en necrópolis/desierto, un shaduf) y agrega
  una franja de camino de tierra granja→aldea, más un anillo de dunas en los
  bordes norte/sur/este (el oeste ya es el río) y pirámides lejanas más allá
  del anillo. Todo en `data/map_layout.json`, sin tocar código de Godot.
- Palmera rehecha con penacho de hojas caídas en dos segmentos (antes era un
  palo con un splat verde).
- Parcelas de cultivo ahora muestran un marco visible aunque no estén aradas
  (`farm_plot.gd` + `assets/textures/plot_marker.png`), así se nota que es
  tierra de labranza desde el primer vistazo.
- Verificado con capturas reales: la granja ahora se ve como una granja
  (rejilla de parcelas), la orilla se ve poblada, y se ven dunas en el
  horizonte. Quedó pendiente confirmar visualmente que las pirámides
  lejanas se vean bien (sesión cortada por límite de tiempo, ver PROGRESS.md).

## Punto 4 resuelto: la noche roja no era de paleta, era del fog (PROMPT_PULIDO.md)
- Causa raíz real, encontrada imprimiendo los valores de luz/ambiente en
  plena captura y comparándolos contra el píxel final: los colores de
  `day_night_controller.gd` SÍ eran azul/violeta correctos en todo momento,
  pero `Environment.fog_aerial_perspective` y `fog_sky_affect` (que hacen
  que la niebla "respire" el color del cielo/sol como en una atmósfera
  real) estaban tomando el disco del sol/cielo y mezclándolo con demasiada
  fuerza, inyectando un cálido/rojizo por encima de todo lo demás sin que
  se notara en los valores de `fog_light_color` (que sí eran correctos).
  Puesto ambos en 0 en `scenes/world/Farm.tscn`: la niebla ahora solo usa
  el color plano que le da `fog_light_color` (correcto, sigue el ciclo),
  sin "broma" atmosférica extra. Además se agregó un transition timer fijo
  de 4s en vez de animar a lo largo de toda la fase (ver nota anterior) y
  se cambió `tonemap_mode` de Filmic a Linear (los tonemappers cinemático
  tienden a "calentar" las sombras muy oscuras, otro contribuyente menor).
- `day_night_controller.gd::snap_to_current_phase()` nuevo, usado por
  `tools/capture.gd` para que las capturas muestren el look ya asentado de
  cada fase en vez de a mitad de transición.

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

## Texturas de terreno: manchas suaves en vez de ruido (punto 1 de PROMPT_PULIDO.md)
- El "ruido de estática de TV" en pasto/arena/necrópolis venía de mezclar un
  color base con un color "claro" casi blanco (`sand_light`) en puntos
  sueltos de alto contraste. Rehecho con un campo de ruido de baja
  resolución (grilla 6x6) mosaiqueado 3x3 y escalado con interpolación
  bicúbica (`tools/gen_terrain.py::organic_patches`), que da manchas
  orgánicas y grandes en vez de grano; encima solo un puñado de detalles
  sueltos (piedritas/briznas) muy espaciados, nunca por todo el tile.
- Se ve un patrón hexagonal muy sutil al repetir el tile varias veces (es
  el artefacto típico de escalar una grilla 6x6 con bicúbica); a la escala
  real del juego (tile de 2m visto en perspectiva) no se nota como
  problema, pero si hiciera falta más adelante, subir `low_res` de 6 a 8-10
  lo suaviza más a costa de manchas más chicas.

## Exportación a Windows
- Instalé las plantillas de exportación oficiales de Godot 4.7.2 (descarga
  desde GitHub Releases del propio motor, gratis) y armé un
  `export_presets.cfg` mínimo para "Windows Desktop" (arquitectura x86_64,
  PCK embebido). `build/ScalesOfAnubis.exe` queda commiteado fuera de git
  (`.gitignore`) porque es un binario de ~100MB regenerable con
  `godot --headless --export-release "Windows Desktop" build/ScalesOfAnubis.exe`;
  lo importante es que el archivo exista en el disco para que abras el
  juego mañana con doble clic, no que viva en el historial de git.

## Sesión en la nube (Linux) — bugs reportados por Deivid jugando
- **Diálogo en bucle**: causa confirmada con una prueba automatizada
  (`tools/tests/test_dialogue.tscn`) que falla sin el arreglo y pasa con
  él. La caja de diálogo consumía la E en `_unhandled_input` y quitaba la
  pausa, pero en ese mismo frame `player.gd` leía
  `Input.is_action_just_pressed("interact")` y volvía a abrir la
  conversación. Arreglo: `GameState.lock_player_input(0.25)` al cerrar un
  diálogo; el jugador ignora interactuar/atacar mientras
  `GameState.player_input_locked()` sea verdadero. Se eligió un bloqueo
  corto por tiempo (y no "consumir" el input) porque `Input` es global y el
  estado just_pressed no se puede borrar de forma fiable desde un nodo.
- **Sonidos demasiado fuertes**: todos los SFX se normalizan en
  `tools/gen_sfx.py::save_wav` a un pico de -12 dBFS (antes 0 dBFS). La
  música se normaliza a -6 dBFS de pico en `tools/gen_music.py`, así queda
  un poco por encima de los efectos. `till` rehecho: un golpe grave de
  seno (115→42 Hz) con un poco de ruido filtrado pasa-bajos, en vez de ruido
  blanco. `SFX.play()` aplica ±6 % de variación aleatoria de tono.
- El panel "DEBUG teclado" que mencionaba CLAUDE_NUBE.md no existe en el
  repositorio (se buscó "debug" en `scripts/` y `scenes/`): probablemente
  fue una prueba local que nunca se commiteó. No hubo nada que borrar.

## Capturas con Forward+ en la nube
- Además del renderer de compatibilidad (OpenGL) que sugería CLAUDE_NUBE.md,
  instalé `mesa-vulkan-drivers` (lavapipe, Vulkan por software, gratis) y
  las capturas corren con `--rendering-driver vulkan` = **Forward+**, el
  mismo renderer que usa el PC de Deivid. Así las sombras, el SSAO, la
  niebla y el glow se ven como allá (solo más lento). Script local `cap`.

## Pirámides lejanas y borde del mundo (punto 1 pendiente)
- Revisadas en captura: se veían como montañas gris azuladas flotando sobre
  el vacío (no había suelo más allá del mapa). Ahora: plano de desierto
  exterior de 520 m bajo el mapa, y 7 pirámides con 4 caras planas de
  caliza (el sol ilumina un lado y el otro queda en sombra), dos con
  piramidión dorado. Datos en `data/map_layout.json → horizonte`
  (regenerable con `tools/gen_horizon.py`, idempotente).

## Punto 3: vida y movimiento
- Shaders propios en `assets/shaders/`: `terrain` (textura + sombras de
  nubes que pasan), `water` (Nilo con ondas que corren con la corriente,
  crestas, destellos y espuma en la orilla), `wind_foliage` (juncos,
  papiros, palmeras, flores, pasto alto: se doblan según la altura, con
  ráfagas que recorren el mapa), `grass_blades` (MultiMesh de ~2000
  mechones de pasto con viento) y `sprite_wind` (cultivos).
- Dos *shader globals* en `project.godot`: `wind_strength` y
  `cloud_shadow_strength` (el ciclo día/noche apaga las nubes de noche).
- Campo de cultivo más chico (9×7 + orilla 2×10) y con **tierra negra del
  Nilo** en vez de pasto con cuadrícula: antes el campo ocupaba toda la
  pantalla y parecía un piso de baldosas verdes. El resto es pasto con
  viento. Las palmeras que quedaban dentro de las parcelas se movieron.
- Pasto más cálido (paleta `grass*`): el `nile_green` anterior se veía menta.
- Cultivos redibujados tallo por tallo (`tools/gen_foliage.py`, 24×32 por
  etapa), dos filas por parcela, sin contorno (el contorno empastaba los
  tallos finos: en su lugar, sombra de contacto en la base).
- La orilla ahora tiene colisión: antes se podía caminar sobre el Nilo.
- Luz ambiental por color propio en vez de tomarla del cielo: el radiance
  del cielo se actualiza con retraso y la noche quedaba teñida de rojo
  varios segundos después del atardecer (se vio en capturas en serie).
  Atardecer menos saturado.
- `AmbientFX`: polvo de día, luciérnagas de noche, hojas al viento, bandadas
  de ibis (el animal de Thot) volando bajo sobre los campos, peces que
  saltan del Nilo con salpicadura. `CharacterFX`: sombra circular bajo cada
  personaje, respiración de 1 px en idle, polvo al caminar y al esquivar.
- Verificado con 4 frames seguidos: miles de píxeles cambian entre frames
  (viento/agua/partículas se mueven).

## Hitos del GDD (sesión en la nube)
- **Infraestructura**: `ChoiceBox` (menú de opciones modal, W/S/E o
  mouse), comentarios de Thot que **no pausan** (`ThotBark`, arriba al
  centro, bajo la balanza, para no tapar la acción), `StoryDirector`
  (estructura de 3 días y eventos), `GameState.reset()` (antes "salir al
  menú + nueva partida" arrastraba el estado anterior porque los autoloads
  sobreviven al cambio de escena).
- **Oleadas por datos** en `data/waves.json`, puntos de aparición en el
  mapa (desierto, necrópolis, noreste, sur) como pide el GDD 6.4, con
  indicadores en el borde de la pantalla.
- **Decisión moral 2 (noche 2)**: 6 sombras van a saquear el centro de la
  aldea mientras crías van a tus cultivos. No hay menú: la decisión es
  adónde vas. Si al amanecer la aldea no fue saqueada (daño < 14) y
  venciste al menos la mitad de los saqueadores → "defendiste la aldea"
  (−10 peso); si no → "salvaste tus cultivos" (+8 peso). Meret reacciona al
  día siguiente. Elegí medirlo por resultado (y no por un botón) porque el
  GDD la plantea como "la aldea y tus cultivos son atacados a la vez".
- **Decisión moral 1** ahora es una elección explícita en el altar (tomar
  la ofrenda / dejarla); dejarla da −2 de peso.
- **Defensas**: 5 pedestales (4 junto al campo, 1 en la aldea, útil para la
  noche 2). Estatua de chacal 30 deben (dispara proyectiles dorados, ojos
  que brillan), brasero sagrado 18 deben (quema en área, ilumina). El
  muro de adobe queda para después (opcional en el GDD).
- **Heraldo de Ammit**: sprite rehecho (el anterior parecía una oveja):
  cabeza de cocodrilo, delantera de león, trasera de hipopótamo. Embestida
  con franja de aviso en el suelo, rugido que invoca crías, golpe de área
  con círculo de aviso que crece, segunda fase al 50 % (más rápido), más
  daño si le pegas mientras se recupera de la embestida. Barra grande con
  nombre y música de jefe. Retiene la noche (`GameTime.hold_night`).
- **Estructura de 3 días**: intro en el Duat (balanza que duda y queda
  exacta, Anubis habla), tutorial por comentarios de Thot, resumen del
  amanecer, Meret da el escarabajo el día 3 (antes lo tenías desde el
  inicio), final con pesaje según el peso real, recuerdo del ba (niño con
  los ojos de Iry, en sepia) y pantalla de gracias con estadísticas y
  decisiones.
- **Derrota** (antes no pasaba nada al llegar a 0 de vida): fundido,
  Anubis te devuelve a la granja. De noche normal: pierdes 25 % del deben y
  amanece. Contra el jefe: reintento con el jefe a vida llena.
- **Semillas**: inventario de semillas (empiezas con 8 trigo, 3 lino, 2
  papiro), 1/2/3 eligen semilla de día (de noche eligen arma), Ptahmose
  vende packs de 3. **El lino ya es plantable** y la misión de Meret pide
  lino de verdad (3 manojos). Lino y papiro rinden 2 por parcela porque
  tardan dos días. Ptahmose no compra tu lino mientras la misión de Meret
  siga abierta, para no venderte tu propia misión sin querer.
- **Combate**: combo de 3 golpes del khopesh (el 3.º pega más), martillo en
  área que aturde, arco de corte visible, buffer de clic, empuje real que
  decae (antes duraba un frame), i-frames breves al recibir daño, aviso
  visible antes de cada golpe enemigo (se tiñen de rojo y se agachan: si te
  alejas o esquivas, fallan), enemigos que no se apilan, aparición desde el
  suelo, se desvanecen al amanecer. Transformación de herramientas al
  anochecer con destello y partículas.
- El códice suma "Kemet" y "Heraldo de Ammit"; esta última dice
  explícitamente que es ficción del juego (GDD 12).
- Pruebas automatizadas: `tools/tests/test_demo.tscn` recorre los 3 días
  completos (granja, compra/venta, defensas, noches, ambas decisiones,
  Meret, jefe, derrota y final) y `test_story.tscn` la intro y el final.

## Audio (M10)
- Música rehecha: loops de 30–70 s (antes 2–8 s) con instrumentos
  sintetizados (arpa Karplus-Strong, ney, darbuka con ritmo maqsum de
  noche, sistro, bordón) en escala doble armónica. Tema propio para
  título/intro/final (autoload `MenuMusic`), día, noche y jefe (132 bpm).
  Los loops se cierran sin clic (eco y colocación circular + rampa final).
- Ambiente en el bus de efectos: viento, río y pájaros de día; grillos y
  viento de noche. Así el volumen de efectos de las opciones también lo
  controla.
- Como no puedo escuchar en la nube, verifiqué niveles (pico −6 dBFS la
  música, −12 los efectos, −15 los ambientes), continuidad en el punto de
  loop y espectrogramas. Si algo suena raro en tu PC, los parámetros están
  al principio de cada función en `tools/gen_music.py`.

## Después de los hitos (orden de CLAUDE.md)
- **Combate**: además de lo anterior, bastón (tecla 3 de noche): proyectil
  de energía hacia el mouse que atraviesa hasta 2 criaturas. El sprite de
  ataque muestra el khopesh para las tres armas (dibujar cada arma en cada
  frame no valía la pena frente al arco/proyectil que ya las distingue).
- **Claridad visual**: códice como rollo de papiro; caja de diálogo con
  marco; comentarios de Thot bajo la balanza.
- **Belleza del mapa**: casas de adobe egipcias; necrópolis con mastabas,
  estelas, pirámide escalonada, estatuas de Anubis y camino.
- **Muro de adobe**: tercera opción de los pedestales (10 deben), se orienta
  solo perpendicular al lado del campo por donde llegan las criaturas.
- **Mando**: stick izquierdo/cruceta mueven, stick derecho apunta, A
  interactúa, X ataca (o gatillo derecho), B esquiva (o gatillo izquierdo),
  Y amuleto, LB/RB cambian arma o semilla (también la rueda del mouse),
  Back abre el códice, Start pausa. La pista del HUD dice "[A]" si usas mando.
