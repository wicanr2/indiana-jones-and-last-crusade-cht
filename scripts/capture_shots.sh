#!/usr/bin/env bash
# 拍 crusade 中文化截圖:關掉 aspect 警告 → 標題 → 開場(中文字幕)→ gym 交談對白 + 動詞。
# 有界:固定 sleep + SIGKILL,無 sentinel、無 GUI(rule 35)。用法:capture_shots.sh [out_dir]
set -u
SV="${SCUMMVM:-build-engine/sv/scummvm}"
GAME="${GAME:-build-engine/game-cht}"
OUT="${1:-screenshots/shots}"
mkdir -p "$OUT"
DISP=:92; WH=960x720
Xvfb $DISP -screen 0 ${WH}x24 >/tmp/xvfb_cru.log 2>&1 & XP=$!
sleep 1
# --aspect-ratio 預設開 → FM-Towns 會跳警告 modal;這裡不傳(預設),改在開機後按 Return 關掉它
DISPLAY=$DISP "$SV" -p "$GAME" --platform=fmtowns --language=cn \
  --no-fullscreen --scaler=normal --scale-factor=3 --subtitles indy3 >/tmp/sv_cru.log 2>&1 & SP=$!
shot(){ DISPLAY=$DISP import -window root "$OUT/$1.png" 2>/dev/null; echo "  shot $1"; }
key(){ DISPLAY=$DISP xdotool key "$1" 2>/dev/null; }
click(){ DISPLAY=$DISP xdotool mousemove "$1" "$2"; sleep 0.4; DISPLAY=$DISP xdotool click "${3:-1}"; sleep 0.5; }
sleep 4
key Return                          # 關掉 aspect-ratio 警告 modal
sleep 2; shot 00_title              # 標題/logo
# 開場過場:每 ~3s 抓一幀(若有中文字幕對白)
for n in $(seq 1 6); do sleep 3; shot "op_$n"; done
# 跳過剩餘過場到 gym
for n in $(seq 1 8); do key Escape; sleep 1.2; done
sleep 2; shot 20_verbs              # gym 中文動詞
# 交談教練:選「交談」(右欄上)→ 點教練(棕西裝,畫面左中)→ 中文對白
click 770 465; click 345 230
sleep 1.2; shot 30_talk_1
sleep 1.5; shot 31_talk_2
key Escape; sleep 1
# 看物件:選「看」→ 點籃框/門 → 中文吐槽
click 600 555; click 230 130
sleep 1.2; shot 40_look
kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
echo "=== CHT console ==="; grep -iE 'CHTMAP|CHTVOICE' /tmp/sv_cru.log | tail -4
echo "done -> $OUT ($(ls "$OUT"/*.png 2>/dev/null | wc -l) shots)"
