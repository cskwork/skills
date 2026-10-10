#!/usr/bin/env python3
"""Print the dominant colors of an image as hex with their share of pixels.

Usage: palette.py IMAGE [--colors 12]
"""
import argparse

from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("image")
    p.add_argument("--colors", type=int, default=12)
    a = p.parse_args()

    img = Image.open(a.image).convert("RGB")
    img.thumbnail((512, 512))
    q = img.quantize(colors=a.colors, method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette() or []
    total = img.width * img.height
    for count, idx in sorted(q.getcolors() or [], reverse=True):
        r, g, b = pal[idx * 3: idx * 3 + 3]
        print(f"#{r:02x}{g:02x}{b:02x}  {count / total:6.1%}")


if __name__ == "__main__":
    main()
