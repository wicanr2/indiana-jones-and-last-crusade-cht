#!/usr/bin/env bash
# 做「中/英 per-character 配音切換」展示段:每個角色一張卡,先播中文 voc(中文高亮)→
# F9 → 播英文 voc(英文高亮),接到 crusade-cht-intro.mp4 後面。播真實 dub 音檔。
set -u
cd "$(dirname "$0")/.."
FONT=/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc
VC=build-engine/game-cht/voice; VE=build-engine/game-cht/voice_en
W=1280; H=720; FPS=25
TMP="$(mktemp -d)"; OUT=dist-all/video; mkdir -p "$OUT"
GOLD='#f0c000'; DIM='#5a5a4a'; WHITE='#e8e8e8'; BG='#0a0e1a'; HI='#f5d020'

# actor key 中文名 英文名 中文聲線 英文聲線
ROWS=(
"9|6421c642|拳擊教練|Boxing Coach|zh-CN-Yunjian|en-US-Roger"
"3|3322ba9e|艾爾莎·施奈德|Elsa Schneider|zh-TW-HsiaoChen|en-GB-Sonia"
"2|03a8380f|亨利·瓊斯|Henry Jones Sr.|zh-TW-YunJhe|en-GB-Ryan"
"4|181de2d8|馬可斯·布洛迪|Marcus Brody|zh-CN-Yunyang|en-GB-Thomas"
"10|dbd3f7a8|聖杯騎士|Grail Knight|zh-TW-YunJhe -slow|en-GB-Thomas -slow"
)
CN_MAN=extracted/crusade_dub_manifest.tsv; EN_MAN=extracted/crusade_en_dub_manifest.tsv

# 卡片:$1 out  $2 name_cn  $3 name_en  $4 cn_text  $5 en_text  $6 vcn  $7 ven  $8 active(cn|en)
card(){
  local out=$1 ncn=$2 nen=$3 ct=$4 et=$5 vcn=$6 ven=$7 act=$8
  local cn_col en_col cn_chip en_chip f9=""
  if [ "$act" = cn ]; then cn_col=$GOLD; en_col=$DIM; cn_chip=$HI; en_chip=$DIM
  else cn_col=$DIM; en_col=$WHITE; cn_chip=$DIM; en_chip=$HI; f9="F9  ⇄"; fi
  convert -size ${W}x${H} xc:"$BG" -font "$FONT" \
    -fill "$GOLD" -pointsize 34 -gravity north -annotate +0+50 "中 / 英　per-character 配音　・　按 F9 切換語音" \
    -fill "$WHITE" -pointsize 50 -gravity north -annotate +0+165 "$ncn　$nen" \
    -fill "$cn_col" -pointsize 46 -gravity north -annotate +0+285 "「$ct」" \
    -fill "$en_col" -pointsize 32 -gravity north -annotate +0+380 "$et" \
    -fill "$cn_chip" -pointsize 30 -gravity north -annotate -300+520 "♪ 中文　$vcn" \
    -fill "$HI" -pointsize 34 -gravity north -annotate +0+515 "$f9" \
    -fill "$en_chip" -pointsize 30 -gravity north -annotate +330+520 "♪ English　$ven" \
    "$out"
}

LIST="$TMP/list.txt"; : > "$LIST"
# 開場卡
convert -size ${W}x${H} xc:"$BG" -font "$FONT" -gravity center \
  -fill "$GOLD" -pointsize 56 -annotate +0-40 "同一句台詞,兩種聲線" \
  -fill "$WHITE" -pointsize 32 -annotate +0+60 "中文 per-character ⇄ 英文 per-character　・　按 F9 即時切換" "$TMP/intro.png"
ffmpeg -y -loglevel error -loop 1 -t 3.2 -i "$TMP/intro.png" \
  -f lavfi -i anullsrc=r=44100:cl=stereo -t 3.2 \
  -vf "fps=$FPS,format=yuv420p,fade=t=in:st=0:d=0.5" -c:v libx264 -pix_fmt yuv420p -c:a aac "$TMP/seg_intro.mp4"
echo "file '$TMP/seg_intro.mp4'" >> "$LIST"

i=0
for row in "${ROWS[@]}"; do
  IFS='|' read -r a k ncn nen vcn ven <<< "$row"
  ct=$(awk -F'\t' -v K="$k" '$1==K{print $2}' "$CN_MAN")
  et=$(awk -F'\t' -v K="$k" '$1==K{print $2}' "$EN_MAN")
  # voc -> wav(boost 音量,補靜音頭尾)
  ffmpeg -y -loglevel error -i "$VC/a$a/$k.voc" -af "volume=3.0,apad=pad_dur=0.5" -ar 44100 -ac 2 "$TMP/cn_$i.wav" 2>/dev/null
  ffmpeg -y -loglevel error -i "$VE/a$a/$k.voc" -af "volume=3.0,apad=pad_dur=0.5" -ar 44100 -ac 2 "$TMP/en_$i.wav" 2>/dev/null
  cnd=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/cn_$i.wav")
  end=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/en_$i.wav")
  card "$TMP/c_cn_$i.png" "$ncn" "$nen" "$ct" "$et" "$vcn" "$ven" cn
  card "$TMP/c_en_$i.png" "$ncn" "$nen" "$ct" "$et" "$vcn" "$ven" en
  # 中文段
  ffmpeg -y -loglevel error -loop 1 -i "$TMP/c_cn_$i.png" -i "$TMP/cn_$i.wav" \
    -vf "fps=$FPS,format=yuv420p" -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "$TMP/s_cn_$i.mp4"
  # 英文段
  ffmpeg -y -loglevel error -loop 1 -i "$TMP/c_en_$i.png" -i "$TMP/en_$i.wav" \
    -vf "fps=$FPS,format=yuv420p" -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "$TMP/s_en_$i.mp4"
  echo "file '$TMP/s_cn_$i.mp4'" >> "$LIST"
  echo "file '$TMP/s_en_$i.mp4'" >> "$LIST"
  echo "  $ncn: 中${cnd}s 英${end}s"
  i=$((i+1))
done

echo "== concat 展示段 =="
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -ar 44100 "$TMP/demo.mp4"

echo "== 接到 intro 後面 =="
INTRO="$OUT/crusade-cht-intro.mp4"
[ -f "$INTRO" ] || { echo "缺 $INTRO,先跑 make_gameplay_video.sh"; exit 1; }
# 重編碼兩段成一致格式再 concat(避免時間軸/編碼不符)
ffmpeg -y -loglevel error -i "$INTRO" -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -ar 44100 -vf "fps=$FPS" "$TMP/intro_n.mp4"
echo "file '$TMP/intro_n.mp4'" > "$TMP/final.txt"
echo "file '$TMP/demo.mp4'" >> "$TMP/final.txt"
# in-place 接到 intro.mp4 後面(intro 已先讀進 TMP/intro_n,寫回安全)。先跑 make_gameplay_video.sh 再跑本檔。
ffmpeg -y -loglevel error -f concat -safe 0 -i "$TMP/final.txt" -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -ar 44100 -movflags +faststart "$OUT/crusade-cht-intro.mp4"
rm -rf "$TMP"
ls -lh "$OUT/crusade-cht-intro.mp4" | awk '{print "影片 ->",$9,"("$5")"}'
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT/crusade-cht-intro.mp4" 2>/dev/null | awk '{print "總長",$1,"s(intro + 中英切換展示)"}'
