#!/usr/bin/env python3
import os
import sys
import json
import re
import datetime
import urllib.request

CONFIG_DIR = os.path.expanduser("~/.config/archisland")
EVENTS_FILE = os.path.join(CONFIG_DIR, "calendar-events.json")
URL_FILE = os.path.join(CONFIG_DIR, "calendar-url.txt")
CACHE_FILE = "/tmp/archisland-calendar-events.json"

def load_events():
    if os.path.exists(EVENTS_FILE):
        try:
            with open(EVENTS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
        except Exception:
            pass
    return []

def save_events(events):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(EVENTS_FILE, "w", encoding="utf-8") as f:
        json.dump(events, f, indent=2, ensure_ascii=False)

def parse_ics(ics_text):
    events = []
    lines = ics_text.replace("\r\n ", "").replace("\r\n\t", "").splitlines()
    in_event = False
    cur = {}
    
    for line in lines:
        line_clean = line.strip()
        if line_clean.startswith("BEGIN:VEVENT"):
            in_event = True
            cur = {}
        elif line_clean.startswith("END:VEVENT"):
            in_event = False
            if "date" in cur and "summary" in cur:
                events.append(cur)
        elif in_event:
            if line_clean.startswith("SUMMARY:"):
                cur["summary"] = line_clean[len("SUMMARY:"):].strip()
            elif line_clean.startswith("LOCATION:"):
                cur["location"] = line_clean[len("LOCATION:"):].strip()
            elif line_clean.startswith("DTSTART"):
                parts = line_clean.split(":", 1)
                if len(parts) == 2:
                    raw = parts[1].strip()
                    m = re.search(r'(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2}))?', raw)
                    if m:
                        y, mo, d, th, tm = m.groups()
                        cur["date"] = f"{y}-{mo}-{d}"
                        if th and tm:
                            cur["time"] = f"{th}:{tm}"
                        else:
                            cur["time"] = "Tüm gün"
    return events

def main():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    
    # 1. Action: add event
    if len(sys.argv) >= 5 and sys.argv[1] == "add":
        date_str = sys.argv[2].strip()
        time_str = sys.argv[3].strip()
        summary = " ".join(sys.argv[4:]).strip()
        if summary:
            events = load_events()
            events.append({
                "id": str(int(datetime.datetime.now().timestamp() * 1000)),
                "date": date_str,
                "time": time_str or "Tüm gün",
                "summary": summary
            })
            save_events(events)
            print(json.dumps({"status": "ok", "message": "Etkinlik eklendi"}))
            return

    # 2. Action: delete event
    if len(sys.argv) >= 3 and sys.argv[1] == "delete":
        target_id = sys.argv[2].strip()
        events = load_events()
        events = [e for e in events if e.get("id") != target_id and e.get("summary") != target_id]
        save_events(events)
        print(json.dumps({"status": "ok", "message": "Etkinlik silindi"}))
        return

    # 3. Action: set ical url
    if len(sys.argv) > 2 and sys.argv[1] == "set-url":
        url = sys.argv[2].strip()
        with open(URL_FILE, "w", encoding="utf-8") as f:
            f.write(url + "\n")
        print(json.dumps({"status": "ok", "message": "URL kaydedildi"}))
        return

    # Normal list / sync
    events = load_events()
    ical_url = ""
    if os.path.exists(URL_FILE):
        with open(URL_FILE, "r", encoding="utf-8") as f:
            ical_url = f.read().strip()

    synced = False
    error = ""

    if ical_url and ical_url.startswith("http"):
        try:
            req = urllib.request.Request(ical_url, headers={"User-Agent": "ArchIsland/1.0"})
            with urllib.request.urlopen(req, timeout=5) as resp:
                text = resp.read().decode("utf-8", errors="ignore")
                remote_events = parse_ics(text)
                for rev in remote_events:
                    if not any(e.get("date") == rev.get("date") and e.get("summary") == rev.get("summary") for e in events):
                        events.append(rev)
                synced = True
        except Exception as e:
            error = str(e)

    # Sort events by date and time
    events.sort(key=lambda x: (x.get("date", ""), x.get("time", "")))

    result = {
        "synced": synced,
        "eventsCount": len(events),
        "lastSync": datetime.datetime.now().strftime("%H:%M"),
        "events": events
    }

    try:
        with open(CACHE_FILE + ".tmp", "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        os.replace(CACHE_FILE + ".tmp", CACHE_FILE)
    except Exception:
        pass

    print(json.dumps(result, ensure_ascii=False))

if __name__ == "__main__":
    main()
