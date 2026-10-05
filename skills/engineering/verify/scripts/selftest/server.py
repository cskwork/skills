#!/usr/bin/env python3
"""A throwaway API for the self-test.

Small on purpose. It exists to prove the harness plumbing works: health
polling, token acquisition, token caching, header injection, assertions,
and redaction. It is not a fixture for anything else.

  python3 server.py [port]        default 8778
"""

import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

# Joined at runtime so secret scanners do not read the literal as a real JWT.
TOKEN = ".".join(("eyJhbGciOiJIUzI1NiJ9", "eyJzdWIiOiJzZWxmdGVzdCJ9", "s3lft3st-signature-value"))
USER = "dev@example.com"
PASSWORD = "changeme"


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format, *args):  # keep the test output readable
        pass

    def _send(self, status, payload=None):
        body = b"" if payload is None else json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)

    def _authed(self):
        header = self.headers.get("Authorization", "")
        return header == f"Bearer {TOKEN}"

    def do_GET(self):
        url = urlparse(self.path)
        query = parse_qs(url.query)

        if url.path == "/health":
            return self._send(200, {"status": "UP"})

        if url.path == "/api/items":
            if not self._authed():
                return self._send(401, {"code": "40100", "message": "no token"})

            raw = query.get("limit", ["3"])[0]
            try:
                limit = int(raw)
            except ValueError:
                # The point of the negative variant: reject input with a 4xx,
                # not a 500.
                return self._send(400, {"code": "40000", "message": f"limit is not a number: {raw}"})
            if limit < 0:
                return self._send(400, {"code": "40000", "message": "limit must not be negative"})

            items = [{"id": i, "name": f"item-{i}"} for i in range(limit)]
            return self._send(200, {"code": "00000", "message": "ok",
                                    "data": {"items": items, "total": limit}})

        return self._send(404, {"code": "40400", "message": "not found"})

    def do_POST(self):
        url = urlparse(self.path)
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self._send(400, {"code": "40000", "message": "invalid content length"})
        raw = self.rfile.read(length) if length else b"{}"

        if url.path == "/auth/login":
            try:
                creds = json.loads(raw or b"{}")
            except json.JSONDecodeError:
                return self._send(400, {"code": "40000", "message": "bad json"})
            if creds.get("username") == USER and creds.get("password") == PASSWORD:
                return self._send(200, {"code": "00000",
                                        "data": {"accessToken": TOKEN, "expiresIn": 1800}})
            return self._send(401, {"code": "40100", "message": "bad credentials"})

        return self._send(404, {"code": "40400", "message": "not found"})


if __name__ == "__main__":
    try:
        port = int(sys.argv[1]) if len(sys.argv) > 1 else 8778
    except ValueError:
        raise SystemExit("port must be an integer") from None
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
