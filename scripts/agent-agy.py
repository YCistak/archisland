#!/usr/bin/env python3
from __future__ import annotations
import argparse
import datetime as dt
import json
import os
import sys
from pathlib import Path

current_dir = Path(__file__).resolve().parent
if str(current_dir) not in sys.path:
    sys.path.insert(0, str(current_dir))

from antigravity_usage_scanner import scan, default_base_dir

def collect(base_dir: Path, force: bool = False) -> dict:
    data = scan(base_dir, force=force)
    all_dates = set()
    for d in data.get("recentDays", []):
        if d.get("prompts", 0) > 0 or d.get("messageCount", 0) > 0:
            all_dates.add(d.get("date"))

    return {
        "schemaVersion": 1,
        "id": "antigravity",
        "name": "Antigravity",
        "updatedAt": data.get("updatedAt", dt.datetime.now(dt.timezone.utc).isoformat()),
        "ready": data.get("ready", False),
        "hasLocalStats": data.get("hasLocalStats", False),
        "todayPrompts": data.get("todayPrompts", 0),
        "todaySessions": data.get("todaySessions", 0),
        "todayTotalTokens": data.get("todayTotalTokens", 0),
        "todayTokensByModel": data.get("todayTokensByModel", {}),
        "recentDays": data.get("recentDays", []),
        "totalPrompts": data.get("totalPrompts", 0),
        "totalSessions": data.get("totalSessions", 0),
        "activeDays": len(all_dates),
        "activeDates": sorted(list(all_dates)),
        "modelUsage": data.get("modelUsage", {}),
        "limits": data.get("limits", []),
        "tierLabel": data.get("tierLabel", "Google DeepMind"),
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Antigravity Usage")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    base = default_base_dir()
    print(json.dumps(collect(base, force=args.force), indent=2))
