# 角色配音卡司(靜態 descumm 講者分析 → 樣貌 → 對味聲線)

原則:**聲音配人樣**。每句台詞的講者 actor **不是靠玩遊戲收 CHTMAP**,而是用 descumm 反組譯
所有 SCUMM script,從 `print(N,[Text(...)])` / `printEgo` 直接讀出講者(rule 62 靜態溯源)。
工具:`tools/extract_speakers.py`(全量 key→actor)、`tools/identify_actors.py`(逐角色台詞+房間辨識)、
`tools/dub_cast.py`(套卡司 → per-actor manifest)、`tools/dub_cast_worker.py`(edge-tts dub)。

## 靜態抽取怎麼做

1. `scummrp -g indy3towns -o` 把 LFL 拆成 script 區塊(SC/LS/OC/EN/EX)。
2. descumm(自編,scummvm-tools)`-3 -n` 反組譯每個區塊。
3. `print(N,Text)` → actor N 說這句;`printEgo(Text)` → 印第。把 Text 的 GBK 位元組算 cht_key
   (同引擎 FNV-1a over GBK pairs)→ 得 (key→actor) 全量對照表。**驗證:1118/1121 key 對上配音 manifest(99.7%)**。

## 確認的 actor 號(全靜態,零玩遊戲)

| 角色 | actor | 樣貌 | 招牌台詞(辨識證據) | 聲線(edge-tts,皆合法) |
|---|---|---|---|---|
| **印第安納·瓊斯** | -1/1 | 呢帽皮夾克 | printEgo + print(1) 共 710 句 | `zh-CN-Yunxi` 通用 voice/(馬蓋先) |
| **亨利老爸** | **2** | 白鬍學究 | 「小子/兒子」不離口、「記住我的日記!那三道試煉!」 | `zh-TW-YunJhe` -14%/-18Hz(老成慢深) |
| **艾爾莎·施奈德** | **3** | 優雅金髮奧地利女 | 「我是艾爾莎·施奈德博士」「聖杯可以是我們的!」 | `zh-TW-HsiaoChen` -4%/-2Hz(成熟女聲) |
| **馬可斯·布洛迪** | **4** | 禿頂老紳士 | 「各位,跟我來,我認得路!」(經典迷路梗) | `zh-CN-Yunyang` -8%/-8Hz(溫厚迷糊) |
| **醉漢** | **5** | 酒館醉客 | 「我的麥酒喝光了」「我讓你看看誰醉了!」 | `zh-CN-Yunxia` -8%/+8Hz(卡通喜感) |
| **唐納文/城堡軍官** | **6** | 油頭名貴西裝 | 「很高興你決定合作」「元首見了一定大為高興!」 | `zh-HK-WanLung` -2%/-6Hz(港音洋派、奸滑) |
| **拳擊教練** | **9** | 健身教練 | 「要我怎麼陪你練拳?」 | `zh-CN-Yunjian` +0%/-4Hz(爽朗有勁) |
| **聖杯騎士** | **10@房86** | 七百歲殘破盔甲 | 「以騎士來說,你這身打扮真奇怪」 | `zh-TW-YunJhe` -18%/-20Hz(極慢極沉古老) |

## 重用的「情境 NPC 槽」(不是單一角色 → 走 npc/ 沉穩+變調)

- **actor 10**(168 句):跨房重用——學生/城堡管家/守衛/軍官全擠這槽。只有**房86=聖杯騎士**抽出專屬;其餘落 npc/。
- **actor 255**(45 句):旁白("十分鐘後^")、存檔系統訊息、學生、情境講者。**不配音**(多為畫面文字/UI)。
- **actor 254**:計分/章節標題("你的最終得分:")。**不配音**。
- **actor 11/7/8**:守衛/蓋世太保(「闖入者!」「別動!」)→ npc/。

> 引擎用 (actor, key) 查 `voice/a<actor>/<key>.voc`。key 是每句唯一雜湊,所以同一個 a10 槽裡,
> 騎士的 key 配蒼老聲、守衛的 key 落 npc/,**互不衝突**——這就是為什麼重用槽也能逐句正確配音。

## 引擎路由(三層)

`voice/a<actor>/<key>.voc`(專屬,8 角色 109 句)→ `voice/npc/<key>.voc`(雜魚 S3 沉穩 + per-actor ±6% 變調)
→ `voice/<key>.voc`(通用,印第馬蓋先)。F9 切 `voice_en/`(英配)。

## 配音覆蓋

- 專屬:a2=37/38、a3=18、a4=19、a5=20、a6=9、a9=4、a10=2 ≈ **109 句 / 7 角色**。
- npc 雜魚:1609 句(S3 + 變調)。通用印第:1715 句。voice_en 英配:1715 句。
