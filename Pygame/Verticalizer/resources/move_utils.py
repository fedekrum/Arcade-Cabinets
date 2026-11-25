#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Move utilities for MAME Verticalizer.
Contains reusable functions for moving games (ROM + XML + images).
"""
import os
import shutil
import xml.etree.ElementTree as ET
from typing import Optional, Tuple
from datetime import datetime

def _log(msg: str) -> None:
    """Log message to console and file."""
    line = f"[{datetime.now().isoformat(timespec='seconds')}] {msg}"
    print(line)
    try:
        # Import config here to avoid circular imports
        import config
        os.makedirs(os.path.dirname(config.LOG_FILE), exist_ok=True)
        with open(config.LOG_FILE, "a", encoding="utf-8", buffering=8192) as f:
            f.write(line + "\n")
    except Exception as e:
        print(f"[LOG ERROR] {e}")

def _ensure_dir(path: str) -> None:
    """Create directory if it doesn't exist."""
    os.makedirs(path, exist_ok=True)

def _find_rom_in_dir(basename: str, directory: str) -> Optional[str]:
    """Find ROM file in specific directory."""
    for ext in (".zip", ".7z"):
        p = os.path.join(directory, basename + ext)
        if os.path.isfile(p): 
            return p
    return None

def _move_or_link(src: str, dst_dir: str) -> None:
    """Move or create symlink for ROM file."""
    _ensure_dir(dst_dir)
    dst = os.path.join(dst_dir, os.path.basename(src))
    if os.path.exists(dst):
        _log(f"[ROM] exists, overwriting: {dst}")
        os.remove(dst)  # Remove existing file
    if True:  # Always move files
        shutil.move(src, dst)
        _log(f"[ROM] MOVED: {src} -> {dst}")
    else:
        rel = os.path.relpath(src, dst_dir)
        try: 
            os.symlink(rel, dst)
            _log(f"[ROM] SYMLINK: {dst} -> {rel}")
        except OSError as e: 
            _log(f"[ROM] symlink failed: {e}; copy")
            shutil.copy2(src, dst)

def _move_images(base: str, source_dirs: tuple, dest_dirs: tuple, direction: str = "vertical") -> None:
    """Move images that start with the game name followed by a hyphen."""
    cnt = 0
    for sdir in source_dirs:
        if not os.path.isdir(sdir): 
            continue
        
        # Look for images with pattern: [game_name]-[type].[ext]
        pattern = os.path.join(sdir, base + "-*")
        from glob import glob
        for src in glob(pattern):
            if os.path.isfile(src):
                ext = os.path.splitext(src)[1].lower()
                if ext in (".png", ".jpg", ".jpeg", ".webp"):
                    for ddir in dest_dirs:
                        _ensure_dir(ddir)
                        dst = os.path.join(ddir, os.path.basename(src))
                        if os.path.exists(dst):
                            _log(f"[IMG] exists, overwriting: {os.path.basename(src)}")
                            os.remove(dst)  # Remove existing file
                        if True:  # Always move files
                            shutil.move(src, dst)
                            cnt += 1
                            _log(f"[IMG] MOVED: {os.path.basename(src)}")
                        else:
                            # Create symlink for images too
                            rel = os.path.relpath(src, ddir)
                            try:
                                os.symlink(rel, dst)
                                cnt += 1
                                _log(f"[IMG] SYMLINK: {os.path.basename(src)}")
                            except OSError as e:
                                _log(f"[IMG] symlink failed: {e}; copy")
                                shutil.copy2(src, dst)
                                cnt += 1
                                _log(f"[IMG] COPIED: {os.path.basename(src)}")
        
        # Also check for simple pattern: [game_name].[ext] (fallback)
        for patt in (base + ".png", base + ".jpg", base + ".jpeg", base + ".webp"):
            src = os.path.join(sdir, patt)
            if os.path.isfile(src):
                for ddir in dest_dirs:
                    _ensure_dir(ddir)
                    dst = os.path.join(ddir, os.path.basename(src))
                    if os.path.exists(dst):
                        _log(f"[IMG] exists, overwriting: {os.path.basename(src)}")
                        os.remove(dst)  # Remove existing file
                    if True:  # Always move files
                        shutil.move(src, dst)
                        cnt += 1
                        _log(f"[IMG] MOVED: {os.path.basename(src)}")
                    else:
                        # Create symlink for images too
                        rel = os.path.relpath(src, ddir)
                        try:
                            os.symlink(rel, dst)
                            cnt += 1
                            _log(f"[IMG] SYMLINK: {os.path.basename(src)}")
                        except OSError as e:
                            _log(f"[IMG] symlink failed: {e}; copy")
                            shutil.copy2(src, dst)
                            cnt += 1
                            _log(f"[IMG] COPIED: {os.path.basename(src)}")
    
    if cnt: 
        _log(f"[IMG] {base}: {cnt} image files moved to {direction}")
    else:
        _log(f"[IMG] {base}: No images found")

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

