#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
MAN=extracted/crusade_en_dub_manifest.tsv
OUT=build-engine/game-cht/voice_en
[ -f "$MAN" ] || python3 tools/build_en_voice.py
mkdir -p "$OUT"
VOICE="${EN_VOICE:-en-US-GuyNeural}"; CONC="${EN_CONC:-8}"
cat > /tmp/dub_en_worker.py <<'PY'
import asyncio,os,edge_tts
V=os.environ.get("EN_VOICE","en-US-GuyNeural"); C=int(os.environ.get("EN_CONC","8"))
jobs=[]
for ln in open("/work/manifest.tsv",encoding="utf-8"):
    ln=ln.rstrip("\n")
    if "\t" not in ln: continue
    k,s=ln.split("\t",1); 
    if os.path.exists(f"/work/voice/{k}.voc") or os.path.exists(f"/work/voice/{k}.mp3"): continue
    jobs.append((k,s))
sem=asyncio.Semaphore(C)
async def one(k,s):
    async with sem:
        try: await edge_tts.Communicate(s,V).save(f"/work/voice/{k}.mp3")
        except Exception as e: print("FAIL",k,e)
async def m():
    print(f"待 EN TTS: {len(jobs)}"); await asyncio.gather(*[one(k,s) for k,s in jobs]); print("EN TTS done")
asyncio.run(m())
PY
timeout 3000 docker run --rm -e EN_VOICE="$VOICE" -e EN_CONC="$CONC" \
  -v "$PWD/$OUT":/work/voice -v "$PWD/$MAN":/work/manifest.tsv:ro -v /tmp/dub_en_worker.py:/work/dub_en_worker.py:ro \
  ghcr.io/astral-sh/uv:python3.12-bookworm-slim uv run --with edge-tts -- python /work/dub_en_worker.py 2>&1 | tail -3
docker run --rm -v "$PWD/$OUT":/v ghcr.io/astral-sh/uv:python3.12-bookworm-slim chown -R "$(id -u):$(id -g)" /v 2>/dev/null || true
made=0; for mp3 in "$OUT"/*.mp3; do [ -e "$mp3" ] || continue; voc="${mp3%.mp3}.voc"; [ -s "$voc" ] || { ffmpeg -y -loglevel error -i "$mp3" -ar 11025 -ac 1 -acodec pcm_u8 "$voc" && made=$((made+1)); }; done
rm -f "$OUT"/*.mp3
echo "voice_en voc: $(ls "$OUT"/*.voc 2>/dev/null | wc -l)(新增 $made)"
