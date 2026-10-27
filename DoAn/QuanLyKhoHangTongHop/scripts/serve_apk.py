import http.server
import socketserver
import os

PORT = 8888
DIRECTORY = r"D:\QLDA\apk_share"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving APK at http://0.0.0.0:{PORT}")
    httpd.serve_forever()
