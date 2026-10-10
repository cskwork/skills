#!/usr/bin/env python3
"""Render a side-by-side HTML board of images with labels.

Usage: board.py --title TITLE --out board.html IMG LABEL [IMG LABEL ...]
Images are referenced by path relative to the board, so keep them in the same tree.
"""
import argparse
import html
import os
import sys


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--title", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("pairs", nargs="+")
    a = p.parse_args()
    if len(a.pairs) % 2:
        sys.exit("expected IMG LABEL pairs")

    out_dir = os.path.dirname(os.path.abspath(a.out))
    cards = []
    for img, label in zip(a.pairs[::2], a.pairs[1::2]):
        if not os.path.isfile(img):
            sys.exit(f"missing image: {img}")
        src = html.escape(os.path.relpath(os.path.abspath(img), out_dir))
        cards.append(
            f'<figure><a href="{src}" target="_blank"><img src="{src}" alt=""></a>'
            f"<figcaption>{html.escape(label)}</figcaption></figure>"
        )

    page = f"""<!doctype html>
<html lang="en"><meta charset="utf-8"><title>{html.escape(a.title)}</title>
<style>
  body {{ margin: 0; padding: 24px; font: 15px/1.4 system-ui, sans-serif; background: #111; color: #eee; }}
  h1 {{ font-size: 18px; font-weight: 600; margin: 0 0 16px; }}
  main {{ display: grid; grid-template-columns: repeat({len(cards)}, minmax(0, 1fr)); gap: 16px; }}
  figure {{ margin: 0; }}
  img {{ width: 100%; display: block; border-radius: 6px; background: #222; }}
  figcaption {{ margin-top: 8px; font-weight: 600; }}
  @media (max-width: 900px) {{ main {{ grid-template-columns: 1fr; }} }}
</style>
<h1>{html.escape(a.title)}</h1>
<main>{''.join(cards)}</main>
<p>Click an image to open it full size.</p>
</html>
"""
    with open(a.out, "w", encoding="utf-8") as f:
        f.write(page)
    print(os.path.abspath(a.out))


if __name__ == "__main__":
    main()
