# 印第安納·瓊斯:最後聖戰 — 繁體中文化(進行中)

> *Indiana Jones and the Last Crusade*(LucasFilm Games, 1989/1990 FM-Towns 版)的繁體中文化專案。
> 與姊妹作 [亞特蘭提斯之謎](https://github.com/wicanr2/indiana-jones-and-the-fate-of-atlantis-cht) 同一套
> 「不改原版資料、改 ScummVM 在繪字處攔截 → 查表 → 點陣中文重畫」的 engine-overlay 手法。

**狀態:文本翻譯完成 + 引擎整合完成 —— 中文已在 ScummVM 正常顯示。** 動詞面板、物件名、句子列全中文(見下圖)。剩中文配音(加值)與三平台打包。完整技術背景見 [`CLAUDE.md`](CLAUDE.md);分階段規劃與關鍵修正見 [`PLAN.md`](PLAN.md)。

![中文動詞面板](screenshots/crusade_cht_verbs.png)

> 底部動詞:推 / 拉 / 給 · 開 / 關 / 看 · 走向 / 拿起 / 查看 · 使用 / 開啟 / 關閉 · 交談 / 旅行;句子列「走向 更衣室」。FM-Towns 版,GBK 12×12 點陣字,走 ScummVM `CharsetRendererV3` + `TownsV3` 中文路徑。

## 與前作（亞特蘭提斯）的關鍵不同

| | 亞特蘭提斯(已完成) | 最後聖戰(本作) |
|---|---|---|
| SCUMM 版本 | v5(`ATLANTIS.001` 容器) | **v3**(`NN.LFL` 資源) |
| 平台版本 | DOS CD talkie | **FM-Towns CD**(.bin/.cue,Jp-En) |
| 語音 | 有(重導既有語音 5552 點) | 原版**無語音** → 字幕為主;**中文 TTS 配音為加值新功能**(無中生有,非重導,見 PLAN) |
| 音樂 | iMUSE | **Red Book CD 音軌**(ScummVM 自放) |
| 繪字路徑 | v5/v7 `ZH_TWN` Big5 | **FM-Towns SJIS / `ZH_CHN` 路徑(待定)** |

最關鍵的技術前例不是亞特蘭提斯,是**同類**(SCUMM v3 + FM-Towns)的 **Zak McKracken FM-Towns 繁中化**(本機 `~/zak-cht`,已完成可玩):scummtr 抽字 + `scummvm-zhtw.patch`(CharsetRendererV3/TownsV3 + `chinese_gb16x12.fnt` 12×12 GBK)+ encode-gbk。最後聖戰主要工作 = 把該 patch 的 `GID_ZAK` 條件擴到 `GID_INDY3`。

## 版權

本 repo 只含工具、patch、翻譯表與文件。**原版 CD 映像 / 遊戲資料 / 字型一律不入庫**(見 `.gitignore`),請自備合法版本。
