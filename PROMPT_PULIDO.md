Rendericé el juego y lo revisé en capturas reales (día, atardecer, noche, aldea, vista general y menú). La base funciona, pero todavía no se ve como un juego comercial. Hasta ahora solo lo verificaste en modo headless y nunca lo miraste, y ese es el problema de fondo.

## Regla nueva, obligatoria desde ya
Crea `tools/capture.gd` + `capture.tscn`: una escena que carga Farm.tscn, pone al jugador en puntos clave (granja, aldea, necrópolis, orilla del Nilo), fija la hora (día, atardecer, noche) y guarda PNGs en `shots/`, ejecutando Godot con ventana (NO headless). **Después de cada cambio visual, genera las capturas, ÁBRELAS Y MÍRALAS** antes de hacer commit. Si algo se ve mal, corrígelo. Añade `shots/` al .gitignore.

## Lo que vi, en orden de prioridad

1. **La textura de pasto parece estática de TV.** El verde está lleno de puntos blancos y grises aleatorios. Rehazla: 3–4 tonos de verde cercanos entre sí, manchas suaves, algunas briznas más oscuras, CERO puntos blancos. Lo mismo con la arena y la tierra de la necrópolis: menos ruido y más suavidad. Esa textura ocupa el 80% de la pantalla, así que es lo que más impacta.
2. **El mapa se ve vacío y plano.** Desde la cámara del jugador solo se ve suelo. Hacen falta:
   - Parcelas de cultivo visibles aunque estén sin arar (surcos marcados o un borde de tierra), para que se note que es una granja.
   - Muchos más props: juncos y papiros densos en la orilla, palmeras de verdad (ahora parecen palos: necesitan hojas visibles), vasijas, cestas, cercas bajas de caña, un shaduf junto al río, piedras, flores pequeñas, pasto alto.
   - Un camino de tierra que conecte granja, aldea y necrópolis.
   - Que el borde del mundo no se vea: rodéalo con dunas o acantilados, y pon a lo lejos pirámides o montañas con niebla.
   - Una aldea más grande y con más vida (toldos de tela, mercado, pozo). El templo es un bloque gris: dale pilonos, columnas y color.
3. **Vida y movimiento (lo que más pide Deivid):**
   - **Viento**: un shader de vértice (`TIME` + seno) que mueva pasto, juncos, papiros, hojas de palmera y cultivos, con intensidad variable en ráfagas.
   - **Agua del Nilo animada**: shader con desplazamiento de UV, brillos que se mueven, y espuma u ondas en la orilla.
   - Partículas ambientales: polvo o arena flotando de día, luciérnagas de noche, hojas que vuelan de vez en cuando.
   - Sombras de nubes que pasen por el suelo (una textura de ruido proyectada que se mueve).
   - Pájaros (ibis) cruzando el cielo de vez en cuando, peces que saltan en el Nilo.
   - Personajes que respiran en idle (bob de 1px), una sombra circular bajo cada sprite y polvo al caminar.
4. **La iluminación de noche está mal.** Todo se tiñe de rojo carmesí oscuro y el jugador se vuelve una silueta roja. El GDD pide noche **azul/violeta profunda** con luz cálida de antorchas y la luz fría de Thot. Arregla el color de la luna, el ambient y la niebla nocturna. El atardecer sí puede ser naranja-rojo. Los sprites deben seguir leyéndose de noche (ambient mínimo o un rim-light).
5. **El HUD está roto:**
   - La barra de vida es un rectángulo rojo plano sin marco ni texto. Hazla con estilo: marco dorado, un ícono de corazón o anj, un fondo oscuro que muestre la vida perdida y animación al recibir daño.
   - El texto "DÍA 1 — DÍA" queda detrás o encima del panel de la balanza y se corta. Ponlo en su propio panel (por ejemplo arriba a la derecha, con un reloj de sol o un ícono de fase).
   - "KHOPESH | AMULETO: —" es texto plano: conviértelo en slots con íconos (ya existen en `assets/sprites/icons/`).
6. **Thot tapa al jugador.** Hazlo orbitar detrás y más arriba, que nunca quede delante del sprite del jugador en pantalla.
7. **El menú principal:** la luna tapa la última letra del título y las pirámides son triángulos planos. Dales sombreado de un lado, arena con dunas, un título con estilo egipcio (dorado, con contorno o sombra), estrellas que titilen y algo de movimiento (arena, nubes, luna).
8. **Cielo:** revisa que el cielo diurno se vea como cielo (degradado celeste y cálido hacia el horizonte), no un azul oscuro plano.

## Reglas
- Todo gratis y generado por ti (o CC0 registrado en CREDITS.md), igual que antes.
- Un commit por cada punto, con capturas revisadas antes de cada commit.
- Al final, re-exporta el .exe, actualiza PROGRESS.md y deja en `shots/` un set final de capturas (día, atardecer, noche, aldea, menú) para que Deivid las vea desde el celular.
- No preguntes nada: decide lo razonable y anótalo en DECISIONES.md.
