#!/usr/bin/env bash
# 合成 crusade YouTube 介紹片:實機 logo/標題動畫(含 FM-Towns 音樂)+ 中文截圖(淡入淡出+中文字幕)
# + 結尾卡(per-character 配音),全程鋪遊戲真實音樂。
# 依賴:先跑 scripts/capture_gameplay_video.sh(產 /tmp/cru_cap.mp4 + /tmp/cru_cap.wav)。
# 產物:dist-all/video/crusade-cht-intro.mp4
set -u
cd "$(dirname "$0")/.."
SHOT=screenshots; FONT=/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc
BG='#0a0e1a'; GOLD='#f0c000'; CAP='#f5d020'; WHITE='#e8e8e8'
W=1280; H=720; FPS=25
CAP_V=/tmp/cru_cap.mp4; CAP_A=/tmp/cru_cap.wav
TMP="$(mktemp -d)"; OUT=dist-all/video; mkdir -p "$OUT"
[ -f "$CAP_V" ] || { echo "缺 $CAP_V,先跑 scripts/capture_gameplay_video.sh"; exit 1; }

card(){ convert -size ${W}x${H} xc:"$BG" -font "$FONT" -gravity center \
  -fill "$GOLD" -pointsize 56 -annotate +0-50 "$2" \
  -fill "$WHITE" -pointsize 32 -annotate +0+60 "$3" "$1"; }
slide(){ convert -size ${W}x${H} xc:"$BG" \
  \( "$SHOT/$2" -resize x560 \) -gravity north -geometry +0+30 -composite \
  -font "$FONT" -fill "$CAP" -gravity south -pointsize 36 -annotate +0+45 "$3" "$1"; }
kenburns(){ local FO; FO=$(awk "BEGIN{print $3-0.5}")
  ffmpeg -y -loglevel error -loop 1 -t "$3" -i "$1" \
    -vf "fps=$FPS,format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st=$FO:d=0.5" \
    -c:v libx264 -pix_fmt yuv420p "$2"; }

echo "== 烘卡片/投影片 =="
card  "$TMP/00.png" '印第安納·瓊斯:最後聖戰' '繁體中文化　LucasArts 1989　ScummVM(FM-Towns)'
slide "$TMP/02.png" crusade_cht_title.png  '連標題的版權行都說起了中文'
slide "$TMP/03.png" crusade_cht_intro.png  '中文場景字幕　巴奈特學院,紐約,1938 年'
slide "$TMP/04.png" crusade_cht_verbs.png  '底部那排動詞　全變中文了'
slide "$TMP/05.png" crusade_cht_look.png   '句子列「走向 更衣室」　中文不被裁'
slide "$TMP/06.png" crusade_cht_campus.png '一路鋪到校園 · 城堡 · 威尼斯 · 聖杯神廟'
card  "$TMP/99.png" '每個角色,都用對味的中文聲線開口' '亨利·艾爾莎·馬可斯·唐納文·聖杯騎士…8 角色專屬配音　Win/Linux/macOS'

echo "== 實機 logo/標題片段(填滿、有動態)=="
# 錄影 t=4~14 是真實 LucasFilm logo → INDIANA JONES 標題動畫(前段是 ScummVM 啟動,跳過)
ffmpeg -y -loglevel error -ss 4 -t 8 -i "$CAP_V" \
  -vf "scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:-1:-1:color=black,fps=$FPS,format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st=7.4:d=0.6" \
  -an "$TMP/seg_logo.mp4"

echo "== 卡片/投影片轉片段 =="
LIST="$TMP/list.txt"; : > "$LIST"
echo "file '$TMP/seg_logo.mp4'" >> "$LIST"
for f in 00 02 03 04 05 06 99; do
  case $f in 00|99) D=4.2;; *) D=3.6;; esac
  kenburns "$TMP/$f.png" "$TMP/seg_$f.mp4" "$D"
  echo "file '$TMP/seg_$f.mp4'" >> "$LIST"
done

echo "== concat 影像 =="
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -c:v libx264 -pix_fmt yuv420p -crf 20 "$TMP/silent.mp4"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4")

echo "== 鋪遊戲音樂(淡入淡出)=="
FO=$(awk "BEGIN{print $DUR-3}")
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -i "$CAP_A" \
  -filter_complex "[1:a]atrim=0:$DUR,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3,volume=0.9[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart \
  "$OUT/crusade-cht-intro.mp4"
rm -rf "$TMP"
ls -lh "$OUT/crusade-cht-intro.mp4" | awk '{print "影片 ->",$9,"("$5")"}'
ffprobe -v error -show_entries format=duration:stream=codec_type -of default=noprint_wrappers=1 "$OUT/crusade-cht-intro.mp4" 2>/dev/null | grep -E 'duration|codec_type'
