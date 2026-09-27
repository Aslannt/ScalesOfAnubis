# Guía de playtest — Scales of Anubis

Lo que más mejora un juego es ver a otras personas jugarlo. Esta guía es
para cuando se lo pases a amigos o familia.

## Antes de empezar
1. Exporta el `.exe` (Godot → Proyecto → Exportar… → Windows Desktop) o
   dales la carpeta `build/`.
2. Pídeles que empiecen con **Nueva partida** y que jueguen solos.
3. Si pueden, graba la pantalla (Win + G abre la grabadora de Windows) o
   siéntate detrás en silencio.

## Mientras juegan: las reglas de oro
- **No los ayudes.** Si se traban, anota dónde y cuánto tiempo pasó. Solo
  intervén si llevan más de 2 o 3 minutos atascados sin avanzar.
- **No expliques nada.** Si algo necesita explicación, el juego tiene que
  darla (y eso es un hallazgo).
- Anota las **caras**: dónde sonríen, dónde se aburren, dónde se frustran.

## Qué observar (marca lo que veas)
- [ ] ¿Entienden la historia de la intro sin preguntar? ¿Saben qué es la balanza?
- [ ] ¿Descubren solos cómo arar, sembrar y regar?
- [ ] ¿Encuentran la aldea y hablan con los tres aldeanos el día 1?
- [ ] ¿Se preparan antes de la primera noche?
- [ ] ¿El combate se siente bien? ¿Cambian de arma (1/2/3)?
- [ ] ¿Notan cuando una cría se está comiendo un cultivo?
- [ ] ¿Construyen defensas? ¿Entienden los niveles y los "???"?
- [ ] ¿Se dan cuenta de que la balanza cambia cómo juegan (Maat / Ammit)?
- [ ] ¿Qué hacen en la decisión del altar y en la noche 2?
- [ ] ¿Charlan y hacen regalos? ¿Descubren la restauración del templo?
- [ ] ¿El Heraldo es difícil, fácil o injusto?
- [ ] ¿Quieren seguir en el modo libre después del final?

## Al terminar: 5 preguntas (en este orden)
1. ¿Qué fue lo que más te gustó?
2. ¿En qué momento te aburriste o no sabías qué hacer?
3. ¿Qué te confundió?
4. Si pudieras cambiar una sola cosa, ¿cuál sería?
5. Del 1 al 10, ¿lo recomendarías a un amigo? ¿Por qué ese número?

## El registro automático
El juego guarda un registro de cada partida (solo en esa computadora, no
se envía a ningún lado):

`%APPDATA%\Godot\app_userdata\Scales of Anubis\playtest\partida_<fecha>.log`

Cada línea dice el minuto, el día y lo que pasó: cuándo empieza cada día y
noche, muertes (y dónde), cultivos perdidos, cambios de la balanza,
defensas, mejoras, amistad, templo, estaciones y **cuándo el jugador se
quedó quieto más de 45 segundos de día** (casi siempre significa "no sé qué
hacer"). Mándamelo junto con tus notas y lo usamos para ajustar el juego.

## Probar el juego automáticamente
`bash tools/correr_pruebas.sh` corre las 8 pruebas automáticas (en Git Bash
dentro de la carpeta del proyecto). Si Godot no está en el PATH:

```
GODOT="/c/ruta/a/Godot_v4.7.2-stable_win64_console.exe" bash tools/correr_pruebas.sh
```
