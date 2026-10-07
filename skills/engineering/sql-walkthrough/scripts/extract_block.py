#!/usr/bin/env python3
"""Extract a MyBatis statement (or one CTE inside it) **with original line numbers**.

Usage:
  extract_block.py <repo-dir> <git-ref> <mapper-path> <statement-id> [cte-name] [--scan] [--sql]

  <git-ref>        e.g. origin/prod, v1.4.2, HEAD, or 'worktree' (read the working-tree file as-is)
  [cte-name]       a CTE name inside the WITH clause; given -> only that block, omitted -> whole statement
  --scan           print only date/range-related lines (_DT, startDate, NOW, INTERVAL, BETWEEN, <=, >=)
  --sql            print runnable SQL without line numbers (XML comments and CDATA removed; #{param} kept)

Example:
  extract_block.py my-batch origin/prod \
      src/main/resources/mapper/StatsMapper.xml upsertDailyStats time_total
"""
import re
import subprocess
import sys


def load(repo, ref, path):
    if ref == 'worktree':
        return open(f"{repo}/{path}", encoding='utf-8').read()
    return subprocess.run(['git', '-C', repo, 'show', f'{ref}:{path}'],
                          capture_output=True, text=True, check=True).stdout


def find_statement(text, sid):
    # <insert id ="x" >, <select id="x" ...> 등 공백 변형 허용
    m = re.search(r'<(select|insert|update|delete)\s+id\s*=\s*"' + re.escape(sid) + r'"[^>]*>', text)
    if not m:
        sys.exit(f"statement id={sid} 없음")
    start = m.start()
    end_m = re.search(r'</' + m.group(1) + r'>', text[start:])
    end = start + end_m.end()
    return start, end


def find_cte(text, start, end, name):
    # 'name AS (' 에서 괄호 짝이 맞는 ')' 까지
    seg = text[start:end]
    m = re.search(r'\b' + re.escape(name) + r'\s+AS\s*\(', seg, re.I)
    if not m:
        sys.exit(f"CTE {name} 없음")
    i = m.end()
    depth = 1
    while i < len(seg) and depth:
        c = seg[i]
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
        i += 1
    return start + m.start(), start + i


def line_no(text, pos):
    return text.count('\n', 0, pos) + 1


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    flags = {a for a in sys.argv[1:] if a.startswith('--')}
    if len(args) < 4:
        sys.exit(__doc__)
    repo, ref, path, sid = args[:4]
    cte = args[4] if len(args) > 4 else None

    text = load(repo, ref, path)
    s, e = find_statement(text, sid)
    if cte:
        s, e = find_cte(text, s, e, cte)
    block = text[s:e]
    first = line_no(text, s)

    if '--sql' in flags:
        sql = re.sub(r'<!--.*?-->', '', block, flags=re.S)
        sql = re.sub(r'<!\[CDATA\[(.*?)\]\]>', r'\1', sql, flags=re.S)
        print(sql)
        return

    lines = block.split('\n')
    if '--scan' in flags:
        pat = re.compile(r'_DT\b|startDate|NOW\(|CURDATE|INTERVAL|BETWEEN|<=|>=', re.I)
        for i, ln in enumerate(lines):
            if pat.search(ln):
                print(f"{first + i:>5}  {ln.strip()}")
        return

    for i, ln in enumerate(lines):
        print(f"{first + i:>5}  {ln}")


if __name__ == '__main__':
    main()
