# 美術進度

loop 自己的美術待辦（不是給 Jacky 的需求單）。來源優先順序：Jacky 放進 `art-inbox/` 的 → Tripo 佇列的產物（`art-inbox/tripo/`）→ 授權明確的 CC0 套件（`art-inbox/props/`）→ 程式生成。做的順序在 `docs/NEXT.md`。

## Jacky 定下的方向

- 畫風：**漫畫風，帥氣、漂亮、可愛**；人物吃場景的光。標準在 `ART_QUALITY_BAR.md`。
- 人物正常動漫比例：主角約 5.5～6 頭身；莉莉絲、雷歐約 7.5 頭身（Jacky 11/14：不用重產）。接的時候用 `--height` 把身高拉齊。
- 冒險者服裝從 **F 級破舊** 到 **S 級華麗**；之後的等級再用 Tripo 產，或用 bpy 在 F 級模型上加護甲、換配色。
- **武器可換、男主角不拿燈籠**：角色是空手模型，武器是獨立模型，掛在手骨上。
- 場景：Tripo 只做有劇情意義的重點物件；地形、牆、地板用 CC0 套件或程式做；光、霧、色彩在 Godot 裡做。

## 模型（都在 `art-inbox/tripo/<id>/`；2026-11-14 產完）

| 類別 | id | 接進遊戲了嗎 |
|---|---|---|
| 主角 | `noen_rank_f_v2`（諾恩）、`sheila_rank_f`（席菈） | **都在遊戲裡**（`PlayerController`、`Sera`） |
| 人物（mixamo 骨架） | `leo`、`leo_party_mage`、`leo_party_tank` | **在遊戲裡**（廢棄祭壇：倒在地上的雷歐小隊；遊戲裡的 id 是 `leo`、`leo_mage`、`leo_tank`） |
| 人物（mixamo 骨架） | `lilith`、`royal_inspector`、`guild_adventurer_a`、`guild_adventurer_b` | **在遊戲裡**（公會大廳：櫃檯的莉莉絲、兩個冒險者、結尾二樓的巡察官） |
| 人物（mixamo 骨架） | `black_market_merchant` | **在遊戲裡**（11/18：公會大廳角落坐著喝酒的客人；⑤ 城鎮的黑市商人也是他） |
| 人物（mixamo 骨架） | `guild_patron_a`～`c`（老練的矮壯冒險者、見習魔法師、斥候） | **11/18 排進佇列、還沒產**（約 165 點）：公會大廳坐著的客人，`GuildHall.PATRONS` 的位子已經留好 |
| 怪物 | `enemy_poison_slime`、`enemy_mold_slime`、`enemy_miasma_wolf`（四足骨架＋走路）、`enemy_spore_treant`（雙足骨架） | **都在遊戲裡**（`Slime`、`MoldSlime`、`MiasmaWolf`、`SporeTreant`） |
| 怪物 | `boss_plague_golem`（雙足骨架；48140 面，收件檢查的上限另外開到 52000） | **在遊戲裡**（`PlagueGolem`，3.6 m） |
| 武器 | `weapon_rusty_miasma_sword`、`weapon_alchemy_crossbow`、`weapon_ominous_split_blade` | **在遊戲裡**（諾恩右手的兩把、席菈右手） |
| 武器 | `weapon_longsword`、`weapon_shortsword`、`weapon_axe`、`weapon_hammer`、`weapon_bow`、`weapon_staff`（都已擺正） | 還沒 |
| 森林 | `prop_corrupt_tree`、`prop_glow_toxic_mushroom`、`prop_rotten_fruit_bush`、`prop_campfire_v2`、`prop_cursed_chest`、`prop_poison_vent`（只留底座）、`prop_paralysis_web_v2` | **都在遊戲裡**（腐敗之森） |
| 祭壇 | `prop_ruined_altar`（顏色貼圖是灰的：顏色用 `ruin_stone.gdshader` 照形狀算，不重產） | **在遊戲裡**（廢棄祭壇，放大 1.7 倍） |
| 飾品 | `prop_cursed_ring`（還沒擺正） | 還沒（⑤） |
| 公會 | `prop_guild_counter_v2`、`prop_aptitude_crystal`、`prop_guild_quest_board`、`prop_guild_signboard` | **都在遊戲裡**（公會大廳；四件的顏色貼圖都有顏色。櫃檯長 1.78 m，遊戲裡把長邊拉成 1.45 倍接上兩邊的矮櫃） |

- 「已擺正」＝寫在 `scripts/gen_props.sh` 的 `ARGS` 裡，建置時會出現在 `game/assets/props/tripo/`，可以直接 `PropModels.instance("tripo/<id>")`。
- `prop_poison_vent` 的毒煙是實心模型、還帶兩顆眼睛：只取底座（`tripo_prop.py --keep-below`），煙用粒子＋`PoisonMist`。底座很扁，在遊戲裡幾乎被霧蓋住——之後要好看可以重產一個只有石頭與裂縫的（約 20 點），不急。
- **顏色貼圖是灰的**（預覽圖有顏色、模型的貼圖沒有；11/15 掃過全部）：`prop_glow_toxic_mushroom`（已經在遊戲裡，顏色改用 `glow_mushroom.gdshader` 照形狀算，不重產）、`prop_ruined_altar`（11/16 接了，一樣用 shader 算：`ruin_stone.gdshader`——藍灰的石塊、苔、會亮的符文；沒有重產）。其他的貼圖都有顏色。
- **Quaternius 的 CC0 小物**（`art-inbox/props/`）第一次用進遊戲（公會大廳）：長桌、長凳、凳子、木桶、木箱、吊燈、壁燈、旗子、書櫃、矮櫃、杯盤、武器架、盾、瓶子、書——清單是 `scripts/gen_props.sh` 的 `QUAT`。11/18 加了森林營火旁的布袋、皮袋、木桶。
- 沒用到的在 `art-inbox/tripo/_unused/`（那裡有 README）；不刪。
- 點數：第一批約 500、第二批 1015；餘額約 1985（≈19.85 美元）。11/18 排了三個客人（約 165 點，還沒產）。預算上限 100 美元。

## 之後可能要排的

席菈腰間的藥瓶與燒焦痕跡（先試 bpy 改）、D／B／S 級服裝、更多森林怪、城鎮的招牌與攤位。排之前先確認 CC0 套件裡沒有。

## 模型規格（收件檢查 `scripts/check_character_glb.py`）

- `.glb`、Y 朝上、公尺、面向 −Z、原點在腳底；人物有骨架與蒙皮，15k～40k 三角面。
- 材質要有 BaseColor、Normal、ORM，貼圖內嵌；動作名稱照 `game/src/world/character_models.gd` 的 `ANIM_MAP`。
- 全年齡、不裸露；不用其他作品的角色、名字、美術；AI 生成的記進 CREDITS 並列入 Steam 申報。
