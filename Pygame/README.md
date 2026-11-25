# Pygame

Herramientas de Python/Pygame que estaban en **pacman** y no vienen en la
instalación stock de Batocera. Se instalan dentro del sistema **pygame** de
EmulationStation (`/userdata/roms/pygame`).

## Herramientas

- **Verticalizer** (`Verticalizer.pygame`): detecta los juegos verticales de
  MAME y FBNeo y mueve a las carpetas `*_vertical` la ROM, el XML y las imágenes.
  Incluye las listas precalculadas `vertical_mame.txt` y `vertical_fbneo.txt`,
  los módulos de `resources/` y su documentación.
- **Referencia** (`Referencia.pygame`): visor de la documentación del mueble
  (hardware, GPIO, etc.) con las imágenes de `media/`.

Retrotrivia y pygun ya estaban en la VM y **no se reemplazan**.

## Instalación

El instalador principal ya la incluye. Para instalar solo este módulo:

```sh
cd /userdata/arcade-cabinets/Pygame
sh install.sh
```

Acepta `-h`/`-v` pero el modo no cambia nada.

## Qué hace

- Copia `Verticalizer/`, `Referencia/` y `images/Verticalizer.png` a
  `/userdata/roms/pygame/`.
- Reemplaza `gamelist.xml` por el de pacman, con las cuatro herramientas
  (Retrotrivia, pygun, Referencia y Verticalizer). Guarda un `.bak_<fecha>`.
- Ajusta el sistema `pygame` de `es_systems_custom.cfg` para que use
  `<command>%ROM%</command>` en vez del `batocera-launch` stock. Si el sistema
  no existe, lo agrega desde `pygame-system.xml`.
- Detiene EmulationStation mientras escribe y deja los `.pygame` ejecutables.

## Ojo

`Verticalizer` **mueve** ROMs, imágenes y metadata entre sistemas. El instalador
solo lo copia: no lo ejecuta. No se copiaron los logs (uno pesaba 48 MB), los
backups ni los `__pycache__` que había en pacman.
