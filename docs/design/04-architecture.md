# 04　架構、程式地圖與開發工具

原則：**邏輯是純資料類別、場景只負責顯示**，所以雲端 session 沒有 GPU 也能用 headless 測試驗證大部分行為。2026-11-14 重新開始時只留了跟劇情無關的底層（D-273）；舊的東西在分支 `archive/pre-restart-2026-11-14`。

## 技術決定

- Godot 4.7.2 stable（標準版，版本固定在 `scripts/get-godot.sh`）、GDScript＋靜態型別（沒加型別視為錯誤）、不用 C#、Forward+。平台 Windows 64-bit；CI 順便匯出 Linux 跑 smoke test。
- 玩家看得到的字一律走翻譯 key（`game/i18n/strings.csv`，欄位 `keys,en,zh_TW`）；JSON 資料裡只放 key。
- 建置時產生的東西（字型子集、音效、轉好的模型）不進 git；什麼進 git 看 [`14-repo-and-assets.md`](14-repo-and-assets.md)。

## 程式地圖（`game/`）

| 位置 | 內容 |
|---|---|
| `autoload/app.gd` | 命令列旗標、截圖／連拍、輸入裝置切換、字型主題 |
| `autoload/game.gd` | 持有 `GameSession`；新遊戲／繼續／切關卡／對話／倒下重試／打擊停頓（`hit_stop(定格, 慢動作幾秒, 慢動作幾倍速)`；換關卡、重來、回標題會 `cancel_hit_stop()`）。關卡表 `LEVELS`、檢查點對關卡 `CHECKPOINT_LEVELS` |
| `autoload/settings.gd`、`perf.gd` | 設定（音量、畫質、難度、語言、按鍵）；效能 overlay（F3） |
| `src/core/game_state.gd`、`save_codec.gd`、`game_session.gd` | 可存檔的狀態；JSON＋版本號＋`.bak` 回復；一局遊戲（任務、自動存檔、重試） |
| `src/core/story_logic.gd`、`quest_db.gd`、`quest_runner.gd`、`dialogue_db.gd`、`dialogue_runner.gd` | 條件與效果、任務與對話的資料驗證與推進 |
| `src/core/status_rules.gd`、`status_effects.gd`、`reversal_cue.gd`、`potion_belt.gd`、`mist_zone.gd` | 異常狀態（`reverses`＝這個人身上的全部反轉，只有諾恩是）、反轉回饋的時間軸（紫紅 → 碎裂 → 金光；畫面、圖示、聲音都照它）、身上的藥、狀態區（瘴氣）的規則 |
| `src/core/golem_phases.gd` | Boss【深淵疫病魔像】這一場走到哪（平常 → 吼 → 狂暴 → 石化凝視 → 擋住了力竭／沒擋住再來一次）、生命的底線、「諾恩有沒有擋在魔像與席菈中間」的判定。純邏輯 |
| `src/core/health.gd`、`combat_tuning.gd`、`enemy_brain.gd`、`sera_brain.gd` | 生命（`min_hp`＝最低只能被打到多少：Boss 的核心還在時用）、戰鬥數值（`data/combat/tuning.json`，F5 重讀、`user://tuning.json` 可覆寫）、敵人狀態機、席菈要做什麼（跟隨距離、射藥節奏、玩家要藥與裝填、結伴前在瘴氣前面來回的節奏） |
| `src/core/input_setup.gd`、`sfx.gd`、`ambience.gd`、`footsteps.gd`、`quality_preset.gd`、`frame_stats.gd`、`benchmark_run.gd` | 按鍵、音效、環境音與配樂、腳步、畫質三級、效能統計 |
| `src/ui/` | 字型與主題、按鍵圖示（`GlyphLine`、`PadGlyph`）、狀態列（`StatusHud`，圖示會翻面）、反轉的畫面那一層（`ReversalOverlay`＋`reversal_overlay.gdshader`）、藥劑格、目標指引、Boss 的生命條（`BossBar`：畫面上方中間，場上有醒著的 Boss 才出現）、章節卡（`ChapterCard`：畫面淡成黑、兩行字、播完呼叫給它的函式——換關卡與「第一章　完」用）、設定頁的小元件 |
| `src/world/` | `CharacterModels`／`PropModels`（模型載入，找不到回傳 null）、`ContactShadow`、`CameraFade`、`HealMotes`、`PoisonBurst`、`ParticleLook`、`SlashTrail`＋`slash_trail.gdshader`（揮劍的劍光：跟著劍的帶子，每一段過了壽命就消失）、`SlashMark`＋`slash_mark.gdshader`（砍中的刀痕：`EnemyActor._hit_fx` 在傷害的 `info` 帶著 `cut` 時生一道）、`TalkCamera`（對話時的鏡頭：看著正在講話的人，講完滑回玩家的鏡頭；滑的路上繞開人的頭）、`GrassTufts`（一整片草叢，一個 MultiMesh）、`forest_ground.gdshader`（森林的地面：苔／土／落葉、路與空地、樹腳下的苔）、`glow_mushroom.gdshader`（夜光毒蕈的顏色：照形狀算，模型的顏色貼圖是灰的）、`brace_glow.gdshader`（蓋在身體上的一圈加法光：硬撐的紅光、史萊姆的綠邊）、`ruin_stone.gdshader`（祭壇與斷柱的石頭：苔、會亮的符文，顏色照形狀算——祭壇模型的顏色貼圖也是灰的）、`altar_ground.gdshader`（祭壇那一關的地面：外圍跟森林同一套土與苔，中間一圈一圈的石板）、`gaze_beam.gdshader`（石化凝視的前兆：地上那道光）、`guild_wood.gdshader`／`guild_wall.gdshader`／`guild_window.gdshader`（公會大廳：照世界座標畫的木板；畫著木骨架與護牆板的牆；自己發光的窗）、`golem_core.gdshader`＋`GolemCore`（拿得走的魔像核心：石球上裂著綠光＋一盞小燈；魔像倒地滾出來、戰後飛到諾恩肩上、結尾扛回公會都是這一顆，`carry_on()`）、`core_flare.gdshader`（還在魔像身上的核心與牠的眼睛：面向鏡頭的一片加法光，`open`＝一圈一圈往中心收的環）、`RockDebris`（飛出去的碎塊：有稜角的小石頭；`glow` 大於 0 是自己會亮的三角晶片）、`FinisherCamera`（收尾那一刀：直接切到兩人的側面、停幾秒、滑回玩家的鏡頭，用真實時間算）、毒霧與接地陰影的 shader |
| `scenes/boot/` | 標題畫面 |
| `scenes/levels/story_level.gd`、`corrupt_forest.gd/.tscn` | 關卡基底；腐敗之森（入口那一段的劇情：相遇、瘴氣、教學戰、戰後對話） |
| `scenes/levels/forest_map.gd`、`forest_scenery.gd`、`forest_explore.gd` | `ForestMap`：森林的地圖（空地、路、毒沼；純資料＋純函式，地面的遮罩 `trail_mask()`、走丟拉回來 `keep_inside()`）。`ForestScenery`：天空與光、地面、樹、草、孢子（只是場景）。`ForestExplore`：自由探索的東西與規則——可以採的毒蕈、三種陷阱、四群敵人（`PACKS`）、席菈的藥、營火、毒沼與寶箱、祭壇路口 |
| `scenes/levels/ruined_altar.gd/.tscn`、`altar_scenery.gd` | 廢棄祭壇（Boss 那一關）：`RuinedAltar` 放劇情（抵達的那段話、魔像醒來、狂暴時席菈退到後面裝禁藥、凝視擋住／沒擋住、禁藥砸中開核心、戰後那段話）與畫面上的字；`AltarScenery` 是看得到的場景（石板、斷柱、台階上的祭壇、外圍的樹；天空與霧沿用 `ForestScenery`） |
| `scenes/levels/guild_hall.gd/.tscn`、`guild_scenery.gd` | 公會大廳（第一章的開場與結尾；新遊戲從這裡開始）：`GuildHall` 放劇情（登錄、水晶警報的時間軸、雷歐、委託、席菈走過來、走出大門；結尾的那段話與「第一章　完」）；`GuildScenery` 是看得到的場景（第一個室內：牆、地板、窗與光、櫃檯那一排、水晶、佈告欄、桌椅、二樓迴廊；`evening`＝結尾的傍晚） |
| `scenes/actors/npc/npc.gd` | `Npc`：站在場景裡的人（莉莉絲、雷歐小隊、冒險者、巡察官）——站著、`face()` 轉過去、`walk_to()`／`walk_path()` 走過去（走到可以消失：`leave_on_arrival`）。不做決定，關卡叫他做什麼就做什麼 |
| `scenes/world/interactable.gd`、`web_trap.gd` | `Interactable`：走近按鍵互動的共用節點（發 `used`，要做什麼由關卡接）；`WebTrap`：麻痺蜘蛛網（碰到黏一次） |
| `scenes/actors/player/` | `PlayerController`：移動、過肩鏡頭、鎖定、閃避、出手、釋放、手上的劍、劍光與揮劍聲（`_update_trail`） |
| `scenes/actors/puppet/` | `Puppet`：有模型就播模型的動作，沒有就用程式拼的人偶（同一套介面：`set_move_speed`、`play_action("dodge"／"attack"／"shoot")`、`hand()`） |
| `scenes/actors/sera/` | `SeraChatter`（她跟 HUD 之間每一關都一樣的那幾句：要藥的回應、裝填的倒數那一行）、`Sera`（席菈：結伴前等在原地——關卡設了 `hesitate_at` 就在它前面走近幾步又退回來、走路、轉身、舉弩、右手的手弩、靠近瘴氣戴的防毒面具）、`SeraVial`（飛向諾恩的藥瓶，落地套用狀態來源；來源寫 `color` 換顏色、寫 `smoke` 砸開時腳邊冒一圈貼地的煙） |
| `scenes/actors/enemy/enemy_actor.gd`、`scenes/actors/slime/`、`wolf/`、`treant/` | 敵人共用（追人、受擊、硬撐、跪地、倒下、毒的螢光綠 `add_toxic_glow`）；劇毒史萊姆 `Slime` 與黴菌史萊姆 `MoldSlime`（子類別）；瘴氣狼 `MiasmaWolf`（四足模型＋走路的動作）；孢子樹人 `SporeTreant`（用 `Puppet`） |
| `scenes/actors/golem/plague_golem.gd`、`scenes/world/plague_aura.gd` | 【深淵疫病魔像】（`EnemyActor`＋`Puppet`：重拳、震地、吼、石化凝視與地上那道光、核心開了之後一刀粉碎、倒下）；演出也在這裡——被砍的那一下（`_on_cut`：頓一下、石屑、打不下去時核心閃一圈）、胸口的核心與眼睛那兩片光（`_update_flares`，位置 `core_point()`／`eye_point()`）、凝視打出去的那道光與掃過全場的一圈（`_gaze_fx`）、粉碎的碎片（`_shatter_fx`）、倒地之後核心滾出來（`_drop_core`，發 `core_dropped`）；往外擴的環共用 `_ring()`。牠身邊的疫病光環（`MistZone` 的規則＋波紋與光點） |
| `scenes/world/poison_mist.gd` | 瘴氣／毒霧的節點（`MistZone`＋霧盤＋體積霧；範圍大的把 `thickness` 調小，不然站在裡面整個畫面是一片紫） |
| `scenes/ui/` | `Hud`（目標、右上角的目標清單、橫幅、存檔提示）、`CombatHud`（生命條）、對話框、暫停、設定、按鍵設定、互動提示 |
| `scenes/bench/` | `--benchmark`：鏡頭飛過關卡、把統計寫到 `user://benchmark/` |
| `data/` | `quests/`、`dialogue/`（照劇情的順序：`ch1_guild_register`、`ch1_guild_leo`、`ch1_guild_quest`、`ch1_guild_sera`、`ch1_sera_joins`、`ch1_forest_gate`、`ch1_after_slimes`、`ch1_campfire`、`ch1_altar_arrive`、`ch1_altar_after`、`ch1_guild_return`）、`status/statuses.json`、`combat/tuning.json` |
| `tests/` | 自製測試框架（`framework/test_case.gd`）；`unit/`、`flow/test_chapter1.gd`（新遊戲 → 一個人走進來 → 席菈在瘴氣前面來回一輪 → 遇到她、結伴 → 她戴面具 → 瘴氣 → 對話 → 席菈跟隨 → 對話的鏡頭先拍她、換諾恩講就切過去、講完還給玩家 → 拿錯的那一瓶 → 清場要幾幀、幾刀（超頻要一刀一隻）→ 戰後對話的兩個回答 → 讀檔 → 探索解鎖與目標清單 → 採毒蕈與存檔 → 三種陷阱 → 三種新敵人 → 營火與連攜 → 詛咒寶箱與裂刃 → 慘叫與祭壇路口；`test_walkthrough_from_new_game_to_the_end_of_chapter_one` 不設旗標從新遊戲的公會大廳一路走到「第一章　完」、回標題）；`flow/test_guild.gd`（公會大廳的每一拍：場景與人、登錄、警報與雷歐、委託與席菈、走出大門、讀檔、結尾與章節卡）；`flow/test_altar.gd`（祭壇那一關的每一拍：場景、抵達、光環、兩招與底線、站著一直砍要多久、凝視沒擋到、擋住 → 禁藥 → 粉碎核心 → 戰後、倒下重來與讀檔） |

