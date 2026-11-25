# Multi-System Verticalizer v4.0

Herramienta optimizada para organizar automáticamente los juegos con orientación vertical (MAME + FBNeo) en Batocera Linux.

## ¿Qué hace?

Este programa identifica y organiza automáticamente los juegos de **MAME** y **FBNeo** que tienen orientación vertical (rotación de 90° o 270°) y los mueve a carpetas separadas, incluyendo ROMs, imágenes y metadatos XML.

## Características v4.0

- ✅ **Multi-sistema** - Soporta MAME y FBNeo en una sola ejecución
- ✅ **Listas separadas optimizadas** - `vertical_mame.txt` y `vertical_fbneo.txt` con formato `gamename 0/1`
- ✅ **Generación rápida para FBNeo** - Usa CSV del sistema (instantáneo vs 15 min de MAME)
- ✅ **Comando bash súper eficiente para MAME** - Procesamiento nativo con `grep` y `awk`
- ✅ **Código bidireccional DRY** - Un solo bucle para ambas direcciones
- ✅ **Función de movimiento reutilizable** - `move_game_complete()` en `move_utils.py`
- ✅ **Procesamiento completo** - ROM + XML + imágenes en una sola operación
- ✅ **Optimizado para Raspberry Pi** - Mínimo I/O de disco, máximo uso de RAM
- ✅ **Reutilización inteligente** - Carga listas existentes si están disponibles
- ✅ **Interfaz mejorada** - Muestra progreso por sistema
- ✅ **Auto-exit** - Sale automáticamente al completar

## Instalación en Batocera

1. **Copia los archivos** a tu Raspberry Pi con Batocera:

   ```bash
   # Monta el share de red y copia los archivos
   cp -r /Volumes/share/roms/pygame/Verticalizer/* /userdata/roms/pygame/Verticalizer/
   ```

2. **Estructura final**:
   ```
   /userdata/roms/pygame/Verticalizer/
   ├── Verticalizer.pygame          # UI principal (nombre requerido)
   └── resources/
       ├── config.py                # Configuración
       ├── hvlistgen.py             # Generador de listas
       ├── move_utils.py            # Utilidades de movimiento
       ├── verticalizer_core.py     # Lógica principal
       ├── vertical.txt             # Lista única (se genera automáticamente)
       └── mame_verticalizer.log    # Log detallado
   ```

## Uso

### Ejecutar desde Batocera UI

1. **Navega** a la sección "Ports" en EmulationStation
2. **Selecciona** "Verticalizer"
3. **Espera** a que complete:
   - **MAME**: Puede tomar 15 minutos la primera vez (genera lista desde MAME)
   - **FBNeo**: Es instantáneo (usa CSV del sistema)
4. **Revisa** los resultados:
   - `/userdata/roms/mame_vertical/` - ROMs verticales de MAME
   - `/userdata/roms/fbneo_vertical/` - ROMs verticales de FBNeo

### Primera ejecución

- **MAME**: Genera `vertical_mame.txt` desde MAME (15 min timeout)
- **FBNeo**: Genera `vertical_fbneo.txt` desde CSV del sistema (instantáneo)
- **Procesa** todos los juegos verticales y horizontales de ambos sistemas
- **Crea** `gamelist.xml` para EmulationStation en cada carpeta vertical
- **Recarga** EmulationStation automáticamente al finalizar

### Ejecuciones posteriores

- **MAME**: Carga `vertical_mame.txt` existente (instantáneo)
- **FBNeo**: Carga `vertical_fbneo.txt` existente (instantáneo)
- **Procesa** solo cambios necesarios en ambos sistemas
- **Mantiene** sincronización bidireccional para cada sistema

## Configuración

Edita `resources/config.py` para personalizar:

```python
# Sistemas soportados
SYSTEMS = {
    'mame': {
        'roms_dir': '/userdata/roms/mame',
        'roms_vertical_dir': '/userdata/roms/mame_vertical',
        'vertical_txt': 'vertical_mame.txt',
        'list_generator': 'mame',  # usa bash pipeline
        'exe': '/usr/bin/mame/mame',
        'csv_file': None,
        'display_name': 'MAME'
    },
    'fbneo': {
        'roms_dir': '/userdata/roms/fbneo',
        'roms_vertical_dir': '/userdata/roms/fbneo_vertical',
        'vertical_txt': 'vertical_fbneo.txt',
        'list_generator': 'fbneo',  # usa CSV
        'exe': None,
        'csv_file': '/usr/share/batocera/configgen/data/special/fbneo.csv',
        'display_name': 'FBNeo'
    }
}

# Log unificado
LOG_FILE = "resources/verticalizer.log"
```

## Archivos generados

### Listas de juegos:
- `resources/vertical_mame.txt` - Lista de MAME con formato `gamename 0/1`
- `resources/vertical_fbneo.txt` - Lista de FBNeo con formato `gamename 0/1`
- `resources/verticalizer.log` - Log detallado unificado del proceso

