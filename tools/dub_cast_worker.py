#!/usr/bin/env python3
# 讀 /work/cast/a<actor>.tsv(key,中文,voice,rate,pitch)→ edge-tts dub → /work/voice/a<actor>/<key>.mp3
import asyncio, os, glob, edge_tts
CAST = "/work/cast"; VROOT = "/work/voice"
jobs = []
for tsv in sorted(glob.glob(f"{CAST}/a*.tsv")):
    actor = os.path.basename(tsv)[:-4]      # "a2"
    outdir = os.path.join(VROOT, actor); os.makedirs(outdir, exist_ok=True)
    for ln in open(tsv, encoding="utf-8"):
        ln = ln.rstrip("\n")
        p = ln.split("\t")
        if len(p) < 5: continue
        key, cn, voice, rate, pitch = p[0], p[1], p[2], p[3], p[4]
        mp3 = os.path.join(outdir, key + ".mp3"); voc = os.path.join(outdir, key + ".voc")
        if os.path.exists(voc): continue
        jobs.append((cn, voice, rate, pitch, mp3))
sem = asyncio.Semaphore(2)
async def one(cn, voice, rate, pitch, mp3):
    async with sem:
        try: await edge_tts.Communicate(cn, voice, rate=rate, pitch=pitch).save(mp3)
        except Exception as e: print("FAIL", mp3, str(e)[:60])
async def main():
    print(f"dub {len(jobs)} 句")
    await asyncio.gather(*[one(*j) for j in jobs])
    print("done")
asyncio.run(main())
