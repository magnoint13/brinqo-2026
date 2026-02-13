# Descripción del juego

Eres un qubit dentro de un ordenador cuántico.

No ocupas una posición definida. Mientras no seas observado, existes como una
una nube de probabilidad que se extiende por el sistema. Tus acciones no son
movimientos clásicos, sino operaciones cuánticas que modifican esa función de
onda. Estas pueden interpretarse como puertas cuánticas: desplazamiento,
escalado y rotación del estado.

En cualquier momento puedes forzar una medición. Al hacerlo, tu función de onda
colapsa y el sistema selecciona una posición concreta siguiendo su distribución
de probabilidad. Este colapso puede situarte en regiones que serían inaccesibles
clásicamente, reproduciendo un efecto análogo al túnel cuántico.

El ordenador está resolviendo un problema de optimización: maximizar la
probabilidad de obtener el resultado correcto y minimizar la de los incorrectos.
En el juego, esta idea se representa de forma literal. Las zonas verdes son
estados deseados; las zonas rojas, resultados erróneos. El cálculo solo tiene
éxito si todas las zonas verdes son alcanzadas mediante colapsos válidos.

Al interactuar con otras partículas puedes generar entrelazamiento cuántico. Las
partículas entrelazadas comparten una función de onda conjunta y colapsan de
forma correlacionada, permitiendo satisfacer varias condiciones del cálculo con
una sola medición. Sin embargo, el sistema no es perfecto: la decoherencia
degrada estas correlaciones con el tiempo.

Aquí, observar no es pasivo.
Medir es decidir el resultado del cálculo.

# Mecánicas cuánticas

- **Superposición y función de onda**: El jugador existe en una distribución
  espacial de estados posibles. El movimiento en el mapa no es un cambio de
  coordenadas clásicas, sino una evolución de la función de onda que
  redistribuye las probabilidades de presencia.

- **Colapso de la función de onda**: Al interactuar (presionar un botón), el
  sistema se observa, forzando a los qubits a abandonar su estado de
  superposición para definir su posición según su función de onda.
  En este caso, se usa una distribución normal.

- **Principio de incertidumbre**: Al realizar una medición, el jugador no podrá
  moverse ya que en ese instante de tiempo se conoce su posición con exactitud,
  pero solo en ese instante. Para poder continuar sería necesario volver a
  preparar el estado.

- **Efecto túnel**: Como consecuencia del colapso de la función de onda, el
  qubit puede atravesar paredes finas al colapsar al otro lado.

- **Entrelazamiento y Correlación**: Al tocar otros qubits, se crea un
  entrelazamiento que sincroniza sus movimientos. Si una colapsa, el resto
  también lo hará.

- **Decoherencia**: El ruido térmico terminará por destruir el entrelazamiento,
  por lo que la computación deberá hacerse dentro de un tiempo concreto. Forzar
  un colapso reiniciará el contador, pero deberás tener cuidado de no caer en
  zonas rojas.

# Rigurosidad

Nos hemos tomado ciertas libertades creativas en favor de la jugabilidad, ya que
no se trata de una simulación física:

- El colapso no destruye el qubit ni necesariamente termina la computación, sino
  que se permite continuar al jugador.

- El movimiento de la nube es continuo y manual, mientras que en un computador
  cuántico real, las transiciones de estado ocurren mediante pulsos de
  microondas u láseres. Los movimientos permitidos tampoco se han pensado para
  simular el funcionamiento de una puerta cuántica real.

- Por limitaciones técnicas, los qubits no son realmente ondas de probabilidad,
  por lo que no se crean patrones de interferencia (zonas donde la probabilidad
  sea 0 solo por estar juntas).

- El cálculo de las posiciones al colapsar se hace de forma independiente, el
  resultado de una no condiciona la posición de las otras. Esto se debe a
  detalles de implementación (comprobar las colisiones con el entorno), pero
  apenas se aprecia en el resultado final.

- Para hacer el efecto túnel más consistente, se ha modificado la generación
  aleatoria para hacerlo más probable.

- La decoherencia se representa con un temporizador visual para que el jugador
  pueda gestionar el riesgo, simplificando la naturaleza del ruido cuántico.

El resto de mecánicas se ha intentado que sean lo más coherente posible. Muchas
gracias a Tomás y a Javi del grupo Bell del Discord de la Jam por asesorarnos.


# Fuentes

- [Efecto de la función de onda](https://www.shadertoy.com/view/MlBGDw) (adaptado)
- [Efecto blur](https://www.shadertoy.com/view/4tSyzy) (adaptado)
