#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Configuration file for Multi-System Verticalizer (MAME + FBNeo)
"""
import os

# Paths configuration for Batocera Linux
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Sistemas soportados con sus configuraciones
SYSTEMS = {
    'mame': {
        'roms_dir': '/userdata/roms/mame',
        'roms_vertical_dir': '/userdata/roms/mame_vertical',
        'vertical_txt': 'vertical_mame.txt',  # Archivo separado
        'list_generator': 'mame',  # usa bash pipeline
        'exe': '/usr/bin/mame/mame',
        'csv_file': None,
        'display_name': 'MAME'
    },
    'fbneo': {
        'roms_dir': '/userdata/roms/fbneo',
        'roms_vertical_dir': '/userdata/roms/fbneo_vertical',
        'vertical_txt': 'vertical_fbneo.txt',  # Archivo separado
        'list_generator': 'fbneo',  # usa CSV
        'exe': None,
        'csv_file': '/usr/share/batocera/configgen/data/special/fbneo.csv',
        'display_name': 'FBNeo'
    }
}

# Sistemas a procesar (lista vacía = todos)
SYSTEMS_TO_PROCESS = []  # Si está vacío, procesa todos

# Log unificado
LOG_FILE = os.path.join(BASE_DIR, "verticalizer.log")

# Backward compatibility: mantener variables antiguas para código que aún las use
ROMS_MAME = SYSTEMS['mame']['roms_dir']
ROMS_MAME_VERTICAL = SYSTEMS['mame']['roms_vertical_dir']
IMAGES_MAME = os.path.join(ROMS_MAME, "images")
IMAGES_MAME_VERTICAL = os.path.join(ROMS_MAME_VERTICAL, "images")
VERTICAL_TXT = os.path.join(BASE_DIR, SYSTEMS['mame']['vertical_txt'])
HORIZONTAL_TXT = os.path.join(BASE_DIR, "horizontal.txt")
MAME_EXE = SYSTEMS['mame']['exe']

# UI Settings
UI_WIDTH = 1024
UI_HEIGHT = 600
UI_FPS = 15

