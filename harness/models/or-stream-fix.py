#!/usr/bin/env python3
"""or-stream-fix — local proxy fixing OpenRouter SSE streams for Claude Code.

Problem: OpenRouter's Anthropic-compatible endpoint emits Gemini's thought
signature as a TRAILING thinking block (text block first, thinking after).
Claude Code requires the Anthropic invariant — thinking blocks precede text —
and silently drops the whole message text when the order is violated. This
only happens when the request carries tools (Claude Code always sends its
tool set), so every Gemini response through the skin comes back unparsable.

Fix: forward requests to OpenRouter untouched and rewrite SSE responses,
dropping thinking blocks that start after the first text block. Those blocks
carry only a signature (no reasoning content), so dropping them costs
Gemini's cross-turn thought-signature continuity but nothing visible.
Everything else — message framing, usage, pings — passes through verbatim.

Run standalone:  ./or-stream-fix.py [port]     (default 8791)
"""
import http.server
import json
import socket
import sys
import urllib.request
import urllib.error

UPSTREAM = "https://openrouter.ai"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8791
class StreamRewriter:
    """Decides which SSE events to keep: drops thinking blocks that start
    after the first non-thinking block (Gemini's trailing signature blocks),
    along with every subsequent event referencing the dropped index."""

    def __init__(self):
        self.started_content = False
        self.dropped = set()

    def keep_event(self, lines):
        data = ""
        for line in lines:
            if line.startswith("data:"):
                data += line[5:].lstrip(" ")
        if '"content_block_' not in data:
            return True
        try:
            payload = json.loads(data)
        except ValueError:
            return True
        etype = payload.get("type")
        index = payload.get("index")
        if etype == "content_block_start":
            block = payload.get("content_block") or {}
            if block.get("type") == "thinking" and self.started_content:
                self.dropped.add(index)
                return False
            self.started_content = True
            return True
        if etype in ("content_block_delta", "content_block_stop"):
            return index not in self.dropped
        return True


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _open_upstream(self, body):
        req = urllib.request.Request(
            UPSTREAM + self.path, data=body if body else None, method=self.command)
        # Accept-Encoding is NOT forwarded: urllib does not decompress and we
        # need the raw SSE bytes readable.
        for h in ("authorization", "anthropic-version", "anthropic-beta",
                  "content-type", "x-api-key"):
            if self.headers.get(h) is not None:
                req.add_header(h, self.headers[h])
        return urllib.request.urlopen(req, timeout=300)

    def _relay(self, body):
        try:
            resp = self._open_upstream(body)
        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header("content-type", e.headers.get("content-type", "application/json"))
            self.send_header("content-length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        except Exception as e:
            data = json.dumps({"type": "error", "error": {"type": "proxy_error",
                                                          "message": str(e)}}).encode()
            self.send_response(502)
            self.send_header("content-type", "application/json")
            self.send_header("content-length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return

        if "text/event-stream" in (resp.headers.get("content-type") or ""):
            self._relay_sse(resp)
        else:
            self._relay_buffered(resp)

    def _relay_buffered(self, resp):
        data = resp.read()
        self.send_response(resp.status)
        self.send_header("content-type", resp.headers.get("content-type", "application/json"))
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _relay_sse(self, resp):
        self.send_response(resp.status)
        self.send_header("content-type", "text/event-stream")
        self.send_header("cache-control", "no-cache")
        self.send_header("transfer-encoding", "chunked")
        self.end_headers()

        rewriter = StreamRewriter()

        def emit(raw):
            self.wfile.write(("%x\r\n" % len(raw)).encode() + raw + b"\r\n")

        # SSE events are separated by a blank line. Accumulate lines, and on
        # a completed event decide keep/drop before forwarding. read1()
        # returns whatever is available, so events forward without waiting
        # for the full buffer to fill.
        pending = []
        buf = b""
        while True:
            chunk = resp.read1(4096)
            if not chunk:
                break
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                text = line.decode("utf-8", "replace").rstrip("\r")
                if text == "":
                    if pending:
                        if rewriter.keep_event(pending):
                            emit(("\n".join(pending) + "\n\n").encode())
                        pending = []
                else:
                    pending.append(text)
        if pending and rewriter.keep_event(pending):
            emit(("\n".join(pending) + "\n\n").encode())
        # Terminate the chunked body.
        self.wfile.write(b"0\r\n\r\n")

    def do_POST(self):
        length = int(self.headers.get("content-length", 0))
        body = self.rfile.read(length) if length else None
        self._relay(body)

    def do_GET(self):
        self._relay(None)

    def log_message(self, *args):
        pass


def port_open(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.3)
        return s.connect_ex(("127.0.0.1", port)) == 0


if __name__ == "__main__":
    if port_open(PORT):
        print(f"or-stream-fix: port {PORT} already in use — assuming proxy is running")
        sys.exit(0)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"or-stream-fix: listening on 127.0.0.1:{PORT}")
    server.serve_forever()
