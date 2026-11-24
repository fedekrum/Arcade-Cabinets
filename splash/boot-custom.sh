#!/bin/sh
case "$1" in
  start)
    # Desactiva logo temprano de Batocera; el splash custom de /userdata/splash lo maneja S28/S30.
    [ -x /etc/init.d/S03system-splash ] && chmod -x /etc/init.d/S03system-splash
    rm -f /var/run/system-splash.ready
    # La pantalla de carga de EmulationStation usa :/logo.png como fondo.
    # Lo cambiamos por nuestra imagen para que la barra aparezca sobre ella.
    if [ -f /boot/splash-es.png ]; then
      cp /boot/splash-es.png /usr/share/emulationstation/resources/logo.png
    fi
    ;;
esac
