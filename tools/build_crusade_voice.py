#!/usr/bin/env python3
"""產生配音 manifest:對每個有中文的對白/物件資源,算出與引擎 playChtVoice 完全一致的
key(FNV-1a 只雜湊 GBK 雙位元組中文字),輸出 voice/<key>.voc 該叫什麼 + 要念的中文。

引擎端(engines/scumm/sound.cpp Sound::playChtVoice)雜湊規則:
  h=2166136261; 逐 byte:若 0x81<=b0<=0xFE 且有 b1 → h=(h^b0)*16777619; h=(h^b1)*16777619; i+=2
  否則 i+=1。檔名 voice/%08x.voc。本檔用 GBK 編碼後套同規則 → key 必相同。

輸出:extracted/crusade_dub_manifest.tsv  (key<TAB>中文)  給 dub 腳本 TTS。
用法:python3 tools/build_crusade_voice.py
"""
import re, sys, os

FNV_OFF = 2166136261
FNV_PRIME = 16777619
MASK = 0xFFFFFFFF

def cht_key(zh: str) -> str:
    gbk = zh.encode("gbk", errors="replace")
    h = FNV_OFF
    i = 0
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

def strip_codes(zh: str) -> str:
    # 給 TTS 念的純文字:去掉 \255\NNN 控制碼、^、@padding、保留中文與標點
    zh = re.sub(r"\\\d{1,3}", "", zh)   # \255 \001 ... 控制碼
    zh = zh.replace("^", "").replace("@", "")
    return zh.strip()

HDR = re.compile(r"^(\[[0-9]+:[A-Z]+#[0-9]+\])(.*)$")

def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "translations/scummtr_zh.txt"
    out = sys.argv[2] if len(sys.argv) > 2 else "extracted/crusade_dub_manifest.tsv"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    seen = {}
    n_lines = 0
    for line in open(src, encoding="utf-8", newline=""):
        line = line.rstrip("\r\n")
        m = HDR.match(line)
        if not m:
            continue
        text = m.group(2)
        # 只配「有中文」的(物件名也配,玩家會聽到「看」描述)
        if not re.search(r"[一-鿿]", text):
            continue
        key = cht_key(text)          # 用「含控制碼的原文」算 key(與引擎 _charsetBuffer 一致)
        say = strip_codes(text)      # TTS 只念純中文
        if not say:
            continue
        n_lines += 1
        seen.setdefault(key, say)    # 同 key 只配一次
    with open(out, "w", encoding="utf-8") as f:
        for key, say in seen.items():
            f.write(f"{key}\t{say}\n")
    print(f"manifest -> {out}: {len(seen)} 個唯一語音(涵蓋 {n_lines} 行對白)")

if __name__ == "__main__":
    main()
