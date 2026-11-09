#!/usr/bin/env python3
"""Blank-band audit (Prompt 3, P7). The owner's script, with the same thresholds, reading pixels without PIL:
macOS `sips` shrinks each PNG to a quarter and writes a BMP, which is parsed here.
Per screenshot: the longest blank band between the header and the tab bar, and the blank space at the bottom.
A row is content when more than 8% of its sampled pixels differ from the canvas by more than 10 in any channel."""
import glob, os, struct, subprocess, sys, tempfile

CANVAS = (237, 237, 232)

def pixels(path):
    out = os.path.join(tempfile.mkdtemp(), "x.bmp")
    w = int(subprocess.run(["sips", "-g", "pixelWidth", path], capture_output=True, text=True).stdout.split()[-1])
    subprocess.run(["sips", "-s", "format", "bmp", "--resampleWidth", str(max(w // 4, 1)), path, "--out", out],
                   capture_output=True, check=True)
    data = open(out, "rb").read()
    offset = struct.unpack_from("<I", data, 10)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    bpp = struct.unpack_from("<H", data, 28)[0]
    step = bpp // 8
    stride = (width * step + 3) & ~3
    flipped = height > 0
    height = abs(height)
    def px(x, y):
        row = height - 1 - y if flipped else y
        i = offset + row * stride + x * step
        b, g, r = data[i], data[i + 1], data[i + 2]
        return (r, g, b)
    return width, height, px

def metrics(path):
    w, h, px = pixels(path)
    top, bottom = int(h * 0.18), int(h * 0.88)   # skip the header and the tab bar
    rows = []
    for y in range(top, bottom):
        n = d = 0
        for x in range(0, w, 2):
            n += 1
            p = px(x, y)
            if max(abs(p[i] - CANVAS[i]) for i in range(3)) > 10:
                d += 1
        rows.append(d / n > 0.08)
    best = cur = 0
    for has in rows:
        cur = 0 if has else cur + 1
        best = max(best, cur)
    trailing = 0
    for has in reversed(rows):
        if has:
            break
        trailing += 1
    return best / len(rows), trailing / len(rows)

for p in sorted(glob.glob(sys.argv[1] + "/*.png")):
    best, trail = metrics(p)
    print(f"{os.path.basename(p)}\t{best:.0%}\t{trail:.0%}\t{'FLAG' if best > 0.25 else ''}")
