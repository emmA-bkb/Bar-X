#!/usr/bin/env python3
"""Takes the colors of an image for the widgets (Material You style).

Shrinks the image with ffmpeg, finds the most striking color (hue) and builds a palette:
accent, tinted dark background and text colors.

Usage: palette.py <image>
Output (JSON): { "accent", "bg", "fg", "fgDim", "fgMuted", "onAccent", "lum" } or { "error": "..." }
"""
import colorsys
import json
import math
import subprocess
import sys

W, H = 64, 36


def pixels(path):
    raw = subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-i", path, "-frames:v", "1",
         "-vf", f"scale={W}:{H}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        capture_output=True, timeout=20, check=True,
    ).stdout
    for i in range(0, len(raw) - 2, 3):
        yield raw[i] / 255, raw[i + 1] / 255, raw[i + 2] / 255


def hexcolor(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1, max(0, min(1, s)), max(0, min(1, v)))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def main():
    bins = [0.0] * 36
    vec = [[0.0, 0.0] for _ in range(36)]  # circular mean of the hue in each band
    sat_sum = weight_sum = 0.0
    lum_sum = count = 0.0
    for r, g, b in pixels(sys.argv[1]):
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        lum_sum += 0.2126 * r + 0.7152 * g + 0.0722 * b
        count += 1
        # Vivid and not too dark colors weigh more
        w = s * s * v + 0.002
        k = int(h * 36) % 36
        bins[k] += w
        vec[k][0] += math.cos(h * 2 * math.pi) * w
        vec[k][1] += math.sin(h * 2 * math.pi) * w
        sat_sum += s * w
        weight_sum += w

    # Strongest band, adding its neighbours so an isolated peak isn't picked
    best = max(range(36), key=lambda k: bins[k - 1] + bins[k] * 2 + bins[(k + 1) % 36])
    x = sum(vec[(best + d) % 36][0] for d in (-1, 0, 1))
    y = sum(vec[(best + d) % 36][1] for d in (-1, 0, 1))
    hue = (math.atan2(y, x) / (2 * math.pi)) % 1
    sat = sat_sum / weight_sum if weight_sum else 0
    gray = sat < 0.12  # wallpaper with almost no color

    s_accent = 0.12 if gray else min(0.62, max(0.42, sat))
    s_tint = 0.06 if gray else 0.38

    print(json.dumps({
        "accent": hexcolor(hue, s_accent, 0.9),
        "bg": hexcolor(hue, s_tint, 0.2),
        "fg": hexcolor(hue, 0.06 if not gray else 0.02, 0.97),
        "fgDim": hexcolor(hue, 0.14 if not gray else 0.04, 0.78),
        "fgMuted": hexcolor(hue, 0.18 if not gray else 0.04, 0.58),
        "onAccent": hexcolor(hue, 0.7 if not gray else 0.1, 0.16),
        "lum": round(lum_sum / count, 3) if count else 0,  # average brightness (0 dark .. 1 light)
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)}))
