# PROGRESS — Scales of Anubis (demo)

_Última actualización: sesión nocturna autónoma, 2026-09-26._

## Léeme primero
Trabajé toda la noche solo, tomando decisiones sin poder preguntarte (ver
`DECISIONES.md` para el detalle de cada una). Prioricé dejar **sólido y sin
errores el loop central** (mundo + movimiento + ciclo día/noche + granja +
combate + aldeanos + audio) con arte propio desde el minuto uno, en vez de
repartirme entre los 11 hitos y dejar todo a medias. Ver "Qué falta" abajo
para el plan recomendado de continuación. **Hay un .exe jugable en `build/
ScalesOfAnubis.exe`**, ya exportado y probado.

## Cómo ejecutar
- **Lo más rápido**: doble clic en `build\ScalesOfAnubis.exe`. Ya está
  exportado y probado (headless) sin errores.
- **Desde el editor**: abre el proyecto con Godot 4.7.2 (`project.godot` en
  la raíz; si no está instalado, `winget install GodotEngine.GodotEngine
  --version 4.7.2`) y dale a Play (F5). Arranca en el menú principal →
  "Nueva partida".
- Chequeo rápido sin ventana: `Godot_v4.7.2...console.exe --path . --headless
  res://scenes/world/Farm.tscn --quit-after 300`.

## Controles
- WASD: moverte · Mouse: apuntar (para el ángulo de ataque) · Clic izq.:
  atacar (de noche, con el arma equipada) · Espacio: esquivar (con i-frames) ·
  **E: interactuar** — con un aldeano abre diálogo; con la parcela de tierra
  frente a ti hace arar → sembrar → regar → cosechar, todo contextual con una
  sola tecla (ver Decisiones) · 1/2: cambiar arma equipada de noche (khopesh
  / martillo) · Q: equipar/ciclar amuleto (Anj / Escarabajo del corazón) ·
  Tab: códice (Libro de los Muertos) · Esc: pausa.

## Qué está hecho (jugable ahora mismo)
- **M0 — Base**: Godot 4.7.2 instalado, proyecto con render a 480×270 escalado
  (`stretch mode = viewport`), filtro nearest, estructura de carpetas
  (`scenes/`, `scripts/`, `assets/`, `data/`, `tools/`).
- **M1 — Mundo y movimiento**: mapa completo generado por datos
  (`data/map_layout.json` → `scripts/world/world_builder.gd`): Nilo, franja
  verde, parcelas de granja (con zona de orilla para papiro), aldea, templo,
  necrópolis con obelisco y tumbas, muelle, palmeras, juncos, rocas en el
  desierto. Todo en geometría low-poly generada por script
  (`building_factory.gd`) con texturas pixeladas propias. Jugador con sprite
  2D (4 direcciones, idle/caminar/atacar) en billboard sobre el mundo 3D,
  movimiento WASD, colisiones, cámara diagonal con suavizado (`camera_rig.gd`).
- **M2 — Tiempo**: ciclo amanecer → día → atardecer → noche completo
  (`game_time.gd` autoload), con iluminación dinámica real (un
  `DirectionalLight3D` que hace de sol/luna, rotando y cambiando de color a
  lo largo del ciclo — ver `day_night_controller.gd`), sombras dinámicas
  activas, cielo con `ProceduralSkyMaterial` que también cambia de color.
  Reloj + fase + día visibles en el HUD.
- **M3 — Granja**: arar/sembrar/regar/cosechar funcionando por parcela
  (`farm_plot.gd`), trigo y papiro plantables (ver limitación de lino abajo),
  crecimiento por días reales del ciclo, inventario y deben en `GameState`.
  Falta la venta a Ptahmose (NPC no implementado todavía, ver abajo).
- **M4 — Combate**: herramientas transformadas conceptualmente en armas
  (khopesh rápido / martillo lento con más daño y empuje), ataque con clic,
  esquiva con i-frames, feedback (flash blanco al recibir daño, empuje,
  cooldowns). Enemigos: Sombra (lenta, ataca al jugador) y Cría de Ammit
  (rápida, prioriza atacar cultivos plantados) con IA simple de persecución
  directa. `night_director.gd` genera oleadas escaladas por día
  (noche 1 pocas sombras, noche 2 suma crías, noche 3+ oleada grande).
  Vida del jugador y de los enemigos con daño/muerte funcionando.
- **Arte propio**: paleta fija (`tools/palette.py`), generadores Python para
  personajes (jugador, Meret, Ptahmose, Iry), enemigos (sombra, cría,
  heraldo — sprite ya generado, falta implementarlo como jefe jugable),
  Thot, cultivos por etapa, iconos de UI/amuletos/herramientas, texturas de
  terreno/edificios y fondo de la pantalla de título. Nada de cubos grises.
- **UI base**: HUD (deben, reloj/fase/día, vida, peso del corazón con texto
  flotante +Isfet/−Maat), menú principal con opciones (volumen por bus,
  pantalla completa), pausa in-game.
