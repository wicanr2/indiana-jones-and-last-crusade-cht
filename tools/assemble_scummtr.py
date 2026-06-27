#!/usr/bin/env python3
"""把英文 scummtr 匯出檔 + zh.tsv(en<TAB>中文)組成「翻譯後的 scummtr.txt」。
- `;;` 註解行、空行:原樣保留(scummtr 忽略註解,但行序必須一致)。
- 內容行:用「整行英文」當 key 查 zh.tsv;有譯文用中文,沒有就留英文(可隨時跑、漸進翻譯)。
- SCUMM 控制碼(\\255\\001 換行、\\NNN、^ 等)是字串的一部分,key/value 都原樣含它們。
用法: assemble_scummtr.py <crusade_en.txt> <zh.tsv> <out_scummtr.txt>
"""
import sys

def load_tsv(path):
    m = {}
    try:
        with open(path, encoding="utf-8", newline="") as f:   # newline='' 避免 \r 被當行尾拆行
            for ln in f:
                ln = ln.rstrip("\r\n")
                if not ln or ln.startswith("#") or "\t" not in ln:
                    continue
                en, zh = ln.split("\t", 1)
                en = en.rstrip("\r"); zh = zh.rstrip("\r")
                if zh.strip():
                    m[en] = zh
    except FileNotFoundError:
        pass
    return m

def main():
    en_path, tsv_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
    tr = load_tsv(tsv_path)
    n_total = n_tr = 0
    # scummtr.txt 是 Windows-1252;讀寫都用 latin-1 保留位元組,中文輸出端再處理(encode-gbk 階段)
    import re
    HDR = re.compile(r"^(\[[0-9]+:[A-Z]+#[0-9]+\])(.*)$")
    out = []
    with open(en_path, encoding="latin-1", newline="") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if line.startswith(";;") or line.strip() == "":
                out.append(line)
                continue
            m = HDR.match(line)
            if not m:               # 沒 header 的內容行(少見):整行當 key
                n_total += 1
                out.append(tr.get(line, line)); n_tr += 1 if line in tr else 0
                continue
            hdr, text = m.group(1), m.group(2)
            n_total += 1
            if text in tr:
                out.append(hdr + tr[text]); n_tr += 1
            else:
                out.append(hdr + text)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"組裝完成 -> {out_path}  已翻 {n_tr}/{n_total} ({100*n_tr//max(n_total,1)}%)")

if __name__ == "__main__":
    main()
