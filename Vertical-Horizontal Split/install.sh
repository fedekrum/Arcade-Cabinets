#!/bin/sh
#
#===============================================================================
# Arcade Cabinets - Separación horizontal / vertical
#===============================================================================
# Descripción:
#   Deja MAME y FBNeo con sus nombres horizontales y crea además los sistemas
#   mame_vertical y fbneo_vertical. Los cuatro comparten la misma estructura,
#   así que se configuran en un solo proceso.
#
# Uso:
#   sh install.sh [-h|-v]
#
# Parámetros:
#   -h  modo horizontal (valor por defecto)
#   -v  modo vertical
#   El modo solo se registra en el log: se copian las ROMs de ambos sentidos.
#
# Requisitos:
#   - Ejecutar como root dentro de Batocera (debe existir /userdata).
#   - Necesita python3 para reescribir es_systems_custom.cfg.
#   - Deben estar en esta carpeta: systems.xml, mame_vertical.cfg,
#     fbneo_vertical.cfg, roms_horizontal/ y roms_vertical/.
#
# Archivos modificados:
#   /userdata/roms/{mame,fbneo,mame_vertical,fbneo_vertical}
#   /userdata/system/configs/emulationstation/es_systems_custom.cfg
#   /userdata/system/configs/emulationstation/es_systems_{mame,fbneo}_vertical.cfg
#   /userdata/system/batocera.conf (cores por sistema)
#
# Notas:
#   - Si una carpeta de destino ya tiene algún .zip, no se copia ninguna ROM
#     del repo en esa carpeta.
#   - Todo archivo existente se respalda con sufijo .bak_<fecha>.
#===============================================================================

set -eu

# ------------------------------------------------------------------------------
# Utilidades de salida
# ------------------------------------------------------------------------------
log()  { printf '[vh-split] %s\n' "$*"; }
fail() { printf '[vh-split] ERROR: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# 1. Modo de instalación
# ------------------------------------------------------------------------------
case "${1:-}" in
  -v)     MODO=vertical ;;
  -h|"")  MODO=horizontal ;;
  *) fail "uso: $0 [-h|-v]" ;;
esac

# ------------------------------------------------------------------------------
# 2. Validación del entorno y de los archivos propios del módulo
# ------------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"
command -v python3 >/dev/null 2>&1 || fail "falta python3 en el sistema"

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TS=$(date +%Y%m%d_%H%M%S)
[ -f "$HERE/systems.xml" ] || fail "no encontré $HERE/systems.xml"

for s in mame fbneo; do
  [ -f "$HERE/${s}_vertical.cfg" ] || fail "no encontré $HERE/${s}_vertical.cfg"
done

backup() {
  if [ -e "$1" ]; then
    cp -a "$1" "$1.bak_$TS"
    log "backup: $1.bak_$TS"
  fi
}

ESDIR=/userdata/system/configs/emulationstation
CUSTOM=$ESDIR/es_systems_custom.cfg

log "configurando Mame Horizontal/Vertical y FBNeo Horizontal/Vertical (modo $MODO)"

# ------------------------------------------------------------------------------
# 3. Preparación
#    ES se detiene antes de tocar los sistemas; al salir podría reescribirlos.
# ------------------------------------------------------------------------------
if [ -x /etc/init.d/S31emulationstation ]; then
  /etc/init.d/S31emulationstation stop >/dev/null 2>&1 || true
fi

mkdir -p /userdata/roms/mame /userdata/roms/fbneo
mkdir -p /userdata/roms/mame_vertical /userdata/roms/fbneo_vertical
mkdir -p "$ESDIR"

