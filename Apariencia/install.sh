#!/bin/sh
#
#===============================================================================
# Arcade Cabinets - Instalador de apariencia
#===============================================================================
# Descripción:
#   Aplica la selección de shaders usada en los arcades. No copia archivos de
#   shader: Batocera ya los incluye en /usr/share/batocera/shaders y el set se
#   elige desde batocera.conf.
#
# Uso:
#   sh install.sh [-h|-v]
#   El modo se acepta y se ignora, para que lo pueda llamar el instalador
#   principal con el mismo parámetro que usa para los otros módulos.
#
# Ajustes aplicados:
#   global.shaderset        = curvature  (en Pi usa crt/fakelottes)
#   mame.shaderset          = curvature
#   mame_vertical.shaderset = curvature
#   gameandwatch.shaderset  = none
#   FBNeo hereda el global.
#
# Requisitos:
#   - Ejecutar como root dentro de Batocera (debe existir /userdata).
#   - Necesita batocera-settings-set.
#
# Notas:
#   - batocera.conf se respalda con sufijo .bak_<fecha>.
#   - Si en el futuro se usan shaders propios, recién ahí tiene sentido
#     guardar los archivos .glslp/.slangp en esta carpeta.
#===============================================================================

set -eu

# ------------------------------------------------------------------------------
# Utilidades de salida
# ------------------------------------------------------------------------------
log()  { printf '[apariencia] %s\n' "$*"; }
fail() { printf '[apariencia] ERROR: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# 1. Modo (se ignora; solo se valida)
# ------------------------------------------------------------------------------
case "${1:-}" in
  -h|-v|"") ;;
  *) fail "uso: $0 [-h|-v]  (el modo no cambia los shaders)" ;;
esac

# ------------------------------------------------------------------------------
# 2. Validación del entorno
# ------------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"
command -v batocera-settings-set >/dev/null 2>&1 || fail "falta batocera-settings-set"

BATOCERA_CONF=/userdata/system/batocera.conf
[ -f "$BATOCERA_CONF" ] || fail "no encontré $BATOCERA_CONF"
TS=$(date +%Y%m%d_%H%M%S)

# ------------------------------------------------------------------------------
# 3. Respaldo y aplicación de los shaders
# ------------------------------------------------------------------------------
cp -a "$BATOCERA_CONF" "$BATOCERA_CONF.bak_$TS"
log "backup: $BATOCERA_CONF.bak_$TS"

batocera-settings-set \
  global.shaderset curvature \
  mame.shaderset curvature \
  mame_vertical.shaderset curvature \
  gameandwatch.shaderset none

log "shaders aplicados: global/mame/mame_vertical=curvature, gameandwatch=none"
