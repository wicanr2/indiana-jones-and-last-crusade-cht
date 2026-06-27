#!/usr/bin/env python3
# 辨識用:每個 actor 的所有台詞 + 出現房間(LF_XXXX)。偵測 actor 號是否跨房重用不同角色。
import os, re, sys, subprocess, collections

DESC, DUMP = sys.argv[1], sys.argv[2]
TEXT = re.compile(rb'Text\("((?:[^"\\]|\\.)*)"\)')
PRINT = re.compile(rb'print\((\d+),')
PEGO  = re.compile(rb'printEgo\(')

ESC = re.compile(rb'\\x([0-9a-fA-F]{2})')
def unescape(s):
    out = bytearray(); i = 0
    while i < len(s):
        if s[i:i+2] == b'\\x' and i+4 <= len(s):
            try: out.append(int(s[i+2:i+4],16)); i+=4; continue
            except ValueError: pass
        out.append(s[i]); i+=1
    return bytes(out)

# actor -> {room -> [lines]}
data = collections.defaultdict(lambda: collections.defaultdict(list))
for root,_,files in os.walk(DUMP):
    room = "?"
    m = re.search(r'LF_(\d+)', root)
    if m: room = int(m.group(1))
    for fn in sorted(files):
        if not re.match(r'(SC|LS|OC|EN|EX)_', fn): continue
        try:
            r = subprocess.run([DESC,"-3","-n",os.path.join(root,fn)],capture_output=True,timeout=30)
        except Exception: continue
        for line in r.stdout.split(b'\n'):
            ts = TEXT.findall(line)
            if not ts: continue
            gbk = b''.join(unescape(t) for t in ts)
            try: txt = gbk.decode("gbk", errors="replace")
            except Exception: txt = "?"
            mp = PRINT.search(line)
            if mp: a = int(mp.group(1))
            elif PEGO.search(line): a = -1
            else: continue
            data[a][room].append(txt)

want = [int(x) for x in sys.argv[3:]] if len(sys.argv) > 3 else sorted(data.keys())
for a in want:
    rooms = data[a]
    total = sum(len(v) for v in rooms.values())
    print(f"\n========== actor {a}  ({total} 句, 房間 {sorted(rooms.keys())}) ==========")
    for rm in sorted(rooms.keys()):
        print(f"  --- 房 {rm} ({len(rooms[rm])} 句) ---")
        for ln in rooms[rm][:8]:
            print(f"    {ln[:50]}")
