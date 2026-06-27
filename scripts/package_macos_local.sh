#!/usr/bin/env bash
# 把 GitHub Action 下載回來的 macOS 引擎 .app 折入中文遊戲(LFL+字型+語音)→ 完整可玩包到 dist-all。
# tar.gz 不用 zip(保留 .app 權限/symlink)。
# 用法:scripts/package_macos_local.sh <下載回來的 IndyCrusade-CHT.app 路徑>
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:?給下載回來的 IndyCrusade-CHT.app 路徑}"
GAME="${GAME:-build-engine/game-cht}"
[ -d "$SRC/Contents/MacOS" ] || { echo "不是 .app: $SRC"; exit 1; }

PKG="dist-all/macos/IndyCrusade-CHT-mac-full"
OUT="$PKG/印第安納瓊斯-聖戰奇兵(繁中).app"
rm -rf "$PKG"; mkdir -p "$PKG"
cp -a "$SRC" "$OUT"
D="$OUT/Contents/Resources/game"
mkdir -p "$D"
# 中文遊戲:LFL + 字型 + 中文語音樹(含 a<N>/ npc/、voice_en/)
cp "$GAME"/*.LFL "$D/"
cp "$GAME"/chinese_gb16x12.fnt "$D/"
cp "$GAME"/crusade_title.spr "$D/" 2>/dev/null || true   # 火車車廂標題中文疊圖
[ -d "$GAME/voice" ]    && cp -r "$GAME/voice"    "$D/" 2>/dev/null || true
[ -d "$GAME/voice_en" ] && cp -r "$GAME/voice_en" "$D/" 2>/dev/null || true
cp "$GAME"/track*.wav "$D/" 2>/dev/null || true

cat > "$PKG/使用說明.txt" <<'TXT'
印第安納瓊斯：聖戰奇兵  繁體中文版（macOS）
============================================

這是什麼
--------
LucasArts 1989 年經典冒險遊戲《Indiana Jones and the Last Crusade》
（FM-Towns 版）的繁體中文化版本，以 ScummVM 引擎執行。本包已內含遊戲
資料與中文語音，解壓即可玩。

支援機型：Intel 與 Apple Silicon（M1/M2/M3…）皆可（universal 二進位）。
系統需求：macOS 11.0 以上。

怎麼玩（第一次請照做）
----------------------
這個 app 沒有經過 Apple 簽章，macOS 預設會擋下來。請二選一：

  做法 A（最簡單，建議）— 對 app 按右鍵
    1. 在 Finder 對「印第安納瓊斯-聖戰奇兵(繁中).app」按右鍵 →「打開」。
    2. 跳出警告時，再按一次「打開」。之後雙擊就能直接玩。

  做法 B — 終端機解除隔離
    打開「終端機」，貼上（路徑換成你放的位置）後按 Enter：
        xattr -dr com.apple.quarantine "印第安納瓊斯-聖戰奇兵(繁中).app"
    然後雙擊 app 即可。

如果出現「已損毀，無法打開」
--------------------------
那是 Gatekeeper 的隔離標記，不是檔案壞掉。照「做法 B」執行 xattr 那行即可。

遊戲中常用按鍵
--------------
‧ F5  叫出選單（存檔 / 讀檔 / 設定）
‧ F9  切換中文 / 英文語音

存檔位置
--------
存檔在 ~/Documents/ScummVM Savegames/，不在 app 內，刪除 app 不會動到存檔。

備註
----
本包含原版遊戲版權資料與中文配音，僅供個人保存使用，請勿散布。
TXT

TARBALL="dist-all/macos/IndyCrusade-CHT-mac-full.tar.gz"
rm -f "$TARBALL"
tar -C dist-all/macos -czf "$TARBALL" "$(basename "$PKG")"
du -sh "$PKG" "$TARBALL"
echo "full macOS 交付 -> $PKG/  (含 .app + 使用說明.txt)"
echo "             tar -> $TARBALL  (傳到 Mac 用,個人自留,含版權資料,勿散布)"
