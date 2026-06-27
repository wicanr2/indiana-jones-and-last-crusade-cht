# 印第安納·瓊斯:最後聖戰 中文化(Indiana Jones and the Last Crusade, FM-Towns)

> 前作經驗來自姊妹專案 **亞特蘭提斯之謎**(`@~/indian_jones/atlantis`)——同一套「patched-ScummVM engine-overlay」漢化法。
> **但這作是 SCUMM v3 / FM-Towns / 無語音,跟 FOA(v5 talkie)差很多,不要照抄,照下面的差異表走。**

## 這份遊戲是什麼(已偵察確認)

- **檔案**:`Indiana Jones and the Last Crusade (1989)(LucasFilm)(Jp-En).bin/.cue` —— **FM-Towns CD 映像**。
  - Track 01 = MODE1/2352 資料軌(ISO9660,內含遊戲);Track 02-09 = **AUDIO**(Red Book CD 音樂,不是語音)。
  - 資料軌內是 `00.LFL` ~ `NN.LFL`(loader 字串 `%02d.LFL (%c%d)`)→ **SCUMM v3** 資源格式。
  - `1990 LucasArts` / `89/10/25towns` / `FM Towns OAK` → 1990 FM-Towns 日文版。
- **ScummVM game id**:`GID_INDY3`(scumm 引擎)。
- **沒有 talkie 語音**:1989 原作無配音;FM-Towns 的 CD 軌是**音樂**。→ **純字幕中文化,不做配音**(比 FOA 少一大塊)。

## 與 FOA(亞特蘭提斯)的關鍵差異(★必讀,別照抄★)

| 面向 | FOA(v5,做過了) | 最後聖戰(v3 / FM-Towns,這作) |
|---|---|---|
| **SCUMM 版本** | v5,資源在 `ATLANTIS.001`(LECF/XOR 0x69 容器) | **v3,資源在 `NN.LFL`** 檔(不同編碼/格式)→ **FOA 的 `tools/scumm_v5.py` 不能用**,要寫 v3 LFL 抽字 |
| **抽字** | 走完 LECF 樹解 SCRP/LSCR | v3 用 scummtr 或 ScummVM 的 v3 dumper / 自寫 LFL parser;先試 **scummtr**(老 SCUMM 友善,參考 `zak-fmtowns-zhtw` skill) |
| **繪字路徑** | v5/v7 的 **`ZH_TWN` Big5** 路徑 | ⚠️ **FM-Towns 走 SJIS / FM-Towns ROM 字型路徑**(`_useCJKMode` 日文),**不是** ZH_TWN。要嘛接 FM-Towns 字型路徑換 Big5、要嘛走 `ZH_CHN` 12×12 GBK 再轉(參考 `zak-fmtowns-zhtw` skill,Zak 也是 FM-Towns)|
| **語音** | MONSTER.SOU 5552 點重導 + edge-tts 配音 | **無**。跳過整個配音 pipeline |
| **解析度** | 320×200 VGA 256 色 | 320×240 FM-Towns 16 色 → **hi-res canvas 規則一樣套**(CJK 24×24 畫在拉高畫布,別縮字)|
| **CD 音樂** | 無 | **有 Red Book 8 軌**,ScummVM 自己放,**別動** |
| **劇情** | 柏拉圖/亞特蘭提斯/蘇菲亞 | 電影正傳:亨利老瓊斯、聖杯、「他選錯了」、拳擊戰、飛船、城堡 |

> **最像這作的前例不是 FOA,是 `zak-fmtowns-zhtw` skill**(Zak McKracken FM-Towns 繁中化):同樣 FM-Towns、scummtr raw 抽字、走 ZH_CHN 12×12 GBK 字型路徑、GBK 0x5C escape。**先讀那個 skill。**

## 沿用 FOA 的要點(這些直接搬)

