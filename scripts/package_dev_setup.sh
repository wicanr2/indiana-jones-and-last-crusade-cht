#!/usr/bin/env bash
# 把 crusade 開發環境打包成可攜 dev-setup,讓「另一台電腦」解開後能重建 + `claude --resume` 接續對話。
# 三層必含:(1) 可重建環境(repo bundle + 腳本 + 素材)(2) 工作交接(SETUP/previous-work)(3) claude-session。
# 產物:dist-all/dev-setup/(資料夾)+ dist-all/dev-setup-<date>.tar.zst
# ⚠️ 私用 handoff:含完整對話記錄 + 版權素材,勿公開散布(dist-all 已 gitignore)。
set -euo pipefail
cd "$(dirname "$0")/.."
ENC="-home-anr2-indian-jones-atlantis"               # session 編碼(主 cwd 是 atlantis,兩專案共用)
SESS="$HOME/.claude/projects/$ENC"
UUID="22323f24-eebd-4984-8518-f685ab31adb6"
ENGINE="${SCUMMVM:-build-engine/sv/scummvm}"         # crusade 自編引擎
GAME="${GAME:-build-engine/game-cht}"                # 中文遊戲(LFL + 字型 + voice 樹)

OUT="dist-all/dev-setup"
rm -rf "$OUT"; mkdir -p "$OUT/repo" "$OUT/claude-session/projects/$ENC" "$OUT/game-data" "$OUT/prebuilt"

echo "== (1) repo:git bundle --all =="
git bundle create "$OUT/repo/crusade.gitbundle" --all

echo "== (2) 工作交接文件 =="
cp packaging/dev-setup/SETUP.md packaging/dev-setup/previous-work.md "$OUT/"
{ echo; echo "---"; echo "_bundle 產出時 HEAD:$(git rev-parse --short HEAD) ($(git log -1 --format=%s | cut -c1-60))_"; } >> "$OUT/previous-work.md"

echo "== (3) claude-session:對話 jsonl + memory =="
cp -a "$SESS/$UUID.jsonl" "$OUT/claude-session/projects/$ENC/" 2>/dev/null || echo "  ⚠️ 找不到 $UUID.jsonl"
cp -a "$SESS/memory" "$OUT/claude-session/projects/$ENC/" 2>/dev/null || true

echo "== 素材:中文遊戲 LFL + 字型 + 全套中文語音(本機自留)=="
cp -a "$GAME/." "$OUT/game-data/" 2>/dev/null || echo "  ⚠️ $GAME 不在,略過"

echo "== 便利:預編 Linux 引擎(canonical 仍是從 patch 重編,見 SETUP.md)=="
[ -f "$ENGINE" ] && cp "$ENGINE" "$OUT/prebuilt/scummvm-linux-x86_64" || echo "  ⚠️ 引擎不在 $ENGINE,略過"

echo "== 介紹影片(若已產)=="
[ -f dist-all/video/crusade-cht-intro.mp4 ] && { mkdir -p "$OUT/video"; cp dist-all/video/crusade-cht-intro.mp4 "$OUT/video/"; } || true

echo "== 壓成 tar.zst =="
DATE="$(date +%Y%m%d)"
TARBALL="dist-all/dev-setup-$DATE.tar.zst"
rm -f "$TARBALL"
tar --zstd -C dist-all -cf "$TARBALL" --exclude='__pycache__' --exclude='*.pyc' dev-setup

echo ""
du -sh "$OUT" "$TARBALL"
echo "dev-setup 資料夾 -> $OUT/"
echo "          tar.zst -> $TARBALL  (私用 handoff,含對話記錄+版權素材,勿公開散布)"
echo "新機接續:還原後 claude --resume $UUID(細節見 $OUT/SETUP.md)"
