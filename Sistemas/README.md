# Sistemas

ROMs de los arcades guardadas cifradas, más el ajuste del sistema **pygame**.
Todo lo que necesita el instalador está en esta carpeta: no lee archivos de
otros módulos.

## Estructura

```
Sistemas/
  DATA/
    atari2600.tar.gz.gpg
    mame.tar.gz.gpg
    fbneo.tar.gz.gpg
    mame_vertical.tar.gz.gpg
    fbneo_vertical.tar.gz.gpg
    pygame.tar.gz.gpg
  pygame-system.xml   # plantilla del sistema pygame si no existe en Batocera
  install.sh
```

La regla es simple: **el nombre del archivo, sin `.tar.gz.gpg`, es la carpeta
de `/userdata/roms`**. Si agregás `Sistemas/DATA/nes.tar.gz.gpg`, el instalador
va a instalar `/userdata/roms/nes`. No hace falta tocar el script.

Los cuatro archives de MAME/FBNeo son el mismo contenido para dos sistemas:
`mame` y `fbneo` comparten el horizontal, y `mame_vertical` y `fbneo_vertical`
comparten el vertical. Se guardan duplicados cifrados para respetar la regla de
un archivo por carpeta.

## Instalación

El instalador principal ya lo incluye:

```sh
sh /tmp/install-arcade.sh -v -p1234
```

Para instalar solo este módulo desde el repo:

```sh
cd /userdata/arcade-cabinets/Sistemas
sh install.sh -p1234
# también acepta la forma separada:
sh install.sh -p 1234
```

Sin `-p`, avisa y salta los archives; el ajuste de pygame igual se aplica. El
módulo detiene EmulationStation, no crea respaldos y borra el directorio
temporal (con la clave y los archives descomprimidos) al terminar, incluso si
falla.

### Qué hace con cada sistema

- Si `/userdata/roms/<sistema>/gamelist.xml` **ya existe**, no toca nada: el
  mueble manda.
- Si **no existe**, vacía la carpeta y extrae el archive ahí. Ojo con esto: si
  hay ROMs sueltas pero no hay `gamelist.xml`, se borran.

### El caso especial de `pygame`

`pygame.tar.gz.gpg` es **aditivo**, no de reemplazo:

- conserva lo que ya haya en `/userdata/roms/pygame` (Retrotrivia y pygun, por
  ejemplo);
- sobrescribe `Referencia/` y `Verticalizer/` con lo que traiga el archive;
- agrega `images/Verticalizer.png`;
- agrega al `gamelist.xml` las entradas `<game>` de **Referencia** y
  **Verticalizer**, sin borrar ni duplicar las existentes;
- ajusta `es_systems_custom.cfg` para que el sistema pygame ejecute `%ROM%` en
  vez del `batocera-launch` stock, usando `pygame-system.xml` si el sistema no
  existe todavía.

El archive incluye un `gamelist-add.xml` con los dos bloques a insertar.
`Verticalizer` **mueve** ROMs, imágenes y metadata entre sistemas; el
instalador solo lo copia, no lo ejecuta.

## Cómo se hace un pnp para una carpeta determinada (referencia)

Esto es lo que hay que hacer para convertir una carpeta ya scrappeada de
`/userdata/roms` en un `.tar.gz.gpg` de este módulo. Se ejecuta **en el arcade
donde están las ROMs ya terminadas**, con la misma contraseña que se le pasa
después a `-p`:

```sh
PASS=1234
SISTEMA=atari2600

cd /userdata/roms
tar -C "$SISTEMA" -cf - . \
  | gzip -9 \
  | gpg --batch --yes --no-tty --passphrase-fd 3 \
        --cipher-algo AES256 --compress-algo none \
        --output "$SISTEMA.tar.gz.gpg" --symmetric 3<<<"$PASS"
```

Puntos clave:

- `tar -C "$SISTEMA" -cf - .` guarda el **contenido** de la carpeta, con `./`
  como raíz. No hay que incluir la carpeta en sí: el instalador ya sabe dónde
  va. Todos los archives de `DATA/` usan este formato.
- Se usa `gzip -9` y además `--compress-algo none` en GPG para no comprimir dos
  veces.
- Batocera trae GPG 1.4, que no entiende `--pinentry-mode loopback`. En una PC
  con GPG 2.x agregalo para que no abra diálogo de contraseña:

  ```sh
  gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 ...
  ```

- El nombre de salida debe ser exactamente `<sistema>.tar.gz.gpg` y se copia a
  `Sistemas/DATA/`. Si el sistema es pygame, el contenido que se cifra es
  `Referencia/`, `Verticalizer/`, `images/Verticalizer.png` y
  `gamelist-add.xml`, no una carpeta de ROMs.

Para verificar el archive antes de subirlo:

```sh
printf '%s\n' "$PASS" \
  | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 \
        -d "$SISTEMA.tar.gz.gpg" 2>/dev/null \
  | tar -tzf - | head
```

Si la PC tiene GPG 1.4, quitá `--pinentry-mode loopback` del comando.
