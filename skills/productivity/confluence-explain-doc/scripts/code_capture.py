#!/usr/bin/env python3
"""Render real source lines as annotated "code capture" HTML, ready to screenshot.

Usage:
  code_capture.py --spec caps.json --src-dir <dir with source files> --out-dir <dir>

caps.json (see examples/code_capture.example.json):
  {"legend": {"red": "Problem", "green": "Fixed", "blue": "Normal flow"},   # optional
   "captures": [{"name": "...", "blocks": [{
       "file": "Foo.java", "lex": "java|js|sql|text", "tag": "Before · main", "tag_color": "#cf222e",
       "path": "service · Foo.bar()", "ranges": [[10, 20], ["regex start", 5]],
       "hl": {"12": "red", "15": "green"}, "notes": {"12": "short note"}}]}]}

Line numbers stay the real file line numbers. Gaps between ranges render as ⋮.
Then screenshot each HTML at the size of #cap (see SKILL.md "Code captures").
"""
import argparse, html, json, os, re
from pygments import highlight
from pygments.formatters import HtmlFormatter
from pygments.lexers import JavaLexer, JavascriptLexer, SqlLexer, TextLexer, PythonLexer, TypeScriptLexer

LEX = {'java': JavaLexer(), 'js': JavascriptLexer(), 'ts': TypeScriptLexer(), 'py': PythonLexer(), 'sql': SqlLexer(), 'text': TextLexer()}
FMT = HtmlFormatter(nowrap=True, style='default')
COL = {'red': ('#ffebe9', '#cf222e'), 'green': ('#e6ffec', '#1a7f37'), 'blue': ('#ddf4ff', '#0969da')}
DEFAULT_LEGEND = {'red': 'Problem', 'green': 'Fixed', 'blue': 'Normal flow'}


def find(lines, pat):
    for i, line in enumerate(lines):
        if re.search(pat, line):
            return i + 1
    raise SystemExit(f'pattern not found: {pat}')


def line_no(lines, key):
    return int(key) if str(key).isdigit() else find(lines, key)


def render_block(b, src_dir, legend):
    lines = open(os.path.join(src_dir, b['file']), encoding='utf-8').read().split('\n')
    ranges = [[line_no(lines, r[0]), line_no(lines, r[0]) + r[1] if isinstance(r[0], str) else r[1]] for r in b['ranges']]
    hl = {line_no(lines, k): v for k, v in b.get('hl', {}).items()}
    notes = {line_no(lines, k): v for k, v in b.get('notes', {}).items()}
    rows = []
    for k, (a, z) in enumerate(ranges):
        if k:
            rows.append('<tr class="gap"><td class="ln">⋮</td><td class="code"></td></tr>')
        for n in range(a, z + 1):
            src = lines[n - 1].expandtabs(4)
            code = highlight(src, LEX[b.get('lex', 'text')], FMT).rstrip('\n') or '&nbsp;'
            c = hl.get(n)
            style = f' style="background:{COL[c][0]};box-shadow:inset 4px 0 0 {COL[c][1]}"' if c else ''
            note = notes.get(n)
            nt = f'<span class="note" style="background:{COL[c or "blue"][1]}">{html.escape(note)}</span>' if note else ''
            rows.append(f'<tr{style}><td class="ln">{n}</td><td class="code">{code}{nt}</td></tr>')
    leg = ''.join(f'<i style="background:{COL[k][1]}"></i>{html.escape(v)}' for k, v in legend.items())
    tag = html.escape(b.get('tag', ''))
    return (f'<div class="blk"><div class="hd"><span class="tag" style="background:{b.get("tag_color", "#57606a")}">{tag}</span>'
            f'<span class="path">{html.escape(b.get("path", b["file"]))}</span><span class="legend">{leg}</span></div>'
            f'<table>{"".join(rows)}</table></div>')


def page(blocks_html):
    css = FMT.get_style_defs('.code')
    return f'''<!doctype html><html><head><meta charset="utf-8"><style>
body{{margin:0;padding:16px;background:#fff;font-family:-apple-system,"Apple SD Gothic Neo","Noto Sans KR",sans-serif}}
#cap{{display:inline-block;min-width:1200px}}
.blk{{border:1px solid #d0d7de;border-radius:8px;overflow:hidden;margin-bottom:14px}}
.hd{{background:#f6f8fa;border-bottom:1px solid #d0d7de;padding:8px 12px;font-size:14px;color:#24292f;display:flex;gap:10px;align-items:center}}
.tag{{color:#fff;border-radius:12px;padding:2px 10px;font-weight:700;font-size:13px}}
.path{{font-family:Menlo,"D2Coding",monospace;font-size:13px}}
.legend{{margin-left:auto;font-size:12px;color:#57606a;display:flex;align-items:center;gap:4px}}
.legend i{{display:inline-block;width:10px;height:10px;border-radius:2px;margin-left:8px}}
table{{border-collapse:collapse;width:100%}}
td{{font-family:Menlo,"D2Coding","Apple SD Gothic Neo",monospace;font-size:14px;line-height:1.55;white-space:pre;vertical-align:top}}
td.ln{{color:#8c959f;text-align:right;padding:0 10px 0 12px;user-select:none;width:1%}}
td.code{{padding:0 12px 0 6px}}
tr.gap td{{color:#8c959f;background:#f6f8fa;line-height:1.2}}
.note{{color:#fff;border-radius:4px;padding:1px 8px;margin-left:14px;font-family:-apple-system,"Apple SD Gothic Neo",sans-serif;font-size:13px;font-weight:700}}
{css}
.code .err{{border:none!important;color:inherit!important;background:none!important}}
</style></head><body><div id="cap">{blocks_html}</div></body></html>'''


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--spec', required=True)
    ap.add_argument('--src-dir', required=True)
    ap.add_argument('--out-dir', required=True)
    a = ap.parse_args()
    spec = json.load(open(a.spec, encoding='utf-8'))
    captures = spec['captures'] if isinstance(spec, dict) else spec
    legend = spec.get('legend', DEFAULT_LEGEND) if isinstance(spec, dict) else DEFAULT_LEGEND
    os.makedirs(a.out_dir, exist_ok=True)
    for c in captures:
        out = os.path.join(a.out_dir, c['name'] + '.html')
        open(out, 'w', encoding='utf-8').write(page(''.join(render_block(b, a.src_dir, legend) for b in c['blocks'])))
        print(out)


if __name__ == '__main__':
    main()
