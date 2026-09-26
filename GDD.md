# Scales of Anubis — Documento de Diseño (Demo)

> Nombre provisional. Farming + acción + defensa por oleadas, basado en mitología egipcia real.
> Referencias: Stardew Valley (granja, aldea, estaciones), God of War (acompañante que enseña mitología, peso narrativo), Guns 'n Goblins (defender tu base de oleadas nocturnas, mejoras de arsenal), Red Dead Redemption 2 (sistema moral), Octopath Traveler / Cult of the Lamb (sprites 2D en mundo 3D).

---

## 1. Pitch

Eres un campesino egipcio que murió. En el juicio de los muertos, tu corazón pesó **exactamente lo mismo** que la pluma de Maat: ni justo ni condenado. Nunca había pasado. Anubis te devuelve a la vida para que inclines la balanza con tus actos. Pero Ammit, la devoradora, no acepta quedarse sin su presa: **cada noche manda a sus criaturas a arrancarte el corazón.**

De día cultivas a orillas del Nilo, ayudas a la aldea y haces ofrendas. De noche defiendes tu granja con tus herramientas, que Anubis bendijo y que se transforman en armas. Mientras juegas, aprendes mitología egipcia real.

## 2. Pilares de diseño

1. **Todo alimenta a todo**: la granja da recursos para el combate, el combate protege la granja, y ambos mueven la balanza del corazón.
2. **Aprender sin clases**: la mitología se enseña por diálogos, objetos y mecánicas, nunca con muros de texto.
3. **Decisiones con peso**: actos buenos y malos tienen consecuencias visibles.
4. **Sensación comercial**: cada acción debe sentirse bien (feedback, sonido, partículas, animación).

## 3. Historia

- **Protagonista**: un campesino resucitado (nombre por definir; placeholder: *Nakht*, "fuerte"). No recuerda bien su vida pasada.
- **Motor narrativo**: tu corazón quedó empatado. Si al final pesa menos que la pluma, llegas a Aaru. Si pesa más, Ammit te devora.
- **Misterio central**: ¿por qué empató tu corazón? Thot lo sabe porque anotó el resultado del juicio, pero no puede decírtelo. Lo vas descubriendo con los **recuerdos de tu ba** (tu alma), que se desbloquean al avanzar.
- **Gancho de la demo**: el primer recuerdo del ba muestra a un niño… que se parece mucho a Iry.

## 4. Personajes

### Thot (acompañante)
- **Aspecto**: ibis pequeño, plumas blancas y negras, paleta de escriba colgada, pequeño disco lunar sobre la cabeza. De noche el disco brilla e ilumina alrededor del jugador.
- **Personalidad**: sabio, pedante, sarcástico, con cariño escondido. Corrige al jugador y a Iry cuando dicen datos mitológicos mal. Humor tipo Mímir de God of War.
- **Función**: tutorial integrado, narra historias al caminar, actualiza el códice, comenta lo que pasa en combate, reacciona a las decisiones morales.
- **Secreto**: estuvo en tu juicio.

### Anubis
- Aparece en la intro (resurrección) y en el altar. Solemne, pocas palabras, imponente. Dios de la momificación y protector de las necrópolis.

### Meret, sacerdotisa de Maat
- Cuida el templo pequeño de la aldea. Explica la balanza y da misiones. Desconfía de ti al principio (un muerto que camina es antinatural). Arco: ganarte su confianza.

### Ptahmose, comerciante del río
- Llega en barca. Compra cosechas, vende semillas, materiales y amuletos. Chismoso: trae rumores y leyendas de otras ciudades (otra fuente de mitología).

### Iry, niño huérfano
- Curioso, te sigue, le hace preguntas a Thot sobre los dioses (excusa para enseñar mitología). Conectado con tu vida pasada (gancho).

### Ammit (antagonista)
- La devoradora de corazones: cabeza de cocodrilo, cuerpo delantero de león, trasero de hipopótamo. En la demo no aparece en persona: solo sus criaturas y su heraldo.

