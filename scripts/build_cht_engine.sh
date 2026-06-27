#!/usr/bin/env bash
# 全新編 ScummVM + 套聖戰奇兵繁中 patch(INDY3 FM-Towns CJK)。不沿用任何既有 binary。
# 產物:build-engine/sv/scummvm
set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"
mkdir -p build-engine && cd build-engine
echo "== clone scummvm (depth1 HEAD) =="
rm -rf sv
git clone --depth 1 https://github.com/scummvm/scummvm.git sv
cd sv
echo "== 套引擎 patch(zak ZH-CJK + 我的 INDY3 適配:numChar 8178→23940、GBK 全 range、繪字/verb 定位)=="
git apply "$ROOT/patches/scumm-cht-indy3.patch"
echo "== configure(scumm only,關壓縮 codec)=="
./configure --disable-all-engines --enable-engine=scumm --enable-release \
  --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth --disable-tremor \
  --disable-faad --disable-mpeg2 --disable-a52 --disable-theoradec --disable-vpx \
  --disable-jpeg --disable-gif --disable-libcurl
echo "== make =="
make -j"$(nproc)"
ls -lh scummvm && echo "BUILD OK -> build-engine/sv/scummvm"