### Carpetas de ROMs:
- `/userdata/roms/mame_vertical/` - ROMs verticales de MAME
- `/userdata/roms/mame_vertical/gamelist.xml` - Metadatos MAME para EmulationStation
- `/userdata/roms/fbneo_vertical/` - ROMs verticales de FBNeo
- `/userdata/roms/fbneo_vertical/gamelist.xml` - Metadatos FBNeo para EmulationStation

## Lógica de actualización

### MAME:
- **Si existe `vertical_mame.txt`**: Carga instantánea (reutilización)
- **Si no existe**: Genera desde MAME con comando bash optimizado (~15 min)
- **Para forzar regeneración**: Borra `resources/vertical_mame.txt`

### FBNeo:
- **Si existe `vertical_fbneo.txt`**: Carga instantánea (reutilización)
- **Si no existe**: Genera desde CSV del sistema (instantáneo)
- **Para forzar regeneración**: Borra `resources/vertical_fbneo.txt`

## Estructura de directorios

```
/userdata/roms/
├── mame/                    # ROMs originales MAME
│   ├── images/             # Imágenes originales MAME
│   └── gamelist.xml        # Metadatos originales MAME
├── mame_vertical/          # ROMs verticales MAME organizados
│   ├── images/             # Imágenes copiadas MAME
│   └── gamelist.xml        # Metadatos migrados MAME
├── fbneo/                  # ROMs originales FBNeo
│   ├── images/             # Imágenes originales FBNeo
│   └── gamelist.xml        # Metadatos originales FBNeo
└── fbneo_vertical/         # ROMs verticales FBNeo organizados
    ├── images/             # Imágenes copiadas FBNeo
    └── gamelist.xml        # Metadatos migrados FBNeo
```

## Procesamiento bidireccional (por sistema)

Cada sistema se procesa de forma independiente:

### MAME:
1. **Verticales**: MAME → `mame_vertical/` (mueve ROMs verticales)
2. **Horizontales**: `mame_vertical/` → MAME (devuelve ROMs horizontales mal ubicados)

### FBNeo:
1. **Verticales**: FBNeo → `fbneo_vertical/` (mueve ROMs verticales)
2. **Horizontales**: `fbneo_vertical/` → FBNeo (devuelve ROMs horizontales mal ubicados)

## Optimizaciones para Raspberry Pi

- **Comando bash nativo para MAME** - `mame -listxml | grep | awk` (más rápido que Python)
- **CSV directo para FBNeo** - Usa archivo del sistema (mucho más rápido)
- **Listas separadas** - Archivos independientes por sistema (`vertical_mame.txt`, `vertical_fbneo.txt`)
- **Procesamiento en RAM** - Mínimo I/O de SD
- **Reutilización inteligente** - No regenera si las listas ya existen
- **Función DRY** - Un solo bucle para ambas direcciones, reutilizable entre sistemas
- **Procesamiento paralelo** - Procesa ambos sistemas en una sola ejecución

## Solución de problemas

### Error: "MAME not found"

- Verifica que MAME esté instalado: `/usr/bin/mame/mame`
- El programa busca en la ruta configurada en `config.py`

### Error: "Source MAME directory not found"

- Verifica que `/userdata/roms/mame` exista
- Asegúrate de tener ROMs en esa ubicación

### Lista incorrecta

- Borra `resources/vertical.txt` para regenerar
- Revisa el log para ver el proceso de generación

### EmulationStation no actualiza

- El programa recarga automáticamente
- Si no funciona, reinicia EmulationStation manualmente

## Logs

Revisa `resources/mame_verticalizer.log` para información detallada:

```
=== MAME VERTICALIZER START ===
[HVLIST] Generating vertical list using bash pipeline...
[HVLIST] COMPLETED: 3258 vertical, 44910 horizontal games
[PROCESS] Processing 48168 games bidirectionally...
[MOVE] Moving pacman (vertical)...
[MOVE] pacman completed: ROM=True, XML=True, Images=True
=== COMPLETED: Done. vertical=3258 horizontal=44910 ===
```

## Ejemplo de salida

```
=== MAME VERTICALIZER START ===
[VERTICAL] Using existing list: 3258 vertical, 44910 horizontal
[PROCESS] Processing 48168 games bidirectionally...
[MOVE] Moving 1944 (vertical)...
[MOVE] 1944 completed: ROM=True, XML=True, Images=True
[GAMELIST] Created gamelist.xml with 3258 games migrated
[RELOAD] EmulationStation reload attempted
=== COMPLETED: Done. vertical=3258 horizontal=44910 ===
```

## Arquitectura del código

- **`Verticalizer.pygame`** - UI principal con pygame
- **`resources/verticalizer_core.py`** - Lógica principal
- **`resources/hvlistgen.py`** - Generador de listas con bash
- **`resources/move_utils.py`** - Utilidades de movimiento reutilizables
- **`resources/config.py`** - Configuración centralizada
