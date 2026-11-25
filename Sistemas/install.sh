#!/bin/sh
#
#===============================================================================
# Arcade Cabinets - Instalador de sistemas y ROMs cifradas
#===============================================================================
# Descripción:
#   Instala los sistemas de DATA/ desde archivos .tar.gz.gpg. El nombre del
#   archivo (sin la extensión) es la carpeta de /userdata/roms que se instala.
#   Además ajusta el sistema "pygame" de EmulationStation para ejecutar los
#   archivos .pygame directamente, como en pacman.
#
# Uso:
#   sh install.sh [-p CLAVE | -pCLAVE]
#
# Parámetros:
#   -p  contraseña de los archivos cifrados. Acepta las dos formas: -p 1234 y
#       -p1234. Sin -p se avisa y se saltan todos los .gpg; el resto del
#       instalador sigue (el ajuste de pygame no necesita contraseña).
#   -h, -v  se aceptan y se ignoran: el instalador principal los reenvía a
#       todos los módulos con el mismo parámetro.
#
# Requisitos:
#   - Ejecutar como root dentro de Batocera (debe existir /userdata).
#   - Necesita gpg, tar, gzip y python3.
#   - Deben estar en esta carpeta: DATA/ y pygame-system.xml.
#
# Archivos modificados:
#   /userdata/roms/<sistema>  (uno por cada .tar.gz.gpg de DATA/)
#   /userdata/roms/pygame     (solo si está ese archive: modo aditivo)
#   /userdata/system/configs/emulationstation/es_systems_custom.cfg
#
# Notas:
#   - Sistemas normales: si /userdata/roms/<sistema>/gamelist.xml ya existe, no
#     se toca nada. Si no existe, se vacía la carpeta y se extrae el archive.
#   - pygame es la excepción: conserva lo que ya haya en /userdata/roms/pygame,
#     sobrescribe Referencia/ y Verticalizer/, agrega images/Verticalizer.png y
#     agrega al gamelist.xml solo las entradas de Referencia y Verticalizer.
#   - No crea respaldos: los archivos se sobrescriben directamente.
#   - El directorio temporal con la clave y los archives se borra al salir,
#     incluso si falla. Si el script se bajó suelto a /tmp, también se borra.
#===============================================================================

set -eu

