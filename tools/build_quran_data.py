from pathlib import Path
import re, json, unicodedata, hashlib

QDIR=Path(__file__).resolve().parents[1] / 'third_party_source' / 'quran'
if not QDIR.exists():
    QDIR=Path('/usr/share/texlive/texmf-dist/tex/latex/quran')
STY=(QDIR/'quran.sty').read_text(encoding='utf-8')
UTH=(QDIR/'qurantext-uthmani.def').read_text(encoding='utf-8')
SIMPLE=(QDIR/'qurantext-simple.def').read_text(encoding='utf-8')
OUT=Path(__file__).resolve().parents[1] / 'assets' / 'data'
OUT.mkdir(parents=True, exist_ok=True)

surah_counts=[7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6]
surah_names=['الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس','هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه','الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم','لقمان','السجدة','الأحزاب','سبإ','فاطر','يس','الصافات','ص','الزمر','غافر','فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق','الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة','الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج','نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس','التكوير','الانفطار','المطففين','الانشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد','الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات','القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر','المسد','الإخلاص','الفلق','الناس']

def extract_texts(content):
    out=[]
    for line in content.splitlines():
        if not line.startswith(r'\qt@newcmd\qurantext@'):
            continue
        m=re.match(r'^\\qt@newcmd\\qurantext@[^\{]+\{(.*)\\qt@no\{[^}]+\}\}$', line)
        if not m:
            raise RuntimeError('unparsed: '+line[:120])
        t=m.group(1)
        t=t.replace(r'\basmalah ', '')
        t=t.replace(r'\basmalah', '')
        out.append(t.strip())
    return out

uth=extract_texts(UTH)
simple=extract_texts(SIMPLE)
assert len(uth)==6236, len(uth)
assert len(simple)==6236, len(simple)
assert sum(surah_counts)==6236

def macro_ranges(name):
    marker='\\def\\'+name+'#1'
    start=STY.find(marker)
    if start<0: raise RuntimeError(name)
    nxt=STY.find('\n\\def\\', start+len(marker))
    if nxt<0: nxt=len(STY)
    body=STY[start:nxt]
    parts=re.findall(r'\\or\s*(\d+)\s*-\s*(\d+)', body)
    return [(int(a),int(b)) for a,b in parts]

juz_ranges=macro_ranges('qt@getjuzdomain')
page_ranges=macro_ranges('qt@getpagedomain')
rub_ranges=macro_ranges('qt@getquarterdomain')
assert len(juz_ranges)==30, len(juz_ranges)
assert len(page_ranges)==604, len(page_ranges)
assert len(rub_ranges)==240, len(rub_ranges)

page_of=[None]*6237
juz_of=[None]*6237
rub_of=[None]*6237
for num,ranges,target in [(None,page_ranges,page_of),(None,juz_ranges,juz_of),(None,rub_ranges,rub_of)]:
    for idx,(a,b) in enumerate(ranges,1):
        for gi in range(a,b+1): target[gi]=idx
assert all(page_of[1:]) and all(juz_of[1:]) and all(rub_of[1:])

sajdas={(7,206):'recommended',(13,15):'recommended',(16,50):'recommended',(17,109):'recommended',(19,58):'recommended',(22,18):'recommended',(22,77):'recommended',(25,60):'recommended',(27,26):'recommended',(32,15):'obligatory',(38,24):'recommended',(41,38):'obligatory',(53,62):'obligatory',(84,21):'recommended',(96,19):'obligatory'}

verses=[]; gi=0
surahs=[]
for s,(name,cnt) in enumerate(zip(surah_names,surah_counts),1):
    start=gi+1
    start_page=page_of[start]
    for a in range(1,cnt+1):
        gi+=1
        rub=rub_of[gi]
        verses.append({'index':gi,'surah':s,'ayah':a,'key':f'{s}:{a}','text':uth[gi-1],'simple':simple[gi-1],'page':page_of[gi],'juz':juz_of[gi],'hizb':(rub-1)//4+1,'rub':rub,'sajdah':sajdas.get((s,a))})
    surahs.append({'number':s,'name_ar':name,'ayah_count':cnt,'start_index':start,'end_index':gi,'start_page':start_page,'end_page':page_of[gi]})

assert gi==6236
key_by_index={v['index']:v['key'] for v in verses}
def range_records(ranges, keyname):
    return [{keyname:i,'start_index':a,'end_index':b,'start_key':key_by_index[a],'end_key':key_by_index[b]} for i,(a,b) in enumerate(ranges,1)]

pages=range_records(page_ranges,'page')
juzs=range_records(juz_ranges,'juz')
rubs=range_records(rub_ranges,'rub')
for x in rubs: x['hizb']=(x['rub']-1)//4+1
hizbs=[]
for h in range(1,61):
    rs=rub_ranges[(h-1)*4:h*4]
    hizbs.append({'hizb':h,'start_index':rs[0][0],'end_index':rs[-1][1],'start_key':key_by_index[rs[0][0]],'end_key':key_by_index[rs[-1][1]]})

def norm(s):
    s=unicodedata.normalize('NFD',s)
    s=''.join(c for c in s if unicodedata.category(c)!='Mn')
    return s.translate(str.maketrans({'ٱ':'ا','أ':'ا','إ':'ا','آ':'ا','ى':'ي','ؤ':'و','ئ':'ي','ـ':''}))

for v in verses: v['search']=norm(v['simple'])

for name,data in [('ayahs.json',verses),('surahs.json',surahs),('pages.json',pages),('juzs.json',juzs),('hizbs.json',hizbs),('rubs.json',rubs)]:
    p=OUT/name
    p.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')

source_files=[QDIR/'qurantext-uthmani.def',QDIR/'qurantext-simple.def',QDIR/'quran.sty']
manifest={'dataset':'Quran App Release offline core','verse_count':len(verses),'surah_count':len(surahs),'page_count':len(pages),'juz_count':len(juzs),'rub_count':len(rubs),'sajdah_count':len(sajdas),'source':'LaTeX quran package, LPPL 1.3c+','source_hashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in source_files},'generated_hashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.glob('*.json') if p.name != 'integrity_manifest.json'},'checks':{'sum_surah_ayah_counts':sum(surah_counts),'first_key':verses[0]['key'],'last_key':verses[-1]['key'],'first_page_start':pages[0]['start_key'],'last_page_end':pages[-1]['end_key']}}
(OUT/'integrity_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(manifest,ensure_ascii=False,indent=2))