**加東西的做法**

- 新關卡：繼承 `StoryLevel`、場景裡放 `Spawn`／`Player`／`Hud`／`PauseMenu`／`DialogueBox`，在 `Game.LEVELS` 與 `CHECKPOINT_LEVELS` 登記；劇情只透過 `Game.session.set_flag()` 推進任務。
- **劇情走到另一個關卡**：下一個任務階段的 `checkpoint` 在 `Game.CHECKPOINT_LEVELS` 登記成別的關卡；這一關設完旗標（任務推進、自動存檔）就叫 `Game.go_to_checkpoint_level()`。新關卡的 `_ready` 照任務階段決定從哪一拍開始（看 `RuinedAltar`）。測試把關卡直接掛在 root 底下，所以先 `Game.change_scenes = false`（只記下 `last_level_request`，不真的換場景）。
- **室內的關卡**（看 `GuildScenery`）：牆、天花板、門、窗都只做「朝屋裡的那一面」（`QuadMesh`，背面不畫）——過肩鏡頭退到牆外的時候看得進來，不會被推到諾恩背上。所以牆上的木柱、橫樑是畫在牆的 shader 裡的（做成盒子的話鏡頭在牆外會看到它們的背面）；屋裡獨立的東西（樑、迴廊、樓梯）才用盒子。牆與家具沒有鏡頭會撞的碰撞（第 1 層只有地板）：擋人的東西放在 `GuildScenery.PEOPLE_LAYER`，關卡讓諾恩與席菈多撞這一層（`collision_mask |= …`）。窗外沒有場景，天色就是玻璃的顏色；光從受光那一側的每扇窗各一盞聚光燈照進來。
- **場景裡站著的人**：`Npc.create(節點名, 角色 id, 位置, 面向的角度)`，要他走就 `walk_path([幾個點], 速度)`（直線走、不繞路，點自己排）。要他講話就在開始對話前把他放進 `TalkCamera.cast`——人多的關卡每一段對話重排一次（看 `GuildHall._talk`：第一個是諾恩，第二個是諾恩這一段面對的人）。
- **換關卡前播一張卡**：`ChapterCard.play(關卡, 小字的翻譯 key, 大字的翻譯 key, Game.go_to_checkpoint_level)`（結尾給 `Game.back_to_title`）。關卡留著那張卡（`card`），測試叫 `card.finish()` 就不用等。
- **Quaternius 的 CC0 小物**：`scripts/gen_props.sh` 最下面的 `QUAT` 加名字（建置時從 `art-inbox/props/` 連貼圖複製到 `game/assets/props/quaternius/`，不進 git）→ `PropModels.instance("quaternius/<名字>")`。掛在牆上的（`Lantern_Wall`、`Shield_Wooden`）從原點往 +Z 伸出來，旗子（`Banner_1`）的桿子往 +X。
- **這一關不能動手**：關卡設 `player.peaceful = true`（出手、釋放的按鍵沒有反應）。
- **Boss**：繼承 `EnemyActor`、加進 `"boss"` 群組（`BossBar` 會畫牠的生命條）；多招寫在 `tuning.json` 的 `<id>.moves`／`pattern`，`_on_strike()` 照 `brain.move_id` 判定。打到一半要演的事（吼、凝視）用 `_held()` 把狀態機停住；階段寫成純邏輯（看 `GolemPhases`），生命不能低於某個值用 `Health.min_hp`。
- **收尾的一刀要特寫**（看 `RuinedAltar._on_core_shattered`）：`Game.hit_stop(定格秒數, 慢動作秒數, 慢動作倍率)` 先定格再用慢動作演一段；同一刻 `FinisherCamera.play(關卡, 出手的人, 挨打的人, 停幾秒, 離多遠, 多高, 看多高[, 不算遮擋的碰撞體])` 切到兩人的側面，演完自己把鏡頭還給玩家（對話一開始也會馬上讓開）。畫面中間還有字的話先 `Hud.hide_center_lines()`。
- **飛出去的碎塊**：`RockDebris.burst(關卡, 位置, 方向, 幾塊, 多大, 顏色, 初速的範圍[, 自己多亮])`。**掛在關卡上的一次性特效**加進去的時候用 `add_child(節點, true)`：同名的會被編成 `名字2`、`名字3`（不加的話是 `@MeshInstance3D@123`，測試找不到）。
- **面向鏡頭的加法光片**（`core_flare.gdshader`）：shader 要寫 `fog_disabled`——不寫的話整片（連沒有光的四個角）都會加上一層霧的顏色，看得出是一塊方的；光片插在身體裡會被切碎，所以畫的時候往鏡頭拉近（`pull`）。位置不要用骨頭掛點自己的軸（每個模型不一樣；魔像的胸口掛點 −Z 是朝上），用掛點的位置＋`Puppet` 的方向；離骨頭多遠要從側面看過（魔像的核心第一版離胸口太遠，正面看不出來，側面看是浮在半空中的一顆球）。
- **倒在地上的人**（雷歐小隊）：站著的模型整個放倒（`Puppet` 繞 X 轉 ±90°），外面包一個節點、原點放在胸口；要他講話就在那個節點設 meta `TalkCamera.DROP_META`（比站著矮多少），對話鏡頭會跟著放低。
- **把一次性動作停在某一刻**（魔像舉著拳頭等在那裡）：`Puppet.hold_action("attack", 第幾秒)`，`release_hold()` 放開。
- **蓋在身上的一層光要在離開場景樹時拿掉**（`_exit_tree`）：材質是角色腳本的變數，角色被釋放時材質比身上的網格先沒，引擎會報「material is null」（諾恩霸體無敵的金光、席菈被石化的灰都遇過）。
- **森林裡加東西**（自由探索）：位置寫在 `ForestExplore` 最上面的常數——可以採的毒蕈 `MUSHROOM_SPOTS`、噴發口 `VENT_SPOTS`、蜘蛛網 `WEB_SPOTS`（x、z、張開的方向）、野果 `BUSH_SPOTS`、敵人 `PACKS`（一群一個名字，每一隻寫種類與位置；種類在 `_new_enemy`）。要加一塊空地或一條路改 `ForestMap.CLEARINGS`／`PATHS`（樹、草、地面的土路會自己跟著）。東西要加在關卡底下（`level.add_child`），目標指引才找得到。
- 走近按鍵的東西：`Interactable.create(節點名, 位置, 提示的翻譯 key[, 範圍])`，把模型加成它的子節點，接 `used`；不能用了設 `enabled = false`。提示的字裡 `{key}` 會換成按鍵。
- 右上角的目標清單：任務階段加 `"checklist": [{"text": 翻譯 key, "flag": 旗標, "need": 5}, {"text": …, "flag": …, "optional": true}]`（`QuestRunner.checklist`）。
- 任務階段沒變的時候要存檔（採到東西、休息）：`Game.session.autosave()`。重來的位置在 `ForestExplore.RESPAWNS`（旗標 `ch1.respawn`）。
- 新武器：`PlayerController.WEAPONS` 加一筆（模型、砍中時給自己的來源、傷害倍率的 tuning key），`player.equip(id)` 換（記在旗標 `noen.weapon`）。
- 新的對話角色：關卡在 `TalkCamera.cast` 登記「說話者的翻譯 key → 那個角色」（看 `CorruptForest._spawn_sera`；同一個人有兩個名字就登記兩筆，例：還沒自我介紹的 `SPK_UNKNOWN`）。沒登記的說話者鏡頭不動。角色有 `talk_to(位置)` 的話，對話開始時會被叫去面向對方。
- **測試不動玩家的設定檔**：測試中存的設定寫到 `user://settings_tests.cfg`（跑完刪掉）。2026-11-17 以前是存在真的 `user://settings.cfg`，跑完會留下 `auto_attack=false`、`locale=en`（同一台機器接著拍戰鬥，諾恩不會自己砍）——機器上留著舊版測試寫的設定檔的話，把 `~/.local/share/CursesTooUseful/settings.cfg` 刪掉再拍，或加 `--tap=attack`。
- **測試預設關掉自動攻擊**（`tests/run_tests.gd` 每個測試開始前都設 `Settings.auto_attack = false`——有的測試會重讀設定檔，把它讀回預設的「開」）：測試自己擺位置、自己叫諾恩出手；要測自動攻擊的測試自己打開。遊戲裡預設是開的——用開發旗標拍戰鬥時諾恩會自己砍。
- 操作提示有提到「按哪個鍵攻擊」的，另外加一句 `<翻譯 key>_AUTO`（自動攻擊開著時 `Hud.hint_key_now()` 會改用它；沒有這一句就照原本的）。
- 任務階段的操作提示：階段加 `"hint": "<翻譯 key>"`，字裡的 `{attack}`、`{dodge}` 這類動作名（`InputSetup.ACTION_KEYS`）與 `{move}`、`{look}` 會換成現在裝置的按鍵（`Hud._refresh_hint`）。
- 會走路的角色要腳步聲：接 `Puppet.footfall`（腳落地的那一刻）呼叫 `Footsteps.stomp()`，不要照距離算（看 `PlayerController`）。
- 新敵人：繼承 `EnemyActor`，覆寫 `tuning_id()`、`_build_body()`、`_on_strike()`，數值加在 `tuning.json`（看 `Slime`）。只是換模型、數值、撞到上的狀態：繼承 `Slime` 覆寫 `tuning_id()`／`model_name()`／`touch_source()`（看 `MoldSlime`）。森林裡有毒的敵人建好外型之後叫 `add_toxic_glow(外型)`（螢光綠的邊與腳下的燈，D-288；邊掛在材質的 `next_pass`，`material_overlay` 留給硬撐的紅光），蓄力時用 `_set_glow()` 調亮。四隻腳的覆寫 `_on_died()`（共用的「向前撲倒」會變成倒栽蔥，看 `MiasmaWolf`）。
- 敵人的模型：雙足、Tripo 的 mixamo 骨架 → 跟人物一樣走 `gen_art.sh`（加 `SRC`／`ARGS`、`import_characters.py` 的 `KNOWN`、`check_character_glb.py` 的 `BUDGETS`），遊戲裡用 `Puppet`（看 `SporeTreant`：走路照速度播、出手的第三段當下砸）。四足、Tripo 自己的骨架（`_anim.glb`）→ `gen_props.sh` 的 `QUADS` 加一行（`tools/blender/tripo_quadruped.py`：轉向、縮放、落地都放在外面多包的一層空物件上——骨架物件自己的位置與旋轉會被動作蓋掉），遊戲裡 `PropModels.instance` 之後找 `AnimationPlayer` 播 `walk`。
- 測試裡把敵人停住（`set_physics_process(false)`）要小心：停在前兆、出招那一格的敵人會一直佔著「同時只有一個人出手」的名額，別的敵人永遠不出手。要換下一隻就把前一隻打倒。存著敵人的陣列在牠們被釋放之後不能用有型別的迴圈變數走（`for e: EnemyActor in …` 會報錯），先 `is_instance_valid` 再轉型（看 `ForestExplore.pack_alive`）。
- 新角色模型：`scripts/gen_art.sh` 的 `SRC`／`ARGS` 加一行、`scripts/import_characters.py` 的 `KNOWN` 加 id，場景裡 `Puppet.character_id = "<id>"`。
- 出手的動作：`tools/blender/common.py` 的 `standard_actions` 裡三段 `swing(拉開, 砍到, 帶過去, 踏幾步)`（`light_attack_01～03`；右手是 `(hang, swing, elbow[, turn])`，橫掃要手臂抬到肩膀高再 `turn`）。遊戲的命中判定在出手後 0.19 秒，劍要在 `T_HIT` 之前砍到位。**劍要在身體右邊或頭上揮、劍身橫對著鏡頭**（D-284）。改的流程：先量再拍——寫一個暫時的測試（照 `test_slash_trail.gd` 最後一個的寫法取每一幀的手與劍尖），投到假的過肩鏡頭（身體座標：後 3.4、高 2.1、右 0.5 m，看前面 2 m）算劍光帶子在畫面上的面積，`ART_ONLY=noen scripts/gen_art.sh && python3 -P scripts/import_characters.py`、import、跑那個測試，一輪 11 秒；數字過了才用 `--joined --at=0,-5 --burst-on=combo`（`BURST_EVERY=4 BURST_COUNT=24`）連拍，從 `build/burst/.burst-<名字>/f-N.png` 原尺寸裁出諾恩看（240 px 的小圖看不出好壞）。`Puppet.attack_variant` 選第幾段，模型沒有那一段就播第一段。
- 新的人物動作：`tools/blender/common.py` 的 `standard_actions` 加一段（每個角色都會有）、`CharacterModels.ANIM_MAP` 與 `Puppet.ACTION_TIME`／`STATES` 加名字、程式人偶補一個最簡單的姿勢（看 `shoot`）。
- 新物件／武器模型：`scripts/gen_props.sh` 的 `ARGS` 加一行 → `PropModels.instance("tripo/<名字>")`（記得寫檔案不在時的替身）。只要模型下面那一截（噴發口只要底座）加 `--keep-below <高度比例>`。模型自帶一圈亮色草皮底座的（樹）加 `--moss-below <高度> --sink <公尺>`：草皮改塗成地面的苔色、底座邊緣埋進地面；苔色在 `tripo_prop.py` 的 `MOSS` 與 `forest_ground.gdshader` 的 `moss`，兩邊要一樣。 **Tripo 的模型接進來先看顏色貼圖是不是灰的**（預覽圖有顏色、模型沒有的情況發生過兩次：夜光毒蕈、祭壇）：是的話用 shader 照形狀上色（看 `ForestScenery.paint_mushroom`）或重產。會發光、旁邊又掛一盞燈的小物：模型放 `GLOW_PROP_LAYER`、燈的 `light_cull_mask` 不照那一層，不然近看被自己的燈打成一片白。
- 存檔格式要改：`SaveCodec.CURRENT_VERSION` +1、加遷移、加一個從舊 JSON 讀起的測試（現在 v6；看 `test_save.gd` 的 v5 → v6：主線後面接了新的階段時，把「做完」的舊存檔接回去。主線**前面**加階段不用遷移——半路上的存檔記的是階段的 id）。
- 主線前面加了新的一段時，後面的關卡要能直接進（開發旗標、測試）：關卡的 `_ready` 看到主線還停在前面的階段，就把前面的旗標都設起來（`GuildHall.skip_opening`，`CorruptForest` 與 `RuinedAltar.skip_to_altar` 都會叫）。
- 新狀態：`statuses.json` 加一筆（種類 dot／action／guard／bleed／aim；要會疊就寫 `stack_max`）＋翻譯 key＋`StatusHud._draw` 的圖示；一樣東西要帶兩種狀態就在來源寫 `also`。反轉的回饋不用接。
- 席菈的藥：來源寫在 `statuses.json` 的 `sources`（要別的顏色就寫 `color`，沒寫是紫的）。她自己射的是 `Sera.vial_source`（關卡可以換；給了 `vial_cycle` 就照順序輪流），玩家按鍵要的是 `Sera.ask_source`（預設 `ASK_SOURCE`）；射出去的那一刻發 `fired`；什麼時候可以要由關卡開（`Sera.ask_enabled`），她答不答應接 `Sera.asked`。
- 劇情演到某一拍才開放的操作，要在左上多寫一行提示：`Hud.set_extra_hint(翻譯 key[, 要填的字])`（任務階段的 `hint` 是整個階段固定的，寫不到；第二個參數填按鍵以外的東西，例：`{"sec": 7}` 對應字裡的 `{sec}`）。
- 換武器：劍光不用調——劍尖的位置從武器模型的外框算（`PlayerController.blade_tip`），顏色與大小在 `SlashTrail` 的常數，哪一段動作有劍光是 `PlayerController.TRAIL_WINDOW`。
- 刀痕的方向、顏色、大小是出手的人放在傷害的 `info` 裡的：`cut`（劍往哪裡掃，`PlayerController.blade_sweep()` 從劍光的取樣算）、`gold`、`heavy`。別的會砍人的東西（之後的同伴、Boss 的武器）要刀痕就帶 `cut`，不帶就沒有。
- 新的敵人不是人的體型時要改命中點：`EnemyActor._hit_height()`／`_hit_radius()`（預設是人的胸口 1.05 m；`Slime` 改成身體中間）——命中的閃光、碎屑、刀痕都生在那裡。
- 要貼著「這一幀的姿勢」的特效（劍光）：用 `Puppet.joint_now("hand_R")` 從骨架現算，並把自己的 `process_priority` 排在動畫後面；直接讀掛點節點的位置會慢一幀。
- 武器打中人時給自己的狀態：`PlayerController.on_hit_source` 填資料表的來源（現在是鏽劍的 `rusty_sword_cut`）；換武器就換這個。
- 關卡裡要有人喊一句（不停下遊戲）：`Hud.show_bark(講的人, 翻譯 key, 秒數, 名字的翻譯 key)`（給了名字，講的人不在畫面裡時會改放畫面下方「名字：台詞」）；要玩家選擇的才用對話（`Game.start_dialogue`），對話要改旗標寫在對話資料的 `do`。
- 量戰鬥的手感有沒有變：`test_chapter1.gd` 的 `_mash_until_clear`（像玩家那樣一直按出手，回傳清場要幾幀、`_mash_swings` 是出了幾刀；測試會印數字）。

