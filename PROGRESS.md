# PROGRESS — Scales of Anubis (demo)

_Última actualización: sesión nocturna autónoma, 2026-09-26._

## Léeme primero
Trabajé toda la noche solo, tomando decisiones sin poder preguntarte (ver
`DECISIONES.md` para el detalle de cada una). Prioricé dejar **sólido y sin
errores el loop central** (mundo + movimiento + ciclo día/noche + granja +
combate) con arte propio desde el minuto uno, en vez de repartirme entre los
11 hitos y dejar todo a medias. Ver la sección "Qué falta" abajo para el plan
recomendado de continuación.

## Cómo ejecutar
1. Abre el proyecto con Godot 4.7.2 (`project.godot` en la raíz), o instala
   Godot si hace falta (`winget install GodotEngine.GodotEngine --version 4.7.2`).
2. Play (F5). Arranca en el menú principal → "Nueva partida".
3. También puedes correr `Godot_v4.7.2...console.exe --path . --headless res://scenes/world/Farm.tscn --quit-after 300` para un chequeo rápido sin ventana.

## Controles
- WASD: moverte · Mouse: apuntar (para el ángulo de ataque) · Clic izq.:
  atacar (de noche, con el arma equipada) · Espacio: esquivar (con i-frames) ·
  **E: interactuar con la parcela de tierra frente a ti** (arar → sembrar →
  regar → cosechar, todo contextual con una sola tecla — ver Decisiones) ·
  1/2: cambiar arma equipada de noche (khopesh / martillo) · Esc: pausa.
- Tab (códice) y Q (amuleto) están mapeados en el input map pero **sin UI
  todavía** (ver "Qué falta").

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
- **Datos centralizados**: `data/textos_es.json` (textos en español para
  traducir después), `data/crops.json`, `data/codex.json` (10 entradas de
  lore verificado, listas para mostrarse — falta la UI del códice),
  `data/map_layout.json`.
- Verificado headless con Godot (`--headless ... --quit-after N`) corriendo
  el ciclo completo día→noche con enemigos spawneando: **sin errores ni
  warnings** en consola.

## Qué falta (próximos pasos recomendados, en orden)
1. **UI del códice (Tab)** y **UI/lógica de amuletos (Q)**: los datos ya
   existen (`Codex` autoload, `data/codex.json`), falta la ventana. Es la
   forma más rápida de sumar valor: los datos ya están.
2. **NPCs de la aldea con diálogo** (Meret, Ptahmose, Iry): sprites y
   posiciones en el mapa faltan (no están en `map_layout.json` props todavía);
   falta sistema de diálogo (retrato + máquina de escribir) y las 3 misiones
   /2 decisiones morales del GDD 6.7. Esto es la mayor pieza de contenido que
   falta y es prerequisito de la venta de cosechas.
3. **Balanza del corazón con UI animada** (M5): el dato (`GameState.heart_weight`,
   señal `heart_weight_changed`) y el texto flotante en el HUD ya funcionan;
   falta la balanza visual (ícono corazón/pluma inclinándose) — hoy es una
   barra simple.
4. **Altar de ofrendas y defensas** (estatua de chacal, brasero): no
   implementado.
5. **Heraldo de Ammit (jefe)**: sprite ya generado (`assets/sprites/enemies/heraldo.png`)
   pero sin escena/IA de jefe todavía.
6. **Estructura narrativa de 3 días completa** (intro del juicio, resumen del
   amanecer con cultivos perdidos/enemigos derrotados —el dato ya se cuenta
   en `GameState.crops_lost_tonight`/`enemies_defeated_tonight`—, pesaje
   final, recuerdo del ba, pantalla de gracias): no implementado.
7. **Audio (M10)**: no hay nada todavía, ni SFX ni música. Es lo único que
   no se tocó en absoluto. Recomiendo síntesis por script (numpy → WAV)
   como pide el CLAUDE.md.
8. **Cayado/bastón, muro de adobe, soporte de mando, guardado de partida**:
   quedan para después, como indica el CLAUDE.md.
9. **Exportar .exe** (M11): falta configurar `export_presets.cfg` e instalar
   las plantillas de exportación de Godot (`winget`/editor → Export Templates
   Manager) — no se hizo esta noche por falta de tiempo, no por dificultad.

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
- No hay plantillas de exportación instaladas todavía → no existe un `.exe`
  en `build/` esta noche. Ver punto 9 arriba.
- El menú de pausa y el de opciones son funcionales pero sin pase de arte
  (fuente por defecto de Godot, sin fondo propio en pausa).
- Sin música ni SFX: el juego es silencioso.
- Sin NPCs ni diálogos: se puede jugar el loop granja+combate pero no hay
  historia ni misiones todavía.
