# previous-work — 工作狀態交接(印第安納瓊斯:聖戰奇兵 繁中化)

> 給接手的 Claude Code 兄弟:先讀這份,再 `claude --resume`(UUID 在最下方 §接續)。
> ⚠️ 這個 session 同時做兩個專案:**atlantis**(亞特蘭提斯,主 cwd)與 **crusade**(聖戰奇兵,本專案)。
> session jsonl + memory 在 `-home-anr2-indian-jones-atlantis` 目錄底下(兩專案共用同一段對話)。

## 專案現況快照

- **repo**:`git@github.com:wicanr2/indiana-jones-and-last-crusade-cht.git`,分支 `master`。
- **遊戲**:*Indiana Jones and the Last Crusade*(LucasFilm Games 1989,**FM-Towns CD 版**,SCUMM **v3**)。
- **做法**:不改原版資料,改 ScummVM——繪字處攔英文 → 查表 → `chinese_gb16x12.fnt`(12×12 GBK)點陣中文重畫。前例是同類 SCUMM v3 + FM-Towns 的 Zak McKracken 繁中化(`~/zak-cht`),把 `GID_ZAK` 路徑擴到 `GID_INDY3`。
- **成果**:玩家走得到的對白全翻(scummtr 匯入 LFL);**per-character 中文配音(8 角色專屬聲線)**;**三平台打包完成**(Linux/Windows/macOS,皆 full、本機自留)。

## 本次 session 做的工作(crusade 部分)

1. **文本翻譯 + 引擎整合**:scummtr 抽字 → 翻譯 → encode-gbk → 匯回 LFL;動詞面板/物件名/句子列全中文。踩過 GBK 尾位元組 `0xFE` 被 `scummtr` `_checkRsc` 誤判,改 CJK-aware。
2. **per-character 配音(本作 headline,靜態反組譯突破)**:原版**無語音**→ 無中生有配中文 TTS。講者**不是玩一輪收 CHTMAP**,是靜態抽:`scummrp` 拆 LFL → 自編 `descumm -3 -n` → `print(N,Text)`/`printEgo` 直接給每句講者 → cht_key(FNV-1a over GBK pairs)。1118/1121 對上 manifest(99.7%)。卡司:印第(馬蓋先)/亨利=2/艾爾莎=3/馬可斯=4/醉漢=5/唐納文=6/教練=9/聖杯騎士=10@房86;雜魚走 `voice/npc/` 沉穩+變調。F9 切中/英配。詳見 `docs/voice-casting.md` + memory `static-speaker-extraction`。
3. **三平台打包**(移植 atlantis,rule 42 逐項照抄):
   - Linux:`scripts/package_appimage.sh`(內嵌 LFL+字型+voice 樹)。
   - Windows:`scripts/build_windows_docker.sh`(docker mingw 自編 SDL2/zlib 靜態)+ `package_windows.sh`。
   - macOS:`.github/workflows/build-macos.yml`(`macos-14` arm64 + `macos-15-intel` x86_64 + `lipo`)+ `package_macos_local.sh`。
   - **關鍵**:`patches/scumm-cht-indy3.patch` 重生補進 per-character 路由(`ChtRateShiftStream`/`voice/a<actor>/`),pin base `fb1c2af1` 確保 fresh clone 套得上。
4. **README + 介紹影片**:README 改雜誌風三層 voice;`scripts/capture_gameplay_video.sh` + `make_gameplay_video.sh` 錄實機 logo→標題+FM-Towns 音樂 → `dist-all/video/crusade-cht-intro.mp4`。

## 工具鏈 / harness

- 配音:edge-tts(合法 zh 聲線——Yunjian/Yunxi/Yunxia/Yunyang/YunJhe/WanLung/HsiaoChen;**Yunye/Yunze 不存在**)。Python 一律 docker `ghcr.io/astral-sh/uv`。
- 反組譯:`scripts/build_descumm.sh` 自編 descumm(scummvm-tools,`-DPOSIX -DCONFIG_H -DSCUMM_LITTLE_ENDIAN`)。
- 引擎:`scripts/build_cht_engine.sh`(全新編 ScummVM + 套 patch,**不沿用任何既有 binary**)。
- **headless 測不到語音/難觸發角色對白**(交談需精準座標 + 字幕時機);UI/截圖可 Xvfb + import。

## 待辦 / 開放項目

- [ ] gym 教練等角色的對白截圖 headless 不好觸發(只到 gym;座標+時機難),目前 README 用標題/場景字幕/動詞/句子列展示,角色語音以文字+影片音軌呈現。
- [ ] 真 Windows / 真 Mac 上跑完整玩法驗證(dev box wine 不可靠、無 Mac 機)。
- [ ] (可選)更多場景中文截圖(城堡/威尼斯/聖杯神廟)。

## 鐵則 / 硬約束(別違反)

- **版權切分**:LFL(已烘中文=版權衍生)/ `.bin`/`.cue` / TTS 語音 **只進本機 full 包 / dev-setup,絕不上公開 CI / release / git**。`dist-all/`、`build-win/`、`build-engine/`、`*.LFL` 都 gitignore。crusade 翻譯烘進 LFL → 只 full、不做公開 slim。
- **參考保真度**(rule 42):移植 atlantis 打包先讀其實際設定逐項照抄(本次:pin `fb1c2af1`、`macos-14`+`macos-15-intel`)。
- **不依賴既有 binary**:新機從 `patches/scumm-cht-indy3.patch` 自編引擎(`build_cht_engine.sh`)。
- **語氣**:印第口吻 + 黑色幽默,不字面直譯;人名/謎題詞精確。

## § 在別台電腦接續(claude --resume)

1. 兩個 repo(atlantis + crusade)放到相同絕對路徑最省事;還原 `claude-session/projects/-home-anr2-indian-jones-atlantis` → `~/.claude/projects/<同編碼>`(見 SETUP.md)。
2. `cd ~/indian_jones/atlantis && claude --resume 22323f24-eebd-4984-8518-f685ab31adb6`(session 主 cwd 是 atlantis;crusade 工作在同段對話內)。
3. 路徑對不上 → 直接 `claude --resume 22323f24-eebd-4984-8518-f685ab31adb6`(UUID 不卡路徑)。

**最近 session UUID:`22323f24-eebd-4984-8518-f685ab31adb6`**

## 記憶索引(claude-session/memory/)

- `static-speaker-extraction` — descumm 靜態抽講者(本作 headline 方法)
- `translation-voice` — 印第口吻 + 黑色幽默
- `packaging-cross-build` — 三平台打包 + cross-compile 踩雷
- `scummvm-build-dependency` / `translation-loop-state` / `voice-redirect-verified` — 見 MEMORY.md
