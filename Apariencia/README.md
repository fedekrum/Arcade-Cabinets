# Apariencia

Acá voy a guardar la configuración visual de los muebles: el shader global,
el de Game and Watch y cualquier otro ajuste de apariencia.

Estado relevado el 2026-11-25 en sf2 (Pi 5) y pacman (Pi 4):

- `global.shaderset=curvature`
- `mame.shaderset=curvature`
- `mame_vertical.shaderset=curvature`
- `gameandwatch.shaderset=none`

En las Pi, el set `curvature` usa `crt/fakelottes` para los sistemas de arcade.

## Instalador

`install.sh` aplica los ajustes con `batocera-settings-set`: set global
`curvature`, MAME/MAME vertical `curvature` y Game and Watch `none`. No copia
archivos de shader: Batocera ya los trae en `/usr/share/batocera/shaders`.

## Archivos

- `scrappers.md`: credenciales de ScreenScraper relevadas de pacman.
