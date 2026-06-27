#!/usr/bin/env python3
# 靜態卡司配音:descumm 抽 (key, actor, room) → 套卡司規則 → 每個有專屬聲線的角色,
# 把他的台詞 key 用其聲線寫成 /tmp 的 per-actor manifest(再由 shell 餵 edge-tts → voice/a<actor>/)。
# 規則優先序:(actor,room) 特例 > actor 預設 > 其餘(略過 → 執行期落 npc/ 沉穩+變調)。
import os, re, sys, subprocess, collections

DESC, DUMP, MAN, OUTDIR = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
os.makedirs(OUTDIR, exist_ok=True)

# ---- 卡司(對話分析 → 樣貌對味聲線)----
# actor 預設:角色號 -> (voice, rate, pitch, 名稱)
ACTOR_VOICE = {
    2: ("zh-TW-YunJheNeural",   "-14%", "-18Hz", "亨利老爸(老成慢深)"),
    3: ("zh-TW-HsiaoChenNeural", "-4%",  "-2Hz", "艾爾莎(成熟女聲)"),
    4: ("zh-CN-YunyangNeural",  "-8%",  "-8Hz", "馬可斯(溫厚迷糊老紳士)"),
    5: ("zh-CN-YunxiaNeural",   "-8%", "+8Hz", "醉漢(卡通喜感、含糊)"),
    9: ("zh-CN-YunjianNeural",  "+0%",  "-4Hz", "拳擊教練(爽朗有勁)"),
}
# (actor, room) 特例:重用情境槽裡的有名角色
ROOM_VOICE = {
    (10, 86): ("zh-TW-YunJheNeural",  "-18%", "-20Hz", "聖杯騎士(七百歲,極慢極沉)"),
    (6,  21): ("zh-HK-WanLungNeural", "-2%",  "-6Hz",  "唐納文/城堡軍官(港音洋派、奸滑)"),
}
# actor 6 其餘房間也當同一反派軍官
ACTOR_VOICE_SOFT = {
    6: ("zh-HK-WanLungNeural", "-2%", "-6Hz", "唐納文/軍官(港音洋派、奸滑)"),
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

# 讀中文 manifest(key->中文,用來 dub 的文本)
cn = {}
for ln in open(MAN, encoding="utf-8"):
    ln = ln.rstrip("\n")
    if "\t" in ln:
        k, s = ln.split("\t", 1); cn[k] = s

# 抽 (key, actor, room),挑出有卡司的 → 分桶到 per-actor manifest
buckets = collections.defaultdict(dict)   # actor -> {key: (voice,rate,pitch)}
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
            if actor < 0: continue                      # 印第 ego → 通用 voice/
            key = cht_key(b''.join(unescape(t) for t in ts))
            if key not in cn: continue                  # 不在中文 manifest 就跳
            # 解析卡司:(actor,room) 特例 > actor 預設 > actor soft
            voice = ROOM_VOICE.get((actor, room)) or ACTOR_VOICE.get(actor) or ACTOR_VOICE_SOFT.get(actor)
            if not voice: continue                      # 雜魚 → 略過(執行期落 npc/)
            v, rate, pitch, name = voice
            buckets[actor][key] = (v, rate, pitch)
            cast_of[actor] = [v, rate, pitch, name]

# 寫 per-actor manifest:key<TAB>中文<TAB>voice<TAB>rate<TAB>pitch
total = 0
for actor, keys in sorted(buckets.items()):
    path = os.path.join(OUTDIR, f"a{actor}.tsv")
    with open(path, "w", encoding="utf-8") as f:
        for key, (v, rate, pitch) in keys.items():
            f.write(f"{key}\t{cn[key]}\t{v}\t{rate}\t{pitch}\n")
    v, rate, pitch, name = cast_of[actor]
    print(f"actor {actor:>3}  {len(keys):>3} 句  {name}  [{v} {rate}/{pitch}]")
    total += len(keys)
print(f"\n專屬配音合計 {total} 句,分 {len(buckets)} 個角色 → {OUTDIR}/a*.tsv")