## 還沒整理的舊東西（改到那個檔的時候順手清）

- `Puppet` 的程式人偶還帶著以前的躺、坐的姿勢；模型都到位之後可以把程式人偶縮成最簡單的替身。
- 部分註解還提到舊劇情的東西（霜橋、送葬者、守衛、提燈）。
- 標題畫面的背景還是舊的鐘樓剪影（`scenes/boot/title_fog.gdshader`）。
- `scripts/gen_sfx.py` 還會產幾個沒在用的音效（風雪、鐵器、刮擦）；市場底噪現在是公會大廳的人聲、「待續」配樂是「第一章　完」的配樂。
- `tools/blender/common.py` 裡有以前自製人體用的函式，現在只有 `tripo_character.py` 在用它的動作部分。

## 開發工具

| 指令 | 用途 |
|---|---|
| `scripts/check.sh`（已經產過素材時約一分半；乾淨的機器第一次要下載 Godot、裝 bpy、轉模型，約 5 分鐘） | 產生素材 → import 兩次 → 全部測試；有 `SCRIPT ERROR` 就算失敗。`--export` 再匯出 |
| `TEST_FILTER=chapter1 <godot> --headless --path game -s res://tests/run_tests.gd` | 只跑檔名含這段字的測試 |
| `scripts/screenshot.sh <out.png> <幀數> [旗標…]` | 用 xvfb＋軟體 Vulkan 截一張。先 `apt-get update && apt-get install -y xvfb mesa-vulkan-drivers`；每個 session 第一張常逾時，先拍一張丟掉；幀數超過一百多也會逾時（沒有固定幀率，軟體算圖太慢）——進場幾秒之後的畫面改用 `BURST_LAZY=1 scripts/burst.sh`，單張在 `build/burst/.burst-<名字>/f-N.png` |
| `scripts/shots.sh forest｜explore｜altar｜guild [--save-baseline]` | 固定鏡頭組（`scripts/shots/forest.txt`：森林口；`explore.txt`：自由探索的五個地方；`altar.txt`：祭壇三張；`guild.txt`：公會大廳六張），印跟基準的差異數字、拼對照圖 |
| `scripts/burst.sh <out.png> <從第幾幀> [旗標…]` | 連拍 8 張拼一張：會動的東西（出手、受擊）用這個驗收 |
| `scripts/gen_art.sh`、`gen_props.sh` | 用 bpy 把 `art-inbox/tripo/` 的模型轉成遊戲用的（`gen-assets.sh` 會叫）：人物與雙足的怪（`tripo_character.py`）、武器與物件（`tripo_prop.py`）、四足的怪（`tripo_quadruped.py`） |