def _update_xml_paths(game_block, game_name: str) -> None:
    """Update paths in XML game block to point to new location."""
    # Update ROM path
    path_elem = game_block.find("path")
    if path_elem is not None:
        # Find actual ROM file
        for ext in (".zip", ".7z"):
            rom_file = game_name + ext
            path_elem.text = f"./{rom_file}"
            break
    
    # Update image paths
    for img_tag in ["image", "marquee", "thumbnail"]:
        img_elem = game_block.find(img_tag)
        if img_elem is not None and img_elem.text:
            # Update to point to new images directory
            img_elem.text = img_elem.text.replace("/images/", "/images/")

def _move_xml_block(game_name: str, source_gamelist: str, dest_gamelist: str) -> None:
    """Move XML block for a specific game from source to destination gamelist."""
    try:
        # Parse source gamelist
        source_tree = ET.parse(source_gamelist)
        source_root = source_tree.getroot()
        
        # Find the game block in source
        game_block = None
        for game in source_root.findall("game"):
            name_elem = game.find("name")
            if name_elem is not None and name_elem.text == game_name:
                game_block = game
                break
        
        if game_block is None:
            _log(f"[MOVE XML] Game {game_name} not found in source gamelist")
            return
        
        # Remove from source
        source_root.remove(game_block)
        
        # Update paths in the game block
        _update_xml_paths(game_block, game_name)
        
        # Parse destination gamelist (create if doesn't exist)
        if os.path.isfile(dest_gamelist):
            dest_tree = ET.parse(dest_gamelist)
            dest_root = dest_tree.getroot()
        else:
            dest_root = ET.Element("gameList")
        
        # Add to destination
        dest_root.append(game_block)
        
        # Save both files
        _write_pretty_xml(source_root, source_gamelist)
        _write_pretty_xml(dest_root, dest_gamelist)
        
        _log(f"[MOVE XML] Moved XML block for {game_name}")
        
    except Exception as e:
        _log(f"[MOVE XML ERROR] Failed to move XML block for {game_name}: {e}")
        raise

def move_game_complete(game_name: str, source_rom_dir: str, dest_rom_dir: str, 
                     source_img_dirs: tuple, dest_img_dirs: tuple, 
                     source_gamelist: str, dest_gamelist: str, 
                     direction: str) -> Tuple[bool, bool, bool]:
    """
    Complete game move: ROM + XML block + images.
    
    Args:
        game_name: Name of the game (without extension)
        source_rom_dir: Source ROM directory
        dest_rom_dir: Destination ROM directory
        source_img_dirs: Tuple of source image directories
        dest_img_dirs: Tuple of destination image directories
        source_gamelist: Path to source gamelist.xml
        dest_gamelist: Path to destination gamelist.xml
        direction: "vertical" or "horizontal" (for logging)
    
    Returns:
        Tuple of (rom_moved, xml_moved, images_moved)
    """
    rom_moved = False
    xml_moved = False
    images_moved = False
    
    _log(f"[MOVE] Moving {game_name} ({direction})...")
    
    # 1. Move ROM
    try:
        src_rom = _find_rom_in_dir(game_name, source_rom_dir)
        if src_rom:
            _log(f"[MOVE] ROM found: {src_rom}")
            _move_or_link(src_rom, dest_rom_dir)
            rom_moved = True
            _log(f"[MOVE] ROM moved successfully")
        else:
            _log(f"[MOVE] ROM not found: {game_name}")
    except Exception as e:
        _log(f"[MOVE ERROR] Failed to move ROM {game_name}: {e}")
    
    # 2. Move XML block
    try:
        if os.path.isfile(source_gamelist):
            _log(f"[MOVE] Moving XML block for {game_name}")
            _move_xml_block(game_name, source_gamelist, dest_gamelist)
            xml_moved = True
            _log(f"[MOVE] XML block moved successfully")
        else:
            _log(f"[MOVE] Source gamelist not found: {source_gamelist}")
    except Exception as e:
        _log(f"[MOVE ERROR] Failed to move XML block for {game_name}: {e}")
    
    # 3. Move images
    try:
        _log(f"[MOVE] Moving images for {game_name}")
        _move_images(game_name, source_img_dirs, dest_img_dirs, direction)
        images_moved = True
        _log(f"[MOVE] Images moved successfully")
    except Exception as e:
        _log(f"[MOVE ERROR] Failed to move images for {game_name}: {e}")
    
    _log(f"[MOVE] {game_name} completed: ROM={rom_moved}, XML={xml_moved}, Images={images_moved}")
    return rom_moved, xml_moved, images_moved
