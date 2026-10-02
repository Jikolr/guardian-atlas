"""Exercise publication in an isolated miniature checkout, no user articles changed."""
import json,os,subprocess,sys,tempfile,shutil,re
from pathlib import Path
B=Path(__file__).resolve().parent
def write(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v),encoding='utf8')
with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp);shutil.copyfile(B/'build_newsletter.py',root/'build_newsletter.py')
    data=root/'dist/data';posts=root/'newsletter/posts'
    write(data/'visual/record-media.json',{'heroes:701':{'image':'test.webp'},'heroes:695':{'image':'test.webp'}})
    write(data/'file-catalog.json',{'files':[]})
    sample={'title':'Test article','date':'2026-10-02','category':'Guides','summary':'A sample','published':True,'body':'## Heading\n\nHello **world**.\n\n<script>alert(1)</script>\n\n[bad](javascript:alert(1))\n\n| A | B |\n|---|---|\n| 1 | 2 |'}
    write(posts/'first.json',sample);write(posts/'second.json',{**sample,'title':'Second','date':'2026-10-03'})
    write(posts/'draft.json',{**sample,'published':False,'title':'Secret draft'})
    env={**os.environ,'PYTHONPATH':str(B/'.editor-deps')}
    def build():subprocess.run([sys.executable,str(root/'build_newsletter.py')],env=env,check=True,capture_output=True)
    build()
    index=(root/'dist/newsletter.html').read_text(encoding='utf8')
    assert '2 posts' in index and 'Secret draft' not in index
    assert index.index('Second')<index.index('Test article')
    article=(root/'dist/newsletter-first.html').read_text(encoding='utf8')
    assert '<script>alert' not in article and 'href="javascript:' not in article
    assert '<strong>world</strong>' in article and 'class="table-scroll"' in article
    assert not (root/'dist/newsletter-draft.html').exists()
    write(posts/'first.json',{**sample,'published':False});(posts/'second.json').unlink();build()
    assert not (root/'dist/newsletter-first.html').exists() and not (root/'dist/newsletter-second.html').exists()
    assert '0 posts' in (root/'dist/newsletter.html').read_text(encoding='utf8')
print('PASS: publication, drafts, date ordering, Markdown, sanitization, deletion and unpublish')