**連拍很慢的原因**（11/16 量的）：軟體算圖底下，`BURST_LAZY=1` 沒畫的那些幀也要約半秒一幀（進場第 40 幀拍一張 28 秒、第 240 幀拍一張 122 秒）。要拍開場好幾秒之後才發生的事，先加開發旗標讓它早一點發生（祭壇的 `--phase2`、`--demo`），不要等。`scripts/burst.sh` 拼出來的小圖一格只有 240 px 寬：要看清楚就自己從 `.burst-<名字>/f-N.png` 挑幾張拼大一點的。

遊戲的命令列旗標（放在 `--` 之後）：`--level=guild_hall`（公會大廳的開場；`--registered` 登錄那段話講過了、`--after-leo` 雷歐走了、`--quest-taken` 接了委託、`--ready` 可以出發了、`--return` 結尾的傍晚；`--registered --demo=leo` 進場就摸水晶、雷歐直接站到旁邊開口，`--quest-taken --demo=sera` 席菈一開始就在幾步外，`--return --demo=end` 停在「第一章　完」；`--registered --at=2.0,-6.2 --burst-on=alarm` 連拍水晶的警報；這一關的 `--talk-skip=N` 遇到選項會選第一個，例：`--return --at=0.2,-2.2 --talk-skip=8` 是巡察官的那一句——六張固定鏡頭在 `scripts/shots/guild.txt`，CI 的盤點截圖也拍）、`--level=corrupt_forest`（直接開新遊戲進關卡、大廳的開場當成演過了，存檔寫到 `user://saves_dev`）、`--cam-yaw=90|180`（鏡頭繞到諾恩側面／正面）、`--hold=move_right,sprint`（一直按住這些動作：連拍走路、跑步用；`move_right` 配預設鏡頭剛好是側面）、`--tap=attack`（一直連按；`--hold=attack` 按住也會接著砍。自動攻擊預設開著，站在敵人旁邊不用這兩個也會砍）、`--at=x,z`（把諾恩放到別的地方，例：空地前面 `--at=0,-5`；`--at=0,19.5` 是站在 10 m 外看還沒結伴的席菈來回，`BURST_LAZY=1 BURST_COUNT=6 BURST_EVERY=50` 從第 12 幀拍剛好一輪）、`--joined`（直接從結伴之後開始，席菈在旁邊；不加的話她等在瘴氣前面、不跟不射）、`--explore`（直接從自由探索開始：教學戰與戰後那段話都過了；配 `--at` 去看後面的森林，例：陷阱林 `--at=0.5,-25`、營火 `--at=-22.3,-41.5`、狼徑 `--at=23.5,-38.5`、毒沼的寶箱 `--at=43.6,-65 --cam-yaw=-12`、樹人窪地 `--at=0,-57.5`——這五張就是 `scripts/shots.sh explore`，CI 的盤點截圖也拍）、`--weapon=split_blade`（直接拿另一把武器）、`--explore --scream`（再跳到採滿五朵、聽到慘叫之後；配 `--at=0,-74` 往北走幾步就換到祭壇那一關）、`--level=ruined_altar`（直接從剛走進祭壇開始；`--at=-1.5,15.6` 是走進來的全景、`--at=0,14.5` 一進場雷歐就開口——這兩張加開打的那一張就是 `scripts/shots.sh altar`，CI 的盤點截圖也拍）、`--level=ruined_altar --boss`（跳過抵達的那段話直接開打）、`--phase2`（魔像一醒來就只剩一半生命：馬上狂暴）、`--phase2 --burst-on=enrage|gaze|fire|chaos|shatter|down`（那一刻開始連拍：吼／凝視的前兆開始／凝視打出去／禁藥砸中／粉碎核心的那一刀／魔像倒下；有 `--burst-on` 或 `--demo` 時諾恩不會倒下、吼與狂暴縮短到一秒、第一次走進光環的那幾行字不出來）、`--boss --at=-2.9,0.1 --cam-yaw=39 --tap=attack --burst-on=hit`（魔像第一次被砍中的那一刻開始拍：`BURST_EVERY=3`；把 `--boss` 換成 `--floor` 是生命一開始就在底線——拍「打不下去」核心閃的那一圈）、`--phase2 --demo=miss --at=4,11 --burst-on=gaze`（沒擋到的那一次：前兆縮短成 1.2 秒、席菈直接放到後面；`BURST_EVERY=8 BURST_COUNT=14` 的第 9 格是打出去）、`--level=ruined_altar --after`（魔像已經倒了：進場一秒多戰後那段話開始；祭壇這一關也認 `--talk-skip=N`，例：`--after --talk-skip=1` 第 110 幀拍席菈的那一句）、`--phase2 --demo=block`（凝視的前兆中一直把諾恩放在那道光上、鏡頭斜斜地看著魔像，禁藥砸中就走過去砍：不用真的打就拍得到「擋住 → 禁藥 → 粉碎」；配 `--burst-on=fire` `BURST_EVERY=4`、或 `--burst-on=chaos` `BURST_EVERY=9 BURST_COUNT=42`——從核心亮起來、粉碎的定格與慢動作、側面的鏡頭、倒地、核心滾出來一直到鏡頭還給玩家，約 8 分鐘）、`--explore --burst-on=wolf|treant|mold`（那一種敵人第一次擺前兆的那一刻開始連拍；要站在牠附近，例：樹人 `--at=0.4,-60.6`）、`--explore --burst-on=chest|camp`（進場 1.2 秒後開寶箱／在營火休息，從那一刻開始拍；寶箱 `--at=44.6,-67.6`、營火 `--at=-21.8,-44.6`）——**用 `--burst-on` 的連拍一律加 `BURST_LAZY=1 BURST_TIMEOUT=240`**（不加會一幀一幀畫到觸發為止，超過兩百幀就逾時）、`--burst-on=reversal`（進場 1.5 秒後讓諾恩中毒並從那一刻開始連拍；`--burst-on=combo` 是連砍三下，`BURST_EVERY=4 BURST_COUNT=24` 剛好三下各 8 格；`scripts/burst.sh` 的起始幀填很大的數字、`BURST_CROP="0,0,1,1"` 看整個畫面）、`--joined --burst-on=ask`（玩家向席菈要一瓶致盲煙霧彈：舉弩 36 幀＋飛 33 幀＋反轉 18 幀，`BURST_EVERY=14` 八格剛好拍完；`BURST_EVERY=20` 的最後幾格是狀態列翻成金色之後）、`--joined --burst-on=vial`（改成讓席菈射一瓶：舉弩 0.6 秒＋飛 0.55 秒，`BURST_EVERY=10` 以上才拍得到落地；加 `--cam-yaw=90`、`BURST_CROP="0.5,0.3,0.78,0.82"` 是她的側面近拍）、`--joined --at=0,-12 --tap=attack --burst-on=hit`（真的打一場，從第一次砍中史萊姆的那一刻開始拍：看刀痕、命中的閃光；不加 `--joined` 會先跳相遇的對話、諾恩不出手；要拍後面幾刀就不加 `--burst-on`、`--burst-from` 填 100 左右）、`--talk-skip=N`（對話一開始先按掉 N 句：拍第 N+1 句的鏡位。相遇那一段 `--at=-0.3,12.2`，`--talk-skip=1` 是諾恩的那一句（這一段現在只有三句、沒有選項）；瘴氣裡那一段 `--joined --at=0,3`，要等反轉演完，用 `BURST_LAZY=1 BURST_COUNT=2 BURST_EVERY=20 BURST_CROP="0,0,1,1" scripts/burst.sh <out> 130 …`）、`--open=pause|settings|controls`、`--locale=zh_TW|en`、`--quality=0..2`、`--perf`、`--benchmark`、`--screenshot=<png> --frames=<n>`。
