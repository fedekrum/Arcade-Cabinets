# FBNeo Split

Igual que `Mame Split`, pero para FinalBurn Neo: deja el sistema `fbneo` con el
nombre **FBNeo Horizontal** y crea **FBNeo Vertical** para los juegos de
`/userdata/roms/fbneo_vertical`.

## Cómo se hace

1. Copiar esta carpeta al arcade, por ejemplo en `/userdata/fbneo-split`.
2. Ejecutar el script como root:

   ```sh
   cd /userdata/fbneo-split
   sh install.sh
   ```

3. Reiniciar el arcade.

## Qué hace

- Renombra `fbneo` a **FBNeo Horizontal**.
- Agrega **FBNeo Vertical**, con el mismo tema y opciones que el horizontal.
- Deja el core **fbneo de libretro** como predeterminado en los dos sistemas.
- Detiene EmulationStation mientras cambia la configuración.
- Si no existe `es_systems_custom.cfg`, lo genera desde la lista completa de
  Batocera: ese archivo reemplaza a la lista original, no se suma a ella. Si ya
  existe (por ejemplo porque se aplicó `Mame Split`), solo toca el bloque de
  FBNeo y deja los demás sistemas como estaban.
- Guarda una copia con fecha de los archivos que modifica, al lado del original.

No mueve juegos ni cambia la rotación de la pantalla.
