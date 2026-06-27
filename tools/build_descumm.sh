#!/usr/bin/env bash
# 自編 descumm(ScummVM script 反組譯器,scummvm-tools)。
# 用途:靜態抽取每句台詞的講者 actor(tools/extract_speakers.py / dub_cast.py 需要它)。
# 不靠整套 scummvm-tools build system,直接 g++ 編 descumm 四個源 + common/util.cpp。
set -euo pipefail
OUT="${1:-$(pwd)/build-engine/bin/descumm}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
git clone --depth 1 https://github.com/scummvm/scummvm-tools.git
cd scummvm-tools
# POSIX 系統型別 + 跳過 SDL_byteorder(CONFIG_H)+ x86 小端
g++ -O2 -w -DPOSIX -DCONFIG_H -DSCUMM_LITTLE_ENDIAN -I. -Iengines/scumm \
  engines/scumm/descumm-tool.cpp engines/scumm/descumm.cpp \
  engines/scumm/descumm6.cpp engines/scumm/descumm-common.cpp \
  common/util.cpp \
  -o "$OUT"
echo "descumm → $OUT"
"$OUT" 2>&1 | head -3
# 用法:descumm -3 -n <script_block>   (-3 = SCUMM v3 / Last Crusade,-n = Indy3-256 hacks)
# script 區塊用 scummrp 從 LFL 拆出:scummrp -g indy3towns -o -d DUMP
