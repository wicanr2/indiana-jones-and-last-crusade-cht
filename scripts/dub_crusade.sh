#!/usr/bin/env bash
# 把 manifest 的中文 TTS 成 voice/<key>.voc(印第馬蓋仙聲線),放進 build-engine/game-cht/voice/。
# edge-tts 走 docker(uv),mp3→VOC(11025/8-bit/mono unsigned,配合引擎 makeVOCStream FLAG_UNSIGNED)。
# 有界:docker 同步前景 + timeout;已存在的 voc 跳過(可續跑)。
set -euo pipefail
cd "$(dirname "$0")/.."
MAN=extracted/crusade_dub_manifest.tsv
OUT=build-engine/game-cht/voice
[ -f "$MAN" ] || python3 tools/build_crusade_voice.py
mkdir -p "$OUT"
VOICE="${DUB_VOICE:-zh-TW-YunJheNeural}"; RATE="${DUB_RATE:--8%}"; PITCH="${DUB_PITCH:--12Hz}"; CONC="${DUB_CONC:-8}"

echo "=== TTS(docker edge-tts,$VOICE rate=$RATE pitch=$PITCH conc=$CONC) → mp3 ==="
cat > /tmp/dub_worker.py <<'PY'
import asyncio, os, edge_tts
V=os.environ.get("DUB_VOICE","zh-TW-YunJheNeural"); R=os.environ.get("DUB_RATE","-8%"); P=os.environ.get("DUB_PITCH","-12Hz")
C=int(os.environ.get("DUB_CONC","8"))
jobs=[]
for ln in open("/work/manifest.tsv",encoding="utf-8"):
    ln=ln.rstrip("\n")
    if not ln or "\t" not in ln: continue
    key,say=ln.split("\t",1)
    mp3=f"/work/voice/{key}.mp3"; voc=f"/work/voice/{key}.voc"
    if os.path.exists(voc) or os.path.exists(mp3): continue
    jobs.append((key,say))
sem=asyncio.Semaphore(C)
async def one(key,say):
    async with sem:
        try:
            await edge_tts.Communicate(say,V,rate=R,pitch=P).save(f"/work/voice/{key}.mp3")
        except Exception as e:
            print("FAIL",key,e)
async def main():
    print(f"待 TTS: {len(jobs)} 句")
    await asyncio.gather(*[one(k,s) for k,s in jobs])
    print("TTS done")
asyncio.run(main())
PY
timeout 3000 docker run --rm -e DUB_VOICE="$VOICE" -e DUB_RATE="$RATE" -e DUB_PITCH="$PITCH" -e DUB_CONC="$CONC" \
  -v "$PWD/$OUT":/work/voice -v "$PWD/$MAN":/work/manifest.tsv:ro -v /tmp/dub_worker.py:/work/dub_worker.py:ro \
  ghcr.io/astral-sh/uv:python3.12-bookworm-slim \
  uv run --with edge-tts -- python /work/dub_worker.py 2>&1 | tail -5
docker run --rm -v "$PWD/$OUT":/v ghcr.io/astral-sh/uv:python3.12-bookworm-slim chown -R "$(id -u):$(id -g)" /v 2>/dev/null || true

echo "=== mp3 → voc(ffmpeg 11025/8-bit/mono unsigned)==="
made=0
for mp3 in "$OUT"/*.mp3; do
  [ -e "$mp3" ] || continue
  voc="${mp3%.mp3}.voc"
  [ -s "$voc" ] || { ffmpeg -y -loglevel error -i "$mp3" -ar 11025 -ac 1 -acodec pcm_u8 "$voc" && made=$((made+1)); }
done
rm -f "$OUT"/*.mp3
echo "完成:voc 總數 $(ls "$OUT"/*.voc 2>/dev/null | wc -l)(本次新增 $made)"
