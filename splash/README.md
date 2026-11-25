# Imágenes de arranque

Acá guardo la imagen que aparece en la pantalla cuando enciendo cada arcade
mientras Batocera está arrancando.

Hay dos: una para el mueble parado (horizontal) y otra para el mueble de pie
(vertical). No son fotos de los muebles: son las imágenes que se ven en la
pantalla.

Las dejo acá para no perderlas y poder ponerlas de nuevo si cambio la tarjeta
o hago una actualización.

## Instalador

`install.sh`, en esta misma carpeta, instala la imagen elegida y los ajustes de
pantalla/grillas (rotación y `es.resolution=1280x1024`). Solo usa archivos que
están acá (`*.png` y `boot-custom.sh`).

```sh
sh install.sh -h   # horizontal
sh install.sh -v   # vertical
```

Sin parámetro también instala la horizontal. El instalador principal de la
raíz le pasa el modo automáticamente.

## Escalado de las imágenes

Tanto `fbv` (splash de arranque) como EmulationStation (barra de carga) **estiran
cualquier imagen para cubrir toda la pantalla**, sin conservar la proporción.
No hace falta preparar las imágenes a una resolución concreta: se usan las que
haya en esta carpeta y se deforman lo que haga falta. El instalador reescribe
`fbv` con `-f -e -r -i` y cambia el fondo del splash del tema por
`<size>1 1</size>` para que pase lo mismo en ES.