- **Códice (Tab)**: ventana con las 10 entradas de `data/codex.json`,
  bloqueadas ("???") hasta desbloquearse por progreso real (matar un
  enemigo, cosechar, empezar una noche, sobrevivir a un día, hablar con
  Iry/Meret, arrancar la partida).
- **Amuletos (Q)**: Anj (regenera vida con el tiempo) y Escarabajo del
  corazón (revive una vez por noche) equipables y funcionando.
- **Balanza del corazón animada**: viga dorada que se inclina con
  suavizado (tween) según `GameState.heart_weight`, corazón y pluma en
  cada extremo, con el texto flotante +Isfet/−Maat ya existente.
- **Aldeanos con diálogo** (M6 parcial): Meret (misión de 3 cosechas para
  el templo, −8 peso), Ptahmose (compra toda la cosecha del inventario al
  precio de `data/crops.json`), Iry (diálogo con comentarios de Thot).
  Diálogo con máquina de escribir, pausa el juego mientras habla.
- **Decisión moral 1** (GDD 6.7): altar de ofrendas junto al templo, robable
  desde el día 2 con E (+20 deben, +10 peso del corazón, una sola vez).
- **Audio (M10 parcial)**: 12 SFX y 3 loops musicales (día/noche/jefe — el
  de jefe generado pero sin usar todavía, ver "Qué falta"), **toda síntesis
  propia** (`tools/gen_sfx.py`, `tools/gen_music.py`, numpy → WAV). Crossfade
  de música día/noche automático.
- **Exportado a Windows** (M11 parcial): plantillas de exportación
  instaladas y `build/ScalesOfAnubis.exe` generado y probado.
- **Datos centralizados**: `data/textos_es.json`, `data/crops.json`,
  `data/codex.json`, `data/dialogues.json`, `data/map_layout.json`.
- Verificado headless con Godot (`--headless ... --quit-after N`) después de
  **cada** cambio importante: ciclo día→noche completo con enemigos
  spawneando, las 3 conversaciones de NPC (incluida la misión de Meret y la
  venta a Ptahmose) y el `.exe` exportado — todo **sin errores ni
  warnings** en consola. Un warning real y un error real de GDScript
  aparecieron durante la sesión y se corrigieron en el momento gracias a
  este chequeo (ver historial de commits).

## Más "jugo" (juice) en granja y combate
- Esquivar ahora se ve (el sprite se vuelve semitransparente mientras dura
  la invulnerabilidad), no solo se siente.
- Los enemigos ya no desaparecen de golpe al morir: se desvanecen y flotan
  un poco antes de irse, con una pequeña explosión de partículas.
- Arar, regar, cosechar y que te destruyan un cultivo ahora sueltan un
  estallido de partículas del color correspondiente (tierra, agua, oro,
  hojas), además del sonido que ya tenían.
- Probado headless con el ciclo arar→sembrar→regar→cosechar completo, el
  desvanecido al esquivar y la muerte de un enemigo: todo sin errores.

## Sensación de combate (GDD 6.3: "feedback obligatorio")
- **Hit-stop** real (breve congelamiento de `Engine.time_scale` al conectar
  un golpe), **sacudida de cámara** (`camera_rig.gd::shake()`), **números
  de daño flotantes** y **partículas de impacto** (`scripts/fx/combat_fx.gd`),
  tanto cuando el jugador golpea como cuando lo golpean a él (número rojo).
  Antes solo había flash blanco + empuje + sonido; ahora están los 5
  elementos que pide el GDD.
- **El ataque ahora apunta hacia el mouse** (`_aim_at_mouse()`), no hacia la
  última dirección en la que caminaste — así lo pide el GDD 6.3/10 y antes
  no se respetaba (usaba la dirección de movimiento).
- Probado headless forzando la noche e invocando el ataque directamente:
  el daño se aplica, el `time_scale` se restaura solo a 1.0, sin errores.

## Pase de pulido visual (después de que Deivid pidió seguir mejorando el aspecto)
- **Sprites con contorno y sombreado** (`tools/postfx.py`): todos los
  personajes, enemigos, Thot y cultivos ahora tienen un contorno oscuro de
  1px y un sombreado vertical suave — ya no son bloques de color plano.
- **Siluetas distintas por personaje**: Meret (tocado + cuello dorado),
  Ptahmose (turbante + panza de comerciante), Iry (proporciones de niño,
  reescalado y anclado al suelo, no solo un adulto encogido a la fuerza).
- **Antorchas con luz cálida parpadeante** (`scripts/world/torch.gd`) en
  casas, templo y altar — de noche la aldea ahora tiene puntos de luz real,
  no solo la luna. Casas con ventana añadida.
- **Vegetación dispersa**: matojos de pasto esparcidos por la franja verde
  (fuera de las parcelas de cultivo) para que el mapa no se vea vacío.
- **Ambiente**: niebla de distancia, SSAO, glow y ajuste de
  contraste/saturación en el `WorldEnvironment`, con el color de la niebla
  siguiendo el ciclo día/noche.
- **Tipografía propia**: fuente pixel "Silkscreen" (OFL, Google Fonts,
  ver CREDITS.md) en toda la interfaz en vez de la fuente por defecto de
  Godot. Cubre los caracteres del español.
