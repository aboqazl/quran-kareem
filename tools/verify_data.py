#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'assets' / 'data'


def load(name):
    return json.loads((DATA / name).read_text(encoding='utf-8'))


def sha256(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

ayahs = load('ayahs.json')
surahs = load('surahs.json')
pages = load('pages.json')
juzs = load('juzs.json')
hizbs = load('hizbs.json')
rubs = load('rubs.json')
manifest = load('integrity_manifest.json')

assert len(ayahs) == 6236, len(ayahs)
assert len(surahs) == 114, len(surahs)
assert len(pages) == 604, len(pages)
assert len(juzs) == 30, len(juzs)
assert len(hizbs) == 60, len(hizbs)
assert len(rubs) == 240, len(rubs)
assert ayahs[0]['key'] == '1:1'
assert ayahs[-1]['key'] == '114:6'
assert pages[0]['start_key'] == '1:1'
assert pages[-1]['end_key'] == '114:6'
assert sum(s['ayah_count'] for s in surahs) == 6236
assert len({a['key'] for a in ayahs}) == 6236
assert len([a for a in ayahs if a.get('sajdah')]) == 15
assert all(1 <= a['page'] <= 604 for a in ayahs)
assert all(1 <= a['juz'] <= 30 for a in ayahs)
assert all(1 <= a['hizb'] <= 60 for a in ayahs)
assert all(1 <= a['rub'] <= 240 for a in ayahs)

for s in surahs:
    subset = ayahs[s['start_index']-1:s['end_index']]
    assert len(subset) == s['ayah_count']
    assert subset[0]['surah'] == s['number']
    assert subset[-1]['surah'] == s['number']
    assert [a['ayah'] for a in subset] == list(range(1, s['ayah_count'] + 1))

for page in pages:
    subset = ayahs[page['start_index']-1:page['end_index']]
    assert subset[0]['key'] == page['start_key']
    assert subset[-1]['key'] == page['end_key']
    assert all(a['page'] == page['page'] for a in subset)

expected = manifest.get('generated_hashes', {})
for name, digest in expected.items():
    path = DATA / name
    assert sha256(path) == digest, f'hash mismatch: {name}'

print('PASS: Quran data integrity')
print('6236 ayahs | 114 surahs | 604 pages | 30 juz | 60 hizb | 240 rub | 15 sajdah')
