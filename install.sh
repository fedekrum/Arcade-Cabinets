#!/bin/sh
# Script principal: baja el repo a un directorio y ejecuta los instaladores
# de cada carpeta. Los parámetros se pasan a todos los que los aceptan.
set -eu

log()  { printf '[arcade] %s\n' "$*"; }
fail() { printf '[arcade] ERROR: %s\n' "$*" >&2; exit 1; }

case "${1:-}" in
  -v)     MODE=vertical;   FLAG=-v ;;
  -h|"")  MODE=horizontal; FLAG=-h ;;
  *) fail "uso: $0 [-h|-v]  (-h horizontal por defecto, -v vertical)" ;;
esac

[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"

REPO_URL="https://codeload.github.com/fedekrum/Arcade-Cabinets/tar.gz/refs/heads/master"
DEST=${ARCADE_INSTALL_DIR:-/userdata/arcade-cabinets}
TS=$(date +%Y%m%d_%H%M%S)
TMP="/tmp/arcade-install.$$"

command -v tar >/dev/null 2>&1 || fail "falta tar"
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  fail "falta curl o wget"
fi

mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

if [ -e "$DEST" ]; then
  mv "$DEST" "$DEST.bak_$TS"
  log "directorio anterior guardado como $DEST.bak_$TS"
fi

log "bajando repo ($MODE)"
TARBALL="$TMP/repo.tar.gz"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$REPO_URL" -o "$TARBALL" || fail "no pude bajar el repo con curl"
else
  wget -q "$REPO_URL" -O "$TARBALL" || fail "no pude bajar el repo con wget"
fi
[ -s "$TARBALL" ] || fail "el archivo bajado está vacío"

mkdir -p "$TMP/src"
tar xzf "$TARBALL" -C "$TMP/src"
SRC=$(find "$TMP/src" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -n "$SRC" ] || fail "no pude extraer el repo"

mkdir -p "$(dirname "$DEST")"
mv "$SRC" "$DEST"
log "repo listo en $DEST"

# Cada instalador usa solamente lo que hay dentro de su propia carpeta.
for sub in "splash/install.sh" "Vertical-Horizontal Split/install.sh"; do
  [ -f "$DEST/$sub" ] || fail "falta $DEST/$sub"
  log "ejecutando $sub $FLAG"
  sh "$DEST/$sub" "$FLAG"
done

log "listo. Reiniciá el arcade para ver los cambios."
