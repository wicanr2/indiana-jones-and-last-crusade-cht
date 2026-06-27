#!/usr/bin/env python3
# 英文 per-character 配音:同 dub_cast.py 的靜態講者抽取,但用英文卡司 + 英文 manifest,
# 輸出 per-actor 英文 manifest → 由 dub_cast_worker dub 進 voice_en/a<actor>/。
# 印第(ego)走 voice_en/ flat(GuyNeural);雜魚走 voice_en/<key> flat fallback。
import os, re, sys, subprocess, collections

DESC, DUMP, MAN, OUTDIR = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
os.makedirs(OUTDIR, exist_ok=True)

# ---- 英文卡司(對齊電影演員,皆 edge-tts 合法)----
ACTOR_VOICE = {
    2: ("en-GB-RyanNeural",   "-8%", "-6Hz", "Henry 老爸(康納萊英腔,沉穩)"),
    3: ("en-GB-SoniaNeural",  "-2%", "+0Hz", "Elsa(英國女聲,優雅)"),
    4: ("en-GB-ThomasNeural", "-6%", "-4Hz", "Marcus(英國老紳士,溫厚)"),
    5: ("en-AU-WilliamMultilingualNeural", "-8%", "+4Hz", "醉漢(澳腔,含糊)"),
    9: ("en-US-RogerNeural",  "+0%", "-2Hz", "教練(美式爽朗)"),
}
ROOM_VOICE = {
    (10, 86): ("en-GB-ThomasNeural",  "-16%", "-12Hz", "聖杯騎士(古英腔,極慢極沉)"),
    (6,  21): ("en-US-SteffanNeural", "-2%",  "-4Hz",  "Donovan/軍官(理性滑順、奸滑)"),
}
ACTOR_VOICE_SOFT = {
    6: ("en-US-SteffanNeural", "-2%", "-4Hz", "Donovan/軍官(理性滑順)"),
}

TEXT = re.compile(rb'Text\("((?:[^"\\]|\\.)*)"\)')
PRINT = re.compile(rb'print\((\d+),')
PEGO  = re.compile(rb'printEgo\(')
FNV_OFF, FNV_PRIME, MASK = 2166136261, 16777619, 0xFFFFFFFF
def unescape(s):
    o = bytearray(); i = 0
    while i < len(s):
        if s[i:i+2] == b'\\x' and i+4 <= len(s):
            try: o.append(int(s[i+2:i+4],16)); i += 4; continue
            except ValueError: pass
        o.append(s[i]); i += 1
    return bytes(o)
def cht_key(gbk):
    h = FNV_OFF; i = 0
    while i < len(gbk):
        b0 = gbk[i]
        if 0x81 <= b0 <= 0xFE and i+1 < len(gbk):
            h = ((h ^ b0) * FNV_PRIME) & MASK
            h = ((h ^ gbk[i+1]) * FNV_PRIME) & MASK
            i += 2
        else: i += 1
    return "%08x" % h

# 英文 manifest:key -> 英文台詞(key 由中文 GBK 算,value 是英文)
en = {}
for ln in open(MAN, encoding="utf-8"):
    ln = ln.rstrip("\n")
    if "\t" in ln:
        k, s = ln.split("\t", 1); en[k] = s

buckets = collections.defaultdict(dict)
cast_of = collections.defaultdict(lambda: ["", "", "", ""])
for root, _, files in os.walk(DUMP):
    m = re.search(r'LF_(\d+)', root); room = int(m.group(1)) if m else -1
    for fn in sorted(files):
        if not re.match(r'(SC|LS|OC|EN|EX)_', fn): continue
        try: r = subprocess.run([DESC,"-3","-n",os.path.join(root,fn)],capture_output=True,timeout=30)
        except Exception: continue
        for line in r.stdout.split(b'\n'):
            ts = TEXT.findall(line)
            if not ts: continue
            mp = PRINT.search(line)
            if mp: actor = int(mp.group(1))
            elif PEGO.search(line): actor = -1
            else: continue
            if actor < 0: continue
            key = cht_key(b''.join(unescape(t) for t in ts))
            if key not in en: continue
            voice = ROOM_VOICE.get((actor, room)) or ACTOR_VOICE.get(actor) or ACTOR_VOICE_SOFT.get(actor)
            if not voice: continue
            v, rate, pitch, name = voice
            buckets[actor][key] = (v, rate, pitch)
            cast_of[actor] = [v, rate, pitch, name]

total = 0
for actor, keys in sorted(buckets.items()):
    with open(os.path.join(OUTDIR, f"a{actor}.tsv"), "w", encoding="utf-8") as f:
        for key, (v, rate, pitch) in keys.items():
            f.write(f"{key}\t{en[key]}\t{v}\t{rate}\t{pitch}\n")
    v, rate, pitch, name = cast_of[actor]
    print(f"actor {actor:>3}  {len(keys):>3} 句  {name}  [{v} {rate}/{pitch}]")
    total += len(keys)
print(f"\n英文專屬配音合計 {total} 句,{len(buckets)} 角色 → {OUTDIR}/a*.tsv")
