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
| `autoload/game.gd` | 持有 `GameSession`；新遊戲／繼續／切關卡／對話／倒下重試／打擊停頓。關卡表 `LEVELS`、檢查點對關卡 `CHECKPOINT_LEVELS` |
| `autoload/settings.gd`、`perf.gd` | 設定（音量、畫質、難度、語言、按鍵）；效能 overlay（F3） |
| `src/core/game_state.gd`、`save_codec.gd`、`game_session.gd` | 可存檔的狀態；JSON＋版本號＋`.bak` 回復；一局遊戲（任務、自動存檔、重試） |
| `src/core/story_logic.gd`、`quest_db.gd`、`quest_runner.gd`、`dialogue_db.gd`、`dialogue_runner.gd` | 條件與效果、任務與對話的資料驗證與推進 |
| `src/core/status_rules.gd`、`status_effects.gd`、`reversal_cue.gd`、`potion_belt.gd`、`mist_zone.gd` | 異常狀態（`reverses`＝這個人身上的全部反轉，只有諾恩是）、反轉回饋的時間軸（紫紅 → 碎裂 → 金光；畫面、圖示、聲音都照它）、身上的藥、狀態區（瘴氣）的規則 |
| `src/core/health.gd`、`combat_tuning.gd`、`enemy_brain.gd`、`sera_brain.gd` | 生命、戰鬥數值（`data/combat/tuning.json`，F5 重讀、`user://tuning.json` 可覆寫）、敵人狀態機、席菈要做什麼（跟隨距離、射藥節奏、玩家要藥與裝填、結伴前在瘴氣前面來回的節奏） |
| `src/core/input_setup.gd`、`sfx.gd`、`ambience.gd`、`footsteps.gd`、`quality_preset.gd`、`frame_stats.gd`、`benchmark_run.gd` | 按鍵、音效、環境音與配樂、腳步、畫質三級、效能統計 |
| `src/ui/` | 字型與主題、按鍵圖示（`GlyphLine`、`PadGlyph`）、狀態列（`StatusHud`，圖示會翻面）、反轉的畫面那一層（`ReversalOverlay`＋`reversal_overlay.gdshader`）、藥劑格、目標指引、章節卡（`ChapterCard`，還沒用到）、設定頁的小元件 |
| `src/world/` | `CharacterModels`／`PropModels`（模型載入，找不到回傳 null）、`ContactShadow`、`CameraFade`、`HealMotes`、`PoisonBurst`、`ParticleLook`、`SlashTrail`＋`slash_trail.gdshader`（揮劍的劍光：跟著劍的帶子，每一段過了壽命就消失）、`SlashMark`＋`slash_mark.gdshader`（砍中的刀痕：`EnemyActor._hit_fx` 在傷害的 `info` 帶著 `cut` 時生一道）、`TalkCamera`（對話時的鏡頭：看著正在講話的人，講完滑回玩家的鏡頭；滑的路上繞開人的頭）、`GrassTufts`（一整片草叢，一個 MultiMesh）、`forest_ground.gdshader`（森林的地面：苔／土／落葉、路與空地、樹腳下的苔）、`glow_mushroom.gdshader`（夜光毒蕈的顏色：照形狀算，模型的顏色貼圖是灰的）、`brace_glow.gdshader`（蓋在身體上的一圈加法光：硬撐的紅光、史萊姆的綠邊）、毒霧與接地陰影的 shader |
| `scenes/boot/` | 標題畫面 |
| `scenes/levels/story_level.gd`、`corrupt_forest.gd/.tscn` | 關卡基底；腐敗之森入口（建場景＋設劇情旗標） |
| `scenes/actors/player/` | `PlayerController`：移動、過肩鏡頭、鎖定、閃避、出手、釋放、手上的劍、劍光與揮劍聲（`_update_trail`） |
| `scenes/actors/puppet/` | `Puppet`：有模型就播模型的動作，沒有就用程式拼的人偶（同一套介面：`set_move_speed`、`play_action("dodge"／"attack"／"shoot")`、`hand()`） |
| `scenes/actors/sera/` | `Sera`（席菈：結伴前等在原地——關卡設了 `hesitate_at` 就在它前面走近幾步又退回來、走路、轉身、舉弩、右手的手弩、靠近瘴氣戴的防毒面具）、`SeraVial`（飛向諾恩的藥瓶，落地套用狀態來源；來源寫 `color` 換顏色、寫 `smoke` 砸開時腳邊冒一圈貼地的煙） |
| `scenes/actors/enemy/enemy_actor.gd`、`scenes/actors/slime/` | 敵人共用（追人、受擊、硬撐、跪地、倒下）；劇毒史萊姆 |
| `scenes/world/poison_mist.gd` | 瘴氣／毒霧的節點（`MistZone`＋霧盤＋體積霧） |
| `scenes/ui/` | `Hud`（目標、橫幅、存檔提示）、`CombatHud`（生命條）、對話框、暫停、設定、按鍵設定、互動提示 |
| `scenes/bench/` | `--benchmark`：鏡頭飛過關卡、把統計寫到 `user://benchmark/` |
| `data/` | `quests/`、`dialogue/`（`ch1_forest_gate`、`ch1_after_slimes`）、`status/statuses.json`、`combat/tuning.json` |
| `tests/` | 自製測試框架（`framework/test_case.gd`）；`unit/`、`flow/test_chapter1.gd`（新遊戲 → 一個人走進來 → 席菈在瘴氣前面來回一輪 → 遇到她、結伴 → 她戴面具 → 瘴氣 → 對話 → 席菈跟隨 → 對話的鏡頭先拍她、換諾恩講就切過去、講完還給玩家 → 拿錯的那一瓶 → 清場要幾幀、幾刀（超頻要一刀一隻）→ 戰後對話的兩個回答 → 讀檔） |

