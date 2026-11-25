#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, subprocess, xml.etree.ElementTree as ET, traceback
from datetime import datetime
from typing import Optional, Tuple, Set, Dict, List

# Import configuration
import config

# Use configuration values (backward compatibility)
LOG_FILE = config.LOG_FILE

def _log(msg: str) -> None:
    line = f"[{datetime.now().isoformat(timespec='seconds')}] {msg}"
    print(line)
    try:
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        # Use buffering for better performance on SD cards
        with open(LOG_FILE, "a", encoding="utf-8", buffering=8192) as f:
            f.write(line + "\n")
    except Exception as e:
        print(f"[LOG ERROR] {e}")

def _ensure_dir(path: str) -> None:
    """Create directory if it doesn't exist."""
    os.makedirs(path, exist_ok=True)

def _ensure_dirs_for_system(system_config: dict) -> None:
    """Create necessary directories and validate paths for a system."""
    try:
        _ensure_dir(system_config['roms_vertical_dir'])
        images_vertical_dir = os.path.join(system_config['roms_vertical_dir'], "images")
        _ensure_dir(images_vertical_dir)
        _log(f"[DIRS] Created directories for {system_config['display_name']} vertical ROMs")
    except Exception as e:
        _log(f"[DIRS ERROR] Failed to create directories for {system_config['display_name']}: {e}")
        raise

