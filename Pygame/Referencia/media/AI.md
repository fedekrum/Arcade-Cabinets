# Propósito

Tener aquí todo lo que la IA debe saber de este proyecto (hardware y software).

## Hardware

- Raspberry Pi 4 con 4 GB de RAM y tarjeta SD de 64 GB.
- Joystick USB conectado de forma permanente e interna.

### Conexiones GPIO

```
    Raspberry Pi 4 - GPIO Header (J8)

01    3.3V  01  ○ ○  02 5V
02   GPIO2  03  ○ ○  04 5V
03   GPIO3  05  ● ■  06 GND     Power On/Off
04   GPIO4  07  ○ ○  08 GPIO14
05     GND  09  □ ○  10 GPIO15
06  GPIO17  11  ○ ○  12 GPIO18
07  GPIO27  13  ○ □  14 GND
08  GPIO22  15  ○ ○  16 GPIO23
09    3.3V  17  ○ ●  18 GPIO24  Relay 12v (marquesina, monitor audio)
10  GPIO10  19  ○ ■  20 GND
11   GPIO9  21  ○ ○  22 GPIO25
12  GPIO11  23  ○ ○  24 GPIO8
13     GND  25  □ ○  26 GPIO7
14   GPIO0  27  ○ ○  28 GPIO1
15   GPIO5  29  ● ■  30 GND     Volumen +
16   GPIO6  31  ● ○  32 GPIO12  Volumen -
17  GPIO13  33  ○ □  34 GND
18  GPIO19  35  ○ ○  36 GPIO16
19  GPIO26  37  ○ ○  38 GPIO20
20     GND  39  □ ○  40 GPIO21
```

- Interruptor On/Off conectado al GPIO3 (Pin 5) ↔ GND (Pin 6).
- Interruptor momentáneo de 3 posiciones (centro neutro): izquierda "Vol-" (GPIO6, Pin 31), derecha "Vol+" (GPIO5, Pin 29), ambos conectados a GND (Pin 30). Están conectados al GPIO.
- Relé controlado por GPIO24 (Pin 18, lógica ACTIVE-HIGH, GND Pin 20) que enciende/apaga la pantalla HDMI, el amplificador de audio y la marquesina superior del arcade.

## Sistema operativo

- Batocera.linux 42 (Buildroot 2024.11) como distribución para juegos.
- Usa BusyBox.

## Acceso para la IA

- Acceso con `sshpass`; hostname mDNS: `pacman.local`, usuario `root`, clave `linux`.
- Ejemplo de conexión y listado no interactivo:

```bash
sshpass -p 'linux' ssh -T -o StrictHostKeyChecking=no root@pacman.local 'ls -la'
```

## Modificaciones de software

Tenemos un archivo `/userdata/system/custom.sh` que ejecuta 2 scripts:

- `/userdata/system/gpio3_power_monitor.sh`: monitorea el interruptor On/Off en GPIO3 (Pin 5) para apagado seguro, y controla el relé en GPIO24 (Pin 18, ACTIVE-HIGH) para encender/apagar el monitor, el amplificador de audio y la marquesina.
- `/userdata/system/volume_buttons.sh`: controla los botones de volumen en GPIO5 (Pin 29, Vol+) y GPIO6 (Pin 31, Vol-) para subir y bajar el volumen del audio.

## Utilidades en Pygame

En la carpeta `/userdata/roms/pygame` hay varias utilidades desarrolladas en Pygame:

- **MAME Verticalizer v3.0** (`Verticalizer/Verticalizer.pygame`) - Organiza automáticamente los juegos de MAME identificando y moviendo aquellos con orientación vertical (rotación de 90° o 270°) a una carpeta separada, incluyendo ROMs, imágenes y metadatos XML. Está optimizado para Raspberry Pi con procesamiento eficiente mediante comandos bash nativos.

- **Referencia** (`Referencia/Referencia.pygame`) - Visualizador de imágenes en modo referencia. Permite navegar con el joystick (izquierda/derecha) para pasar imágenes en orden alfabético desde la carpeta `images` dentro de la aplicación. Las imágenes se muestran centradas y escaladas automáticamente. Se sale de la aplicación presionando A o B.