## 5. Loop de juego

```
DÍA (≈ 6 min reales)                      NOCHE (≈ 3–4 min reales)
Sembrar / regar / cosechar                Oleadas de criaturas de Ammit
Vender a Ptahmose / comprar               Pelear con herramientas-arma
Misiones de la aldea                      Defensas construidas actúan solas
Ofrendas en el altar de Anubis            Amuletos
Construir defensas                        Proteger cultivos, aldea y a ti
        │                                          │
        └──── ATARDECER: aviso de Thot, ───────────┘
              cielo rojo, música cambia
AMANECER: resumen de la noche (cultivos perdidos, enemigos, cambio en la balanza)
```

## 6. Sistemas

### 6.1 El peso del corazón (mecánica central)
- Valor de **0 a 100**. Empieza en **50** (empate exacto con la pluma).
- **Menor = más liviano = bueno.** El objetivo es terminar por debajo de 50.
- UI: una **balanza dorada** arriba al centro de la pantalla, corazón a un lado, pluma al otro. Se inclina con animación suave cada vez que cambia, con un sonido y un texto flotante ("+3 Isfet" / "−5 Maat").
- **Aligera el corazón**: ofrendas en el altar, completar misiones, proteger la aldea, ayudar a Iry.
- **Carga el corazón (con ventaja inmediata)**: robar ofrendas del templo (+deben), mentirle a Meret, abandonar la aldea en la noche 2 para salvar tus cultivos.
- Thot y los aldeanos reaccionan distinto según el peso.
- Al final de la demo se muestra un **pesaje de prueba** con el resultado actual.

### 6.2 Granja
- **Moneda**: *deben* (unidad real egipcia de peso y valor, de cobre).
- **Parcelas**: tierra negra junto al Nilo (el limo fértil que da nombre a Kemet).
- **Acciones**: arar (azada) → sembrar → regar (cántaro, se recarga en el Nilo) → crecer → cosechar (hoz).
- **Cultivos de la demo**:
  | Cultivo | Días | Uso | Dato que enseña |
  |---|---|---|---|
  | Trigo (emmer) | 1 | Vender, ofrenda básica | Base del pan y la cerveza egipcios |
  | Lino | 2 | Misión de Meret (vendas), vender | Con lino se hacían la ropa y las vendas de momificación |
  | Papiro | 2 | Solo en parcelas de la orilla; vale más | Crecía en los pantanos del Nilo; de él salía el material de escritura |
- Los cultivos tienen estados visuales (semilla, brote, crecido, listo) y **pueden ser dañados de noche**.
- Estación de la demo: **Peret** (siembra). El calendario muestra las tres estaciones reales: Akhet (inundación), Peret (siembra), Shemu (cosecha).

### 6.3 Combate: herramientas bendecidas
De día son herramientas. Al anochecer brillan y se transforman (animación + sonido).
| Día | Noche | Estilo |
|---|---|---|
| Hoz | **Khopesh** (espada curva) | Rápida, combo de 3 golpes, empuje leve |
| Azada | **Martillo** | Lenta, golpe en área, aturde |
| Cayado *(opcional si hay tiempo)* | **Bastón** | Proyectil de energía a distancia |

- Ataque hacia la dirección del mouse. Esquiva con i-frames.
- Feedback obligatorio: hit-stop breve, flash blanco del enemigo, sacudida de cámara leve, partículas, número de daño, sonido.

### 6.4 Enemigos (criaturas de Ammit)
| Enemigo | Comportamiento |
|---|---|
| **Sombras** (*sheut*, la sombra en la creencia egipcia) | Lentas, en grupo, van hacia el jugador |
| **Crías de Ammit** | Pequeñas y rápidas, prefieren atacar cultivos |
| **Heraldo de Ammit** (jefe, noche 3) | Bestia grande con rasgos de cocodrilo, león e hipopótamo. Fases: embestida con aviso, rugido que invoca crías, golpe de área. Barra de vida grande con nombre |