**加東西的做法**

- 新關卡：繼承 `StoryLevel`、場景裡放 `Spawn`／`Player`／`Hud`／`PauseMenu`／`DialogueBox`，在 `Game.LEVELS` 與 `CHECKPOINT_LEVELS` 登記；劇情只透過 `Game.session.set_flag()` 推進任務。
- 新的對話角色：關卡在 `TalkCamera.cast` 登記「說話者的翻譯 key → 那個角色」（看 `CorruptForest._spawn_sera`；同一個人有兩個名字就登記兩筆，例：還沒自我介紹的 `SPK_UNKNOWN`）。沒登記的說話者鏡頭不動。角色有 `talk_to(位置)` 的話，對話開始時會被叫去面向對方。
- 任務階段的操作提示：階段加 `"hint": "<翻譯 key>"`，字裡的 `{attack}`、`{dodge}` 這類動作名（`InputSetup.ACTION_KEYS`）與 `{move}`、`{look}` 會換成現在裝置的按鍵（`Hud._refresh_hint`）。
- 會走路的角色要腳步聲：接 `Puppet.footfall`（腳落地的那一刻）呼叫 `Footsteps.stomp()`，不要照距離算（看 `PlayerController`）。
- 新敵人：繼承 `EnemyActor`，覆寫 `tuning_id()`、`_build_body()`、`_on_strike()`，數值加在 `tuning.json`（看 `Slime`）。森林裡有毒的敵人照 `Slime._add_glow()` 加螢光綠的邊與腳下的燈（D-288；邊掛在材質的 `next_pass`，`material_overlay` 留給硬撐的紅光）。
- 新角色模型：`scripts/gen_art.sh` 的 `SRC`／`ARGS` 加一行、`scripts/import_characters.py` 的 `KNOWN` 加 id，場景裡 `Puppet.character_id = "<id>"`。
- 出手的動作：`tools/blender/common.py` 的 `standard_actions` 裡三段 `swing(拉開, 砍到, 帶過去, 踏幾步)`（`light_attack_01～03`；右手是 `(hang, swing, elbow[, turn])`，橫掃要手臂抬到肩膀高再 `turn`）。遊戲的命中判定在出手後 0.19 秒，劍要在 `T_HIT` 之前砍到位。**劍要在身體右邊或頭上揮、劍身橫對著鏡頭**（D-284）。改的流程：先量再拍——寫一個暫時的測試（照 `test_slash_trail.gd` 最後一個的寫法取每一幀的手與劍尖），投到假的過肩鏡頭（身體座標：後 3.4、高 2.1、右 0.5 m，看前面 2 m）算劍光帶子在畫面上的面積，`ART_ONLY=noen scripts/gen_art.sh && python3 -P scripts/import_characters.py`、import、跑那個測試，一輪 11 秒；數字過了才用 `--joined --at=0,-5 --burst-on=combo`（`BURST_EVERY=4 BURST_COUNT=24`）連拍，從 `build/burst/.burst-<名字>/f-N.png` 原尺寸裁出諾恩看（240 px 的小圖看不出好壞）。`Puppet.attack_variant` 選第幾段，模型沒有那一段就播第一段。
- 新的人物動作：`tools/blender/common.py` 的 `standard_actions` 加一段（每個角色都會有）、`CharacterModels.ANIM_MAP` 與 `Puppet.ACTION_TIME`／`STATES` 加名字、程式人偶補一個最簡單的姿勢（看 `shoot`）。
- 新物件／武器模型：`scripts/gen_props.sh` 的 `ARGS` 加一行 → `PropModels.instance("tripo/<名字>")`（記得寫檔案不在時的替身）。模型自帶一圈亮色草皮底座的（樹）加 `--moss-below <高度> --sink <公尺>`：草皮改塗成地面的苔色、底座邊緣埋進地面；苔色在 `tripo_prop.py` 的 `MOSS` 與 `forest_ground.gdshader` 的 `moss`，兩邊要一樣。 **Tripo 的模型接進來先看顏色貼圖是不是灰的**（預覽圖有顏色、模型沒有的情況發生過兩次：夜光毒蕈、祭壇）：是的話用 shader 照形狀上色（看 `CorruptForest._paint_mushroom`）或重產。會發光、旁邊又掛一盞燈的小物：模型放 `GLOW_PROP_LAYER`、燈的 `light_cull_mask` 不照那一層，不然近看被自己的燈打成一片白。
- 存檔格式要改：`SaveCodec.CURRENT_VERSION` +1、加遷移、加一個從舊 JSON 讀起的測試（現在 v4；看 `test_save.gd` 的 v3 → v4）。
- 新狀態：`statuses.json` 加一筆（種類 dot／action／guard／bleed／aim；要會疊就寫 `stack_max`）＋翻譯 key＋`StatusHud._draw` 的圖示；一樣東西要帶兩種狀態就在來源寫 `also`。反轉的回饋不用接。
- 席菈的藥：來源寫在 `statuses.json` 的 `sources`（要別的顏色就寫 `color`，沒寫是紫的）。她自己射的是 `Sera.vial_source`（關卡可以換），玩家按鍵要的是 `Sera.ASK_SOURCE`；什麼時候可以要由關卡開（`Sera.ask_enabled`），她答不答應接 `Sera.asked`。
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
- `scripts/gen_sfx.py` 還會產幾個沒在用的音效（市場底噪、「待續」配樂等）。
- `tools/blender/common.py` 裡有以前自製人體用的函式，現在只有 `tripo_character.py` 在用它的動作部分。

