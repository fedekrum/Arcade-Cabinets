#!/bin/sh
# Instala el splash y los ajustes de pantalla/grillas de este mueble.
# Usa solamente archivos que están dentro de la carpeta splash/.
set -eu

log()  { printf '[splash] %s\n' "$*"; }
fail() { printf '[splash] ERROR: %s\n' "$*" >&2; exit 1; }

# Por defecto horizontal; -v elige vertical. -h es horizontal, no ayuda.
case "${1:-}" in
  -v)     MODE=vertical ;;
  -h|"")  MODE=horizontal ;;
  *) fail "uso: $0 [-h|-v]  (-h horizontal por defecto, -v vertical)" ;;
esac

[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"
[ -f /etc/init.d/S00bootcustom ] || fail "no encontré /etc/init.d/S00bootcustom"

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TS=$(date +%Y%m%d_%H%M%S)

backup() {
  if [ -e "$1" ]; then
    cp -a "$1" "$1.bak_$TS"
    log "backup: $1.bak_$TS"
  fi
}

case "$MODE" in
  # Grillas: valores de sf2 para horizontal, de pacman para vertical.
  vertical)   IMG="$HERE/vertical.png";    ES_IMG="$HERE/vertical-es.png"; ROT=3; GRID_ALL="4 5"; GRID_VERT="4 3"; GRID_FB_VERT="4 3" ;;  # 90° CCW, como pacman
  horizontal) IMG="$HERE/horizontal.png"; ES_IMG="$HERE/horizontal.png"; ROT=0; GRID_ALL="4 5"; GRID_VERT="6 3"; GRID_FB_VERT="6 3" ;;
esac
[ -f "$IMG" ] || fail "no encontré $IMG (copiá este install.sh junto a las imágenes)"
[ -f "$ES_IMG" ] || fail "no encontré $ES_IMG (falta la imagen de la barra de carga)"
command -v python3 >/dev/null 2>&1 || fail "falta python3 en el sistema"

log "instalando splash $MODE"

# /boot se monta solo lectura en Batocera.
mount -o remount,rw /boot 2>/dev/null || fail "no pude montar /boot en lectura/escritura"
trap 'mount -o remount,ro /boot >/dev/null 2>&1 || true' EXIT

# Archivo clave: lo ejecuta S00bootcustom en cada arranque.
backup /boot/boot-custom.sh
cp "$HERE/boot-custom.sh" /boot/boot-custom.sh
chmod 755 /boot/boot-custom.sh

# La copia en /userdata/system no se usa; en sf2 no existe.
if [ -e /userdata/system/boot-custom.sh ]; then
  backup /userdata/system/boot-custom.sh
  rm -f /userdata/system/boot-custom.sh
fi

# S28splash: fbv estira siempre la imagen al framebuffer, sin conservar la
# proporción. Normaliza tanto la línea de pacman como la original de Batocera.
backup /etc/init.d/S28splash
python3 - <<'PY'
import re
p = "/etc/init.d/S28splash"
s = open(p).read()
canonical = 'start-stop-daemon -S -b -q -m -p /var/run/user-splash-image.pid --exec /usr/bin/fbv -- -f -e -r -i "$image"'
pat = r'^[ \t]*start-stop-daemon[^\n]*fbv[^\n]*$'
new, n = re.subn(pat, canonical, s, count=1, flags=re.M)
if n and new != s:
    open(p, "w").write(new)
    print("[splash] S28splash: fbv estira sin conservar proporción")
elif canonical in s:
    print("[splash] S28splash: fbv ya estaba como en sf2")
else:
    print("[splash] S28splash: no reconocí la línea fbv, revisala a mano")
PY

# Imagen del splash.
mkdir -p /userdata/splash
backup /userdata/splash/krum.png
cp "$IMG" /userdata/splash/krum.png
chmod 644 /userdata/splash/krum.png

# Imagen de la barra de carga de EmulationStation (se reaplica en cada arranque).
backup /boot/splash-es.png
cp "$ES_IMG" /boot/splash-es.png
chmod 644 /boot/splash-es.png

# Los cambios de configuración se hacen con ES detenido: si no, al iniciarlo
# pide correcciones y puede sobrescribir es_settings.cfg al salir.
if [ -x /etc/init.d/S31emulationstation ]; then
  /etc/init.d/S31emulationstation stop >/dev/null 2>&1 || true
fi

# Opciones de splash y música de fondo en userdata y en la configuración de arranque.
batocera-settings-set \
  splash.screen.enabled 1 \
  splash.screen.sound 0 \
  splash.screen.length 5 \
  audio.bgmusic 0

