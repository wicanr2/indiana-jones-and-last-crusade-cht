#!/usr/bin/env bash
# 把 docker-cross 編好的 scummvm.exe 打成 Windows x64 full 包(開箱即玩,個人自留)。
# crusade 的中文翻譯烘進 LFL(版權衍生)→ 只有 full(內含遊戲+語音),不做公開 slim。
# SDL2 靜態連結 → 只附 3 個 mingw runtime DLL。
set -euo pipefail
cd "$(dirname "$0")/.."
EXE=build-win/out/scummvm.exe
GAME="${GAME:-build-engine/game-cht}"
[ -f "$EXE" ] || { echo "先跑 scripts/build_windows_docker.sh(需要 $EXE)"; exit 1; }
P="dist-all/windows/IndyCrusade-CHT-win64-full"
rm -rf "$P"; mkdir -p "$P/game"
cp "$EXE" "$P/"
cp build-win/out/*.dll "$P/" 2>/dev/null || true        # libgcc_s_seh-1 / libstdc++-6 / libwinpthread-1
# 內含中文遊戲:LFL + 字型 + 中文語音樹(voice/ 含 a<N>/ npc/、voice_en/)+ CD 音樂(若有)
cp "$GAME"/*.LFL "$P/game/"
cp "$GAME"/chinese_gb16x12.fnt "$P/game/"
cp "$GAME"/crusade_title.spr "$P/game/" 2>/dev/null || true   # 火車車廂標題中文疊圖
[ -d "$GAME/voice" ]    && cp -r "$GAME/voice"    "$P/game/" 2>/dev/null || true
[ -d "$GAME/voice_en" ] && cp -r "$GAME/voice_en" "$P/game/" 2>/dev/null || true
cp "$GAME"/track*.wav "$P/game/" 2>/dev/null || true
# FM-Towns 平台 + ZH_CHN 語言(觸發 chinese_gb16x12.fnt + _useCJKMode);indy3 必須最後
printf '@echo off\r\nscummvm.exe -p game --platform=fmtowns --language=cn %%* indy3\r\n' > "$P/play.bat"
# 使用說明.txt(繁中,CRLF)
{
cat <<'TXT'
印第安納瓊斯:最後聖戰  繁體中文版(Windows x64)
==================================================

這是什麼
--------
LucasArts 1989 年經典冒險遊戲《Indiana Jones and the Last Crusade》
(FM-Towns 版)的繁體中文化版本,以 ScummVM 引擎執行。本包已內含遊戲
資料與中文語音,解壓即玩。

怎麼玩
------
1. 把整個資料夾解壓到任意位置(例如桌面)。
2. 雙擊「play.bat」即可開始遊戲。
   (若 Windows SmartScreen 跳出警告 → 「更多資訊」→「仍要執行」。)

遊戲中常用按鍵
--------------
‧ F5  叫出選單(存檔 / 讀檔 / 設定)
‧ F9  切換中文 / 英文語音
‧ Alt+Enter  全螢幕 / 視窗切換

存檔位置
--------
存檔在你的使用者文件夾下的 ScummVM 存檔目錄,不在這個資料夾內,
刪除本資料夾不會動到存檔。

包內容
------
‧ scummvm.exe + 3 個執行階段 DLL(libgcc_s_seh-1 / libstdc++-6 / libwinpthread-1)
‧ play.bat(啟動用)
‧ game\(已內含中文遊戲 LFL + 字型 + 中文語音,解壓即玩)

備註:本包含原版遊戲版權資料與中文配音,僅供個人保存使用,請勿散布。
TXT
} | sed 's/$/\r/' > "$P/使用說明.txt"
Z="dist-all/windows/IndyCrusade-CHT-win64-full.zip"
rm -f "$Z"
if command -v zip >/dev/null 2>&1; then ( cd dist-all/windows && zip -qr "IndyCrusade-CHT-win64-full.zip" "IndyCrusade-CHT-win64-full" )
else python3 -c "import shutil; shutil.make_archive('dist-all/windows/IndyCrusade-CHT-win64-full','zip','dist-all/windows','IndyCrusade-CHT-win64-full')"; fi
du -sh "$P" "$Z"; echo "Windows full -> $Z"
