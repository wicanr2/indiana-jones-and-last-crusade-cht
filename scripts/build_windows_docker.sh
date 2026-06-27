#!/usr/bin/env bash
# Cross-compile ScummVM (scumm engine) for Windows x64 via docker mingw-w64. (移植自 atlantis)
# 自編 SDL2 + zlib(mingw static)。壓縮音訊全關(中文語音是 raw VOC)→ 靜態 exe + 3 個 mingw runtime DLL。
# pin SCUMMVM_REF 確保 patches/scumm-cht-indy3.patch 套得上(patch 對此 base 重生)。
# 用法(在 repo 根目錄):docker run --rm -v "$PWD":/work -w /work debian:12-slim bash scripts/build_windows_docker.sh
set -euo pipefail
SDL2_VER=2.30.9 ; H=x86_64-w64-mingw32
SCUMMVM_REF=fb1c2af1af154dfde7bd8be4fac92b7d5befbe8a
PFX=/work/build-win/win-prefix ; SRC=/work/build-win/src ; SV=/work/build-win/scummvm-win
mkdir -p "$PFX" "$SRC"

echo "== toolchain =="
apt-get update -qq && apt-get install -y -qq g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 \
  binutils-mingw-w64-x86-64 mingw-w64-tools make curl git ca-certificates nasm xz-utils pkg-config >/dev/null

if [ ! -f "$PFX/lib/libSDL2.a" ]; then
  echo "== build SDL2 (mingw static) =="
  cd "$SRC"; [ -d SDL2-$SDL2_VER ] || curl -sL "https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VER}/SDL2-${SDL2_VER}.tar.gz" | tar xz
  cd SDL2-$SDL2_VER && ./configure --host=$H --prefix="$PFX" --disable-shared --enable-static --disable-render-d3d >/tmp/c.log 2>&1 || { tail -15 /tmp/c.log; exit 1; }
  make -j"$(nproc)" >/tmp/m.log 2>&1 || { tail -20 /tmp/m.log; exit 1; }; make install >/dev/null
fi
echo "SDL2: $(ls $PFX/lib/libSDL2.a)"

if [ ! -f "$PFX/lib/libz.a" ]; then
  echo "== build zlib (mingw static) =="
  cd "$SRC"; [ -d zlib-1.3.1 ] || curl -sL "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz" | tar xz
  cd zlib-1.3.1 && make -f win32/Makefile.gcc PREFIX=${H}- BINARY_PATH="$PFX/bin" INCLUDE_PATH="$PFX/include" LIBRARY_PATH="$PFX/lib" install >/tmp/z.log 2>&1 || { tail -15 /tmp/z.log; exit 1; }
fi
echo "zlib: $(ls $PFX/lib/libz.a)"

echo "== scummvm clone(pin $SCUMMVM_REF)+ patch =="
rm -rf "$SV"
git clone --depth 1 https://github.com/scummvm/scummvm.git "$SV" -q
cd "$SV"
if [ "$(git rev-parse HEAD)" != "$SCUMMVM_REF" ]; then
  git fetch --depth 1 origin "$SCUMMVM_REF" -q && git checkout -q "$SCUMMVM_REF"
fi
git apply /work/patches/scumm-cht-indy3.patch
# cross-compile: force little-endian(x64 Windows always LE;configure 的 runtime 端序檢測在 Linux 跑不了 .exe)
sed -i '/^echo_n "Checking endianness... "/a _endian=little' configure
echo "patched (base $(git rev-parse --short HEAD))."

echo "== configure (scumm only, minimal deps, self SDL2) =="
export PATH="$PFX/bin:$PATH"
export SDL2_CONFIG="$PFX/bin/sdl2-config"
./configure --host=$H --backend=sdl --enable-engine=scumm --disable-all-engines --enable-engine=scumm \
  --with-sdl-prefix="$PFX" --with-zlib-prefix="$PFX" \
  --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth --disable-tremor \
  --disable-faad --disable-mpeg2 --disable-a52 --disable-theoradec --disable-vpx \
  --disable-png --disable-jpeg --disable-gif --disable-freetype2 --disable-libcurl \
  --disable-sndio --disable-timidity --disable-sparkle --disable-discord \
  --enable-release >/tmp/svc.log 2>&1 || { echo "--- configure FAIL ---"; tail -30 /tmp/svc.log; exit 1; }
echo "configured."
make -j"$(nproc)" >/tmp/svm.log 2>&1 || { echo "--- make FAIL ---"; tail -30 /tmp/svm.log; exit 1; }
ls -la "$SV"/scummvm.exe && echo "BUILD OK: scummvm.exe"

# stage exe + 防禦性收 3 個 mingw runtime DLL(靜態連結,import 表全系統 DLL,通常收 0 個)
rm -rf /work/build-win/out; mkdir -p /work/build-win/out
cp "$SV"/scummvm.exe /work/build-win/out/
SEARCH="/usr/lib/gcc/$H/*-win32 /usr/lib/gcc/$H /usr/$H/lib /usr/$H/bin $PFX/bin $PFX/lib"
for d in libgcc_s_seh-1 libstdc++-6 libwinpthread-1; do
  f=$(find $SEARCH -maxdepth 1 -iname "$d.dll" 2>/dev/null | head -1); [ -n "$f" ] && cp -n "$f" /work/build-win/out/ || true
done
echo "DLLs in package: $(ls /work/build-win/out/*.dll 2>/dev/null | wc -l)"
ls -la /work/build-win/out/
