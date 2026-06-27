#!/usr/bin/env bash
# 錄「crusade 實機畫面 + FM-Towns 音樂」素材(headless:Xvfb + ffmpeg x11grab + SDL disk 音訊)。
# 驅動:關 modal → LucasFilm logo / 標題(版權所有)/ 製作群 / 巴奈特學院字幕 → ESC 到 gym 中文動詞。
# 有界:固定秒數 SIGKILL,無 sentinel、無 GUI(rule 35)。移植自 atlantis。
# 產物:/tmp/cru_cap.mp4(畫面)+ /tmp/cru_cap.wav(音樂)
set -u
SV="${SCUMMVM:-build-engine/sv/scummvm}"
GAME="${GAME:-build-engine/game-cht}"
SECS="${1:-42}"
DISP=:96; WH=960x720
RAW=/tmp/cru_cap.raw; VID=/tmp/cru_cap.mp4; WAV=/tmp/cru_cap.wav
rm -f "$RAW" "$VID" "$WAV"
Xvfb $DISP -screen 0 ${WH}x24 >/tmp/xvfb_cap.log 2>&1 & XP=$!
sleep 1
DISPLAY=$DISP SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE="$RAW" SDL_DISKAUDIODELAY=10 \
  "$SV" -p "$GAME" --platform=fmtowns --language=cn --subtitles \
  --no-fullscreen --scaler=normal --scale-factor=3 --output-rate=44100 indy3 >/tmp/sv_cap.log 2>&1 & SP=$!
sleep 1
# 背景送鍵驅動(時間軸對齊 ffmpeg 0s)
( K(){ DISPLAY=$DISP xdotool key "$1" 2>/dev/null; }
  sleep 3; for n in 1 2 3 4; do K Return; sleep 0.7; done   # 關 aspect / CD-audio modal
  sleep 22                                                   # logo→標題→製作群→巴奈特學院字幕
  for n in $(seq 1 10); do K Escape; sleep 1.1; done         # 跳到 gym
  sleep 6                                                    # gym 中文動詞
) & KP=$!
DISPLAY=$DISP ffmpeg -y -loglevel error -f x11grab -video_size $WH -framerate 25 -i $DISP \
  -t "$SECS" -c:v libx264 -pix_fmt yuv420p -crf 18 "$VID"
kill $KP 2>/dev/null; kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
ffmpeg -y -loglevel error -f s16le -ar 44100 -ac 2 -i "$RAW" "$WAV" 2>/dev/null
echo "畫面 -> $VID ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VID" 2>/dev/null)s)"
echo "音樂 -> $WAV ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WAV" 2>/dev/null)s, $(stat -c%s "$RAW" 2>/dev/null) raw bytes)"
