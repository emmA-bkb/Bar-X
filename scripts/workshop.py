#!/usr/bin/env python3
"""Fetches wallpapers from Wallpaper Engine's Steam Workshop (app 431960).

Uses only public pages and APIs (no login or key):
  1. the Workshop browse page, for the list of items in the chosen order
  2. ISteamRemoteStorage/GetPublishedFileDetails, for title, preview, tags etc.

Usage: workshop.py <sort> <page> [type] [query]
  sort: trend | mostrecent | toprated | subscribed
  type: "" | Scene | Video | Web
Output (JSON): { "page": N, "hasMore": bool, "items": [...] } or { "error": "..." }
"""
import json
import re
import sys
import urllib.parse
import urllib.request

APP_ID = "431960"
PER_PAGE = 30
UA = "Mozilla/5.0 (X11; Linux x86_64) Uix"

SORTS = {
    "trend": "trend",
    "mostrecent": "mostrecent",
    "toprated": "toprated",
    "subscribed": "totaluniquesubscribers",
}


def fetch(url, data=None):
    req = urllib.request.Request(url, data=data, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=20) as resp:
        return resp.read().decode("utf-8", errors="replace")


def browse_ids(sort, page, kind, query):
    params = [
        ("appid", APP_ID),
        ("section", "readytouseitems"),
        ("browsesort", SORTS.get(sort, "trend")),
        ("actualsort", SORTS.get(sort, "trend")),
        ("p", str(page)),
        ("numperpage", str(PER_PAGE)),
        ("requiredtags[]", "Everyone"),  # free-form sorting only
    ]
    if sort == "trend":
        params.append(("days", "7"))
    if kind:
        params.append(("requiredtags[]", kind))
    if query:
        params.append(("searchtext", query))
    html = fetch("https://steamcommunity.com/workshop/browse/?" + urllib.parse.urlencode(params))
    ids = []
    for m in re.finditer(r"sharedfiles/filedetails/\?id=(\d+)", html):
        if m.group(1) not in ids:
            ids.append(m.group(1))
    return ids


def details(ids):
    if not ids:
        return []
    form = {"itemcount": str(len(ids))}
    for i, pid in enumerate(ids):
        form[f"publishedfileids[{i}]"] = pid
    body = fetch(
        "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/",
        urllib.parse.urlencode(form).encode(),
    )
    files = json.loads(body).get("response", {}).get("publishedfiledetails", [])
    by_id = {f.get("publishedfileid"): f for f in files if f.get("result") == 1}

    items = []
    for pid in ids:  # keeps the Workshop order
        f = by_id.get(pid)
        if not f:
            continue
        tags = [t.get("tag", "") for t in f.get("tags", [])]
        kind = next((t for t in tags if t in ("Scene", "Video", "Web", "Application")), "Scene")
        items.append({
            "id": pid,
            "title": re.sub(r"\s+", " ", f.get("title", "")).strip() or pid,
            "preview": f.get("preview_url", ""),
            "type": kind.lower(),
            "tags": [t for t in tags if t not in ("Scene", "Video", "Web", "Application", "Wallpaper", "Everyone")],
            "subscriptions": int(f.get("subscriptions", 0) or 0),
            "size": int(f.get("file_size", 0) or 0),
        })
    return items


def main():
    sort = sys.argv[1] if len(sys.argv) > 1 else "trend"
    page = max(1, int(sys.argv[2])) if len(sys.argv) > 2 else 1
    kind = sys.argv[3] if len(sys.argv) > 3 else ""
    query = sys.argv[4] if len(sys.argv) > 4 else ""
    try:
        ids = browse_ids(sort, page, kind, query)
        items = details(ids)
        print(json.dumps({"page": page, "hasMore": len(ids) >= PER_PAGE, "items": items}, ensure_ascii=False))
    except Exception as e:  # no internet, Steam down, etc.
        print(json.dumps({"error": str(e)}))


if __name__ == "__main__":
    main()
