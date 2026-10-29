"""Preview the static site with prepared full-resolution PNGs kept outside dist."""
from pathlib import Path
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit
import argparse
import json


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--work', type=Path, required=True)
    parser.add_argument('--dist', type=Path, default=Path(__file__).parent / 'dist')
    parser.add_argument('--port', type=int, default=8768)
    args = parser.parse_args()
    site, releases = args.dist.resolve(), (args.work / 'release').resolve()

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=str(site), **kw)

        def translate_path(self, url):
            parsed = unquote(urlsplit(url).path)
            prefix = '/downloads/hero-illustrations/'
            if parsed.startswith(prefix):
                filename = parsed[len(prefix):]
                target = (releases / filename).resolve()
                if target.parent == releases and target.suffix in ('.png', '.zip'):
                    return str(target)
                return str(site / '__invalid_download__')
            return super().translate_path(url)

        def do_GET(self):
            # Local preview serves the prepared bytes before release publication,
            # while the saved catalogue already contains its final public URLs.
            if urlsplit(self.path).path == '/data/hero-illustrations/index.json':
                source = site / 'data/hero-illustrations/index.json'
                if source.exists():
                    catalog = json.loads(source.read_text(encoding='utf8'))
                    for item in catalog['illustrations']:
                        for file in item['files'].values():
                            file['url'] = '/downloads/hero-illustrations/' + file['filename']
                    for pack in catalog.get('packs', []):
                        pack['url'] = '/downloads/hero-illustrations/' + pack['filename']
                    data = json.dumps(catalog).encode('utf8')
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json; charset=utf-8')
                    self.send_header('Content-Length', str(len(data)))
                    self.end_headers()
                    self.wfile.write(data)
                    return
            super().do_GET()

    print(f'Hero gallery: http://127.0.0.1:{args.port}/hero-illustrations.html', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
