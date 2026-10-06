import unittest,json,tempfile
from pathlib import Path
from unittest.mock import patch
import build_community as m
class CommunityTests(unittest.TestCase):
 def test_video_urls(self):
  for u in ['https://youtu.be/KBDiwxO5dOI','https://www.youtube.com/watch?v=KBDiwxO5dOI&t=10','https://youtube.com/shorts/KBDiwxO5dOI']:
   self.assertEqual(m.video_id(u),'KBDiwxO5dOI')
  for u in ['https://youtube.com.evil.test/watch?v=KBDiwxO5dOI','javascript:alert(1)','https://www.youtube.com/watch?v=oops']:
   with self.assertRaises(ValueError):m.video_id(u)
 def test_offline_and_curated(self):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp);c=root/'community';d=root/'dist';c.mkdir();d.mkdir();(c/'videos').mkdir()
   profile=json.loads((m.C/'contact.json').read_text(encoding='utf8'));m.save(c/'contact.json',profile)
   cache=json.loads((m.C/'youtube-cache.json').read_text(encoding='utf8'));m.save(c/'youtube-cache.json',cache)
   with patch.object(m,'C',c),patch.object(m,'D',d),patch.object(m,'urlopen',side_effect=OSError('offline')):
    self.assertEqual(m.refresh(),cache)
    m.save(c/'videos/pick.json',{'title':'A curated example','url':'https://youtu.be/KBDiwxO5dOI','creator':'Nihal','date':'2026-10-02','published':True})
    m.save(c/'videos/draft.json',{'published':False,'title':'Hidden draft'})
    m.main(True)
    data=json.loads((d/'data/raid-videos.json').read_text(encoding='utf8'))
    rows=[v for v in data['videos'] if v['id']=='KBDiwxO5dOI'];self.assertEqual(len(rows),1);self.assertEqual(rows[0]['source'],'curated')
    self.assertNotIn('Hidden draft',(d/'raid-videos.html').read_text(encoding='utf8'))
    self.assertIn('A curated example',(d/'raid-videos.html').read_text(encoding='utf8'))
if __name__=='__main__':unittest.main()
