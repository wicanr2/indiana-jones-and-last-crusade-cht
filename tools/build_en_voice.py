#!/usr/bin/env python3
"""英文語音 manifest:key 仍由「顯示的中文字串」算(引擎只認顯示字串),配對該行的英文原文。
key = FNV-1a(中文 GBK 雙位元組字),與引擎/中文 manifest 完全一致;value = 英文原文(去控制碼)。
輸出 extracted/crusade_en_dub_manifest.tsv(key<TAB>英文),給 dub 腳本以 en-US 聲線 TTS → voice_en/。
用法:python3 tools/build_en_voice.py
"""
import re, os
FNV_OFF=2166136261; FNV_PRIME=16777619; MASK=0xFFFFFFFF
HDR=re.compile(r"^(\[[0-9]+:[A-Z]+#[0-9]+\])(.*)$")

def cht_key(zh):
    gbk=zh.encode("gbk",errors="replace"); h=FNV_OFF; i=0
    while i<len(gbk):
        b0=gbk[i]
        if 0x81<=b0<=0xFE and i+1<len(gbk):
            h=((h^b0)*FNV_PRIME)&MASK; h=((h^gbk[i+1])*FNV_PRIME)&MASK; i+=2
        else: i+=1
    return "%08x"%h

def strip_en(s):
    s=re.sub(r"\\\d{1,3}"," ",s)             # \255\001 控制碼→空白
    s=s.replace("^","").replace("@","")
    return re.sub(r"\s+"," ",s).strip()

def load(path, enc):
    d={}
    for line in open(path,encoding=enc,newline=""):
        line=line.rstrip("\r\n"); m=HDR.match(line)
        if m: d.setdefault(m.group(1),[]).append(m.group(2))
    return d

def main():
    en=load("translations/crusade_en.txt","latin-1")   # 英文劇本(含控制碼)
    zh=load("translations/scummtr_zh.txt","utf-8")      # 中文(UTF-8)
    os.makedirs("extracted",exist_ok=True)
    seen={}
    for hdr, zlist in zh.items():
        elist=en.get(hdr,[])
        for i,ztext in enumerate(zlist):
            if not re.search(r"[一-鿿]",ztext): continue   # 只配有中文(=有 dub)的行
            etext = elist[i] if i<len(elist) else ""
            say=strip_en(etext)
            if not say: continue
            seen.setdefault(cht_key(ztext), say)
    with open("extracted/crusade_en_dub_manifest.tsv","w",encoding="utf-8") as f:
        for k,s in seen.items(): f.write(f"{k}\t{s}\n")
    print(f"英文 manifest: {len(seen)} 句 -> extracted/crusade_en_dub_manifest.tsv")

if __name__=="__main__": main()
