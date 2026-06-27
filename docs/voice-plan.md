# 配音規劃:分角色聲線 + 英文語音

引擎 hook(`Sound::playChtVoice`)已支援三件事,框架就緒:

1. **通用中文**:`voice/<key>.voc`(已完成,1715 句,印第單一聲線)。
2. **分角色**:`voice/a<actor>/<key>.voc` 優先,fallback 通用 `voice/<key>.voc`。`<actor>` = 引擎 `getTalkingActor()`。
3. **英文語音**:`_chtVoiceEn` 旗標 true 時改抓 `voice_en/`(同 key)。F 鍵切換(待接,比照 atlantis F9)。

## A. 印第聲線(馬蓋先味)— 待你選

`voice_audition/indy_macgyver/` 有 A–F 六變體(YunJhe / Yunxi / Yunjian × 不同 rate/pitch)。
選定後改 `scripts/dub_crusade.sh` 的 `DUB_VOICE/RATE/PITCH` 重 dub 全部。

## B. 分角色聲線 — 機制 + 待補的「誰說哪句」對照

**難點**:dub 是離線(文字→語音),但「哪個角色說哪句」要 runtime 才知道(`getTalkingActor()`)。
**解法(已內建)**:引擎 `scummvm -d3` 會對每句 dub 印 `CHTMAP <actor> <key>`。
- 流程:① 用 `-d3` 玩一輪(或讓玩家玩),收集 `CHTMAP` log → `(key→actor)` 對照。
  ② `tools/` 依 `(actor→聲線)` 設定,把該 actor 的 key 重 dub 到 `voice/a<actor>/`。
- 角色→聲線(初版建議):

  | 角色 | actor(待 CHTMAP 確認) | edge-tts 聲線 |
  |---|---|---|
  | 印第(主角) | 通用 `voice/` | zh-TW-YunJheNeural(馬蓋先,待選 A–F) |
  | 亨利(老爸) | ? | zh-TW-YunJheNeural 更沉(pitch 更低)或 CN 老嗓 |
  | 蘇格蘭管家/唐納文 | ? | zh-CN-YunjianNeural(沉) |
  | 艾爾莎(女) | ? | zh-TW-HsiaoChenNeural(女聲,借 FOA 蘇菲亞) |
  | 馬可斯 | ? | 偏老男聲 |
- 多數行是印第(看描述 + 自言自語)→ 通用 `voice/` 已覆蓋;分角色先做「亨利 / 艾爾莎 / 唐納文」幾個主要 NPC 即可見效。

## C. 英文語音 — 設計(聲線借 atlantis)

最後聖戰原版無語音 → 英文語音同樣是**自製 TTS**,念**英文原文**(`crusade_en.txt` 對應行)。
- key 仍由「顯示的中文字串」算(引擎只認顯示字串)→ `voice_en/<key>.voc` = 該行英文 TTS。
- F 鍵 `_chtVoiceEn` 切中/英語音(比照 atlantis F9,字幕仍中文 → 中字英配,或 F8 切英字)。
- **聲線借 FOA(atlantis)**:印第用成熟美音男聲(en-US-GuyNeural / en-US-DavisNeural,近 Doug Lee 味);NPC 分聲線同 B 的 actor 機制(`voice_en/a<actor>/`)。
- 管線:`tools/build_en_voice.py`(產英文 manifest:key⇄英文)+ `scripts/dub_crusade.sh DUB_LANG=en`(同 docker edge-tts,輸出 voice_en/)。

## 下一步順序

1. 你選 A–F 印第聲線 → 重 dub 通用中文。
2. `-d3` 收 CHTMAP → 建 (key→actor) → 分角色重 dub 主要 NPC。
3. 跑英文 dub 批次(voice_en/)→ 接 F 鍵切換中/英語音。
