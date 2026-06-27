#!/usr/bin/env python3
# 靜態講者抽取:descumm 反組譯每個 script 區塊 → print(N,Text)/printEgo → 每句台詞的講者 actor。
# 把 Text() 的 GBK 位元組算成 cht_key(同引擎 FNV-1a over GBK pairs),輸出 key<TAB>actor。
# 不需玩遊戲、不需 CHTMAP —— 講者就寫在 bytecode 裡(rule 62 靜態溯源)。
import os, re, sys, subprocess, collections

DESC = sys.argv[1] if len(sys.argv) > 1 else "descumm"
DUMP = sys.argv[2] if len(sys.argv) > 2 else "DUMP"
OUT  = sys.argv[3] if len(sys.argv) > 3 else "speakers.tsv"

FNV_OFF, FNV_PRIME, MASK = 2166136261, 16777619, 0xFFFFFFFF

def cht_key(gbk: bytes) -> str:
    h = FNV_OFF; i = 0
    while i < len(gbk):
        b0 = gbk[i]
        if 0x81 <= b0 <= 0xFE and i + 1 < len(gbk):
            b1 = gbk[i + 1]
            h = ((h ^ b0) * FNV_PRIME) & MASK
            h = ((h ^ b1) * FNV_PRIME) & MASK
            i += 2
        else:
            i += 1
    return "%08x" % h

# 把 descumm 的 Text("...") 內容(\xHH + 字面 ASCII)還原成位元組
ESC = re.compile(rb'\\x([0-9a-fA-F]{2})')
def unescape(s: bytes) -> bytes:
    out = bytearray(); i = 0
    while i < len(s):
        if s[i:i+2] == b'\\x' and i+4 <= len(s):
            try:
                out.append(int(s[i+2:i+4], 16)); i += 4; continue
            except ValueError:
                pass
        if s[i:i+2] == b'\\\\':  # 跳脫反斜線
            out.append(0x5C); i += 2; continue
        out.append(s[i]); i += 1
    return bytes(out)

# 一行裡所有 Text("....") 片段(可能 + newline() + 串接);抓引號內原始位元組
TEXT = re.compile(rb'Text\("((?:[^"\\]|\\.)*)"\)')
# print(N,[...]) 取 N;printEgo → ego;VerbOps(...,[Text]) → ego(玩家選的台詞,印第說)
PRINT = re.compile(rb'print\((\d+),')
PEGO  = re.compile(rb'printEgo\(')
VERB  = re.compile(rb'VerbOps\(')

# 收集:key -> Counter(actor)。同 key 可能多處出現,取多數
key_actor = collections.defaultdict(collections.Counter)
actor_lines = collections.defaultdict(int)   # actor -> 句數
actor_samples = collections.defaultdict(list) # actor -> 幾句樣本(辨識角色)
n_blocks = n_ok = n_print = 0

EGO = -1  # ego 用 -1 標(= 印第,走通用 voice/)

for root, _, files in os.walk(DUMP):
    for fn in sorted(files):
        if not re.match(r'(SC|LS|OC|EN|EX)_', fn):
            continue
        path = os.path.join(root, fn)
        n_blocks += 1
        try:
            r = subprocess.run([DESC, "-3", "-n", path],
                               capture_output=True, timeout=30)
        except Exception:
            continue
        out = r.stdout
        if b'print' not in out and b'VerbOps' not in out:
            continue
        n_ok += 1
        for line in out.split(b'\n'):
            texts = TEXT.findall(line)
            if not texts:
                continue
            gbk = b''.join(unescape(t) for t in texts)
            k = cht_key(gbk)
            # 字串至少要有一對 GBK(否則 key 退化)
            if k == "%08x" % FNV_OFF:
                continue
            m = PRINT.search(line)
            if m:
                actor = int(m.group(1)); n_print += 1
            elif PEGO.search(line):
                actor = EGO
            elif VERB.search(line):
                actor = EGO  # 對話選項 = 印第說
            else:
                continue
            key_actor[k][actor] += 1
            actor_lines[actor] += 1
            if len(actor_samples[actor]) < 6:
                try:
                    actor_samples[actor].append(gbk.decode("gbk", errors="replace"))
                except Exception:
                    pass

# 輸出 key->actor(多數決;平手取較小 actor)
with open(OUT, "w", encoding="utf-8") as f:
    for k, c in sorted(key_actor.items()):
        actor = c.most_common(1)[0][0]
        f.write(f"{k}\t{actor}\n")

print(f"區塊 {n_blocks} 個,有對白 {n_ok} 個,print(N) {n_print} 句")
print(f"distinct key→actor: {len(key_actor)}")
print(f"\n=== 各 actor 句數(-1=印第ego)===")
for a, n in sorted(actor_lines.items(), key=lambda x: -x[1]):
    samp = " / ".join(s[:18] for s in actor_samples[a][:3])
    print(f"actor {a:>4}: {n:>4} 句   例: {samp}")
