#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import subprocess
import re
import time
import config
from datetime import datetime

def _log(msg: str) -> None:
    line = f"[{datetime.now().isoformat(timespec='seconds')}] {msg}"
    print(line)
    try:
        os.makedirs(os.path.dirname(config.LOG_FILE), exist_ok=True)
        with open(config.LOG_FILE, "a", encoding="utf-8", buffering=8192) as f:
            f.write(line + "\n")
    except Exception as e:
        print(f"[LOG ERROR] {e}")

def is_vertical_game(xml_output: str) -> bool:
    """Determine if a game is vertical based on its XML output."""
    # Check for rotation
    if 'rotate="90"' in xml_output or 'rotate="270"' in xml_output:
        return True
    
    # Check for games with vertical dimensions (width < height)
    width_match = re.search(r'width="(\d+)"', xml_output)
    height_match = re.search(r'height="(\d+)"', xml_output)
    
    if width_match and height_match:
        width = int(width_match.group(1))
        height = int(height_match.group(1))
        return width < height
    
    return False

def hvListGen_mame() -> None:
    """Generate single vertical_mame.txt with format 'gamename 0/1' using efficient bash pipeline."""
    _log("=== GENERATING MAME VERTICAL LIST (BASH OPTIMIZED) ===")
    
    try:
        system_config = config.SYSTEMS['mame']
        exe = system_config['exe']
        vertical_txt = os.path.join(config.BASE_DIR, system_config['vertical_txt'])
        
        # Step 1: Use MAME executable
        _log("[HVLIST] Using MAME executable...")
        
        if not os.path.isfile(exe):
            raise RuntimeError(f"MAME executable not found: {exe}")
        
        _log(f"[HVLIST] MAME exe: {exe}")
        
        # Step 2: Run the efficient bash pipeline
        _log("[HVLIST] Running MAME listxml with bash pipeline...")
        
        bash_command = f"""{exe} -listxml \\
| grep -E '^[[:space:]]*<(mame|/mame|machine|/machine|display)([[:space:]>]|$)' \\
| awk '
  BEGIN{{in_m=0;have=0;pref=0;hdr="";rot="";vertical=0}}
  /^[[:space:]]*<machine[ >]/{{in_m=1;have=0;pref=0;hdr=$0;rot="";vertical=0;next}}
  in_m && /^[[:space:]]*<display[ >]/{{line=$0; take=(!have)||(line~/tag="screen"/);
    if(take){{
      rot="0"; if(match(line,/rotate="[^"]+"/)) rot=substr(line,RSTART+8,RLENGTH-9);
      vertical=(rot=="90"||rot=="270")?1:0; have=1; pref=(line~/tag="screen"/)?2:1
    }}
    next}}
  /^[[:space:]]*<\\/machine>/{{if(in_m&&have){{
      name=""; if(match(hdr,/name="[^"]*"/)){{name=substr(hdr,RSTART,RLENGTH); sub(/^name="/,"",name); sub(/"$/,"",name)}}
      printf "%s %d\\n", name, vertical
    }} in_m=0; next}}
'"""
        
        _log("[HVLIST] Executing bash pipeline...")
        result = subprocess.run(bash_command, 
                              shell=True, 
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.PIPE, 
                              timeout=900,  # 15 minutes timeout
                              text=True)
        
        if result.returncode != 0:
            _log(f"[HVLIST ERROR] Bash pipeline failed: {result.stderr}")
            raise RuntimeError(f"Bash pipeline failed: {result.stderr}")
        
        _log(f"[HVLIST] Bash pipeline completed, processing {len(result.stdout)} characters")
        
        # Step 3: Save the raw output directly to vertical_mame.txt
        _log("[HVLIST] Saving raw output to vertical_mame.txt...")
        
        # Sort the output and save to vertical_mame.txt
        lines = result.stdout.strip().split('\n')
        sorted_lines = sorted(lines)
        
        with open(vertical_txt, "w", encoding="utf-8") as f:
            for line in sorted_lines:
                if line.strip():
                    f.write(line + "\n")
        
        _log(f"[HVLIST] Saved {len(sorted_lines)} games to {vertical_txt}")
        
        # Count vertical and horizontal for logging
        vertical_count = 0
        horizontal_count = 0
        for line in sorted_lines:
            if line.strip():
                parts = line.strip().split()
                if len(parts) == 2:
                    if parts[1] == "1":
                        vertical_count += 1
                    else:
                        horizontal_count += 1
        
        _log(f"[HVLIST] COMPLETED: {vertical_count} vertical, {horizontal_count} horizontal MAME games")
        
    except subprocess.TimeoutExpired:
        _log("[HVLIST ERROR] Timeout after 15 minutes")
        raise RuntimeError("MAME listxml timeout after 15 minutes")
    except Exception as e:
        _log(f"[HVLIST ERROR] {e}")
        raise

def hvListGen_fbneo() -> None:
    """Generate single vertical_fbneo.txt with format 'gamename 0/1' using CSV file."""
    _log("=== GENERATING FBNEO VERTICAL LIST FROM CSV ===")
    
    try:
        system_config = config.SYSTEMS['fbneo']
        csv_file = system_config['csv_file']
        vertical_txt = os.path.join(config.BASE_DIR, system_config['vertical_txt'])
        
        if not os.path.isfile(csv_file):
            raise RuntimeError(f"FBNeo CSV not found: {csv_file}")
        
        _log(f"[HVLIST] Reading FBNeo CSV: {csv_file}")
        
        vertical = set()
        horizontal = set()
        
        # Leer CSV: formato gamename;rotation
        with open(csv_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or ';' not in line:
                    continue
                
                parts = line.split(';')
                if len(parts) == 2:
                    game_name = parts[0].strip()
                    rotation = parts[1].strip()
                    
                    # Rotación 90 o 270 = vertical
                    is_vertical = rotation in ('90', '270')
                    
                    if is_vertical:
                        vertical.add(game_name)
                    else:
                        horizontal.add(game_name)
        
        # Escribir vertical_fbneo.txt con formato "gamename 0/1"
        _log(f"[HVLIST] Writing vertical list to {vertical_txt}...")
        
        with open(vertical_txt, 'w', encoding='utf-8') as f:
            # Escribir verticales
            for game in sorted(vertical):
                f.write(f"{game} 1\n")
            # Escribir horizontales
            for game in sorted(horizontal):
                f.write(f"{game} 0\n")
        
        _log(f"[HVLIST] Saved {len(vertical)} vertical and {len(horizontal)} horizontal games to {vertical_txt}")
        _log(f"[HVLIST] COMPLETED: {len(vertical)} vertical, {len(horizontal)} horizontal FBNeo games")
        
    except Exception as e:
        _log(f"[HVLIST ERROR] {e}")
        raise

# Backward compatibility: mantener función original
def hvListGen() -> None:
    """Generate single vertical.txt with format 'gamename 0/1' using efficient bash pipeline (MAME)."""
    hvListGen_mame()

if __name__ == "__main__":
    # Si se ejecuta directamente, procesar todos los sistemas disponibles
    for system in config.SYSTEMS.keys():
        try:
            if system == 'mame':
                hvListGen_mame()
            elif system == 'fbneo':
                hvListGen_fbneo()
        except Exception as e:
            _log(f"[ERROR] Failed to generate list for {system}: {e}")

