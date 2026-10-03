#!/usr/bin/env python3
"""ArchIsland Session Manager: Save and restore open Hyprland windows cleanly without external dependencies."""

from __future__ import annotations
import json
import os
import subprocess
import sys
from pathlib import Path

STATE_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "archisland"
SESSION_FILE = STATE_DIR / "last-session.json"

def get_hypr_clients() -> list[dict]:
    try:
        out = subprocess.check_output(["hyprctl", "clients", "-j"], text=True)
        return json.loads(out)
    except Exception as e:
        sys.stderr.write(f"Error reading hyprctl clients: {e}\n")
        return []

def save_session() -> int:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    clients = get_hypr_clients()
    saved = []
    for c in clients:
        if not c.get("mapped", True) or c.get("hidden", False):
            continue
        ws = c.get("workspace", {})
        ws_id = ws.get("id")
        if ws_id is not None and ws_id < 0:
            continue
        saved.append({
            "class": c.get("class", ""),
            "initialClass": c.get("initialClass", ""),
            "title": c.get("title", ""),
            "workspace_id": ws_id,
            "workspace_name": ws.get("name", str(ws_id)),
            "floating": c.get("floating", False),
            "at": c.get("at", [0, 0]),
            "size": c.get("size", [800, 600]),
            "pid": c.get("pid")
        })
    with open(SESSION_FILE, "w", encoding="utf-8") as f:
        json.dump(saved, f, indent=2, ensure_ascii=False)
    print(f"ArchIsland: {len(saved)} pencere kaydedildi -> {SESSION_FILE}")
    return len(saved)

def restore_session() -> int:
    if not SESSION_FILE.exists():
        print(f"ArchIsland: Kayıtlı oturum dosyası bulunamadı ({SESSION_FILE})")
        return 0
    try:
        with open(SESSION_FILE, "r", encoding="utf-8") as f:
            windows = json.load(f)
    except Exception as e:
        sys.stderr.write(f"Dosya okuma hatası: {e}\n")
        return 0

    restored = 0
    for w in windows:
        cls = w.get("initialClass") or w.get("class")
        ws_name = w.get("workspace_name", "1")
        if not cls:
            continue
        cmd = cls.lower()
        if "konsole" in cmd:
            cmd = "konsole"
        elif "code" in cmd:
            cmd = "code"
        elif "firefox" in cmd:
            cmd = "firefox"
        elif "zen" in cmd:
            cmd = "zen-browser"
        elif "chrome" in cmd:
            cmd = "google-chrome-stable"
        
        try:
            subprocess.Popen(["hyprctl", "dispatch", "exec", f"[workspace {ws_name} silent] {cmd}"])
            restored += 1
        except Exception:
            pass
    print(f"ArchIsland: {restored} uygulama geri yüklendi.")
    return restored

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "save"
    if action in ("save", "snapshot"):
        save_session()
    elif action in ("restore", "load"):
        restore_session()
    elif action == "list":
        if SESSION_FILE.exists():
            with open(SESSION_FILE, "r", encoding="utf-8") as f:
                print(f.read())
        else:
            print("[]")
    else:
        print("Usage: session-manager.py [save|restore|list]")
