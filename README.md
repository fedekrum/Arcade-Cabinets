# Arcade Cabinets

Notas para instalar Batocera en mis arcades y ajustarlo a mi gusto.

## Instalador principal

`install.sh`, en la raíz del repo, se ocupa de todo: baja el repo a un
directorio con `curl` o `wget`, y ejecuta los instaladores de cada carpeta
pasando `-h` o `-v` a todos los que lo aceptan.

```sh
wget -O /tmp/install-arcade.sh https://raw.githubusercontent.com/fedekrum/Arcade-Cabinets/master/install.sh
sh /tmp/install-arcade.sh -h   # horizontal (valor por defecto)
sh /tmp/install-arcade.sh -v   # vertical
```

Se puede cambiar el directorio de trabajo con la variable `ARCADE_INSTALL_DIR`
(por defecto `/userdata/arcade-cabinets`).

Al terminar (incluso si falla), el instalador **borra todo lo que bajó**: el
repo copiado, el directorio temporal y el propio `/tmp/install-arcade.sh`. No
queda nada del proceso salvo lo que instalaron los módulos. No crea respaldos.

Si instalás un módulo suelto con `curl`/`wget` a `/tmp`, su `install.sh` también
se borra solo al finalizar. Si lo ejecutás desde el repo, se conserva.

## Módulos

Cada carpeta tiene su propio `install.sh` y solo usa archivos que están dentro
de su carpeta:

- `Splash/install.sh`: imágenes de arranque y de la barra de carga, rotación,
  grillas y música de fondo. Acepta `-h`/`-v`.
- `Vertical-Horizontal Split/install.sh`: sistemas Mame/FBNeo horizontales y
  verticales, cores y copia de ROMs. Acepta `-h`/`-v`; por ahora el modo no
  cambia qué ROMs se copian.
- `QEMU VM/`: notas del laboratorio local. No se instala en los arcades.
- `Apariencia/install.sh`: selección de shaders (global, MAME y Game and Watch).
  No copia archivos: Batocera ya incluye los shaders y se eligen desde
  `batocera.conf`. Acepta `-h`/`-v` pero el modo no cambia nada.
- `Pygame/install.sh`: herramientas Verticalizer y Referencia para el sistema
  pygame, y ajuste de ese sistema para ejecutar los `.pygame` con `%ROM%`.
  Acepta `-h`/`-v` pero el modo no cambia nada.

Después de correr el instalador, reiniciá el arcade.