Aparecen desde el desierto y desde la necrópolis, con indicadores en el borde de la pantalla.

### 6.5 Defensas (se construyen de día con deben y materiales)
- **Estatua de chacal**: dispara proyectiles a enemigos cercanos.
- **Brasero sagrado**: quema en área a quien pase cerca.
- **Muro de adobe** *(opcional)*: bloquea y canaliza.

### 6.6 Amuletos (se equipan, tecla Q)
- **Anj**: cura una parte de la vida; se recarga con el tiempo.
- **Escarabajo del corazón**: si mueres, revives una vez por noche. (Dato real: se ponía sobre el pecho de la momia para que el corazón no testificara en contra del difunto en el juicio.)
- *(Más adelante: Ojo de Horus, Djed.)*

### 6.7 Aldea y misiones de la demo
- **Ptahmose**: vende tu primera cosecha (tutorial de comercio).
- **Meret**: trae lino para las vendas del templo (−peso).
- **Iry**: quiere saber quién es Anubis → Thot lo explica → entrada en el códice.
- **Decisión moral 1 (día 2)**: el altar del templo tiene ofrendas sin vigilancia. Robar = +deben, +peso.
- **Decisión moral 2 (noche 2)**: la aldea y tus cultivos son atacados a la vez. Defender la aldea = −peso, pierdes cosecha.

### 6.8 Códice ("Libro de los Muertos")
- Tecla Tab. Unas **10 entradas** que se desbloquean al conocer dioses, criaturas, cultivos y amuletos. Cada entrada: ilustración pixel art + 2–4 frases + comentario sarcástico de Thot.
- Entradas mínimas: Anubis, Thot, Maat y la pluma, Ammit, Duat, Aaru, Ba, Sheut, Trigo/Lino/Papiro, Anj, Escarabajo del corazón.

## 7. Estructura de la demo

- **Intro** (≈1 min): pantalla negra → juicio en el Duat, la balanza se equilibra exacta, silencio. Anubis habla. Despiertas en tu granja. Thot aparece.
- **Día 1**: tutorial suave con Thot (moverse, arar, sembrar, regar). Conoces a Meret, Ptahmose e Iry. Primer atardecer.
- **Noche 1**: pocas sombras. Aprendes a pelear.
- **Día 2**: primera cosecha, venta, primera defensa, misión de lino, decisión de robar.
- **Noche 2**: sombras + crías, decisión aldea vs cultivos.
- **Día 3**: preparación, amuleto escarabajo, Thot advierte algo grande.
- **Noche 3**: oleadas + **Heraldo de Ammit**.
- **Final**: amanecer, pesaje de prueba con el resultado, primer recuerdo del ba (el niño que se parece a Iry), pantalla "Gracias por jugar la demo de Scales of Anubis".

## 8. Dirección de arte

- **Estilo**: 2.5D pixel art. Mundo 3D con geometría low-poly y texturas pixeladas (filtro *nearest*); personajes, enemigos y objetos como **sprites 2D** en el mundo 3D (billboard), con 4 u 8 direcciones.
- **Render a baja resolución** (ej. 480×270 o 640×360) escalado a pantalla completa, para que todo se vea pixelado y coherente.
- **Cámara**: tercera persona desde arriba en diagonal, perspectiva suave, sigue al jugador con suavizado.
- **Paleta**: arena, ocre, oro, turquesa, lapislázuli, verde del Nilo, negro de Anubis. Noche: azules y violetas profundos con luz cálida de braseros y la luz lunar de Thot.
- **Iluminación**: el ciclo día/noche es clave para el look: atardecer rojo-naranja, noche con sombras dinámicas y luces puntuales.
- **Mapa**: granja al centro, Nilo a un lado (con juncos y papiro), aldea pequeña (templo de Maat, casas de adobe, muelle de Ptahmose), necrópolis con tumbas y un obelisco al fondo, desierto abierto al otro lado.
- La arquitectura egipcia es geométrica (pirámides, obeliscos, columnas, pilonos): aprovecharlo con low-poly limpio.

