#!/usr/bin/env bash
# 跑中文聖戰奇兵。關鍵旗標:--platform=fmtowns(避免 auto-detect 選錯 VGA/DOS 變體 → Bad ID)、
# --language=cn(ZH_CHN,觸發 chinese_gb16x12.fnt 路徑 + _useCJKMode)。
# headless 截圖:HEADLESS=1 scripts/run_cht.sh
set -u
cd "$(dirname "$0")/.."
SV="${SCUMMVM:-build-engine/sv/scummvm}"
GAME="${GAME:-build-engine/game-cht}"
if [ "${HEADLESS:-0}" = 1 ]; then
  DISP=:95; Xvfb $DISP -screen 0 640x480x24 >/tmp/xvfb_cru.log 2>&1 & XP=$!
  sleep 1
  DISPLAY=$DISP "$SV" -p "$GAME" --platform=fmtowns --language=cn --no-fullscreen --scaler=normal --scale-factor=2 indy3 >/tmp/sv_cru.log 2>&1 & SP=$!
  sleep "${SECS:-14}"
  DISPLAY=$DISP import -window root "${OUT:-/tmp/cru.png}" 2>/dev/null
  kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
  echo "截圖 -> ${OUT:-/tmp/cru.png}"
else
  exec "$SV" -p "$GAME" --platform=fmtowns --language=cn indy3
fi
