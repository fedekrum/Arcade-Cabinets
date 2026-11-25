#!/bin/sh
case "$1" in
  start)
    # Desactiva logo temprano de Batocera; el splash custom de /userdata/splash lo maneja S28/S30.
    [ -x /etc/init.d/S03system-splash ] && chmod -x /etc/init.d/S03system-splash
    rm -f /var/run/system-splash.ready
    # /etc se restaura al reiniciar Batocera. Reaplicar antes de S28splash
    # el estirado a pantalla completa sin conservar la proporción.
    if [ -f /etc/init.d/S28splash ]; then
      sed -i '/--exec \/usr\/bin\/fbv --/s/--exec \/usr\/bin\/fbv -- .*/--exec \/usr\/bin\/fbv -- -f -e -r -i "$image"/' /etc/init.d/S28splash
    fi
    # La pantalla de carga de EmulationStation usa :/logo.png como fondo.
    # Lo cambiamos por nuestra imagen para que la barra aparezca sobre ella.
    if [ -f /boot/splash-es.png ]; then
      cp /boot/splash-es.png /usr/share/emulationstation/resources/logo.png
    fi
    # /usr también se restaura al reiniciar. Estirar el fondo de ES sin
    # conservar proporción ni recortar (minSize hace cover, no stretch).
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
