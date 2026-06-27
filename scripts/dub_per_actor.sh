#!/usr/bin/env bash
# 依角色聲線把每個角色的台詞 dub 進 voice/a<actor>/。
# 輸入:① CHTMAP log(`scummvm -d3` 跑出的 "CHTMAP <actor> <key>" 行,可多檔串接)
#       ② tools/voice_cast.tsv(actor<TAB>voice<TAB>rate<TAB>pitch)
#       ③ 中文 manifest(key<TAB>中文)
# 對每個在 voice_cast 有設定的 actor,取其在 CHTMAP 出現過的 key,用其聲線 dub → voice/a<actor>/。
# 用法:scripts/dub_per_actor.sh <chtmap.log> [更多 log...]
set -euo pipefail
cd "$(dirname "$0")/.."
CAST=tools/voice_cast.tsv
MAN=extracted/crusade_dub_manifest.tsv
[ $# -ge 1 ] || { echo "用法: $0 <chtmap.log> [更多...]"; exit 1; }
# key→actor(後出現的覆蓋;同 key 通常同 actor)
declare -A K2A
for f in "$@"; do
  grep -aoE 'CHTMAP [0-9]+ [0-9a-f]+' "$f" 2>/dev/null | while read -r _ a k; do echo "$k $a"; done
done | sort -u > /tmp/k2a.txt
echo "CHTMAP 收到 key→actor: $(wc -l < /tmp/k2a.txt) 筆"

# 對每個有聲線設定的 actor,組它的 (key,中文) 清單 → dub
grep -vE '^\s*#|^\s*$' "$CAST" | while IFS=$'\t' read -r actor voice rate pitch note; do
  [ -n "${actor:-}" ] || continue
  OUT="build-engine/game-cht/voice/a$actor"; mkdir -p "$OUT"
  # 此 actor 在 CHTMAP 出現過的 key
  awk -v a="$actor" '$2==a{print $1}' /tmp/k2a.txt | sort -u > /tmp/keys_$actor.txt
  : > /tmp/man_$actor.tsv
  while read -r k; do
    cn=$(awk -F'\t' -v K="$k" '$1==K{print $2}' "$MAN"); [ -n "$cn" ] && printf '%s\t%s\n' "$k" "$cn" >> /tmp/man_$actor.tsv
  done < /tmp/keys_$actor.txt
  cnt=$(wc -l < /tmp/man_$actor.tsv)
  echo "actor $actor($note):$cnt 句 → $voice $rate/$pitch"
  [ "$cnt" -gt 0 ] || continue
  cat > /tmp/pa_worker.py <<PY
import asyncio,os,edge_tts
V="$voice";R="$rate";P="$pitch"
jobs=[l.rstrip("\n").split("\t",1) for l in open("/work/m.tsv") if "\t" in l]
jobs=[(k,s) for k,s in jobs if not os.path.exists(f"/work/out/{k}.voc") and not os.path.exists(f"/work/out/{k}.mp3")]
sem=asyncio.Semaphore(6)
async def one(k,s):
    async with sem:
        try: await edge_tts.Communicate(s,V,rate=R,pitch=P).save(f"/work/out/{k}.mp3")
        except Exception as e: print("FAIL",k,e)
async def m(): await asyncio.gather(*[one(k,s) for k,s in jobs]); print("done",len(jobs))
asyncio.run(m())
PY
  timeout 1200 docker run --rm -v "$PWD/$OUT":/work/out -v /tmp/man_$actor.tsv:/work/m.tsv:ro -v /tmp/pa_worker.py:/work/pa_worker.py:ro \
    ghcr.io/astral-sh/uv:python3.12-bookworm-slim uv run --with edge-tts -- python /work/pa_worker.py 2>&1 | tail -1
  docker run --rm -v "$PWD/$OUT":/v ghcr.io/astral-sh/uv:python3.12-bookworm-slim chown -R "$(id -u):$(id -g)" /v 2>/dev/null||true
  for mp3 in "$OUT"/*.mp3; do [ -e "$mp3" ]||continue; ffmpeg -y -loglevel error -i "$mp3" -ar 11025 -ac 1 -acodec pcm_u8 "${mp3%.mp3}.voc"; done
  rm -f "$OUT"/*.mp3
  echo "  → voice/a$actor: $(ls "$OUT"/*.voc 2>/dev/null|wc -l) voc"
done
echo "完成。引擎自動 voice/a<actor>/ 優先 → 各角色專屬聲線。"