# ------------------------------------------------------------------------------
# Utilidades de salida
# ------------------------------------------------------------------------------
log()  { printf '[sistemas] %s\n' "$*"; }
fail() { printf '[sistemas] ERROR: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# Limpieza final
#   Borra el temporal donde se guarda la clave y se descomprimen los archives.
#   Se ejecuta al salir, incluso si falla, para no dejar ROMs ni secretos atrás.
# ------------------------------------------------------------------------------
limpieza() {
  if [ -n "${TMP:-}" ] && [ -d "$TMP" ]; then
    rm -rf "$TMP"
  fi
  if [ -n "${PASSFILE:-}" ] && [ -f "$PASSFILE" ]; then
    rm -f -- "$PASSFILE"
  fi
  case "$0" in
    /tmp/*|/var/tmp/*) rm -f -- "$0" ;;
  esac
}
trap 'limpieza' EXIT

# ------------------------------------------------------------------------------
# 1. Parámetros
# ------------------------------------------------------------------------------
PASS=
HAS_PASS=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -p)
      shift
      [ "$#" -gt 0 ] || fail "uso: $0 [-p CLAVE | -pCLAVE]"
      PASS=$1
      HAS_PASS=1
      ;;
    -p?*)
      PASS=${1#-p}
      HAS_PASS=1
      ;;
    -h|-v) ;;
    *) fail "uso: $0 [-p CLAVE | -pCLAVE]" ;;
  esac
  shift
done

# ------------------------------------------------------------------------------
# 2. Validación del entorno y de los archivos propios del módulo
# ------------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || fail "hay que ejecutarlo como root"
[ -d /userdata ] || fail "esto no parece Batocera"

for cmd in gpg tar gzip python3; do
  command -v "$cmd" >/dev/null 2>&1 || fail "falta $cmd en el sistema"
done

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DATA=$HERE/DATA
[ -d "$DATA" ] || fail "no encontré $DATA"
[ -f "$HERE/pygame-system.xml" ] || fail "no encontré $HERE/pygame-system.xml"

ESDIR=/userdata/system/configs/emulationstation
CUSTOM=$ESDIR/es_systems_custom.cfg

TMP=$(mktemp -d "${TMPDIR:-/tmp}/arcade-sistemas.XXXXXX")
PASSFILE=$TMP/passphrase

# GPG 1.4 (Batocera) no entiende --pinentry-mode; GPG 2.x sí lo necesita para
# usar una contraseña por fd sin pedirla por pantalla.
GPG_OPTS='--batch --yes --no-tty --passphrase-fd 3'
if gpg --version 2>/dev/null | head -1 | grep -q 'GnuPG) 2'; then
  GPG_OPTS="$GPG_OPTS --pinentry-mode loopback"
fi

log "instalando sistemas desde $DATA"

# ------------------------------------------------------------------------------
# 3. Preparación
#    ES se detiene antes de tocar ROMs o su configuración: al salir podría
#    reescribir es_systems_custom.cfg con lo que tiene en memoria.
# ------------------------------------------------------------------------------
if [ -x /etc/init.d/S31emulationstation ]; then
  /etc/init.d/S31emulationstation stop >/dev/null 2>&1 || true
fi
mkdir -p "$ESDIR" /userdata/roms

# ------------------------------------------------------------------------------
# 4. Sistemas cifrados
#    Cada .tar.gz.gpg se desencripta en el temporal antes de extraerse, para
#    que un archive corrupto no deje la carpeta de destino a medias.
# ------------------------------------------------------------------------------
if [ "$HAS_PASS" -eq 1 ]; then
  printf '%s\n' "$PASS" > "$PASSFILE"
  chmod 600 "$PASSFILE"

  found=0
  for archive in "$DATA"/*.tar.gz.gpg; do
    [ -f "$archive" ] || continue
    found=1

    name=$(basename "$archive")
    name=${name%.tar.gz.gpg}
    packed=$TMP/$name.tar.gz

    log "desencriptando $name"
    # shellcheck disable=SC2086  # GPG_OPTS es una lista de opciones fija.
    gpg $GPG_OPTS --output "$packed" -d "$archive" 3<"$PASSFILE"

    # --------------------------------------------------------------------------
    # 4a. pygame: modo aditivo. Nunca se borra lo que ya había en la carpeta;
    #     solo se sobrescriben las dos herramientas y se suman sus entradas.
    # --------------------------------------------------------------------------
    if [ "$name" = pygame ]; then
      unpacked=$TMP/pygame
      mkdir -p "$unpacked"
      tar -xzf "$packed" -C "$unpacked"

      for req in Referencia Verticalizer images/Verticalizer.png gamelist-add.xml; do
        [ -e "$unpacked/$req" ] || fail "al archive pygame le falta $req"
      done

      dest=/userdata/roms/pygame
      mkdir -p "$dest/images"
      cp -a "$unpacked/Referencia" "$unpacked/Verticalizer" "$dest/"
      cp -f "$unpacked/images/Verticalizer.png" "$dest/images/Verticalizer.png"
      chmod 755 "$dest/Verticalizer/Verticalizer.pygame" \
                "$dest/Referencia/Referencia.pygame"

      # Inserta los bloques nuevos antes de </gameList> sin tocar las entradas
      # existentes; si el path ya está, no lo duplica.
      python3 - "$dest/gamelist.xml" "$unpacked/gamelist-add.xml" <<'PY'
import re
import sys

gamelist, additions = sys.argv[1], sys.argv[2]
new = open(additions, encoding="utf-8").read()

try:
    xml = open(gamelist, encoding="utf-8").read()
except FileNotFoundError:
    xml = "<?xml version='1.0' encoding='utf-8'?>\n<gameList>\n</gameList>\n"

changed = False
for block in re.findall(r"<game>.*?</game>", new, re.S):
    path = re.search(r"<path>(.*?)</path>", block, re.S)
    if path is None:
        continue
    if "<path>%s</path>" % path.group(1) in xml:
        print("[sistemas] pygame: %s ya estaba en gamelist.xml" % path.group(1))
        continue
    if "</gameList>" not in xml:
        print("[sistemas] pygame: no encontré </gameList>, revisalo a mano")
        break
    xml = xml.replace("</gameList>", "\t%s\n</gameList>" % block.strip(), 1)
    changed = True
    print("[sistemas] pygame: %s agregado a gamelist.xml" % path.group(1))

if changed:
    open(gamelist, "w", encoding="utf-8").write(xml)
PY

      log "pygame: Referencia, Verticalizer y Verticalizer.png actualizados"
      continue
    fi

    # --------------------------------------------------------------------------
    # 4b. Resto de sistemas: solo se instalan si todavía no hay gamelist.xml.
    # --------------------------------------------------------------------------
    dest=/userdata/roms/$name
    if [ -f "$dest/gamelist.xml" ]; then
      log "$name: ya hay gamelist.xml, no toco nada"
      continue
    fi

    mkdir -p "$dest"
    find "$dest" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
    tar -xzf "$packed" -C "$dest"
    log "$name: instalado desde $archive"
  done

  [ "$found" -eq 1 ] || log "aviso: no hay .tar.gz.gpg en $DATA"
else
  log "sin -p: se saltan los .tar.gz.gpg de DATA/"
fi

# ------------------------------------------------------------------------------
# 5. Sistema pygame de EmulationStation
#    La lista stock usa batocera-launch; pacman ejecuta el .pygame con %ROM%.
#    Si el sistema no existe, se agrega desde la plantilla pygame-system.xml.
# ------------------------------------------------------------------------------
if [ ! -f "$CUSTOM" ]; then
  [ -f /usr/share/emulationstation/es_systems.cfg ] || fail "no encontré la lista stock de sistemas"
  cp /usr/share/emulationstation/es_systems.cfg "$CUSTOM"
  log "es_systems_custom.cfg creado desde la lista stock"
fi

python3 - "$CUSTOM" "$HERE/pygame-system.xml" <<'PY'
import re
import sys

custom, template = sys.argv[1], sys.argv[2]
s = open(custom, encoding="utf-8").read()
pat = r"<system>(?:(?!</system>).)*?<name>pygame</name>(?:(?!</system>).)*?</system>"
m = re.search(pat, s, re.S)

if m:
    block = m.group(0)
    if "<command>%ROM%</command>" in block:
        print("[sistemas] pygame ya ejecutaba %ROM%")
    else:
        block = re.sub(r"<command>[^<]*</command>", "<command>%ROM%</command>", block, count=1)
        block = re.sub(r"<fullname>[^<]*</fullname>", "<fullname>Python Games</fullname>", block, count=1)
        s = s[:m.start()] + block + s[m.end():]
        open(custom, "w", encoding="utf-8").write(s)
        print("[sistemas] pygame ajustado a %ROM%")
else:
    bloque = open(template, encoding="utf-8").read()
    if "</systemList>" in s:
        s = s.replace("</systemList>", bloque + "\n</systemList>", 1)
        open(custom, "w", encoding="utf-8").write(s)
        print("[sistemas] pygame agregado desde la plantilla")
    else:
        print("[sistemas] no encontré </systemList>, revisalo a mano")
PY

log "listo. Reiniciá el arcade para ver los cambios."
