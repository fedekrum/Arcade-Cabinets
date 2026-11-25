#!/bin/sh
#
#===============================================================================
# Arcade Cabinets - Instalador principal
#===============================================================================
# Descripción:
#   Descarga el repo desde la rama master y ejecuta los instaladores de cada
#   módulo. Los parámetros se reenvían a todos los módulos que los aceptan.
#
# Uso:
#   sh install.sh [-h|-v]
#
# Parámetros:
#   -h  modo horizontal (valor por defecto)
#   -v  modo vertical
#
# Requisitos:
#   - Ejecutar como root dentro de Batocera (debe existir /userdata).
#   - Necesita tar y curl o wget.
#
# Variables de entorno:
#   ARCADE_INSTALL_DIR  destino del repo (por defecto /userdata/arcade-cabinets)
#
# Efectos:
#   - Si el destino existe, lo renombra a <destino>.bak_<fecha>.
#   - Ejecuta splash/install.sh y Vertical-Horizontal Split/install.sh.
#===============================================================================

set -eu

# ------------------------------------------------------------------------------
# Utilidades de salida
# ------------------------------------------------------------------------------
log()  { printf '[arcade] %s\n' "$*"; }
fail() { printf '[arcade] ERROR: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# 1. Modo de instalación
# ------------------------------------------------------------------------------
case "${1:-}" in
  -v)     MODE=vertical;   FLAG=-v ;;
  -h|"")  MODE=horizontal; FLAG=-h ;;
  *) fail "uso: $0 [-h|-v]  (-h horizontal por defecto, -v vertical)" ;;
esac

# ------------------------------------------------------------------------------
# 2. Validación del entorno
# ------------------------------------------------------------------------------
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

# Limpieza garantizada del directorio temporal, incluso si falla el script.
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# ------------------------------------------------------------------------------
# 3. Respaldo de una instalación anterior
# ------------------------------------------------------------------------------
if [ -e "$DEST" ]; then
  mv "$DEST" "$DEST.bak_$TS"
  log "directorio anterior guardado como $DEST.bak_$TS"
fi

# ------------------------------------------------------------------------------
# 4. Descarga y extracción del repo
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 5. Instaladores por módulo
#    Cada instalador usa solamente los archivos de su propia carpeta.
# ------------------------------------------------------------------------------
for sub in "splash/install.sh" "Vertical-Horizontal Split/install.sh"; do
  [ -f "$DEST/$sub" ] || fail "falta $DEST/$sub"
  log "ejecutando $sub $FLAG"
  sh "$DEST/$sub" "$FLAG"
done

log "listo. Reiniciá el arcade para ver los cambios."