- **Retratos de diálogo**: cada línea de diálogo muestra el retrato de
  quien habla (jugador, Meret, Ptahmose, Iry, Thot), detectado
  automáticamente por el nombre al inicio de la línea.
- **Iconos del códice corregidos**: varias entradas mostraban la hoja de
  sprites entera encogida (se veía como ruido); ahora usan un solo frame
  recortado (`tools/gen_portraits.py` → `crop_codex_icons`).
- Terreno regenerado a mayor resolución (48×48) con ruido en grumos en vez
  de grano fino uniforme, y patrones ajustados para que sigan siendo
  perfectamente tileables.
- Todo esto verificado headless en cada paso (incluida una prueba forzada
  del códice con las 10 entradas desbloqueadas y otra de los 3 diálogos con
  retrato), y dos errores reales de GDScript se encontraron y corrigieron
  en el momento (inferencia de tipo en `world_builder.gd` con datos de
  JSON sin tipar).
- **Pendiente de que Deivid lo vea en pantalla**: no pude verificar
  visualmente en una ventana real (solo con capturas de los sprites sueltos
  y chequeos headless sin errores). Si algún texto se ve muy chico/grande
  con la fuente nueva, o algún panel se ve corrido, es lo primero a ajustar
  — son casi seguro solo números de tamaño/posición, no bugs de lógica.

## Qué falta (próximos pasos recomendados, en orden)
1. **Decisión moral 2** (defender aldea vs. cultivos, noche 2): no
   implementada — requiere un evento de noche con dos amenazas simultáneas,
   más ambicioso que la decisión 1. La **decisión moral 1 ya está
   implementada**: altar de ofrendas cerca del templo (`scripts/world/altar.gd`),
   robable con E desde el día 2 (+20 deben, +10 peso del corazón, una sola
   vez; antes del día 2 Thot te lo impide con un comentario). Probado
   headless: día 1 bloqueado, día 2 roba correctamente, segundo intento no
   hace nada.
2. **Defensas** (estatua de chacal, brasero): no implementadas.
3. **Heraldo de Ammit (jefe)**: sprite ya generado
   (`assets/sprites/enemies/heraldo.png`) y tema musical listo
   (`assets/audio/music/jefe.wav`), pero sin escena/IA de jefe todavía.
4. **Estructura narrativa de 3 días completa** (intro del juicio, resumen del
   amanecer con cultivos perdidos/enemigos derrotados —el dato ya se cuenta
   en `GameState.crops_lost_tonight`/`enemies_defeated_tonight`—, pesaje
   final, recuerdo del ba, pantalla de gracias): no implementado.
5. **Cayado/bastón, muro de adobe, soporte de mando, guardado de partida**:
   quedan para después, como indica el CLAUDE.md.
6. **Pase de arte (M9)**: reemplazar el pixel art generado proceduralmente
   por arte pulido a mano, fuente pixel-perfect propia (hoy es la fuente por
   defecto de Godot), retratos de diálogo (hoy solo hay nombre + texto).

## Simplificaciones y decisiones tomadas (detalle completo en DECISIONES.md)
- **Sembrar es automático**: la tecla E hace todo el ciclo de la parcela de
  forma contextual (arar si está sin trabajar, sembrar si está arada,
  regar/cosechar si corresponde), sin selección manual de semilla ni compra
  de semillas a Ptahmose. **Lino no es plantable en esta demo** (solo trigo
  en tierra normal y papiro en la orilla) para no bloquear el loop con un
  sistema de selección de semillas sin terminar. Es la simplificación más
  importante que tomé; si prefieres el sistema completo (comprar semillas,
  elegir cuál sembrar), es el primer cambio que yo haría con más tiempo.
- Duración del ciclo día/noche comprimida respecto al GDD (día ~150s + noche
  ~100s en vez de ~6min/~3-4min reales) para que una demo de 3 días dure
  razonable en una sola sesión de prueba; es trivial ajustar en
  `scripts/autoload/game_time.gd` (constantes al inicio del archivo).
- Enemigos usan persecución directa (sin navmesh/pathfinding): funciona bien
  en el campo abierto de la granja pero pueden trabarse contra edificios de
  la aldea/necrópolis si el spawn los manda por ahí. No es un problema en el
  área de granja donde ocurren las oleadas.

## Problemas conocidos
- El menú de pausa y el de opciones son funcionales pero sin pase de arte
  (fuente por defecto de Godot, sin fondo propio en pausa).
- No hay retratos de diálogo (solo nombre + texto).
- Enemigos usan persecución directa sin pathfinding (ver Decisiones): en el
  campo abierto de la granja no se nota, pero si un spawn los manda cerca de
  un edificio de la aldea/necrópolis podrían trabarse contra la geometría.
- El tema musical de jefe (`jefe.wav`) está generado pero no se activa
  todavía (no hay jefe implementado aún).
- Lino no es plantable por el jugador (ver Decisiones: simplificación del
  sistema de semillas). Meret acepta trigo/papiro en su lugar y el propio
  diálogo lo comenta con humor.
