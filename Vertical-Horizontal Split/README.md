# Vertical-Horizontal Split

Un solo proceso para los dos arcades que tienen la misma estructura: **Mame** y
**FinalBurn Neo**. Deja cada uno con el nombre Horizontal y crea su versión
Vertical.

- Mame → **Mame Horizontal** + **Mame Vertical** (`/userdata/roms/mame_vertical`)
- FBNeo → **FBNeo Horizontal** + **FBNeo Vertical** (`/userdata/roms/fbneo_vertical`)

## Cómo se hace

1. Copiar esta carpeta al arcade, por ejemplo en `/userdata/vh-split`.
2. Ejecutar el script como root:

   ```sh
   cd /userdata/vh-split
   sh install.sh
   ```

3. Reiniciar el arcade.

## Qué hace

- Renombra `mame` y `fbneo` a **Mame Horizontal** y **FBNeo Horizontal**.
- Crea `mame_vertical` y `fbneo_vertical` copiando la configuración de los
  horizontales y cambiando nombre, ruta de ROMs y fullname.
- Deja el core de libretro por defecto en los cuatro sistemas (`mame` o `fbneo`
  según corresponda).
- Detiene EmulationStation mientras cambia la configuración.
- Guarda una copia con fecha de los archivos que modifica, al lado del original.

`es_systems_custom.cfg` **reemplaza** la lista de sistemas de Batocera, no se
suma a ella: si no existe, el script la genera copiando la lista completa para
que no falten NES, Neo-Geo, etc. Si ya existe, solo toca los bloques de Mame y
FBNeo y deja los demás sistemas como estaban.

No mueve juegos ni cambia la rotación de la pantalla.