ES_SETTINGS=/userdata/system/configs/emulationstation/es_settings.cfg
if [ -f "$ES_SETTINGS" ]; then
  if grep -q '<bool name="audio.bgmusic"' "$ES_SETTINGS"; then
    sed -i 's|<bool name="audio.bgmusic" value="[^"]*" />|<bool name="audio.bgmusic" value="false" />|' "$ES_SETTINGS"
  else
    sed -i '/<\/config>/i\	<bool name="audio.bgmusic" value="false" />' "$ES_SETTINGS"
  fi

  # Vista en grilla: default horizontal para todo y grilla propia de Mame Vertical.
  python3 - "$ES_SETTINGS" "$GRID_ALL" "$GRID_VERT" "$GRID_FB_VERT" <<'PY'
import re, sys

p, grid_all, grid_vert, grid_fb_vert = sys.argv[1:5]
s = open(p, encoding="utf-8").read()

def poner(texto, nombre, valor):
    patron = r'<string name="%s" value="[^"]*"\s*/>' % re.escape(nombre)
    nuevo = '<string name="%s" value="%s" />' % (nombre, valor)
    if re.search(patron, texto):
        return re.sub(patron, nuevo, texto, count=1)
    return texto.replace("</config>", "\t" + nuevo + "\n</config>", 1)

s = poner(s, "all.gridSize", grid_all)
s = poner(s, "mame_vertical.gridSize", grid_vert)
s = poner(s, "fbneo_vertical.gridSize", grid_fb_vert)
open(p, "w", encoding="utf-8").write(s)
print("[splash] grillas: all=%s, mame_vertical=%s, fbneo_vertical=%s" % (grid_all, grid_vert, grid_fb_vert))
PY
fi
sed -i '/^splash\.video\.rotation=/d' /userdata/system/batocera.conf

# ES: el fondo del splash se estira a toda la pantalla. `size` estira la
# imagen; `maxSize`/`minSize` conservan la proporción y dejan bordes.
THEME_SET=$(sed -n 's/.*<string name="ThemeSet" value="\([^"]*\)".*/\1/p' "$ES_SETTINGS" 2>/dev/null | head -1)
SPLASH_XML="/usr/share/emulationstation/themes/${THEME_SET:-es-theme-carbon}/gamesplash.xml"
if [ -f "$SPLASH_XML" ]; then
  backup "$SPLASH_XML"
  python3 - "$SPLASH_XML" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8-sig").read()
canonical = "<size>1 1</size>"
m = re.search(r'(<view name="splash">.*?<image name="background">)(.*?)(</image>)', s, re.S)
if not m:
    print("[splash] gamesplash.xml: no encontré el fondo del splash, revisalo a mano")
else:
    body = m.group(2)
    if "<size>" in body:
        newbody = re.sub(r"<size>[^<]*</size>", canonical, body, count=1)
    else:
        newbody = re.sub(r"<(?:min|max)Size>[^<]*</(?:min|max)Size>", canonical, body, count=1)
    if newbody == body and canonical in body:
        print("[splash] gamesplash.xml: ya estiraba el fondo")
    else:
        s = s[:m.start(2)] + newbody + s[m.end(2):]
        open(p, "w", encoding="utf-8").write(s)
        print("[splash] gamesplash.xml: fondo estirado a 1 1")
PY
else
  log "no encontré gamesplash.xml del tema '$THEME_SET'; ES queda sin ajustar"
fi

if grep -q '^splash\.screen\.enabled=' /boot/batocera-boot.conf; then
  sed -i 's/^splash\.screen\.enabled=.*/splash.screen.enabled=1/' /boot/batocera-boot.conf
else
  echo 'splash.screen.enabled=1' >> /boot/batocera-boot.conf
fi

# Rotación: 0 para horizontal, 3 (90° CCW) para vertical, como pacman.
batocera-settings-set display.rotate "$ROT"

# El framebuffer siempre es 1280x1024 (5:4); con rotate=3 se ve 4:5.
batocera-settings-set es.resolution 1280x1024
batocera-settings-set -f /boot/batocera-boot.conf es.resolution 1280x1024

# Logo temprano desactivado también para este arranque.
if [ -e /etc/init.d/S03system-splash ]; then
  chmod 644 /etc/init.d/S03system-splash
fi
rm -f /var/run/system-splash.ready

log "listo (rotación $ROT). Reiniciá el arcade para ver el splash $MODE."
