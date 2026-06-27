# PLAN — 最後聖戰 繁中化分階段規劃

承前作亞特蘭提斯的節奏,但按 v3 / FM-Towns / 無語音調整。每階段先建可驗證的成功標準再動手。

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
| 2 | **抽字** | 先試 `scummtr -g indy3 -r`(raw + CRLF);對不上再寫 v3 LFL parser。產出可編輯字串表 |
| 3 | **繪字路徑探勘(最大技術問號)** | 讀 ScummVM `engines/scumm` 看 INDY3 + FM-Towns 怎麼進 `_useCJKMode` / 畫雙位元組字 → 決定「接 FM-Towns SJIS 路徑換 Big5」還是「走 `ZH_CHN` 12×12 GBK」。產出 PoC:畫出一個中文字 |
| 4 | **字型** | 烘點陣 atlas(沿用前作 `build_cjk_font.py`);hi-res canvas(24×24 畫在拉高畫布,不縮字) |
| 5 | **CJK patch + runtime 攔截** | drawString / 對白攔截英文 → 查表 → Big5;runtime log 出「畫了卻沒翻」的字串 |
| 6 | **翻譯** | 印第口吻 + 黑色幽默;人名/謎題詞精確;建 `CONTEXT.md` 術語表。劇情:聖杯三試煉、亨利老瓊斯、拳擊戰、飛船、城堡 |
| 7 | **打包** | 三平台(skill `retro-game-cht-package`):Linux AppImage / Windows docker-mingw / macOS universal(macos-14 + macos-15-intel 分弧 lipo)。slim/full 版權切分 |
| 8 | **收尾** | README 三層 voice(rule `80`)、截圖、YouTube 介紹片、dev-setup 交接包 |

## 沿用前作(直接搬)

- engine-overlay 哲學、runtime 攔截、CONTEXT.md、`build_cjk_font.py` / `build_translation.py`、三平台打包 skill、dev-setup-bundle skill。

## 硬約束

- 版權切分(CD 映像 / 遊戲資料只進本機 full 包,不上公開 CI/git)。
- 參考保真度(rule 42):動 CI/打包先讀前作會動的 `.github/workflows` 與 `scripts/` 照抄 proven values。
- CJK hi-res canvas、靜態溯源、feedback loop。

## 風險 / 開放問題

- **繪字路徑**(階段 3)是最大不確定:FM-Towns 的 CJK 走 SJIS ROM 字型,要嘛改該路徑吃 Big5、要嘛走 `ZH_CHN`。Zak FM-Towns 前例(`zak-fmtowns-zhtw`)用 ZH_CHN 12×12 GBK + GBK 0x5C escape,可能直接適用。
- v3 LFL 抽字若 scummtr 不順,需自寫 parser(v3 編碼與 v5 不同)。
