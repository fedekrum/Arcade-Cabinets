#!/bin/sh
#
#===============================================================================
# Arcade Cabinets - Instalador de herramientas pygame
#===============================================================================
# Descripción:
#   Instala en el sistema "pygame" las dos herramientas que tiene pacman y que
#   no vienen en la instalación stock de Batocera: Verticalizer y Referencia.
#   También ajusta el sistema pygame de EmulationStation para que ejecute el
#   archivo .pygame directamente (%ROM%), como en pacman.
#
# Uso:
#   sh install.sh [-h|-v]
#   El modo se acepta y se ignora, para que lo pueda llamar el instalador
#   principal con el mismo parámetro que usan los otros módulos.
#
# Parámetros:
#   -h  modo horizontal (valor por defecto)
#   -v  modo vertical
#
# Requisitos:
#   - Ejecutar como root dentro de Batocera (debe existir /userdata).
#   - Necesita python3 y el paquete pygame de Batocera.
#   - Deben estar en esta carpeta: gamelist.xml, pygame-system.xml,
#     Verticalizer/, Referencia/ e images/.
#
# Archivos modificados:
#   /userdata/roms/pygame/Verticalizer
#   /userdata/roms/pygame/Referencia
#   /userdata/roms/pygame/images/Verticalizer.png
#   /userdata/roms/pygame/gamelist.xml
#   /userdata/system/configs/emulationstation/es_systems_custom.cfg
#
# Notas:
#   - El gamelist.xml reemplaza al existente (se guarda un .bak_<fecha>) y
#     incluye las cuatro herramientas: Retrotrivia, pygun, Referencia y
#     Verticalizer.
#   - Verticalizer mueve ROMs, XML e imágenes entre mame/fbneo y sus carpetas
#     verticales. Este instalador solo lo copia: NO lo ejecuta.
#   - No se copian logs, backups ni archivos __pycache__ de pacman.
#===============================================================================

set -eu

# ------------------------------------------------------------------------------
# Utilidades de salida
# ------------------------------------------------------------------------------
log()  { printf '[pygame] %s\n' "$*"; }
fail() { printf '[pygame] ERROR: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# 1. Modo (se ignora; solo se valida)
# ------------------------------------------------------------------------------
case "${1:-}" in
  -h|-v|"") ;;
  *) fail "uso: $0 [-h|-v]  (el modo no cambia las herramientas)" ;;
esac

# ------------------------------------------------------------------------------
# 2. Validación del entorno y de los archivos del módulo
# ------------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"
command -v python3 >/dev/null 2>&1 || fail "falta python3 en el sistema"

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TS=$(date +%Y%m%d_%H%M%S)

[ -f "$HERE/gamelist.xml" ] || fail "no encontré $HERE/gamelist.xml"
[ -f "$HERE/pygame-system.xml" ] || fail "no encontré $HERE/pygame-system.xml"
for sub in Verticalizer Referencia images; do
  [ -d "$HERE/$sub" ] || fail "no encontré $HERE/$sub"
done

backup() {
  if [ -e "$1" ]; then
    cp -a "$1" "$1.bak_$TS"
    log "backup: $1.bak_$TS"
  fi
}

DEST=/userdata/roms/pygame
ESDIR=/userdata/system/configs/emulationstation
CUSTOM=$ESDIR/es_systems_custom.cfg

log "instalando herramientas pygame en el sistema pygame"

# ------------------------------------------------------------------------------
# 3. Preparación
#    ES se detiene antes de tocar sus configuraciones; al salir podría
#    sobrescribirlas con los valores que tiene en memoria.
# ------------------------------------------------------------------------------
if [ -x /etc/init.d/S31emulationstation ]; then
  /etc/init.d/S31emulationstation stop >/dev/null 2>&1 || true
fi

mkdir -p "$DEST" "$ESDIR"

# ------------------------------------------------------------------------------
# 4. Copia de las herramientas y del gamelist
# ------------------------------------------------------------------------------
for sub in Verticalizer Referencia images; do
  cp -a "$HERE/$sub" "$DEST/"
done
chmod 755 "$DEST/Verticalizer/Verticalizer.pygame" "$DEST/Referencia/Referencia.pygame"
log "copiadas: Verticalizer, Referencia, images/Verticalizer.png"

backup "$DEST/gamelist.xml"
cp "$HERE/gamelist.xml" "$DEST/gamelist.xml"
chmod 644 "$DEST/gamelist.xml"

# ------------------------------------------------------------------------------
# 5. Sistema pygame de EmulationStation
#    La lista stock viene con batocera-launch; pacman ejecuta el .pygame
#    directamente con %ROM%. Si el sistema no existe, se agrega desde la
#    plantilla pygame-system.xml.
# ------------------------------------------------------------------------------
if [ ! -f "$CUSTOM" ]; then
  [ -f /usr/share/emulationstation/es_systems.cfg ] || fail "no encontré la lista stock de sistemas"
  cp /usr/share/emulationstation/es_systems.cfg "$CUSTOM"
  log "es_systems_custom.cfg creado desde la lista stock"
else
  backup "$CUSTOM"
fi

python3 - "$CUSTOM" "$HERE/pygame-system.xml" <<'PY'
import re, sys

custom, template = sys.argv[1], sys.argv[2]
s = open(custom, encoding="utf-8").read()
pat = r"<system>(?:(?!</system>).)*?<name>pygame</name>(?:(?!</system>).)*?</system>"
m = re.search(pat, s, re.S)

if m:
    block = m.group(0)
    if "<command>%ROM%</command>" in block:
        print("[pygame] sistema pygame ya ejecutaba %ROM%")
    else:
        block = re.sub(r"<command>[^<]*</command>", "<command>%ROM%</command>", block, count=1)
        block = re.sub(r"<fullname>[^<]*</fullname>", "<fullname>Python Games</fullname>", block, count=1)
        s = s[:m.start()] + block + s[m.end():]
        open(custom, "w", encoding="utf-8").write(s)
        print("[pygame] sistema pygame ajustado a %ROM%")
else:
    bloque = open(template, encoding="utf-8").read()
    if "</systemList>" in s:
        s = s.replace("</systemList>", bloque + "\n</systemList>", 1)
        open(custom, "w", encoding="utf-8").write(s)
        print("[pygame] sistema pygame agregado desde la plantilla")
    else:
        print("[pygame] no encontré </systemList>, revisalo a mano")
PY

log "listo. Reiniciá el arcade para ver las cuatro herramientas en pygame."
