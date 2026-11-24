# Mame Split

Acá está el arreglo para tener los juegos de Mame separados en dos sistemas:
**Mame Horizontal** para los juegos de pantalla acostada y **Mame Vertical**
para los de pantalla parada.

Los juegos ya están separados en las carpetas `mame` y `mame_vertical`, y esas
carpetas quedan en la tarjeta aunque se actualice Batocera. Lo que se puede
perder con una actualización es la configuración que crea los sistemas: esto la
vuelve a poner.

## Cómo se hace

1. Copiar esta carpeta al arcade, por ejemplo en `/userdata/mame-split`.
2. Ejecutar el script como root desde el terminal de Batocera o por SSH:

   ```sh
   cd /userdata/mame-split
   sh install.sh
   ```

3. Reiniciar el arcade.

## Qué hace

- Cambia el nombre del sistema `mame` a **Mame Horizontal**.
- Crea el sistema **Mame Vertical**, que lee los juegos de
  `/userdata/roms/mame_vertical`. Si no hay un `es_systems_custom.cfg`, lo genera
  copiando la lista completa de sistemas de Batocera (ese archivo reemplaza a la
  lista original, no se suma a ella).
- Deja el core **mame de libretro** como predeterminado en los dos sistemas.
- Detiene EmulationStation mientras cambia la configuración, para que al
  arrancar no pida correcciones.
- Guarda una copia con fecha de los archivos que modifica, al lado del original.

No mueve juegos ni cambia la rotación de la pantalla.
