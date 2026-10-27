#!/usr/bin/env python3

import argparse
import http.client
import mimetypes
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class StageWebHandler(SimpleHTTPRequestHandler):
    stage_host = "api-mobile-stage.oysyn.asia"
    web_root = Path.cwd() / "build" / "web"

    def do_GET(self):
        if self.path.startswith("/api/") or self.path == "/health":
            self._proxy()
            return
        self._serve_web_file()

    def do_HEAD(self):
        if self.path.startswith("/api/") or self.path == "/health":
            self._proxy()
            return
        self._serve_web_file(head_only=True)

    def do_POST(self):
        self._proxy()

    def do_PUT(self):
        self._proxy()

    def do_PATCH(self):
        self._proxy()

    def do_DELETE(self):
        self._proxy()

    def do_OPTIONS(self):
        self._proxy()

    def _proxy(self):
        body_length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(body_length) if body_length else None
        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in HOP_BY_HOP_HEADERS
            and key.lower() not in {"host", "origin", "referer", "accept-encoding"}
        }
        headers["Host"] = self.stage_host
        headers["Accept-Encoding"] = "identity"

        connection = http.client.HTTPSConnection(self.stage_host, timeout=60)
        try:
            connection.request(self.command, self.path, body=body, headers=headers)
            response = connection.getresponse()
            payload = response.read()
            self.send_response(response.status)
            for key, value in response.getheaders():
                if key.lower() not in HOP_BY_HOP_HEADERS and key.lower() != "content-length":
                    self.send_header(key, value)
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(payload)
        except Exception as error:
            payload = f"Stage proxy error: {type(error).__name__}".encode()
            self.send_response(502)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        finally:
            connection.close()

    def _serve_web_file(self, head_only=False):
        path = urlsplit(self.path).path.lstrip("/")
        requested = (self.web_root / path).resolve()
        root = self.web_root.resolve()
        if not path or not requested.is_relative_to(root) or not requested.is_file():
            requested = root / "index.html"

        payload = requested.read_bytes()
        content_type = mimetypes.guess_type(requested.name)[0] or "application/octet-stream"
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if not head_only:
            self.wfile.write(payload)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8093)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), StageWebHandler)
    print(f"OySyn Stage web emulator: http://{args.host}:{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
