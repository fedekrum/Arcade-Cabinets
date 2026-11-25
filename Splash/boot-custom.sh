#!/bin/sh
#
#===============================================================================
# Arcade Cabinets - Hook de arranque persistente
#===============================================================================
# Descripción:
#   Se ejecuta desde /etc/init.d/S00bootcustom en cada arranque de Batocera.
#   Reaplica los cambios que el sistema restaura en /etc y /usr, y desactiva
#   el logo temprano para que no se vea antes del splash del usuario.
#
# Uso:
#   bash /boot/boot-custom.sh start    (lo invoca Batocera, no el usuario)
#
# Acciones en "start":
#   1. Quita el permiso de ejecución a S03system-splash y borra su flag.
#   2. Reescribe la línea de fbv en S28splash con -f -e -r -i (estira sin
#      conservar proporción).
#   3. Reemplaza el logo interno de EmulationStation por /boot/splash-es.png.
#   4. Genera/ajusta splash.xml (splash de arranque de ES) con size 1 1.
#   5. Ajusta gamesplash.xml (carga de juegos) con size 1 1.
#
# Notas:
#   - Batocera restaura /etc y /usr en cada reinicio: este hook es el único
#     punto de persistencia de estos cambios.
#   - El tema se lee de es_settings.cfg; si no está, se usa es-theme-carbon.
#   - No modifica ninguna imagen: solo las copia y ajusta cómo se dibujan.
#===============================================================================

case "$1" in
  start)
    # --------------------------------------------------------------------------
    # 1. Logo temprano de Batocera
    #    Lo reemplaza después el splash de /userdata/splash (S28/S30).
    # --------------------------------------------------------------------------
    [ -x /etc/init.d/S03system-splash ] && chmod -x /etc/init.d/S03system-splash
    rm -f /var/run/system-splash.ready

    # --------------------------------------------------------------------------
    # 2. Splash de fbv
    #    /etc se restaura al reiniciar: hay que reaplicar antes de S28splash
    #    el estirado a pantalla completa sin conservar la proporción.
    # --------------------------------------------------------------------------
    if [ -f /etc/init.d/S28splash ]; then
      sed -i '/--exec \/usr\/bin\/fbv --/s/--exec \/usr\/bin\/fbv -- .*/--exec \/usr\/bin\/fbv -- -f -e -r -i "$image"/' /etc/init.d/S28splash
    fi

    # --------------------------------------------------------------------------
    # 3. Fondo de la barra de carga de EmulationStation
    #    ES usa :/logo.png como fondo; nuestra imagen hace que la barra
    #    aparezca sobre ella.
    # --------------------------------------------------------------------------
    if [ -f /boot/splash-es.png ]; then
      cp /boot/splash-es.png /usr/share/emulationstation/resources/logo.png
    fi

    # --------------------------------------------------------------------------
    # 4. Archivos XML del tema
    #    /usr también se restaura al reiniciar. Se estira el fondo sin
    #    conservar proporción ni recortar: minSize hace cover, no stretch.
    # --------------------------------------------------------------------------
    python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET

settings = Path("/userdata/system/configs/emulationstation/es_settings.cfg")
theme = "es-theme-carbon"
if settings.is_file():
    node = ET.parse(settings).getroot().find("./string[@name='ThemeSet']")
    if node is not None:
        theme = node.get("value") or theme
theme_dir = Path("/usr/share/emulationstation/themes") / theme

# El arranque usa splash.xml; gamesplash.xml es la carga de juegos.
path = theme_dir / "splash.xml"
if theme_dir.is_dir():
    if path.is_file():
        tree = ET.parse(path)
    else:
        root = ET.Element("theme")
        ET.SubElement(root, "formatVersion").text = "7"
        tree = ET.ElementTree(root)
    root = tree.getroot()
    view = root.find("./view[@name='splash']")
    if view is None:
        view = ET.SubElement(root, "view", name="splash")
    image = view.find("./image[@name='background']")
    if image is None:
        image = ET.SubElement(view, "image", name="background")
    for child in list(image):
        if child.tag in ("size", "minSize", "maxSize", "pos", "origin"):
            image.remove(child)
    ET.SubElement(image, "pos").text = "0.5 0.5"
    ET.SubElement(image, "origin").text = "0.5 0.5"
    ET.SubElement(image, "size").text = "1 1"
    tree.write(path, encoding="utf-8", xml_declaration=True)

path = theme_dir / "gamesplash.xml"
if path.is_file():
    tree = ET.parse(path)
    for view in tree.getroot().iter("view"):
        if "splash" not in view.get("name", "").replace(",", " ").split():
            continue
        for image in view.findall("./image[@name='background']"):
            for child in list(image):
                if child.tag in ("size", "minSize", "maxSize"):
                    image.remove(child)
            ET.SubElement(image, "size").text = "1 1"
    tree.write(path, encoding="utf-8", xml_declaration=True)
PY
    ;;
esac