def _load_vertical_horizontal_lists_for_system(system_config: dict) -> Tuple[Set[str], Set[str]]:
    """Load vertical and horizontal game lists from system's vertical.txt file."""
    vertical = set()
    horizontal = set()
    
    vertical_txt = os.path.join(config.BASE_DIR, system_config['vertical_txt'])
    
    # Load from single vertical.txt file with format "gamename 0/1"
    if os.path.isfile(vertical_txt):
        try:
            with open(vertical_txt, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        parts = line.split()
                        if len(parts) == 2:
                            game_name = parts[0]
                            is_vertical = parts[1] == "1"
                            if is_vertical:
                                vertical.add(game_name)
                            else:
                                horizontal.add(game_name)
                        else:
                            _log(f"[LOAD WARNING] Invalid line format: {line}")
            
            _log(f"[LOAD] Loaded {len(vertical)} vertical and {len(horizontal)} horizontal {system_config['display_name']} games from {vertical_txt}")
        except Exception as e:
            _log(f"[LOAD ERROR] Failed to load {system_config['display_name']} vertical list: {e}")
    else:
        _log(f"[LOAD] {vertical_txt} not found, will generate from {system_config['display_name']}")
    
    return vertical, horizontal

def _ensure_gamelist_dirs_for_system(system_config: dict) -> None:
    """Ensure directories exist for gamelist.xml creation for a system."""
    _log(f"[GAMELIST] Ensuring images directories exist for {system_config['display_name']}...")
    images_vertical_dir = os.path.join(system_config['roms_vertical_dir'], "images")
    _ensure_dir(images_vertical_dir)
    _log(f"[GAMELIST] Created images directory: {images_vertical_dir}")

def _create_gamelist_xml_for_system(system_config: dict, vertical_games: Set[str]) -> None:
    """Create gamelist.xml for the vertical folder by migrating data from original gamelist.xml."""
    _log(f"[GAMELIST] Creating gamelist.xml for {system_config['display_name']} vertical folder...")
    
    try:
        _ensure_gamelist_dirs_for_system(system_config)
        
        # Read original gamelist.xml
        original_gamelist = os.path.join(system_config['roms_dir'], "gamelist.xml")
        vertical_gamelist = os.path.join(system_config['roms_vertical_dir'], "gamelist.xml")
        
        if not os.path.isfile(original_gamelist):
            _log(f"[GAMELIST] Original gamelist.xml not found: {original_gamelist}")
            _log(f"[GAMELIST] Creating basic gamelist.xml for {system_config['display_name']}...")
            _create_basic_gamelist_xml_for_system(system_config, vertical_games)
            return
        
        _log(f"[GAMELIST] Reading original gamelist.xml: {original_gamelist}")
        
        # Parse original gamelist.xml
        try:
            tree = ET.parse(original_gamelist)
            root = tree.getroot()
        except ET.ParseError as e:
            _log(f"[GAMELIST] Error parsing original gamelist.xml: {e}")
            _create_basic_gamelist_xml_for_system(system_config, vertical_games)
            return
        
        # Create new gamelist for vertical games
        new_root = ET.Element("gameList")
        
        # Find games in original gamelist that are vertical
        games_migrated = 0
        for game_elem in root.findall("game"):
            # Get game name from path (remove extension)
            path_elem = game_elem.find("path")
            if path_elem is not None and path_elem.text:
                game_name = os.path.splitext(os.path.basename(path_elem.text))[0]
                
                if game_name in vertical_games:
                    # Check if ROM file exists in vertical folder
                    rom_file = None
                    for ext in (".zip", ".7z"):
                        rom_path = os.path.join(system_config['roms_vertical_dir'], game_name + ext)
                        if os.path.isfile(rom_path):
                            rom_file = game_name + ext
                            break
                    
                    if rom_file:
                        # Create new game element with updated path
                        new_game = ET.SubElement(new_root, "game")
                        
                        # Copy all elements from original game
                        for child in game_elem:
                            if child.tag == "path":
                                # Update path to point to vertical folder
                                new_path = ET.SubElement(new_game, "path")
                                new_path.text = f"./{rom_file}"
                            else:
                                # Copy other elements as-is
                                new_game.append(child)
                        
                        # Update image paths to point to vertical images folder
                        for img_tag in ["image", "marquee", "thumbnail"]:
                            img_elem = new_game.find(img_tag)
                            if img_elem is not None and img_elem.text:
                                # Update path to point to vertical images
                                img_elem.text = img_elem.text.replace("/images/", "/images/")
                        
                        games_migrated += 1
                        if games_migrated % 100 == 0:
                            _log(f"[GAMELIST] Migrated {games_migrated} {system_config['display_name']} games...")
        
        # Write new gamelist.xml with pretty formatting
        _write_pretty_xml(new_root, vertical_gamelist)
        
        _log(f"[GAMELIST] Created gamelist.xml with {games_migrated} {system_config['display_name']} games migrated from original")
        
    except Exception as e:
        _log(f"[GAMELIST ERROR] Failed to create gamelist.xml for {system_config['display_name']}: {e}")
        _log(f"[GAMELIST] Falling back to basic gamelist.xml for {system_config['display_name']}...")
        _create_basic_gamelist_xml_for_system(system_config, vertical_games)

def _write_pretty_xml(root, filepath: str) -> None:
    """Write XML with pretty formatting and proper indentation."""
    try:
        # Format the XML with proper indentation
        import xml.dom.minidom
        
        # Convert ElementTree to minidom for pretty printing
        rough_string = ET.tostring(root, 'utf-8')
        dom = xml.dom.minidom.parseString(rough_string)
        
        # Get pretty formatted string
        pretty_xml = dom.toprettyxml(indent="  ", encoding="utf-8")
        
        # Remove empty lines and fix formatting
        lines = pretty_xml.decode('utf-8').split('\n')
        filtered_lines = [line for line in lines if line.strip()]
        
        # Write to file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(filtered_lines))
            
        _log(f"[GAMELIST] Wrote pretty formatted XML to: {filepath}")
        
    except Exception as e:
        _log(f"[GAMELIST] Pretty formatting failed, using basic format: {e}")
        # Fallback to basic formatting
        ET.ElementTree(root).write(filepath, encoding="utf-8", xml_declaration=True)

def _create_basic_gamelist_xml_for_system(system_config: dict, vertical_games: Set[str]) -> None:
    """Create a basic gamelist.xml when original is not available for a system."""
    _log(f"[GAMELIST] Creating basic gamelist.xml for {system_config['display_name']}...")
    
    try:
        _ensure_gamelist_dirs_for_system(system_config)
        
        gamelist_path = os.path.join(system_config['roms_vertical_dir'], "gamelist.xml")
        images_vertical_dir = os.path.join(system_config['roms_vertical_dir'], "images")
        
        # Create XML structure using ElementTree for better formatting
        root = ET.Element("gameList")
        
        for game in sorted(vertical_games):
            # Find ROM file
            rom_file = None
            for ext in (".zip", ".7z"):
                rom_path = os.path.join(system_config['roms_vertical_dir'], game + ext)
                if os.path.isfile(rom_path):
                    rom_file = game + ext
                    break
            
            if rom_file:
                # Find image files
                image_file = None
                marquee_file = None
                thumb_file = None
                
                if os.path.isdir(images_vertical_dir):
                    # Look for image files
                    for ext in (".png", ".jpg", ".jpeg", ".webp"):
                        img_path = os.path.join(images_vertical_dir, game + "-image" + ext)
                        if os.path.isfile(img_path):
                            image_file = os.path.basename(img_path)
                            break
                        
                        marquee_path = os.path.join(images_vertical_dir, game + "-marquee" + ext)
                        if os.path.isfile(marquee_path):
                            marquee_file = os.path.basename(marquee_path)
                            break
                        
                        thumb_path = os.path.join(images_vertical_dir, game + "-thumb" + ext)
                        if os.path.isfile(thumb_path):
                            thumb_file = os.path.basename(thumb_path)
                            break
                
                # Create game element
                game_elem = ET.SubElement(root, "game")
                
                # Add path
                path_elem = ET.SubElement(game_elem, "path")
                path_elem.text = f"./{rom_file}"
                
                # Add name
                name_elem = ET.SubElement(game_elem, "name")
                name_elem.text = game
                
                # Add description
                desc_elem = ET.SubElement(game_elem, "desc")
                desc_elem.text = f"Vertical {system_config['display_name']} Game"
                
                # Add images if found
                if image_file:
                    img_elem = ET.SubElement(game_elem, "image")
                    img_elem.text = f"./images/{image_file}"
                
                if marquee_file:
                    marquee_elem = ET.SubElement(game_elem, "marquee")
                    marquee_elem.text = f"./images/{marquee_file}"
                
                if thumb_file:
                    thumb_elem = ET.SubElement(game_elem, "thumbnail")
                    thumb_elem.text = f"./images/{thumb_file}"
        
        # Write gamelist.xml with pretty formatting
        _write_pretty_xml(root, gamelist_path)
        
        _log(f"[GAMELIST] Created basic gamelist.xml with {len(vertical_games)} {system_config['display_name']} games")
        
    except Exception as e:
        _log(f"[GAMELIST ERROR] Failed to create basic gamelist.xml for {system_config['display_name']}: {e}")

def _reload_emulationstation(systems_processed: List[str]) -> None:
    """Reload EmulationStation ROMs to reflect changes for processed systems."""
    _log("[RELOAD] Reloading EmulationStation ROMs...")
    
    try:
        # Build reload commands for all processed systems
        reload_commands = []
        
        # Method 1: Touch the gamelist.xml files to trigger reload
        for system in systems_processed:
            if system in config.SYSTEMS:
                sys_config = config.SYSTEMS[system]
                reload_commands.append(f"touch {sys_config['roms_dir']}/gamelist.xml")
                reload_commands.append(f"touch {sys_config['roms_vertical_dir']}/gamelist.xml")
        
        # Method 2: Send SIGUSR1 to EmulationStation process
        reload_commands.append("pkill -USR1 emulationstation")
        
        # Method 3: Restart EmulationStation service (if running as service)
        reload_commands.append("systemctl restart emulationstation")
        
        # Method 4: Kill and restart EmulationStation
        reload_commands.append("pkill emulationstation && /usr/bin/emulationstation &")
        
        for cmd in reload_commands:
            try:
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    _log(f"[RELOAD] Success: {cmd}")
                    break
                else:
                    _log(f"[RELOAD] Failed: {cmd} (rc={result.returncode})")
            except subprocess.TimeoutExpired:
                _log(f"[RELOAD] Timeout: {cmd}")
            except Exception as e:
                _log(f"[RELOAD] Error: {cmd} - {e}")
        
        _log("[RELOAD] EmulationStation reload attempted")
        
    except Exception as e:
        _log(f"[RELOAD ERROR] Failed to reload EmulationStation: {e}")

def _process_games_bidirectional_for_system(system_config: dict, vertical_games: Set[str], horizontal_games: Set[str]) -> Tuple[int, int, int, int]:
    """Process games bidirectionally with a single loop using complete move function for a specific system."""
    moved_vertical = 0
    missing_vertical = 0
    moved_horizontal = 0
    missing_horizontal = 0
    
    # Single loop processing both directions
    all_games = list(vertical_games) + list(horizontal_games)
    total_games = len(all_games)
    
    _log(f"[PROCESS] Processing {total_games} {system_config['display_name']} games bidirectionally...")
    
    # Setup paths for this system
    roms_dir = system_config['roms_dir']
    roms_vertical_dir = system_config['roms_vertical_dir']
    images_dir = os.path.join(roms_dir, "images")
    images_vertical_dir = os.path.join(roms_vertical_dir, "images")
    
    for i, game in enumerate(sorted(all_games)):
        if i % 100 == 0:  # Log progress every 100 games
            _log(f"[PROCESS] {system_config['display_name']} Progress: {i}/{total_games} ({i/total_games*100:.1f}%)")
        
        # Determine direction and paths based on game type
        if game in vertical_games:
            # Vertical game: Base -> Vertical
            source_rom_dir = roms_dir
            dest_rom_dir = roms_vertical_dir
            source_img_dirs = (images_dir,)
            dest_img_dirs = (images_vertical_dir,)
            source_gamelist = os.path.join(roms_dir, "gamelist.xml")
            dest_gamelist = os.path.join(roms_vertical_dir, "gamelist.xml")
            direction = "vertical"
        else:
            # Horizontal game: Vertical -> Base (if exists in vertical folder)
            source_rom_dir = roms_vertical_dir
            dest_rom_dir = roms_dir
            source_img_dirs = (images_vertical_dir,)
            dest_img_dirs = (images_dir,)
            source_gamelist = os.path.join(roms_vertical_dir, "gamelist.xml")
            dest_gamelist = os.path.join(roms_dir, "gamelist.xml")
            direction = "horizontal"
        
        # Use complete move function
        try:
            from move_utils import move_game_complete
            rom_moved, xml_moved, images_moved = move_game_complete(
                game, source_rom_dir, dest_rom_dir, 
                source_img_dirs, dest_img_dirs,
                source_gamelist, dest_gamelist, direction
            )
            
            # Count results
            if direction == "vertical":
                if rom_moved:
                    moved_vertical += 1
                else:
                    missing_vertical += 1
            else:
                if rom_moved:
                    moved_horizontal += 1
                else:
                    missing_horizontal += 1
                    
        except Exception as e:
            _log(f"[ERROR] Failed to move {system_config['display_name']} game {game}: {e}")
            if direction == "vertical":
                missing_vertical += 1
            else:
                missing_horizontal += 1
    
    return moved_vertical, missing_vertical, moved_horizontal, missing_horizontal

def _process_single_system(system: str) -> Tuple[str, int, int, int]:
    """Process a single system."""
    system_config = config.SYSTEMS[system]
    
    _log(f"=== PROCESSING {system_config['display_name'].upper()} ===")
    _log(f"[CONFIG] {system_config['display_name']} ROMS_DIR: {system_config['roms_dir']}")
    _log(f"[CONFIG] {system_config['display_name']} ROMS_VERTICAL_DIR: {system_config['roms_vertical_dir']}")
    
    # Validate source directory
    if not os.path.isdir(system_config['roms_dir']):
        _log(f"[ERROR] Source {system_config['display_name']} directory not found: {system_config['roms_dir']}")
        raise RuntimeError(f"Source {system_config['display_name']} directory not found: {system_config['roms_dir']}")
    
    _ensure_dirs_for_system(system_config)
    
    # Check if vertical.txt exists for this system
    vertical_txt = os.path.join(config.BASE_DIR, system_config['vertical_txt'])
    if os.path.isfile(vertical_txt):
        # File exists, load it for speed
        vertical, horizontal = _load_vertical_horizontal_lists_for_system(system_config)
        _log(f"[VERTICAL] Using existing {system_config['display_name']} list: {len(vertical)} vertical, {len(horizontal)} horizontal")
    else:
        # File missing, generate it using hvlistgen
        _log(f"[VERTICAL] {vertical_txt} not found, will generate from {system_config['display_name']}")
        
        _log(f"[VERTICAL] Generating list using hvlistgen for {system_config['display_name']}...")
        try:
            # Import and run hvlistgen
            import sys
            import hvlistgen
            
            if system_config['list_generator'] == 'mame':
                hvlistgen.hvListGen_mame()
            elif system_config['list_generator'] == 'fbneo':
                hvlistgen.hvListGen_fbneo()
            
            # Load the newly generated list
            vertical, horizontal = _load_vertical_horizontal_lists_for_system(system_config)
            _log(f"[VERTICAL] Generated {system_config['display_name']} list: {len(vertical)} vertical, {len(horizontal)} horizontal")
            
        except Exception as e:
            _log(f"[VERTICAL ERROR] Failed to generate {system_config['display_name']} list: {e}")
            raise
    
    # Process games bidirectionally
    moved_vertical, missing_vertical, moved_horizontal, missing_horizontal = _process_games_bidirectional_for_system(
        system_config, vertical, horizontal
    )
    
    # Create gamelist.xml for vertical folder
    _create_gamelist_xml_for_system(system_config, vertical)
    
    summary = f"{system_config['display_name']}: vertical={len(vertical)} horizontal={len(horizontal)} moved_vertical={moved_vertical} missing_vertical={missing_vertical} moved_horizontal={moved_horizontal} missing_horizontal={missing_horizontal}"
    _log(f"=== {system_config['display_name'].upper()} COMPLETED: {summary} ===")
    
    return summary, moved_vertical, missing_vertical, len(vertical)

def verticalize(systems: List[str] = None) -> Dict[str, Tuple[str, int, int, int]]:
    """
    Main function to verticalize ROMs for multiple systems.
    
    Args:
        systems: List of systems to process ['mame', 'fbneo']. If None, processes all available systems.
    
    Returns:
        Dict with results per system:
        {
            'mame': (summary, moved_vertical, missing_vertical, total_vertical),
            'fbneo': (summary, moved_vertical, missing_vertical, total_vertical),
            ...
        }
    """
    try:
        _log("=== MULTI-SYSTEM VERTICALIZER START ===")
        
        # If no systems specified, process all available systems
        if not systems:
            systems = list(config.SYSTEMS.keys())
            if config.SYSTEMS_TO_PROCESS:
                systems = [s for s in systems if s in config.SYSTEMS_TO_PROCESS]
        
        _log(f"[CONFIG] Processing systems: {', '.join(systems)}")
        _log(f"[CONFIG] LOG_FILE: {LOG_FILE}")
        
        results = {}
        systems_processed = []
        
        # Process each system
        for system in systems:
            if system not in config.SYSTEMS:
                _log(f"[ERROR] Unknown system: {system}")
                continue
            
            try:
                result = _process_single_system(system)
                results[system] = result
                systems_processed.append(system)
            except Exception as e:
                _log(f"[ERROR] Failed to process {system}: {e}")
                _log(traceback.format_exc())
                results[system] = None
        
        # Reload EmulationStation once at the end for all processed systems
        if systems_processed:
            _reload_emulationstation(systems_processed)
        
        _log("=== MULTI-SYSTEM VERTICALIZER COMPLETED ===")
        return results
        
    except Exception as e:
        error_msg = f"FATAL ERROR: {str(e)}"
        _log(error_msg)
        _log(traceback.format_exc())
        raise RuntimeError(error_msg) from e

# Backward compatibility: mantener función original para MAME solo
def verticalize_mame() -> Tuple[str, int, int, int, bool, bool]:
    """Main function to verticalize MAME ROMs (backward compatibility)."""
    try:
        results = verticalize(systems=['mame'])
        if 'mame' in results and results['mame']:
            summary, moved_vertical, missing_vertical, total_vertical = results['mame']
            return summary, moved_vertical, missing_vertical, total_vertical, True, True
        else:
            raise RuntimeError("Failed to process MAME")
    except Exception as e:
        error_msg = f"FATAL ERROR: {str(e)}"
        _log(error_msg)
        _log(traceback.format_exc())
        raise RuntimeError(error_msg) from e

