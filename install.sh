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
#   sh install.sh [-h|-v] [-p CLAVE | -pCLAVE]
#
# Parámetros:
#   -h  modo horizontal (valor por defecto)
#   -v  modo vertical
#   -p  contraseña de los .tar.gz.gpg de Sistemas/DATA. Acepta -p 1234 y
#       -p1234. Si no se pasa, ese módulo avisa y salta los archives cifrados.
#
# Requisitos:
#   - Ejecutar como root dentro de Batocera (debe existir /userdata).
#   - Necesita tar y curl o wget.
#
# Variables de entorno:
#   ARCADE_INSTALL_DIR  destino del repo (por defecto /userdata/arcade-cabinets)
#
# Efectos:
#   - Ejecuta Apariencia/install.sh, Splash/install.sh,
#     Vertical-Horizontal Split/install.sh y Sistemas/install.sh.
#   - La contraseña de -p se pasa solo a Sistemas/install.sh; los demás
#     módulos reciben únicamente -h o -v.
#   - Al terminar borra el repo descargado, el directorio temporal y el propio
#     script si se ejecutó desde /tmp. No queda nada del proceso salvo lo que
#     instalaron los módulos.
#===============================================================================

set -eu

# ------------------------------------------------------------------------------
# Utilidades de salida
# ------------------------------------------------------------------------------
log()  { printf '[arcade] %s\n' "$*"; }
fail() { printf '[arcade] ERROR: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# Limpieza final
#   Se ejecuta al salir, incluso si falla: borra el repo descargado, el
#   directorio temporal y el propio script si se bajó a /tmp.
# ------------------------------------------------------------------------------
limpieza() {
  if [ -n "${TMP:-}" ] && [ -d "$TMP" ]; then
    rm -rf "$TMP"
  fi
  if [ -n "${DEST:-}" ]; then
    if [ -e "$DEST" ]; then
      rm -rf "$DEST"
      log "limpieza: borrado $DEST"
    fi
  fi
  # Si el instalador se bajó suelto a /tmp, no deja ni el script.
  case "$0" in
    /tmp/*|/var/tmp/*) rm -f -- "$0" ;;
  esac
}
trap 'limpieza' EXIT

# ------------------------------------------------------------------------------
# 1. Modo de instalación y contraseña
#    Los parámetros se pueden dar en cualquier orden. -p admite las dos formas:
#    "-p 1234" y "-p1234".
# ------------------------------------------------------------------------------
MODE=horizontal
FLAG=-h
PASS=
HAS_PASS=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -v)
      MODE=vertical
      FLAG=-v
      ;;
    -h)
      MODE=horizontal
      FLAG=-h
      ;;
    -p)
      shift
      [ "$#" -gt 0 ] || fail "-p necesita una contraseña"
      PASS=$1
      HAS_PASS=1
      ;;
    -p?*)
      PASS=${1#-p}
      HAS_PASS=1
      ;;
    *) fail "uso: $0 [-h|-v] [-p CLAVE | -pCLAVE]" ;;
  esac
  shift
done

# ------------------------------------------------------------------------------
# 2. Validación del entorno
# ------------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"

REPO_URL="https://codeload.github.com/fedekrum/Arcade-Cabinets/tar.gz/refs/heads/master"
DEST=${ARCADE_INSTALL_DIR:-/userdata/arcade-cabinets}
TMP="/tmp/arcade-install.$$"

command -v tar >/dev/null 2>&1 || fail "falta tar"
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  fail "falta curl o wget"
fi

mkdir -p "$TMP"

# ------------------------------------------------------------------------------
# 3. Descarte de una instalación anterior
# ------------------------------------------------------------------------------
if [ -e "$DEST" ]; then
  rm -rf "$DEST"
  log "directorio anterior descartado: $DEST"
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
for sub in "Apariencia/install.sh" "Splash/install.sh" "Vertical-Horizontal Split/install.sh" "Sistemas/install.sh"; do
  [ -f "$DEST/$sub" ] || fail "falta $DEST/$sub"

  if [ "$sub" = "Sistemas/install.sh" ] && [ "$HAS_PASS" -eq 1 ]; then
    # La clave viaja solo al módulo que desencripta; los otros ni la reciben.
    log "ejecutando $sub con -p"
    sh "$DEST/$sub" "-p$PASS"
  else
    log "ejecutando $sub $FLAG"
    sh "$DEST/$sub" "$FLAG"
  fi
done

log "listo. Reiniciá el arcade para ver los cambios."
