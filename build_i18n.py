"""Compile reviewed translations into small, self-hosted, lazy-loaded language packs."""
from pathlib import Path
from html import escape, unescape
from html.parser import HTMLParser
from collections import Counter
import gzip
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / '.editor-deps'))
import bleach
import markdown

LOCALES = ('es', 'fr', 'ja', 'ko', 'zh-Hans', 'zh-Hant', 'id')
TAGS = {'p','br','hr','h1','h2','h3','h4','h5','h6','a','img','strong','em','del','s','blockquote','ul','ol','li','pre','code','table','thead','tbody','tr','th','td'}
ATTRIBUTES = {'*':['id'],'a':['href','title'],'img':['src','alt','title','width','height'],'th':['align'],'td':['align']}

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def encode(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode('utf-8')

def source_hash(post):
    return hashlib.sha256(json.dumps({k:post[k] for k in ('title','summary','body')}, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')).hexdigest()

def render(body):
    return bleach.clean(markdown.markdown(body, extensions=['tables','fenced_code','toc']), tags=TAGS, attributes=ATTRIBUTES, protocols=['http','https','mailto'], strip=True)

class References(HTMLParser):
    """Translations may change prose, but must retain every link and image."""
    def __init__(self, body):
        super().__init__()
        self.refs = []
        self.feed(body)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'a': self.refs.append(('a', attrs.get('href', '')))
        if tag == 'img': self.refs.append(('img', attrs.get('src', '')))

def compile_article(original, translated):
    english, body = render(original['body']), render(translated['body'])
    if References(english).refs != References(body).refs:
        raise ValueError('Translated article changed a link, image, or their order')
    if Counter(re.findall(r'<code[^>]*>(.*?)</code>', english, re.S)) != Counter(re.findall(r'<code[^>]*>(.*?)</code>', body, re.S)):
        raise ValueError('Translated article changed source code')
    headings = re.findall(r'<h2 id="([^"]+)">(.*?)</h2>', english)
    translated_headings = re.findall(r'<h2 id="([^"]+)">(.*?)</h2>', body)
    if len(headings) != len(translated_headings):
        raise ValueError('Translated article changed section count')
    heading_messages = {}
    stable_ids = []
    for (ident, heading), (_, translated_heading) in zip(headings, translated_headings):
        title = unescape(re.sub('<[^>]+>', '', heading))
        stable_ids.append(original.get('anchors', {}).get(title, ident))
        heading_messages[title] = unescape(re.sub('<[^>]+>', '', translated_heading))
    ids = iter(stable_ids)
    body = re.sub(r'<h2 id="[^"]+">(.*?)</h2>', lambda m: f'<h2 id="{escape(next(ids), quote=True)}">{m[1]}</h2>', body)
    body = re.sub(r'(<table>.*?</table>)', r'<div class="table-scroll">\1</div>', body, flags=re.S)
    return {'sourceSha256':source_hash(original), 'title':translated['title'], 'summary':translated['summary'], 'body':body}, heading_messages

def build(root=ROOT):
    source = read(root / 'i18n/source.json')['messages']
    manual = root / 'i18n/manual-source.json'
    if manual.exists():
        source = list({row['id']:row for row in source + read(manual)['messages']}.values())
    ids = {row['id'] for row in source}
    output = root / 'dist/data/i18n'
    output.mkdir(parents=True, exist_ok=True)
    posts = {p.stem:read(p) for p in (root / 'newsletter/posts').glob('*.json')}
    posts = {slug:post for slug,post in posts.items() if post.get('published')}
    manifest = {'version':1, 'default':'en', 'locales':{}}
    for locale in LOCALES:
        catalog = read(root / f'i18n/locales/{locale}.json')
        if catalog['locale'] != locale:
            raise ValueError(f'{locale}: wrong locale tag')
        translations = catalog['messages']
        if set(translations) != ids:
            raise ValueError(f'{locale}: missing {len(ids-set(translations))} IDs, extra {len(set(translations)-ids)} IDs')
        messages = {}
        for row in source:
            value = translations[row['id']]
            if not isinstance(value, str) or not value.strip():
                raise ValueError(f'{locale}/{row["id"]}: empty translation')
            if Counter(re.findall(r'\{\d+\}', row['source'])) != Counter(re.findall(r'\{\d+\}', value)):
                raise ValueError(f'{locale}/{row["id"]}: changed placeholders')
            messages[row['source']] = value
        articles, stale, missing = {}, [], []
        for slug, post in posts.items():
            path = root / f'newsletter/translations/{locale}/{slug}.json'
            if not path.exists():
                missing.append(slug)
                continue
            translated = read(path)
            if translated.get('sourceSha256') != source_hash(post):
                stale.append(slug)
                continue
            article, heading_messages = compile_article(post, translated)
            articles[slug] = article
            messages.update(heading_messages)
            messages[post['title']] = translated['title']
            messages[post['title'] + ' · Guardian Atlas'] = translated['title'] + ' · Guardian Atlas'
            messages[post['summary']] = translated['summary']
        # The English renderer adds reciprocal next-post links when exactly two posts are public.
        if len(posts) == 2:
            for slug, article in articles.items():
                other_slug = next(key for key in posts if key != slug)
                other = articles.get(other_slug, posts[other_slug])
                article['body'] += f'<aside class="next-post"><span>{escape(messages.get("Keep reading", "Keep reading"))}</span><a href="newsletter-{other_slug}.html">{escape(other["title"])} →</a><p>{escape(other["summary"])}</p></aside>'
        payload = encode({'locale':locale, 'messages':messages, 'articles':articles, 'staleArticles':stale, 'untranslatedArticles':missing})
        packed = gzip.compress(payload, mtime=0)
        filename = f'{locale}.json.gz'
        (output / filename).write_bytes(packed)
        manifest['locales'][locale] = {'file':filename, 'sha256':hashlib.sha256(packed).hexdigest(), 'bytes':len(packed)}
        print(f'{locale}: {len(messages)} messages, {len(articles)} articles, {len(packed):,} compressed bytes' + (f'; English fallback: {", ".join(stale)}' if stale else ''))
    (output / 'manifest.json').write_bytes(encode(manifest))
    # Refresh the shared navigation/runtime URLs on every page when their content changes.
    runtime_paths = [root / 'dist' / name for name in ('site-nav.js','site-language.js','site-language.css')]
    runtime_hash = hashlib.sha256(b''.join(path.read_bytes() for path in runtime_paths if path.exists())).hexdigest()[:12]
    for page in (root / 'dist').glob('*.html'):
        original = page.read_text(encoding='utf-8')
        refreshed = re.sub(r'''(src=["']site-nav\.js)(?:\?[^"']*)?(["'])''', lambda match: match[1]+'?v='+runtime_hash+match[2], original)
        if refreshed != original: page.write_text(refreshed, encoding='utf-8')
    # Keep the public download inventory in step with these generated exports.
    catalog_path = root / 'dist/data/file-catalog.json'
    if catalog_path.exists():
        catalog = read(catalog_path)
        existing = {item['path']:item for item in catalog['files'] if item.get('section') == 'exports'}
        for path in sorted(output.iterdir()):
            rel = path.relative_to(root / 'dist').as_posix()
            if rel not in existing:
                catalog['files'].append({'section':'exports','path':rel,'url':rel,'bytes':path.stat().st_size,'kind':'Website translations'})
        for item in catalog['files']:
            url = item.get('url')
            if url and (root / 'dist' / url).is_file(): item['bytes'] = (root / 'dist' / url).stat().st_size
        catalog_path.write_bytes(encode(catalog))
    return manifest

if __name__ == '__main__':
    build()
