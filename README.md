# Descripción del juego

El jugador es un orbital dentro de un ordenador cuántico.

Mientras no se observe el estado del jugador, este solo existe como una nube de
probabilidad que se extiende por una región del sistema. Las acciones que puede
realizar son operaciones cuánticas que modifican esa función de onda, y pueden
interpretarse como diferentes puertas cuánticas: desplazamiento, escalado y
rotación del estado.

En cualquier momento se puede forzar una medición. Al hacerlo, la función de
onda colapsa y se define una posición concreta siguiendo la distribución de
probabilidad del orbital. Este colapso puede situar al jugador en regiones que
serían inaccesibles clásicamente, reproduciendo un efecto análogo al túnel
cuántico.

El objetivo del juego es maximizar la probabilidad de colapsar en una verde
(obtener el resultado correcto) y minimizar las zonas rojas (resultados
incorrectos). Solo se considerará un éxito si todas las zonas verdes son
alcanzadas mediante colapsos válidos.

Al interactuar con otros orbitales, se generarán entrelazamientos cuánticos. Las
partículas entrelazadas comparten una función de onda conjunta y colapsan de
forma correlacionada, permitiendo satisfacer varias zonas verdes a la vez. Sin
embargo, no es un sistema perfecto: la decoherencia lo degrada con el tiempo.

# Mecánicas cuánticas

- **Superposición y función de onda**: El jugador existe en una distribución
  espacial de posiciones posibles, y se puede mover gracias a diferentes
  operaciones cuánticas que modifican esta función de onda.

- **Colapso de la función de onda**: Al interactuar (presionar un botón), el
  sistema se observa, forzando a abandonar el estado de superposición para
  definirse según una distribución normal.

- **Principio de incertidumbre**: Al realizar una medición, el jugador no podrá
  moverse ya que en ese instante de tiempo se conoce su posición con exactitud,
  pero solo en ese instante. Tampoco se conoce su velocidad, y para poder
  continuar, será necesario volver a preparar el estado.

- **Efecto túnel**: Como consecuencia del colapso de la función de onda, el
  orbital puede atravesar paredes finas al colapsar al otro lado.

- **Entrelazamiento y Correlación**: Al tocar otros orbitales, se crea un
  entrelazamiento que sincroniza sus movimientos. Si uno colapsa, el resto
  también lo hará.

- **Decoherencia**: El ruido térmico terminará por destruir el entrelazamiento,
  por lo que el nivel deberá resolverse dentro de un tiempo concreto. Forzar un
  colapso reiniciará el contador, lo que permitirá mantener el entrelazamiento,
  pero será arriesgado por la posibilidad de caer en las zonas rojas.

# Rigurosidad

Nos hemos tomado ciertas libertades creativas en favor de la jugabilidad, ya que
no se trata de una simulación física:

- El movimiento de la nube es continuo y manual, mientras que en un computador
  cuántico real, las transiciones de estado ocurren mediante pulsos de
  microondas u láseres. Los movimientos permitidos tampoco se han pensado para
  simular el funcionamiento de una puerta cuántica real.

- Por limitaciones técnicas, los orbitales no son realmente ondas de
  probabilidad, por lo que no se crean patrones de interferencia (zonas donde la
  probabilidad sea 0 porque se anulen entre ellas).

- El cálculo de las posiciones al colapsar se hace de forma independiente, el
  resultado de una no condiciona la posición de las otras. Esto se debe a
  detalles de implementación (comprobar las colisiones con el entorno), pero
  apenas se aprecia en el resultado final.

- Para hacer el efecto túnel más consistente, se ha modificado la media de la
  generación aleatoria para que sea más probable colapsar hacia más adelante
  según la dirección de movimiento. Si el jugador está quieto, esto no se
  aplica.

- La decoherencia se simplifica mediante una representación con un temporizador
  visual.

El resto de mecánicas se ha intentado que sean lo más coherente posible. Muchas
gracias a Tomás del grupo Bell del Discord de la Jam por asesorarnos.


# Fuentes

- [Efecto de la función de onda](https://www.shadertoy.com/view/MlBGDw) (adaptado)
- [Efecto blur](https://www.shadertoy.com/view/4tSyzy) (adaptado)
- [Fuente de letra](https://fontmeme.com/fonts/monocraft-font/)
- [Fuente de los vídeos de fondo y de la música](https://pixabay.com/es/)
