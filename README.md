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

   Elige la imagen solo: si `display.rotate` es 1 o 3 usa `vertical.png`; si no,
   usa `horizontal.png`. También se puede forzar:

   ```sh
   sh install.sh vertical
   sh install.sh horizontal
   ```

3. Reiniciar el arcade.

### Qué hace

- Copia la imagen elegida a `/userdata/splash/krum.png`.
- Instala `/boot/boot-custom.sh`, el mismo que usa sf2, para que en cada arranque
  se desactive el logo temprano de Batocera.
- Quita el permiso de ejecución a `S03system-splash` y borra su marca de
  "ya mostré el logo".
- Restaura la línea original de `S28splash` si estaba modificada (era el caso de
  pacman).
- Deja el splash encendido, sin sonido y con 5 segundos de duración; también
  elimina `splash.video.rotation` si quedó de pruebas.
- Guarda un backup con fecha de cada archivo que modifica, al lado del original.

No cambia la rotación de la pantalla ni otros ajustes del mueble.
