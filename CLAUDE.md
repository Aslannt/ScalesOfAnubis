# Instrucciones para Claude Code — Scales of Anubis

Vas a construir la **demo jugable** del juego descrito en `GDD.md`. Léelo completo antes de empezar.

## Situación
- El usuario (Deivid) se fue a dormir. **Trabajas solo toda la noche. No hay nadie para responder preguntas.**
- **No preguntes nada.** Cuando haya una duda, toma la decisión más razonable según el GDD, anótala en `DECISIONES.md` y sigue.
- Meta: que mañana abra el juego y le **dé gusto verlo y jugarlo**. Calidad comercial, profesional, pulida. Prefiere una demo más corta pero pulida y sin bugs, antes que muchas funciones a medias.

## Entorno
- Windows. Ryzen 5 5600, RTX 3060 12 GB, 32 GB RAM. Sobra potencia para Godot.
- Motor: **Godot 4** (última versión estable), GDScript.
- Todo debe ser **gratuito**. Nada de servicios de pago, APIs de pago ni pruebas gratuitas.
- Puedes instalar software gratuito que necesites (Godot, plantillas de exportación, Git, Python, librerías de pip, herramientas de audio/imagen libres) con winget, pip o descarga oficial.

## Reglas de seguridad (no negociables)
- Trabaja **solo dentro de la carpeta del proyecto**. No borres ni modifiques archivos fuera de ella.
- No cierres procesos del sistema ni programas ajenos al proyecto. El usuario ya cerró lo suyo antes de dormir.
- No cambies configuraciones de Windows, drivers ni el registro.
- Git: haz commit al terminar cada hito y cada vez que algo funcione. Nunca reescribas el historial.

## Forma de trabajo
1. Hitos en orden (abajo). Cada hito debe terminar **jugable y sin errores**.
2. Después de cada cambio importante, ejecuta Godot en modo headless para detectar errores de scripts y escenas. Corrige todo error y warning relevante antes de seguir.
3. Mantén `PROGRESS.md` actualizado: qué se hizo, qué falta, problemas conocidos, cómo jugar. Es lo primero que Deivid leerá mañana.
4. Si algo se traba más de ~30 minutos, anota el problema, busca una solución más simple y sigue. No te quedes atascado.
5. Código limpio y ordenado por carpetas (`scenes/`, `scripts/`, `assets/`, `data/`). Datos del juego (cultivos, enemigos, diálogos, códice) en archivos de datos, no quemados en el código.
6. Textos del juego en español, centralizados para traducir después.

## Arte y audio (gratis)
- **Nunca cubos grises feos**, ni siquiera como placeholder: desde el primer hito usa la paleta del GDD y formas con intención.
- Genera tu propio pixel art con scripts (por ejemplo Python + Pillow) usando **una paleta fija** para que todo sea coherente: sprites de personajes en 4 direcciones con animaciones (idle, caminar, atacar), enemigos, cultivos por etapa, íconos, retratos, texturas pixeladas para el terreno y edificios.
- Geometría 3D low-poly construida en Godot o generada por script (pirámides, obeliscos, columnas, casas de adobe, templo).
- Puedes usar assets **CC0** (por ejemplo Kenney.nl) si calzan con el estilo. Registra toda fuente y licencia en `CREDITS.md`.
- SFX y música: genera tus propios sonidos (síntesis por script, estilo sfxr) y loops musicales simples con escala de sonido egipcio/oriental. Solo material propio o CC0.

## Hitos
- **M0 — Base**: instalar Godot 4 y Git, crear proyecto, estructura de carpetas, pipeline de render a baja resolución escalada (look pixelado), escena de prueba corriendo.
- **M1 — Mundo y movimiento**: mapa de la granja (Nilo, parcelas, aldea, necrópolis, desierto), jugador como sprite en el mundo 3D, movimiento con WASD, cámara en diagonal con suavizado, colisiones.
- **M2 — Tiempo**: ciclo día → atardecer → noche → amanecer, reloj en HUD, iluminación dinámica (este es el alma del look).
- **M3 — Granja**: arar, sembrar, regar, crecer por días, cosechar; inventario; deben; venta a Ptahmose.
- **M4 — Combate**: transformación de herramientas al anochecer, khopesh y martillo, esquiva, sombras y crías de Ammit, oleadas, daño a cultivos, vida y derrota. Mucho feedback (hit-stop, flash, shake, partículas, sonido).
- **M5 — Corazón y progresión**: balanza del corazón con UI animada, altar de ofrendas, amuletos (Anj, Escarabajo), defensas (estatua de chacal, brasero).
- **M6 — Aldea**: Meret, Ptahmose e Iry con diálogos, misiones y las dos decisiones morales.
- **M7 — Thot y códice**: Thot siguiendo al jugador, comentarios contextuales, tutorial integrado, códice con las entradas del GDD (solo lore de la sección 12).
- **M8 — Demo completa**: intro del juicio, estructura de 3 días, jefe Heraldo de Ammit, pesaje final, recuerdo del ba, pantalla de gracias. Menú principal, pausa, opciones.
- **M9 — Pase de arte**: reemplazar todo lo provisional por pixel art coherente, retratos de diálogo, efectos de luz y partículas, pantalla de título atractiva.
- **M10 — Audio**: música por fase y jefe, SFX completos, volumen en opciones.
- **M11 — Pulido y entrega**: jugar la demo de principio a fin varias veces (simulando con pruebas automatizadas donde se pueda), balancear, corregir bugs, **exportar un .exe para Windows** en `build/`, y dejar en `PROGRESS.md` cómo jugarlo.

Si terminas todo, sigue mejorando en este orden: sensación del combate → claridad visual → belleza del mapa → cayado/bastón → muro de adobe → soporte de mando → guardado de partida.

## Al terminar o si se acaba el tiempo
Deja todo commiteado, el juego abriendo sin errores, y `PROGRESS.md` con: resumen de lo logrado, cómo ejecutar, controles, problemas conocidos y próximos pasos recomendados.