## 開發工具

| 指令 | 用途 |
|---|---|
| `scripts/check.sh`（已經產過素材時約半分鐘；乾淨的機器第一次要下載 Godot、裝 bpy、轉模型，約 5 分鐘） | 產生素材 → import 兩次 → 全部測試；有 `SCRIPT ERROR` 就算失敗。`--export` 再匯出 |
| `TEST_FILTER=chapter1 <godot> --headless --path game -s res://tests/run_tests.gd` | 只跑檔名含這段字的測試 |
| `scripts/screenshot.sh <out.png> <幀數> [旗標…]` | 用 xvfb＋軟體 Vulkan 截一張。先 `apt-get update && apt-get install -y xvfb mesa-vulkan-drivers`；每個 session 第一張常逾時，先拍一張丟掉；幀數超過一百多也會逾時（沒有固定幀率，軟體算圖太慢）——進場幾秒之後的畫面改用 `BURST_LAZY=1 scripts/burst.sh`，單張在 `build/burst/.burst-<名字>/f-N.png` |
| `scripts/shots.sh forest [--save-baseline]` | 固定鏡頭組（`scripts/shots/forest.txt`），印跟基準的差異數字、拼對照圖 |
| `scripts/burst.sh <out.png> <從第幾幀> [旗標…]` | 連拍 8 張拼一張：會動的東西（出手、受擊）用這個驗收 |
| `scripts/gen_art.sh`、`gen_props.sh` | 用 bpy 把 `art-inbox/tripo/` 的模型轉成遊戲用的（`gen-assets.sh` 會叫） |

