# Arcade Cabinets

Notas para instalar Batocera en mis arcades y ajustarlo a mi gusto.

## Splash de arranque

`splash/` tiene las dos imágenes que pueden aparecer al encender cada mueble.
`install.sh` deja la máquina como la tengo en sf2: sale la imagen elegida en vez
del logo de Batocera, y sigue saliendo después de actualizar Batocera.

### Cómo se hace

1. Copiar este repositorio al arcade (o al menos `install.sh` y la carpeta
   `splash`), por ejemplo en `/userdata/install-arcade`.
2. Ejecutarlo como root desde el terminal de Batocera o por SSH:

   ```sh
   cd /userdata/install-arcade
   sh install.sh
   ```

   La imagen se elige por un parámetro: sin parámetro (o con `-h`) se instala
   la horizontal; con `-v` se instala la vertical. Ojo: `-h` no es de ayuda,
   significa horizontal.

   ```sh
   sh install.sh        # horizontal
   sh install.sh -h     # horizontal
   sh install.sh -v     # vertical
   ```

3. Reiniciar el arcade.

### Qué hace

- Copia la imagen elegida a `/userdata/splash/krum.png` (splash de arranque).
- Copia a `/boot/splash-es.png` la imagen de la barra de carga: la horizontal tal
  cual, y para la vertical una copia girada 90° (`vertical-es.png`), porque ES la
  muestra rotada cuando la pantalla está en 90° CCW.
- Instala `/boot/boot-custom.sh`, que en cada arranque desactiva el logo temprano
  de Batocera y pone esa imagen como fondo de la barra de progreso de
  EmulationStation (`:/logo.png`), para que la barra aparezca sobre ella.
- Quita el permiso de ejecución a `S03system-splash` y borra su marca de
  "ya mostré el logo".
- Restaura la línea original de `S28splash` si estaba modificada (era el caso de
  pacman).
- Deja el splash encendido, sin sonido y con 5 segundos de duración; también
  elimina `splash.video.rotation` si quedó de pruebas.
- Fija la rotación: `display.rotate=0` con `-h` y `display.rotate=3` (90° CCW,
  como pacman) con `-v`. Detiene EmulationStation antes de cambiarla para que
  Batocera no pida correcciones al iniciarlo.
- Apaga la música de fondo de la interfaz de ES (`audio.bgmusic=0` y el ajuste
  `audio.bgmusic` de `es_settings.cfg` en `false`).
- Ajusta la vista en grilla: `all.gridSize=4 5` para todos los sistemas y las
  grillas de los sistemas verticales según el mueble (`mame_vertical.gridSize` y
  `fbneo_vertical.gridSize` = `6 3` con `-h`, como sf2; `4 3` con `-v`, como
  pacman). No toca las grillas propias de otros sistemas.
- Guarda un backup con fecha de cada archivo que modifica, al lado del original.

No cambia otros ajustes del mueble.

## Vertical-Horizontal Split

`Vertical-Horizontal Split/` junta en un solo proceso los dos sistemas que son
estructuralmente iguales:

- Mame → **Mame Horizontal** y **Mame Vertical** (`/userdata/roms/mame_vertical`)
- FBNeo → **FBNeo Horizontal** y **FBNeo Vertical** (`/userdata/roms/fbneo_vertical`)

Copiar esa carpeta al arcade y correr `sh install.sh` como root; tiene su propio
`README.md`. El core por defecto queda en `libretro:mame` o `libretro:fbneo`
según el sistema.

Importante: `es_systems_custom.cfg` **reemplaza** la lista de sistemas de
Batocera, no se suma a ella. El script la genera copiando la lista completa para
que no falten NES, Neo-Geo, etc. Si se crea con solo dos sistemas,
EmulationStation dice que no encuentra juegos y se queda colgado. Cuando el
archivo ya existe, el script solo toca los bloques de Mame y FBNeo.