## 9. Audio
- Música: día tranquilo (arpa, flauta, percusión suave), atardecer con tensión creciente, noche con percusión fuerte, tema de jefe.
- SFX para todo: pasos, azada, riego, cosecha, golpes, transformación de herramientas, balanza, UI, enemigos.

## 10. Controles (teclado + mouse; mando si hay tiempo)
- WASD mover · Mouse apuntar · Clic izq. usar herramienta/atacar · Espacio esquivar · E interactuar · 1/2/3 cambiar herramienta · Q amuleto · Tab códice · Esc pausa.

## 11. Interfaz
- Menú principal con título y fondo animado, Nueva partida, Opciones (volumen, pantalla completa), Salir.
- HUD: balanza (arriba centro), vida, hora y fase del día, deben, herramienta activa, amuleto.
- Diálogos con retrato pixel art, texto con efecto máquina de escribir, nombre del personaje.
- Resumen al amanecer. Pantalla de pausa.
- Textos en **español**, con los textos centralizados para poder traducir luego al inglés.

## 12. Lore verificado (fuente de verdad)
Usar solo estos datos para textos mitológicos. No inventar mitología nueva presentándola como real; lo inventado para el juego (el empate, las criaturas de Ammit atacando de noche, el heraldo) es ficción del juego y no se presenta como mito real en el códice.

- **Duat**: el inframundo egipcio que recorren los muertos.
- **Pesaje del corazón**: el corazón (*ib*) del difunto se pesa contra la pluma de Maat. Anubis realiza el pesaje y Thot anota el resultado. Aparece en el capítulo (hechizo) 125 del Libro de los Muertos.
- **Maat**: diosa y concepto de verdad, orden y justicia. Su símbolo es la pluma de avestruz. Lo opuesto es **Isfet**, el caos.
- **Ammit**: la devoradora; cabeza de cocodrilo, parte delantera de león, trasera de hipopótamo. Devora los corazones que pesan demasiado.
- **Aaru** (Sekhet-Aaru, el Campo de Juncos): el paraíso de los justos, gobernado por Osiris; una versión eterna y abundante de los campos de Egipto, donde se cultivaba.
- **Anubis**: dios con cabeza de chacal, de la momificación y protector de los cementerios y necrópolis.
- **Thot**: dios de la escritura, la sabiduría y la luna; representado como ibis o como hombre con cabeza de ibis (también como babuino).
- **Ba**: parte del alma, representada como un pájaro con cabeza humana. **Sheut**: la sombra, también parte de la persona.
- **Apep (Apofis)**: serpiente del caos que ataca cada noche la barca de Ra en su viaje por el inframundo.
- **Kemet**: "la tierra negra", nombre que los egipcios daban a su país, por el limo fértil del Nilo.
- **Estaciones**: Akhet (inundación), Peret (siembra y crecimiento), Shemu (cosecha).
- **Anj**: símbolo de la vida. **Escarabajo del corazón**: amuleto sobre el pecho de la momia para que el corazón no hablara en contra del difunto. **Djed**: pilar, estabilidad, asociado a Osiris. **Ojo de Horus (wedjat)**: protección y sanación.
- **Shabti**: figuritas enterradas con el difunto para hacer por él el trabajo agrícola en el más allá.
- **Deben**: unidad egipcia de peso usada para valorar bienes.
- **Senet**: juego de mesa egipcio asociado al viaje del alma.
- Ojo: **Serket** era una diosa protectora (escorpión), no usarla como enemiga.

## 13. Fuera del alcance de la demo
Estaciones completas, bajar al Duat, más aldeanos, relaciones/romance, guardado múltiple, finales completos, más armas y amuletos, multijugador.