遊戲的命令列旗標（放在 `--` 之後）：`--level=corrupt_forest`（直接開新遊戲進關卡，存檔寫到 `user://saves_dev`）、`--cam-yaw=90|180`（鏡頭繞到諾恩側面／正面）、`--hold=move_right,sprint`（一直按住這些動作：連拍走路、跑步用；`move_right` 配預設鏡頭剛好是側面）、`--tap=attack`（一直連按：出手要「剛按下去」才算，`--hold` 只會砍一刀）、`--at=x,z`（把諾恩放到別的地方，例：空地前面 `--at=0,-5`；`--at=0,19.5` 是站在 10 m 外看還沒結伴的席菈來回，`BURST_LAZY=1 BURST_COUNT=6 BURST_EVERY=50` 從第 12 幀拍剛好一輪）、`--joined`（直接從結伴之後開始，席菈在旁邊；不加的話她等在瘴氣前面、不跟不射）、`--burst-on=reversal`（進場 1.5 秒後讓諾恩中毒並從那一刻開始連拍；`--burst-on=combo` 是連砍三下，`BURST_EVERY=4 BURST_COUNT=24` 剛好三下各 8 格；`scripts/burst.sh` 的起始幀填很大的數字、`BURST_CROP="0,0,1,1"` 看整個畫面）、`--joined --burst-on=ask`（玩家向席菈要一瓶致盲煙霧彈：舉弩 36 幀＋飛 33 幀＋反轉 18 幀，`BURST_EVERY=14` 八格剛好拍完；`BURST_EVERY=20` 的最後幾格是狀態列翻成金色之後）、`--joined --burst-on=vial`（改成讓席菈射一瓶：舉弩 0.6 秒＋飛 0.55 秒，`BURST_EVERY=10` 以上才拍得到落地；加 `--cam-yaw=90`、`BURST_CROP="0.5,0.3,0.78,0.82"` 是她的側面近拍）、`--joined --at=0,-12 --tap=attack --burst-on=hit`（真的打一場，從第一次砍中史萊姆的那一刻開始拍：看刀痕、命中的閃光；不加 `--joined` 會先跳相遇的對話、諾恩不出手；要拍後面幾刀就不加 `--burst-on`、`--burst-from` 填 100 左右）、`--talk-skip=N`（對話一開始先按掉 N 句：拍第 N+1 句的鏡位。相遇那一段 `--at=-0.3,12.2`，`--talk-skip=1` 是諾恩的那一句、`3` 是選項；瘴氣裡那一段 `--joined --at=0,3`，要等反轉演完，用 `BURST_LAZY=1 BURST_COUNT=2 BURST_EVERY=20 BURST_CROP="0,0,1,1" scripts/burst.sh <out> 130 …`）、`--open=pause|settings|controls`、`--locale=zh_TW|en`、`--quality=0..2`、`--perf`、`--benchmark`、`--screenshot=<png> --frames=<n>`。
