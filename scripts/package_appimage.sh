#!/usr/bin/env bash
# 把中文聖戰奇兵(crusade scummvm + game-cht)打成單檔 AppImage。
# full:內嵌遊戲 LFL + 字型(+ 有 track*.wav 就含 FM-Towns CD 音樂)→ 開箱即玩(個人自留,含版權)。
# 產物:dist-all/linux/IndyCrusade-CHT-FULL-x86_64.AppImage
set -euo pipefail
cd "$(dirname "$0")/.."
SV="${SCUMMVM:-build-engine/sv/scummvm}"
GAME="${GAME:-build-engine/game-cht}"
TOOL="${APPIMAGETOOL:-/home/anr2/zak-cht-build/appimagetool}"
[ -x "$SV" ] || { echo "缺引擎:$SV(先 scripts/build_cht_engine.sh)"; exit 1; }
[ -x "$TOOL" ] || { echo "缺 appimagetool:$TOOL"; exit 1; }

APPDIR="dist-all/linux/IndyCrusade-CHT-FULL.AppDir"
OUT="dist-all/linux/IndyCrusade-CHT-FULL-x86_64.AppImage"
rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/game"

cp "$SV" "$APPDIR/usr/bin/scummvm"
# bundle 非系統 .so(排除 glibc/loader/常駐基礎庫)
ldd "$SV" | awk '/=>/{print $3}' | grep -E '\.so' \
  | grep -viE '/(libc|libm|libpthread|libdl|librt|ld-linux|libstdc\+\+|libgcc_s|libX11|libxcb|libXau|libXdmcp)\.' \
  | while read -r so; do [ -f "$so" ] && cp -Ln "$so" "$APPDIR/usr/lib/" || true; done

# 內嵌中文遊戲(LFL + 字型 + 中文語音 voice/*.voc + CD 音樂 track*.wav 若有)
cp "$GAME"/*.LFL "$APPDIR/game/"
cp "$GAME"/chinese_gb16x12.fnt "$APPDIR/game/"
cp "$GAME"/crusade_title.spr "$APPDIR/game/" 2>/dev/null || true   # 火車車廂標題中文疊圖
[ -d "$GAME/voice" ] && cp -r "$GAME/voice" "$APPDIR/game/" 2>/dev/null || true        # 含 npc/ a<N>/ 子目錄
[ -d "$GAME/voice_en" ] && cp -r "$GAME/voice_en" "$APPDIR/game/" 2>/dev/null || true
cp "$GAME"/track*.wav "$APPDIR/game/" 2>/dev/null || true

cat > "$APPDIR/AppRun" <<'RUN'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
# FM-Towns 平台 + ZH_CHN 語言(觸發 chinese_gb16x12.fnt + _useCJKMode);內嵌 game/
exec "$HERE/usr/bin/scummvm" -p "$HERE/game" --platform=fmtowns --language=cn "$@" indy3
RUN
chmod +x "$APPDIR/AppRun" "$APPDIR/usr/bin/scummvm"

cat > "$APPDIR/indycrusade-cht.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Indy Crusade CHT
Comment=印第安納·瓊斯:聖戰奇兵 繁體中文版
Exec=AppRun
Icon=indycrusade-cht
Categories=Game;
Terminal=false
DESK
# icon:用中文動詞截圖,否則 fallback glyph
if command -v convert >/dev/null 2>&1; then
  [ -f screenshots/crusade_cht_verbs.png ] && \
    convert screenshots/crusade_cht_verbs.png -gravity center -resize 256x256^ -extent 256x256 "$APPDIR/indycrusade-cht.png" 2>/dev/null || \
    convert -size 256x256 xc:'#101830' -fill '#f0c000' -gravity center -pointsize 110 -annotate 0 "聖" "$APPDIR/indycrusade-cht.png" 2>/dev/null || true
fi
[ -f "$APPDIR/indycrusade-cht.png" ] || : > "$APPDIR/indycrusade-cht.png"
cp "$APPDIR/indycrusade-cht.png" "$APPDIR/.DirIcon" 2>/dev/null || true

ARCH=x86_64 "$TOOL" --appimage-extract-and-run "$APPDIR" "$OUT" 2>&1 | tail -3
rm -rf "$APPDIR"
ls -lh "$OUT" && echo "AppImage -> $OUT"
