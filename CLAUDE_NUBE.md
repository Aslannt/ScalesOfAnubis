# Sesión en la nube — Scales of Anubis

Esta sesión corre en una **máquina Linux en la nube**, no en el PC de Deivid. Lee primero `CLAUDE.md`, `GDD.md`, `PROGRESS.md`, `DECISIONES.md` y `PROMPT_PULIDO.md`. Las reglas de `CLAUDE.md` siguen vigentes, con estos cambios:

## Qué cambia respecto a CLAUDE.md
- **Sistema**: Linux, no Windows. Nada de winget. Ignora lo de cerrar programas o cambiar configuraciones de Windows.
- **Godot**: descarga Godot 4.7.2 para Linux desde los releases oficiales de GitHub (`Godot_v4.7.2-stable_linux.x86_64.zip`) y sus plantillas de exportación (`Godot_v4.7.2-stable_export_templates.tpz`, que se instalan en `~/.local/share/godot/export_templates/4.7.2.stable/`). Usa la misma versión 4.7.2 que el proyecto.
- **Capturas con ventana**: no hay pantalla, así que usa `xvfb-run` con el renderer de compatibilidad:
  `xvfb-run -s "-screen 0 1280x720x24" ./Godot_v4.7.2-stable_linux.x86_64 --path . --rendering-driver opengl3 res://capture.tscn`
  Esto ya se probó y funciona. Ojo: sin GPU real el cielo, las sombras y el SSAO se ven más simples que en el PC de Deivid; juzga texturas, composición, HUD, colores y animación, no la calidad exacta de la iluminación.
- **Sigue siendo obligatorio** generar capturas y mirarlas antes de cada commit visual. Para las animaciones (viento, agua, partículas), guarda 3–4 frames seguidos y compáralos para confirmar que hay movimiento.
- **Exportar para Windows**: Godot en Linux exporta el `.exe` de Windows con el preset que ya existe. No lo subas al repositorio (`build/` está en .gitignore): Deivid lo exporta en su PC con el editor.
- **Git**: haz commit y **push** a la rama de la sesión después de cada punto terminado, para que nada se pierda si la sesión se corta. Nunca reescribas el historial.
- **Saltos de línea**: el repo viene de Windows. No conviertas los finales de línea de archivos que no tocaste, para que los diffs muestren solo cambios reales.

## Qué hacer
0. **Primero, dos bugs que Deivid encontró jugando**. Arréglalos antes que nada y verifícalos con una prueba automatizada:
   - **Diálogo en bucle**: al terminar una conversación con un NPC, se vuelve a abrir sola y no se puede salir. Causa probable: `dialogue_box.gd` cierra el diálogo con la tecla E dentro de `_unhandled_input` y quita la pausa, pero `player.gd` lee `Input.is_action_just_pressed("interact")` en su propio proceso, en ese mismo frame, y vuelve a llamar a `npc.interact()`. Solución: que el jugador ignore la tecla de interactuar durante unos 0,2 s después de cerrar un diálogo (o que consuma el input de forma que no se duplique). Prueba el caso: hablar, avanzar todas las líneas con E y confirmar que el diálogo se cierra y el jugador puede moverse.
   - **Sonidos demasiado fuertes**, sobre todo arar con E (`till.wav`). Todos los SFX están normalizados al 100% (pico de 32767), sin mezcla. Normaliza todos los efectos a un pico de alrededor de -12 dBFS en `tools/gen_sfx.py`, suaviza `till` (menos ruido blanco, más un golpe de tierra grave y corto), añade una pequeña variación aleatoria de tono en `SFX.play()` para que no suene repetitivo, y deja la música un poco por encima de los efectos.
   - Si en `scripts/ui/hud.gd` queda algún panel de diagnóstico de teclado ("DEBUG teclado"), elimínalo.
1. Continúa `PROMPT_PULIDO.md` exactamente donde quedó, según la sección "Falta" de `PROGRESS.md`: pirámides lejanas → viento/agua/ambiente (punto 3) → HUD (punto 5) → Thot (punto 6) → menú (punto 7) → cielo (punto 8).
2. Después sigue con los hitos pendientes del GDD, en este orden: decisión moral 2 → defensas (estatua de chacal y brasero) → Heraldo de Ammit (jefe, el sprite y la música ya existen) → estructura de 3 días completa (intro del juicio, resumen del amanecer, pesaje final, recuerdo del ba, pantalla de gracias) → sistema de semillas con lino plantable → pulido de combate.
3. Al final: set de capturas finales en `shots/` (día, atardecer, noche, aldea, combate, menú). Súbelo en una carpeta `capturas_finales/` (esa sí se commitea) para que Deivid las vea en GitHub desde el celular. Actualiza `PROGRESS.md` con qué se hizo y cómo probarlo.

Trabaja sin preguntar, como en la sesión anterior. Decide lo razonable y anótalo en `DECISIONES.md`.
