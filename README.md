# 印第安納·瓊斯:最後聖戰 — 繁體中文化(進行中)

> *Indiana Jones and the Last Crusade*(LucasFilm Games, 1989/1990 FM-Towns 版)的繁體中文化專案。
> 與姊妹作 [亞特蘭提斯之謎](https://github.com/wicanr2/indiana-jones-and-the-fate-of-atlantis-cht) 同一套
> 「不改原版資料、改 ScummVM 在繪字處攔截 → 查表 → 點陣中文重畫」的 engine-overlay 手法。

**狀態:剛起步(已偵察素材,尚未開工)。** 完整技術背景與起手式見 [`CLAUDE.md`](CLAUDE.md);分階段規劃見 [`PLAN.md`](PLAN.md)。

## 與前作（亞特蘭提斯）的關鍵不同

| | 亞特蘭提斯(已完成) | 最後聖戰(本作) |
|---|---|---|
| SCUMM 版本 | v5(`ATLANTIS.001` 容器) | **v3**(`NN.LFL` 資源) |
| 平台版本 | DOS CD talkie | **FM-Towns CD**(.bin/.cue,Jp-En) |
| 語音 | 有(中文配音 5552 點) | **無語音 → 純字幕中文化** |
| 音樂 | iMUSE | **Red Book CD 音軌**(ScummVM 自放) |
| 繪字路徑 | v5/v7 `ZH_TWN` Big5 | **FM-Towns SJIS / `ZH_CHN` 路徑(待定)** |

最像的技術前例不是亞特蘭提斯,是 FM-Towns 的 [Zak McKracken 繁中化](https://github.com/wicanr2)(`zak-fmtowns-zhtw`)。

## 版權

本 repo 只含工具、patch、翻譯表與文件。**原版 CD 映像 / 遊戲資料 / 字型一律不入庫**(見 `.gitignore`),請自備合法版本。
