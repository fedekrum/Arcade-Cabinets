#!/bin/sh
# Deja FBNeo como "FBNeo Horizontal" y agrega "FBNeo Vertical", igual que Mame.
set -eu

log()  { printf '[fbneo-split] %s\n' "$*"; }
fail() { printf '[fbneo-split] ERROR: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"
command -v python3 >/dev/null 2>&1 || fail "falta python3 en el sistema"

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TS=$(date +%Y%m%d_%H%M%S)
[ -f "$HERE/systems.xml" ] || fail "no encontré $HERE/systems.xml"
[ -f "$HERE/fbneo_vertical.cfg" ] || fail "no encontré $HERE/fbneo_vertical.cfg"

backup() {
  if [ -e "$1" ]; then
    cp -a "$1" "$1.bak_$TS"
    log "backup: $1.bak_$TS"
  fi
}

CUSTOM=/userdata/system/configs/emulationstation/es_systems_custom.cfg
VERT=/userdata/system/configs/emulationstation/es_systems_fbneo_vertical.cfg

log "configurando FBNeo Horizontal / FBNeo Vertical"

# Los cambios de sistemas se hacen con ES detenido.
if [ -x /etc/init.d/S31emulationstation ]; then
  /etc/init.d/S31emulationstation stop >/dev/null 2>&1 || true
fi

mkdir -p /userdata/roms/fbneo_vertical
mkdir -p "$(dirname "$CUSTOM")"

if [ ! -f "$CUSTOM" ]; then
  # es_systems_custom.cfg reemplaza la lista stock: hay que arrancar de la
  # lista completa, si no ES se queda solo con los sistemas que pongamos acá.
  [ -f /usr/share/emulationstation/es_systems.cfg ] || fail "no encontré la lista stock de sistemas"
  cp /usr/share/emulationstation/es_systems.cfg "$CUSTOM"
  log "es_systems_custom.cfg creado desde la lista stock"
else
  backup "$CUSTOM"
fi

python3 - "$CUSTOM" "$HERE/systems.xml" <<'PY'
import re, sys

custom, template = sys.argv[1], sys.argv[2]
s = open(custom, encoding="utf-8").read()
t = open(template, encoding="utf-8").read()

def bloque(texto, nombre):
    patron = r"<system>(?:(?!</system>).)*?<name>%s</name>(?:(?!</system>).)*?</system>" % re.escape(nombre)
    m = re.search(patron, texto, re.S)
    return m.group(0) if m else None

fbneo = bloque(s, "fbneo")
if fbneo:
    if "<fullname>FBNeo Horizontal</fullname>" not in fbneo:
        if "<fullname>" in fbneo:
            nuevo = re.sub(r"<fullname>[^<]*</fullname>", "<fullname>FBNeo Horizontal</fullname>", fbneo, count=1)
        else:
            nuevo = fbneo.replace("<system>", "<system>\n    <fullname>FBNeo Horizontal</fullname>", 1)
        s = s.replace(fbneo, nuevo, 1)
        print("[fbneo-split] FBNeo -> FBNeo Horizontal")
    else:
        print("[fbneo-split] FBNeo ya se llamaba FBNeo Horizontal")
else:
    print("[fbneo-split] FBNeo: no encontré el bloque, revisalo a mano")

if bloque(s, "fbneo_vertical"):
    print("[fbneo-split] fbneo_vertical ya estaba en es_systems_custom.cfg")
else:
    vertical = bloque(t, "fbneo_vertical")
    if vertical and "</systemList>" in s:
        s = s.replace("</systemList>", vertical + "\n</systemList>", 1)
        print("[fbneo-split] fbneo_vertical agregado a es_systems_custom.cfg")

open(custom, "w", encoding="utf-8").write(s)
PY

backup "$VERT"
cp "$HERE/fbneo_vertical.cfg" "$VERT"

# Core por defecto en ambos sistemas: libretro:fbneo.
batocera-settings-set \
  fbneo.core fbneo fbneo.emulator libretro \
  fbneo_vertical.core fbneo fbneo_vertical.emulator libretro

log "listo. Reiniciá el arcade para ver FBNeo Horizontal y FBNeo Vertical."