# ------------------------------------------------------------------------------
# 4. Copia de ROMs
#    Horizontales para mame/fbneo, verticales para sus versiones rotadas.
#    Si el destino ya tiene algún .zip, se respeta tal cual y no se copia nada.
# ------------------------------------------------------------------------------
tiene_zips() {
  for z in "$1"/*.zip; do
    [ -e "$z" ] && return 0
  done
  return 1
}

copiar_roms() {
  origen="$1"
  shift
  [ -d "$origen" ] || fail "no encontré $origen (copiá las carpetas roms_* junto a install.sh)"

  for destino in "$@"; do
    if tiene_zips "$destino"; then
      log "$destino: ya hay ROMs, no copio nada"
      continue
    fi

    n=0
    for f in "$origen"/*.zip; do
      [ -e "$f" ] || continue
      cp "$f" "$destino/"
      n=$((n + 1))
    done
    log "$origen -> $destino: $n copias"
  done
}

copiar_roms "$HERE/roms_horizontal" /userdata/roms/mame /userdata/roms/fbneo
copiar_roms "$HERE/roms_vertical" /userdata/roms/mame_vertical /userdata/roms/fbneo_vertical

# ------------------------------------------------------------------------------
# 5. Lista de sistemas de EmulationStation
# ------------------------------------------------------------------------------
if [ ! -f "$CUSTOM" ]; then
  # es_systems_custom.cfg reemplaza la lista stock: hay que arrancar de la
  # lista completa, si no ES se queda solo con los sistemas que pongamos acá.
  [ -f /usr/share/emulationstation/es_systems.cfg ] || fail "no encontré la lista stock de sistemas"
  cp /usr/share/emulationstation/es_systems.cfg "$CUSTOM"
  log "es_systems_custom.cfg creado desde la lista stock"
else
  backup "$CUSTOM"
fi

# Renombra los sistemas horizontales e inserta los verticales desde systems.xml.
python3 - "$CUSTOM" "$HERE/systems.xml" <<'PY'
import re, sys

custom, template = sys.argv[1], sys.argv[2]
s = open(custom, encoding="utf-8").read()
t = open(template, encoding="utf-8").read()

def bloque(texto, nombre):
    patron = r"<system>(?:(?!</system>).)*?<name>%s</name>(?:(?!</system>).)*?</system>" % re.escape(nombre)
    m = re.search(patron, texto, re.S)
    return m.group(0) if m else None

for sistema, titulo in (("mame", "Mame Horizontal"), ("fbneo", "FBNeo Horizontal")):
    actual = bloque(s, sistema)
    if actual:
        if "<fullname>%s</fullname>" % titulo not in actual:
            if "<fullname>" in actual:
                nuevo = re.sub(r"<fullname>[^<]*</fullname>", "<fullname>%s</fullname>" % titulo, actual, count=1)
            else:
                nuevo = actual.replace("<system>", "<system>\n    <fullname>%s</fullname>" % titulo, 1)
            s = s.replace(actual, nuevo, 1)
            print("[vh-split] %s -> %s" % (sistema, titulo))
        else:
            print("[vh-split] %s ya se llamaba %s" % (sistema, titulo))
    else:
        print("[vh-split] %s: no encontré el bloque, revisalo a mano" % sistema)

    vertical = sistema + "_vertical"
    if bloque(s, vertical):
        print("[vh-split] %s ya estaba en es_systems_custom.cfg" % vertical)
    else:
        bloque_nuevo = bloque(t, vertical)
        if bloque_nuevo and "</systemList>" in s:
            s = s.replace("</systemList>", bloque_nuevo + "\n</systemList>", 1)
            print("[vh-split] %s agregado a es_systems_custom.cfg" % vertical)
        else:
            print("[vh-split] %s: no pude agregarlo, revisalo a mano" % vertical)

open(custom, "w", encoding="utf-8").write(s)
PY

for s in mame fbneo; do
  V=$ESDIR/es_systems_${s}_vertical.cfg
  backup "$V"
  cp "$HERE/${s}_vertical.cfg" "$V"
done

# ------------------------------------------------------------------------------
# 6. Core por defecto en los cuatro sistemas
# ------------------------------------------------------------------------------
batocera-settings-set \
  mame.core mame mame.emulator libretro \
  mame_vertical.core mame mame_vertical.emulator libretro \
  fbneo.core fbneo fbneo.emulator libretro \
  fbneo_vertical.core fbneo fbneo_vertical.emulator libretro

log "listo. Reiniciá el arcade para ver los cuatro sistemas."
