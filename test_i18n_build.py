"""Protect article evidence and ensure stale translations never replace updated copy."""
import copy
import gzip
import json
from pathlib import Path
import tempfile
import unittest
import build_i18n as i18n

class TranslationBuildTests(unittest.TestCase):
    def test_all_current_articles_retain_evidence_and_anchors(self):
        translated_paths = list((i18n.ROOT / 'newsletter/translations').glob('*/*.json'))
        public_posts = [path for path in (i18n.ROOT / 'newsletter/posts').glob('*.json') if i18n.read(path).get('published')]
        self.assertEqual(len(translated_paths), len(public_posts) * len(i18n.LOCALES))
        for path in translated_paths:
            with self.subTest(path=str(path)):
                original = i18n.read(i18n.ROOT / 'newsletter/posts' / path.name)
                translated = i18n.read(path)
                self.assertEqual(translated['sourceSha256'], i18n.source_hash(original))
                article, headings = i18n.compile_article(original, translated)
                self.assertGreater(len(article['body']), 5000)
                self.assertNotEqual(article['title'], original['title'])
                self.assertTrue(headings)
                for anchor in original.get('anchors', {}).values():
                    self.assertIn(f'id="{anchor}"', article['body'])

    def test_deterministic_packs_and_stale_editorial_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def save(path, value):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(json.dumps(value), encoding='utf-8')
            save(root / 'i18n/source.json', {'messages':[{'id':'title', 'source':'Map {0}'}]})
            original = {'title':'A patch', 'summary':'Patch evidence', 'body':'## Evidence\n\n[Source](index.html) and `source_id`.\n\n![Map](map.webp)', 'published':True, 'anchors':{'Evidence':'stable-evidence'}}
            save(root / 'newsletter/posts/patch.json', original)
            for locale in i18n.LOCALES:
                save(root / f'i18n/locales/{locale}.json', {'locale':locale, 'messages':{'title':'Carte {0}'}})
                save(root / f'newsletter/translations/{locale}/patch.json', {'locale':locale, 'title':'Un patch', 'summary':'Les données', 'body':'## Données\n\n[Source](index.html) et `source_id`.\n\n![Carte](map.webp)', 'sourceSha256':i18n.source_hash(original)})
            first = i18n.build(root)
            second = i18n.build(root)
            self.assertEqual(first, second)
            def pack(): return json.loads(gzip.decompress((root/'dist/data/i18n/fr.json.gz').read_bytes()))
            self.assertIn('id="stable-evidence"', pack()['articles']['patch']['body'])
            original['body'] += '\n\nAn important correction.'
            save(root/'newsletter/posts/patch.json', original)
            i18n.build(root)
            self.assertNotIn('patch', pack()['articles'])
            self.assertEqual(pack()['staleArticles'], ['patch'])
            self.assertNotIn('A patch', pack()['messages'])
            save(root/'i18n/locales/es.json', {'locale':'es', 'messages':{'title':'Mapa'}})
            with self.assertRaisesRegex(ValueError, 'changed placeholders'): i18n.build(root)

    def test_changed_sources_are_rejected_and_html_is_sanitized(self):
        original = {'title':'Original', 'summary':'Summary', 'body':'## Heading\n\n[Source](index.html) and `source_id`'}
        translated = {'title':'Traduit', 'summary':'Résumé', 'body':'## Titre\n\n[Source](index.html) et `source_id`\n\n<script>alert(1)</script>'}
        article, _ = i18n.compile_article(original, translated)
        self.assertNotIn('<script', article['body'])
        changed = copy.deepcopy(translated)
        changed['body'] = changed['body'].replace('source_id', 'invented_id')
        with self.assertRaisesRegex(ValueError, 'changed source code'): i18n.compile_article(original, changed)
        changed['body'] = translated['body'].replace('index.html', 'wrong.html')
        with self.assertRaisesRegex(ValueError, 'changed a link'): i18n.compile_article(original, changed)

if __name__ == '__main__': unittest.main()
