#!/usr/bin/env bash
# 把繁中譯文編成 GBK 匯入 INDY3 LFL,組出可玩的中文遊戲目錄 build-engine/game-cht。
# 需要:① 你自備的英文 INDY3 FM-Towns LFL(從 CD 資料軌取出)放在 game/extracted/INDY3ENG/
#       ② chinese_gb16x12.fnt(12x12 GBK 點陣字,沿用 zak-cht)
#       ③ patched scummtr(zak scummtr-cjk + 本專案 _checkRsc CJK 修正,見 patches/scummtr-cjk-checkrsc.patch)
# 流程:assemble(en+zh.tsv→scummtr.txt)→ encode-gbk → scummtr -i 匯入。
set -e
cd "$(dirname "$0")/.."
SCUMMTR="${SCUMMTR_CJK:-build-engine/bin/scummtr-cjk}"   # patched scummtr(CJK + _checkRsc 修正)
FONT="${CJK_FONT:-/home/anr2/zak-cht-build/zak-cht-linux/game/chinese_gb16x12.fnt}"
ENC="${ENCODE_GBK:-/home/anr2/zak-cht/tools/encode-gbk.py}"
SRC=game/extracted/INDY3ENG

[ -d "$SRC" ] || { echo "缺英文 LFL:$SRC(先 bchunk 拆 CD 資料軌)"; exit 1; }
[ -x "$SCUMMTR" ] || { echo "缺 patched scummtr:$SCUMMTR"; exit 1; }

OUT=build-engine/game-cht
rm -rf "$OUT"; mkdir -p "$OUT"
cp "$SRC"/*.LFL "$OUT/"
cp "$FONT" "$OUT/"
echo "== assemble:英文源 + zh.tsv → 翻譯後 scummtr.txt =="
python3 tools/assemble_scummtr.py translations/crusade_en.txt translations/zh.tsv translations/scummtr_zh.txt
echo "== encode-gbk:UTF-8 → GBK+CRLF =="
python3 "$ENC" translations/scummtr_zh.txt "$OUT/scummtr.txt"
echo "== scummtr 匯入中文到 LFL =="
( cd "$OUT" && "$OLDPWD/$SCUMMTR" -g indy3towns -rwh -A ao -i ) || \
  ( cd "$OUT" && "$(cd ..; pwd)/../$SCUMMTR" -g indy3towns -rwh -A ao -i )
echo "完成 -> $OUT(可跑:見 scripts/run_cht.sh)"
