# SETUP — 在新機還原 crusade 開發環境 + 接續對話

> 這個 bundle 是私用 handoff:含完整對話記錄 `*.jsonl` + 版權素材(LFL/語音),**勿公開散布**。
> 同一段對話同時做 atlantis 與 crusade 兩個專案(session 在 `-home-anr2-indian-jones-atlantis` 底下)。

## 1. 還原 repo

```bash
mkdir -p ~/indian_jones && cd ~/indian_jones
git clone repo/crusade.gitbundle crusade   # 從 bundle 還原完整歷史
cd crusade
```

## 2. 還原 claude session(讓 `claude --resume` 接得上)

```bash
ENC=-home-anr2-indian-jones-atlantis
mkdir -p ~/.claude/projects/$ENC
cp -a claude-session/projects/$ENC/22323f24-eebd-4984-8518-f685ab31adb6.jsonl ~/.claude/projects/$ENC/
cp -a claude-session/projects/$ENC/memory ~/.claude/projects/$ENC/
```

## 3. 還原版權素材(中文遊戲 + 語音)

```bash
mkdir -p build-engine/game-cht
cp -a game-data/. build-engine/game-cht/     # LFL + chinese_gb16x12.fnt + voice/ 樹
```

## 4. 引擎:用 prebuilt 或自編

- 圖方便:`prebuilt/scummvm-linux-x86_64` 是現成 Linux 引擎(本機自留)。
- canonical(新機 / 其他平台):`bash scripts/build_cht_engine.sh`(全新編 ScummVM + 套 `patches/scumm-cht-indy3.patch`,不依賴任何既有 binary)。

## 5. 接續對話

```bash
cd ~/indian_jones/atlantis 2>/dev/null || cd ~/indian_jones/crusade
claude --resume 22323f24-eebd-4984-8518-f685ab31adb6
```

路徑對不上也沒關係,UUID 不卡路徑。接手前先讀 `previous-work.md`。

## 6. 打包(三平台)

- Linux:`scripts/package_appimage.sh`
- Windows:`docker run --rm -v "$PWD":/work -w /work debian:12-slim bash scripts/build_windows_docker.sh` → `scripts/package_windows.sh`
- macOS:`gh workflow run build-macos.yml` → `gh run download <id> -n macos-engine-app` → 重建 `.app` 外殼 → `scripts/package_macos_local.sh <app>`
- 介紹影片:`scripts/capture_gameplay_video.sh` → `scripts/make_gameplay_video.sh`
