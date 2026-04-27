#!/usr/bin/env python3
"""Simple HTTP server for CS640 virtual hosts."""

import http.server
import socketserver
import os

PORT = 80
Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("Serving on port", PORT)
    httpd.serve_forever()
