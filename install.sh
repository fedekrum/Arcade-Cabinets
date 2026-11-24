#!/bin/sh
# Deja el splash de Batocera como está en sf2.
set -eu

log()  { printf '[install] %s\n' "$*"; }
fail() { printf '[install] ERROR: %s\n' "$*" >&2; exit 1; }

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

# Elegimos imagen: la rotación 1/3 significa mueble vertical.
ROT=$(batocera-settings-get display.rotate 2>/dev/null || true)
case "${1:-}" in
  vertical)   MODE=vertical ;;
  horizontal) MODE=horizontal ;;
  "")
    case "$ROT" in
      1|3) MODE=vertical ;;
      *)   MODE=horizontal ;;
    esac
    ;;
  *) fail "uso: $0 [vertical|horizontal]" ;;
esac

case "$MODE" in
  vertical)   IMG="$HERE/splash/vertical.png" ;;
  horizontal) IMG="$HERE/splash/horizontal.png" ;;
esac
[ -f "$IMG" ] || fail "no encontré $IMG (copiá la carpeta splash junto a install.sh)"
command -v python3 >/dev/null 2>&1 || fail "falta python3 en el sistema"

log "instalando splash $MODE"

# /boot se monta solo lectura en Batocera.
mount -o remount,rw /boot 2>/dev/null || fail "no pude montar /boot en lectura/escritura"
trap 'mount -o remount,ro /boot >/dev/null 2>&1 || true' EXIT

# Archivo clave: lo ejecuta S00bootcustom en cada arranque.
backup /boot/boot-custom.sh
cat > /boot/boot-custom.sh <<'EOF'
#!/bin/sh
case "$1" in
  start)
    # Desactiva logo temprano de Batocera; el splash custom de /userdata/splash lo maneja S28/S30.
    [ -x /etc/init.d/S03system-splash ] && chmod -x /etc/init.d/S03system-splash
    rm -f /var/run/system-splash.ready
    ;;
esac
EOF
chmod 755 /boot/boot-custom.sh

# La copia en /userdata/system no se usa; en sf2 no existe.
if [ -e /userdata/system/boot-custom.sh ]; then
  backup /userdata/system/boot-custom.sh
  rm -f /userdata/system/boot-custom.sh
fi

# S28splash: volver a la línea original de fbv si pacman la había parcheado.
backup /etc/init.d/S28splash
python3 - <<'PY'
p = "/etc/init.d/S28splash"
s = open(p).read()
patched = 'start-stop-daemon -S -b -q -m -p /var/run/user-splash-image.pid -x /bin/sh -- -c "fbv -f -i \\"$image\\" </dev/tty1 >/dev/null 2>&1"'
stock = 'start-stop-daemon -S -b -q -m -p /var/run/user-splash-image.pid --exec /usr/bin/fbv -- -f -i "$image"'
if patched in s:
    open(p, "w").write(s.replace(patched, stock))
    print("[install] S28splash: línea fbv restaurada")
elif stock in s:
    print("[install] S28splash: ya estaba como en sf2")
else:
    print("[install] S28splash: no reconocí la línea fbv, revisala a mano")
PY

# Imagen del splash.
mkdir -p /userdata/splash
backup /userdata/splash/krum.png
cp "$IMG" /userdata/splash/krum.png
chmod 644 /userdata/splash/krum.png

# Opciones de splash en userdata y en la configuración de arranque.
batocera-settings-set \
  splash.screen.enabled 1 \
  splash.screen.sound 0 \
  splash.screen.length 5
sed -i '/^splash\.video\.rotation=/d' /userdata/system/batocera.conf

if grep -q '^splash\.screen\.enabled=' /boot/batocera-boot.conf; then
  sed -i 's/^splash\.screen\.enabled=.*/splash.screen.enabled=1/' /boot/batocera-boot.conf
else
  echo 'splash.screen.enabled=1' >> /boot/batocera-boot.conf
fi

# Logo temprano desactivado también para este arranque.
if [ -e /etc/init.d/S03system-splash ]; then
  chmod 644 /etc/init.d/S03system-splash
fi
rm -f /var/run/system-splash.ready

log "listo. Reiniciá el arcade para ver el splash $MODE."
