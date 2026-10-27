#!/usr/bin/env python3
"""Tests whether Wallpaper Engine wallpapers work on Linux.

Same test as linux-wallpaper-engine-ux: opens each wallpaper in linux-wallpaperengine
in a tiny 1x1 window, waits 5 seconds and reads the error messages.
  broken  -> froze, fatal error, or closed by itself
  minor   -> warnings (missing texture/shader, unsupported feature...)
  perfect -> no warnings
On Hyprland the test windows open in a hidden special workspace (special:uixscan),
so nothing shows up on your screen.

Results go to ~/.config/uix/compat.json (scan-wallpaper-engine.py uses them for the badges).

Usage: scan-compat.py <new|all>
  new -> only the ones without a result yet    all -> all of them again
Output, one line per event (TAB): total N | start title | result path status title | done perfect minor broken
"""
import json
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
COMPAT_FILE = os.path.expanduser("~/.config/uix/compat.json")
WAIT = 5  # seconds running before deciding
PARALLEL = 3

FATAL = [re.compile(p, re.I) for p in (
    r"segmentation fault", r"segfault", r"failed to initialize glfw", r"glfw.*error",
    r"abort.*core dumped", r"cannot open display")]
MINOR = [re.compile(p, re.I) for p in (
    r"missing texture", r"missing shader", r"missing material", r"scenescript",
    r"cannot find", r"warning", r"not supported", r"failed to load")]
IGNORE = [re.compile(p, re.I) for p in (
    r"the platform does not provide the window position",
    r"the platform does not support setting the window position")]

HYPRLAND = bool(os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")) and shutil.which("hyprctl")
lock = threading.Lock()
stopping = False


def emit(*fields):
    with lock:
        print("\t".join(str(f).replace("\t", " ").replace("\n", " ") for f in fields), flush=True)


def wallpapers():
    out = subprocess.run([sys.executable, "-I", os.path.join(HERE, "scan-wallpaper-engine.py")],
                         capture_output=True, text=True).stdout
    for line in out.splitlines():
        f = line.split("\t")
        if f[0] == "we" and len(f) >= 5:
            yield {"path": f[1], "title": f[3], "compat": f[5] if len(f) > 5 else ""}


def classify(stderr, exited):
    lines = [l.strip() for l in stderr.splitlines() if l.strip() and not any(p.search(l) for p in IGNORE)]
    for l in lines:
        if any(p.search(l) for p in FATAL):
            return "broken", [l]
    if exited:
        return "broken", ["Process exited unexpectedly"]
    errors = [l for l in lines if any(p.search(l) for p in MINOR)]
    return ("minor", errors[:20]) if errors else ("perfect", [])


def engine_cmd(path):
    return ["linux-wallpaperengine", "--window", "0x0x1x1", "--silent", path]


# /usr/bin/linux-wallpaperengine is a script that runs "./linux-wallpaperengine", so the
# pattern doesn't start with ^. The $ at the end avoids matching the "sh -c ..." wrapping the process.
def kill_engine(path):
    pattern = re.escape(shlex.join(engine_cmd(path))) + "$"
    subprocess.run(["pkill", "-9", "-f", pattern], capture_output=True)


def test(wp, tmp):
    key = re.sub(r"\W", "_", wp["path"])[-60:]
    err = os.path.join(tmp, key + ".err")
    done = os.path.join(tmp, key + ".exit")
    shell = f"{shlex.join(engine_cmd(wp['path']))} 2>{shlex.quote(err)}; echo $? >{shlex.quote(done)}"

    if HYPRLAND:
        cmd = "sh -c " + shlex.quote(shell)
        lua = "hl.dsp.exec_cmd(%s, { workspace = \"special:uixscan silent\" })" % json.dumps(cmd, ensure_ascii=False)
        subprocess.run(["hyprctl", "dispatch", lua], capture_output=True)
    else:
        subprocess.Popen(["sh", "-c", shell], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    deadline = time.time() + WAIT
    while time.time() < deadline and not os.path.exists(done) and not stopping:
        time.sleep(0.2)
    exited = os.path.exists(done)
    if not exited:
        kill_engine(wp["path"])
        time.sleep(0.3)
    try:
        with open(err, errors="replace") as f:
            stderr = f.read()
    except OSError:
        stderr = ""
    return classify(stderr, exited)


def load_results():
    try:
        with open(COMPAT_FILE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_results(results):
    os.makedirs(os.path.dirname(COMPAT_FILE), exist_ok=True)
    tmp = COMPAT_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    os.replace(tmp, COMPAT_FILE)


def stop(*_):
    global stopping
    stopping = True
    subprocess.run(["pkill", "-9", "-f", r"linux-wallpaperengine --window 0x0x1x1 --silent /[^ ]+$"], capture_output=True)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "new"
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    if not shutil.which("linux-wallpaperengine"):
        emit("error", "linux-wallpaperengine is not installed")
        return

    todo = [w for w in wallpapers() if mode == "all" or not w["compat"]]
    emit("total", len(todo))
    results = load_results()
    counts = {"perfect": 0, "minor": 0, "broken": 0}

    def run(wp):
        if stopping:
            return
        emit("start", wp["title"])
        status, errors = test(wp, tmp)
        if stopping:
            return
        with lock:
            results[wp["path"]] = {"compatibility": status, "autoErrors": errors, "lastTested": int(time.time() * 1000)}
            counts[status] += 1
            save_results(results)
        emit("result", wp["path"], status, wp["title"])

    with tempfile.TemporaryDirectory(prefix="uix-scan-") as tmp:
        with ThreadPoolExecutor(PARALLEL) as pool:
            list(pool.map(run, todo))

    emit("done", counts["perfect"], counts["minor"], counts["broken"])


if __name__ == "__main__":
    main()
