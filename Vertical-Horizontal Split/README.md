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
- Copia `roms_horizontal/*.zip` a `mame` y `fbneo`, y `roms_vertical/*.zip` a
  `mame_vertical` y `fbneo_vertical`, junto con el `gamelist.xml` y las imágenes
  del scrapping que están en esas carpetas del repo. Si alguna carpeta de
  destino ya tiene un `.zip`, un `gamelist.xml` o la carpeta `images/`, no copia
  nada ahí: respeta lo que ya haya en el mueble.
- Acepta `-h`/`-v` porque se los pasa el instalador principal; por ahora el
  modo no cambia qué ROMs se copian.
- No crea respaldos: los archivos que modifica se sobrescriben directamente.

`es_systems_custom.cfg` **reemplaza** la lista de sistemas de Batocera, no se
suma a ella: si no existe, el script la genera copiando la lista completa para
que no falten NES, Neo-Geo, etc. Si ya existe, solo toca los bloques de Mame y
FBNeo y deja los demás sistemas como estaban.

No cambia la rotación de la pantalla: eso lo hace `splash/install.sh`.
