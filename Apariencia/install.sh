#!/bin/sh
#
#===============================================================================
# Arcade Cabinets - Instalador de apariencia
#===============================================================================
# Descripción:
#   Aplica la selección de shaders usada en los arcades y las credenciales de
#   ScreenScraper. No copia archivos de shader: Batocera ya los incluye en
#   /usr/share/batocera/shaders y el set se elige desde batocera.conf.
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
#   ScreenScraperUser/Pass en es_settings.cfg (ver scrappers.md).
#
# Requisitos:
#   - Ejecutar como root dentro de Batocera (debe existir /userdata).
#   - Necesita batocera-settings-set.
#
# Notas:
#   - No crea respaldos: los archivos se sobrescriben directamente.
#   - Si en el futuro se usan shaders propios, recién ahí tiene sentido
#     guardar los archivos .glslp/.slangp en esta carpeta.
#   - Si el script se bajó suelto a /tmp, se borra solo al terminar.
#===============================================================================

set -eu

# ------------------------------------------------------------------------------
# Utilidades de salida
# ------------------------------------------------------------------------------
log()  { printf '[apariencia] %s\n' "$*"; }
fail() { printf '[apariencia] ERROR: %s\n' "$*" >&2; exit 1; }

# Limpieza final: si el módulo se bajó suelto a /tmp, no deja el script.
limpieza() {
  case "$0" in
    /tmp/*|/var/tmp/*) rm -f -- "$0" ;;
  esac
}
trap 'limpieza' EXIT

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

# ------------------------------------------------------------------------------
# 3. Aplicación de los shaders
# ------------------------------------------------------------------------------
batocera-settings-set \
  global.shaderset curvature \
  mame.shaderset curvature \
  mame_vertical.shaderset curvature \
  gameandwatch.shaderset none

log "shaders aplicados: global/mame/mame_vertical=curvature, gameandwatch=none"

# ------------------------------------------------------------------------------
# 4. Credenciales de ScreenScraper
#    ES se detiene antes de escribir para que no sobrescriba es_settings.cfg
#    al salir. Valores documentados en scrappers.md.
# ------------------------------------------------------------------------------
ES_SETTINGS=/userdata/system/configs/emulationstation/es_settings.cfg
if [ -f "$ES_SETTINGS" ]; then
  if [ -x /etc/init.d/S31emulationstation ]; then
    /etc/init.d/S31emulationstation stop >/dev/null 2>&1 || true
  fi
  python3 - "$ES_SETTINGS" <<'PY'
import re, sys

p = sys.argv[1]
s = open(p, encoding="utf-8").read()

def poner(texto, nombre, valor):
    patron = r'<string name="%s" value="[^"]*"\s*/>' % re.escape(nombre)
    nuevo = '<string name="%s" value="%s" />' % (nombre, valor)
    if re.search(patron, texto):
        return re.sub(patron, nuevo, texto, count=1)
    return texto.replace("</config>", "\t" + nuevo + "\n</config>", 1)

s = poner(s, "ScreenScraperUser", "fedekrum")
s = poner(s, "ScreenScraperPass", "HjCTfjBGeR62zJ")
open(p, "w", encoding="utf-8").write(s)
PY
  log "credenciales de ScreenScraper aplicadas"
else
  log "no encontré $ES_SETTINGS; credenciales no aplicadas"
fi