1. **engine-overlay 哲學**:不改遊戲資料一個 byte,改 ScummVM —— 繪字處攔截英文 → 查表 → 點陣中文重畫。
2. **runtime 攔截**:patch 把引擎「畫出來卻沒翻」的英文 log 出來,翻的是實際顯示的字串(離線抽字會有碎片對不上)。
3. **CONTEXT.md ubiquitous language**:開工先建術語表(瓊斯、印第、亨利、聖杯、納粹…),人名/謎題詞精確、對白走印第口吻+黑色幽默(見 FOA 的 `translation-voice` 記憶 + CONTEXT.md)。
4. **字型/譯表 builder 可重用**:FOA 的 `tools/build_cjk_font.py`(TTF→點陣 atlas)、`tools/build_translation.py`(tsv→.tab)直接拿來改。
5. **三平台打包**:用 skill **`retro-game-cht-package`**(Linux AppImage / Windows docker-mingw / macOS universal)。**macOS 一定 `macos-14`+`macos-15-intel` 分弧 lipo,不要單次雙弧**(ScummVM autoconf 會炸版本解析)。
6. **dev-setup 交接**:收尾用 skill `dev-setup-bundle` 打包(repo bundle + claude-session + 素材)。
7. **README 三層 voice**(rule `80-retro-cht-readme-polish`):Hero 信 / Magazine 雜誌風 / Technical 工程文件,別混。

## 硬約束(鐵則)

- **版權切分**:原版遊戲資料 + CD 音樂**只進本機 full 包,絕不上公開 CI / git**。`dist-all/`、`game/` gitignore。公開 CI 只出引擎 + 自製中文資產(slim)。
- **參考保真度**(rule `42-reference-fidelity`):要動 CI / 打包,先讀「會動的 reference」(FOA 的 `.github/workflows/build-macos.yml`、`scripts/`)逐項照抄 proven values(runner 標籤等),別憑記憶。FOA 的教訓:沒抄 `macos-14` → 寫退役 `macos-13` 卡死。
- **CJK hi-res canvas**(rule):中文 24×24 畫在拉高畫布,不縮小硬塞原版小字位。
- **靜態溯源 / feedback loop**(rules `62`/`60`):撞牆先靜態反追資源來源、先建可重跑 pass/fail 訊號,別太早下「動態/看不出來」。

## 建議起手式(下一個 session)

1. **掛載 CD 資料軌抽出 LFL**:`.bin/.cue` → 取 Track 01(ISO9660)→ mount/`bchunk`/`isoinfo` 取出 `*.LFL`、字型、CD 音軌資訊。
2. **先讓 ScummVM 認得 / 跑起來**:`scummvm --detect -p <解出的資料>` 應偵測為 *Indiana Jones and the Last Crusade (FM-Towns)*,`GID_INDY3`。先確認原版能跑、能截圖(建可玩 baseline)。
3. **抽字**:先試 `scummtr -g indy3 -r`(raw),確認 v3 / FM-Towns 字串怎麼出來;對不上再寫 LFL parser。
4. **繪字路徑探勘**:讀 ScummVM `engines/scumm` 看 INDY3 + FM-Towns 怎麼進 `_useCJKMode` / 畫雙位元組字 —— **決定接 FM-Towns SJIS 路徑換 Big5,還是走 ZH_CHN 路徑**(這是本作最大技術問號,參考 zak-fmtowns-zhtw)。
5. 之後照 FOA 節奏:字型 → CJK patch → runtime 攔截 → 印第口吻翻譯 → 三平台打包。

## 參考座標

- **前作 repo**(同作者、同手法、最完整範本):`~/indian_jones/atlantis`(已完成:字幕+配音+三平台 ship)。
- **最像的技術前例**:skill `zak-fmtowns-zhtw`(FM-Towns SCUMM 繁中化)。
- **打包**:skill `retro-game-cht-package`。**交接**:skill `dev-setup-bundle`。
- **DGDS 系列**(另一條 ScummVM 漢化線,手法可借鏡):skill `rise-of-the-dragon-cht`、`~/willy`。
- Steam 若有 FOA 那種版本差異問題,記得 CD 版 vs 數位版 md5 比對(FOA 經驗)。
