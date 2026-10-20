"""Caddy forward_auth target that only lets the tailnet owner and servers through.

usage: tailnet-gate.py <port> <owner> <server-tag>

Caddy sends Remote-Addr / Remote-Port of the client; the node is looked up via
tailscaled's LocalAPI. Anything that isn't positively identified is refused.
"""

import http.client
import json
import socket
import sys
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SOCKET = "/run/tailscale/tailscaled.sock"


class LocalAPI(http.client.HTTPConnection):
    def __init__(self):
        super().__init__("local-tailscaled.sock", timeout=5)

    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.settimeout(self.timeout)
        self.sock.connect(SOCKET)


def whois(addr):
    conn = LocalAPI()
    try:
        conn.request("GET", "/localapi/v0/whois?addr=" + urllib.parse.quote(addr))
        resp = conn.getresponse()
        if resp.status != 200:
            return None
        return json.load(resp)
    finally:
        conn.close()


def allowed(info, owner, server_tag):
    if info is None:
        return False
    # tagged nodes have no user, so only the tag says what they are
    tags = (info.get("Node") or {}).get("Tags") or []
    if tags:
        return server_tag in tags
    login = (info.get("UserProfile") or {}).get("LoginName", "")
    return login.split("@")[0] == owner


def main():
    port, owner, server_tag = int(sys.argv[1]), sys.argv[2], sys.argv[3]

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            addr, rport = self.headers.get("Remote-Addr"), self.headers.get("Remote-Port")
            ok = False
            if addr and rport:
                try:
                    ok = allowed(whois(f"{addr}:{rport}"), owner, server_tag)
                except OSError:
                    pass
            self.send_response(204 if ok else 403)
            self.end_headers()

        def log_message(self, *args):
            pass

    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
