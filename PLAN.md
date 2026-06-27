# PLAN — 最後聖戰 繁中化分階段規劃

承前作亞特蘭提斯的節奏,但按 v3 / FM-Towns / 無語音調整。每階段先建可驗證的成功標準再動手。

## 進度

- ✅ **階段 1 取資料**:bchunk 拆 FM-Towns CD `.bin/.cue` → 資料軌 `INDY3ENG/*.LFL`(90 檔)。
- ✅ **階段 2 抽字**:`scummtr -g indy3towns -rwh -o`(預編 scummtr 0.5.1)→ 2172 行、1859 個唯一字串。
- ✅ **階段 6 翻譯**:**1859/1859 唯一字串全翻完**(印第口吻+黑色幽默;羅馬數字/JEHOVA 拼字謎/聖杯描述等謎題精確保留;人名/控制碼/地板字母格/德語梗刻意留原樣)。管線:`tools/assemble_scummtr.py`(英文源+`zh.tsv` en→zh → 組裝 import-ready scummtr.txt;untranslated 自動留原文)。中文-only by-ID:`translations/crusade_zh_by_id.tsv`。
- ✅ **階段 3-5 引擎整合(中文已在 ScummVM 顯示!)**:全新編 ScummVM(`scripts/build_cht_engine.sh`)+ 套 `patches/scumm-cht-indy3.patch`(zak ZH-CJK + INDY3 適配);字型重用 `chinese_gb16x12.fnt`(12×12 GBK);patched scummtr(zak scummtr-cjk + 本專案 `_checkRsc` CJK 修正)`encode-gbk` + 匯入(`scripts/import_cht.sh`)。**動詞面板、物件名、句子列全中文正常渲染**(截圖 `screenshots/crusade_cht_verbs.png`、`crusade_cht_look.png`)。
  - 關鍵修正:① ScummVM HEAD 的 `case ZH_CHN` 對 INDY3 載 numChar=**8178**(GB2312),但字型是 **23940**(full GBK)→ 把 INDY3 從 8178 分支移到 23940 分支。② scummtr `_checkRsc` 把物件名結尾的 GBK trail byte `0xFE`(如「件」)誤判 truncated → 改 CJK-aware。③ 跑時 `--platform=fmtowns --language=cn`(否則 auto-detect 選錯 VGA 變體 → Bad ID）。
- ⏳ **下一步**:階段 7 中文 TTS 配音(沿用 FOA dub pipeline)、階段 8 三平台打包(`retro-game-cht-package` skill)。
- ⚠️ 版權:英文原劇本(`crusade_en.txt`/`zh.tsv`)+ 遊戲 LFL gitignore 不入庫;只提交 patch / 工具 / 中文-only by-ID / 截圖。

## 已完成(偵察)

- 確認素材:`Indiana Jones and the Last Crusade (1989)(LucasFilm)(Jp-En).bin/.cue` = **FM-Towns CD 映像**。
  - Track 01 = MODE1/2352 資料軌(ISO9660);Track 02-09 = Red Book **音樂**軌。
  - 資料軌內 `00.LFL`~`NN.LFL`(loader 字串 `%02d.LFL (%c%d)`)→ **SCUMM v3**。
  - 標記:`1990 LucasArts` / `89/10/25towns` / `FM Towns OAK` → 1990 FM-Towns 日文版。
- ScummVM game id:`GID_INDY3`。

## 階段

| # | 階段 | 成功標準 |
|---|---|---|
| 1 | **取資料 + 原版能跑** | 從 `.bin` 取出 Track 01 的 `*.LFL` / 字型;`scummvm --detect` 認出 Indy3 FM-Towns;原版能跑、能截圖(baseline) |
| 2 | **抽字** | `scummtr` export/import `*.LFL`(套 `~/zak-cht/patches/scummtr-cjk.patch`,作法同 zak;不用自寫 v3 parser)。產出可編輯字串表 |
| 3 | **繪字路徑(已大幅去風險)** | 套 `~/zak-cht/patches/scummvm-zhtw.patch`,把 `GID_ZAK` 的 CJK 條件**擴到 `GID_INDY3`**(CharsetRendererV3 + FM-Towns TownsV3 + `chinese_gb16x12.fnt`)。PoC:INDY3 畫出一個中文字。逐一對齊 INDY3 對白/verb 顯示差異 |
| 4 | **字型** | **直接重用** `~/zak-cht` 的 `chinese_gb16x12.fnt`(12×12 GBK,`build-zh-font-wqysharp.py`);若要更大字再評估 hi-res canvas |
| 5 | **CJK patch + runtime 攔截** | drawString / 對白攔截英文 → 查表 → Big5;runtime log 出「畫了卻沒翻」的字串 |
| 6 | **翻譯** | 印第口吻 + 黑色幽默;人名/謎題詞精確;建 `CONTEXT.md` 術語表。劇情:聖杯三試煉、亨利老瓊斯、拳擊戰、飛船、城堡 |
| 7 | **中文 TTS 配音(加值,見下節)** | prototype 幾句評估 sync → 可接受才全配。**先把字幕做穩,再上語音** |
| 8 | **打包** | 三平台(skill `retro-game-cht-package`):Linux AppImage / Windows docker-mingw / macOS universal(macos-14 + macos-15-intel 分弧 lipo)。slim/full 版權切分 |
| 9 | **收尾** | README 三層 voice(rule `80`)、截圖、YouTube 介紹片、dev-setup 交接包 |

## 中文語音(TTS 配音)— 加值新功能

> **決定:做。** 字幕為主、配音為加值;由本專案自製 TTS(edge-tts 分角色)。**不是 FOA 那種重導,是無中生有。**

**已驗證(別再重查):最後聖戰 FM-Towns 版沒有任何原始語音。** CD 掃描無 `MONSTER.SOU` / `.VOC` / `SPEECH` / `VOICE` 等語音資源;音訊只有 TOWNS SOUND LIBRARY(Joe Mizuno 1989)的 PCM 音效 + Red Book CD 音樂。ScummVM 的 INDY3 路徑也沒有 speech/talkie 旗標。對白是純文字。所以**沒有語音點可重導**,只能新增一套語音子系統。

**作法(積木都在:本來就攔截對白顯示路徑來畫中文字幕):**
1. **觸發**:在攔截對白的同一個 hook,按「行 ID(對白內容 hash,翻譯表本來就用這 key)」找對應中文 VOC。
2. **播放**:丟 ScummVM mixer 一個 channel(與 FM-Towns CD 音樂並存沒問題)。
3. **同步**:把該行字幕顯示時間設成 = 語音長度(模仿 talkie 的「字等語音播完」邏輯);talk-delay 設成語音長度,嘴型動畫會跟著動。
4. **生產**:沿用 FOA 的 dub pipeline(`scripts/dub_batch.sh` + `tools/build_voice.py`,edge-tts 分角色:印第馬蓋仙腔、亨利老瓊斯、Donovan、Elsa…)+ 翻譯表 ID 機制。

**風險 / 注意:**
- sync **不會像原生 talkie 那麼準**(原版無逐句時序),「字等語音」逼近;快速點掉對白時可能略 overlap。**sync 品質要 prototype 才能定論,別先全配。**
- 引擎 patch 量 + 測試比 FOA 重導大(新增子系統)。
- 對白量大 → TTS 量大,但批次自動化(如 FOA)。
- **相依鏈**:語音卡在「繪字路徑(階段 3)能不能穩」之前是空談 → 嚴格按階段順序,語音排階段 7。

## 沿用前作(直接搬)

- engine-overlay 哲學、runtime 攔截、CONTEXT.md、`build_cjk_font.py` / `build_translation.py`、三平台打包 skill、dev-setup-bundle skill。

## 硬約束

- 版權切分(CD 映像 / 遊戲資料只進本機 full 包,不上公開 CI/git)。
- 參考保真度(rule 42):動 CI/打包先讀前作會動的 `.github/workflows` 與 `scripts/` 照抄 proven values。
- CJK hi-res canvas、靜態溯源、feedback loop。

## 風險 / 開放問題

- **繪字路徑**(階段 3)原為最大不確定,**現已大幅去風險**:`~/zak-cht` 是**同類**(SCUMM v3 + FM-Towns)的已完成前例,`scummvm-zhtw.patch` 走 CharsetRendererV3/TownsV3 + `chinese_gb16x12.fnt`。剩餘工作=把 `GID_ZAK` gating 擴到 `GID_INDY3` + 對齊 INDY3 對白/verb 顯示差異(patch 註解已提及 INDY)。
- v3 LFL 抽字用 scummtr(zak 已驗證);若 INDY3 有 zak 沒遇到的 LFL 結構差異再處理。
- **GBK range**:zak 給 ZAK 全 GBK range(cover 繁中擴展字),patch 註解說 INDY 預設用較窄 GB2312 區位碼 → INDY3 八成要比照 ZAK 開全 range,留意。
- **語音 sync**(階段 7):text-only 遊戲沒有逐句語音時序,自製 TTS 的「字等語音」同步要 prototype 驗證,別假設一定順。
