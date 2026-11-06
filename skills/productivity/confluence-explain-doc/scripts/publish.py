#!/usr/bin/env python3
"""Create/update a Confluence page from storage XML and attach files (REST, basic auth).

  publish.py create --space-key KEY --title T --body body.xml [--attach a.png ...]
  publish.py update --page-id ID --body body.xml [--attach a.png ...]   # same-name attachments are replaced
  publish.py check  --page-id ID                                          # print images / expands / red cells / url

Auth: ATL_SITE (e.g. https://your-org.atlassian.net, required), ATL_EMAIL (or `acli jira auth status`),
ATL_TOKEN or ATL_TOKEN_FILE (API token). Values usually come from the domain profile.
"""
import argparse, json, os, re, subprocess, sys, urllib.request, base64, mimetypes, uuid

SITE = os.environ.get("ATL_SITE", "").rstrip("/")

def creds():
    email = os.environ.get("ATL_EMAIL")
    if not email:
        out = subprocess.run(["acli", "jira", "auth", "status"], capture_output=True, text=True).stdout
        m = re.search(r"Email:\s*(\S+)", out)
        email = m.group(1) if m else sys.exit("set ATL_EMAIL")
    token = os.environ.get("ATL_TOKEN") or (open(os.path.expanduser(os.environ["ATL_TOKEN_FILE"])).read().strip() if os.environ.get("ATL_TOKEN_FILE") else sys.exit("set ATL_TOKEN or ATL_TOKEN_FILE"))
    return "Basic " + base64.b64encode(f"{email}:{token}".encode()).decode()

def req(method, path, data=None, headers=None):
    if not SITE:
        sys.exit("set ATL_SITE")
    h = {"Authorization": creds(), "Accept": "application/json"}
    h.update(headers or {})
    r = urllib.request.Request(SITE + "/wiki" + path, data=data, method=method, headers=h)
    with urllib.request.urlopen(r) as resp:
        return json.loads(resp.read() or b"{}")

def attach(pid, path):
    name = os.path.basename(path)
    found = req("GET", f"/rest/api/content/{pid}/child/attachment?filename={urllib.request.quote(name)}")["results"]
    url = f"/rest/api/content/{pid}/child/attachment" + (f"/{found[0]['id']}/data" if found else "")
    b = uuid.uuid4().hex
    body = (f"--{b}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{name}\"\r\n"
            f"Content-Type: {mimetypes.guess_type(name)[0] or 'application/octet-stream'}\r\n\r\n").encode() + open(path, "rb").read() + f"\r\n--{b}--\r\n".encode()
    req("POST", url, body, {"Content-Type": f"multipart/form-data; boundary={b}", "X-Atlassian-Token": "no-check"})
    print("attached", name, "(replaced)" if found else "")

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("cmd", choices=["create", "update", "check"])
    ap.add_argument("--space-key"); ap.add_argument("--title"); ap.add_argument("--page-id"); ap.add_argument("--body")
    ap.add_argument("--attach", nargs="*", default=[]); a = ap.parse_args()
    if a.cmd == "check":
        d = req("GET", f"/rest/api/content/{a.page_id}?expand=body.view,version"); v = d["body"]["view"]["value"]
        print(json.dumps({"version": d["version"]["number"], "images": len(re.findall(r"<img ", v)),
                          "expands": v.count("expand-container"), "red_cells": v.count("data-highlight-colour"),
                          "url": f"{SITE}/wiki/pages/viewpage.action?pageId={a.page_id}"}, ensure_ascii=False)); return
    body = open(a.body, encoding="utf-8").read()
    if a.cmd == "create":
        d = req("POST", "/rest/api/content", json.dumps({"type": "page", "title": a.title, "space": {"key": a.space_key},
                "body": {"storage": {"value": body, "representation": "storage"}}}).encode(), {"Content-Type": "application/json"})
        pid = d["id"]
    else:
        pid = a.page_id; cur = req("GET", f"/rest/api/content/{pid}?expand=version")
        for p in a.attach: attach(pid, p)
        a.attach = []
        req("PUT", f"/rest/api/content/{pid}", json.dumps({"id": pid, "type": "page", "title": a.title or cur["title"],
            "version": {"number": cur["version"]["number"] + 1}, "body": {"storage": {"value": body, "representation": "storage"}}}).encode(),
            {"Content-Type": "application/json"})
    for p in a.attach: attach(pid, p)
    print(f"page {pid} {SITE}/wiki/pages/viewpage.action?pageId={pid}")

if __name__ == "__main__":
    main()
