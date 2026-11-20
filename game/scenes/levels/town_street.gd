class_name TownStreet
extends StoryLevel
## 公會門外的賒帳街（docs/story/chapter-1-expanded.md「自由時段 A」；第一章 ⑤）。
## 主線：替莉莉絲把空籃子送回藥房（小學徒與兩副防毒面具、店主的五只保溫杯、藥錢記在誰名下）→ 從東門出發，換到腐敗之森。
## 看得到的東西在 TownScenery；這裡放人、劇情與規則。劇情只透過 Game.session.set_flag() 推進。

const QUEST: String = "ch1_main"
const STAGE_BASKET: String = "deliver_basket"
const STAGE_GATE: String = "east_gate"
const TOWN_STAGES: PackedStringArray = [STAGE_BASKET, STAGE_GATE]
## 回程（增補稿「祭壇與回程」）：傍晚從東門回來，先把五朵夜光毒蕈交給藥房（對話 ch1_town_return：五只杯蓋亮起來、阿展把辭工單改成
## 「帶學徒認路」、盾／藥錢各一句），想的話去麵攤兌麵票（ch1_town_noodle_back），再走回公會大門換到大廳的結尾
const STAGE_RETURN: String = "return_pharmacy"
const FLAG_DELIVERED: String = "ch1.mushrooms_delivered"
const FLAG_RETURNED: String = "ch1.town_returned"
const FLAG_NOODLE_BACK: String = "ch1.noodle_redeemed"
const RETURN_DIALOGUE: String = "ch1_town_return"
const NOODLE_BACK_DIALOGUE: String = "ch1_town_noodle_back"
const RETURN_LIDS_LINE: String = "DLG_CH1_TRET_002"
## 交蕈那段話裡看得到的東西（_on_return_line）：諾恩開口的那一句把一籃毒蕈擱上櫃檯；阿展改辭工單的那一句把紙拿到眼前、
## 劃掉「獨自採集」、補寫「帶學徒認路」；店主的下一句（_005 開頭的三種）紙收起來；開收據的那一句給席菈的收據、她收進手套那一句收起來
const RETURN_BASKET_LINE: String = "DLG_CH1_TRET_001"
const RETURN_SLIP_LINE: String = "DLG_CH1_TRET_003"
const RETURN_SLIP_AWAY: String = "DLG_CH1_TRET_005"
const RETURN_RECEIPT_LINE: String = "DLG_CH1_TRET_006_RECEIPT"
const RETURN_RECEIPT_AWAY: String = "DLG_CH1_TRET_007_RECEIPT"
const RETURN_SLIP_LINES: PackedStringArray = ["AZHAN_SLIP_LINE_1", "AZHAN_SLIP_LINE_2", "AZHAN_SLIP_DUTY", "AZHAN_SLIP_ALONE"]
const SLIP_STRIKE_INDEX: int = 3
const SLIP_NEW_LINE: String = "AZHAN_SLIP_GUIDE"
## 紙拿到眼前之後多久劃掉、多久補寫（秒）；補寫的字是另一種墨色（左手寫的）
const SLIP_STRIKE_AFTER: float = 0.9
const SLIP_WRITE_AFTER: float = 1.5
const SLIP_NEW_INK: Color = Color(0.16, 0.26, 0.5)
const SLIP_PAPER: Color = Color(0.9, 0.88, 0.8)
const SLIP_INK: Color = Color(0.2, 0.18, 0.16)
const RECEIPT_LINES: PackedStringArray = ["RECEIPT_LINE_1", "RECEIPT_LINE_2"]
## 對話的鏡頭一起看的東西（TalkCamera.cast 的 key；"look" 寫這個）：櫃檯上那一排保溫杯
const CUPS_KEY: String = "TOWN_CUPS"
## 看杯子的那一句鏡頭站哪（街上、櫃檯西北邊斜斜往下看：杯子在中間、店主在右後面、籃子與阿展在左後面；
## 諾恩不管從哪一頭走過來都在鏡頭後面或畫面外——開始講話時他離櫃檯 2.6 m，比鏡頭遠）
const CUPS_CAMERA: Vector3 = TownScenery.PHARMACY_COUNTER + Vector3(-1.3, 1.9, -2.5)
## 回程一開始席菈站在諾恩的哪裡（他面向西、鏡頭在東邊：左後方，不貼在鏡頭前）
const SERA_RETURN_OFFSET: Vector3 = Vector3(0.7, 0, 1.6)
const AZHAN_KEY: String = RailEvent.AZHAN_KEY
const AZHAN_POS: Vector3 = TownScenery.PHARMACY_COUNTER + Vector3(1.9, 0, -0.5)
## 回程從東門裡面開始、朝西（yaw 90°）
const RETURN_ENTRANCE: Vector3 = Vector3(TownScenery.GATE_X - 4.0, 0.05, 0.0)
const RETURN_YAW_DEG: float = 90.0
## 走到公會大門這麼近就進去
const GUILD_ENTER_DIST: float = 2.4
## 櫃檯上的五只保溫杯（回程才擺出來）：杯蓋一個接一個亮，隔幾秒
const CUP_COUNT: int = 5
const CUP_LIGHT_EVERY: float = 0.35
## 杯蓋亮起來的顏色（夜光毒蕈的青綠；太亮會被打成一片白）、亮度，照在櫃檯與店主身上的那一盞小燈
const CUP_GLOW: Color = Color(0.22, 0.95, 0.72)
const CUP_LIT: float = 1.25
const CUP_LIGHT_ENERGY: float = 0.4
## 櫃檯上那一籃夜光毒蕈（回程；諾恩開口才擱上去，蕈放進杯子之後只剩空籃）：籃子、裡面那一叢多大
const BASKET_POS: Vector3 = TownScenery.PHARMACY_COUNTER + Vector3(1.12, 0.92, -0.37)
## 回程櫃檯上那面盾放哪（櫃檯東半邊靠裡面；傍晚那兩瓶藥收掉了，TownScenery.COUNTER_BOTTLES_DUSK）
const SHIELD_ON_COUNTER: Vector3 = TownScenery.PHARMACY_COUNTER + Vector3(0.95, 0.95, 0.18)
const RETURN_SHIELD_LINE: String = "DLG_CH1_TRET_005_TAKEN"
const BASKET_MODEL: String = "quaternius/FarmCrate_Empty"
const BASKET_SCALE: float = 0.62
const BASKET_MUSHROOM_SCALE: float = 0.3
## 回程的麵攤（鍋的蒸氣、火光、紅燈籠是 TownScenery 傍晚擺的）：兌了麵票攤車上多兩碗熱湯；
## 當初把黴泥趕進酒桶的，鍋底下縮著那一團（一下一下地打嗝）
const BOWL_MODEL: String = "quaternius/Pot_1"
const BOWL_SCALE: float = 0.42
const BOWL_SPOTS: Array[Vector3] = [Vector3(-0.32, 0.9, 0.3), Vector3(0.3, 0.9, 0.34)]
const SOUP_COLOR: Color = Color(0.86, 0.62, 0.3)
const HICCUP_EVERY: float = 1.7
const FLAG_BASKET: String = "ch1.basket_delivered"
## 藥錢記在誰名下：together＝「等我們兩個一起回來收」、receipt＝「給做杯子的人開張收據吧」（結尾用）
const FLAG_LEDGER: String = "ch1.ledger"
const FLAG_LEFT: String = "ch1.town_left"
const TOWN_FLAGS: PackedStringArray = [FLAG_BASKET, FLAG_LEFT]
const PHARMACY_DIALOGUE: String = "ch1_town_pharmacy"
## 街尾的商人：先問要不要試戴（ch1_town_ring）→ 戴上、打開裝備面板 → 關掉之後問買不買（ch1_town_ring_buy）
const RING_DIALOGUE: String = "ch1_town_ring"
const RING_BUY_DIALOGUE: String = "ch1_town_ring_buy"
const RING_ID: String = "pain_ring"
## 對話裡選的（講完由這一關照著做、然後清掉）：要試戴、要買
const FLAG_RING_TRY: String = "ch1.ring_try"
const FLAG_RING_BUY: String = "ch1.ring_buy"
## 試戴過戒指（右上角的清單）
const FLAG_RING_TRIED: String = "ch1.ring_tried"
## 籃子送到之後，門邊凳子上的席菈可以說話：她的藥單（ch1_town_sera_list）；講完「抄給我」那一個就拿到三瓶毒藥
const SERA_LIST_DIALOGUE: String = "ch1_town_sera_list"
const FLAG_SERA_LIST: String = "ch1.sera_list"
const SERA_LIST_LINES: PackedStringArray = ["SERA_LIST_LINE_1", "SERA_LIST_LINE_2", "SERA_LIST_LINE_3", "SERA_LIST_LINE_4"]
## 「那……這三瓶給你」那一句：紙上蓋一個「抄好了」
const SERA_LIST_GIVE_LINE: String = "DLG_CH1_SLIST_COPY3"
const LIST_PAPER: Color = Color(0.95, 0.92, 0.84)
const LIST_INK: Color = Color(0.2, 0.16, 0.24)
## 街上的佈告欄：兩張佈告（麵攤的地下室、訓練場的鐵盾）。讀過就算接了，不讀也可以直接去找人（劇本：不必先把佈告欄讀完）
const NOTICE_LINES: PackedStringArray = ["NOTICE_LINE_1", "NOTICE_LINE_2", "NOTICE_LINE_3", "NOTICE_LINE_4"]
const FLAG_NOTICES: String = "ch1.notices_read"
const NOTICE_SHOW_SEC: float = 9.0
const NOTICE_AWAY: float = 3.4
## 佈告二：倉庫大叔（找盾）→ 藥房後院曬衣繩上的鐵盾 → 補借據把盾留下（iou）／帶上去問阿展（taken）→ 回倉庫領謝禮
const UNCLE_KEY: String = "SPK_WAREHOUSE"
const UNCLE_POS: Vector3 = TownScenery.WAREHOUSE_FRONT + Vector3(-1.2, 0, -0.6)
const SHIELD_ASK_DIALOGUE: String = "ch1_town_shield_ask"
const SHIELD_DIALOGUE: String = "ch1_town_shield"
const SHIELD_REPORT_DIALOGUE: String = "ch1_town_shield_report"
const FLAG_SHIELD_ASKED: String = "ch1.shield_asked"
## 盾怎麼處理："iou"／"taken"（ch1.shield_done 也一起設）
const FLAG_SHIELD: String = "ch1.shield"
const FLAG_SHIELD_DONE: String = "ch1.shield_done"
const FLAG_SHIELD_PAID: String = "ch1.shield_paid"
const SHIELD_REWARD: int = 3
const SHIELD_ITEM: String = "rusty_shield"
## 曬衣繩上的盾（翻過來掛著、綁帶朝外）
const SHIELD_POS: Vector3 = Vector3(8.6, 1.45, 14.2)
const SLIP_LINES: PackedStringArray = ["AZHAN_SLIP_LINE_1", "AZHAN_SLIP_LINE_2", "AZHAN_SLIP_LINE_3"]
## 佈告一：麵攤攤主（湯沒煮開）→ 地下室的三團黴泥縮在鐵網後面抱著暖管：
## 提燈（lamp）：一次引一團爬出來、砍掉；切熱水管（barrel）：第一次轉錯（樓上的茶杯冒泡）、再轉一次全部滾進空酒桶、蓋上
## → 回麵攤領兩張麵票＋一瓶暖泥塞
const VENDOR_KEY: String = "SPK_NOODLE"
const VENDOR_POS: Vector3 = TownScenery.NOODLE_STALL + Vector3(0.3, 0, -1.05)
const NOODLE_ASK_DIALOGUE: String = "ch1_town_noodle_ask"
const NOODLE_REPORT_DIALOGUE: String = "ch1_town_noodle_report"
const FLAG_CELLAR_ASKED: String = "ch1.cellar_asked"
## 怎麼解的："lamp"／"barrel"（ch1.cellar_done 也一起設）
const FLAG_CELLAR_WAY: String = "ch1.cellar_way"
const FLAG_CELLAR_DONE: String = "ch1.cellar_done"
const FLAG_CELLAR_PAID: String = "ch1.cellar_paid"
const NOODLE_TICKET: String = "noodle_ticket"
const WARM_PLUG: String = "warm_mud_plug"
## 地下室牆上那盞油燈多亮（地下室的環境光很暗，TownScenery.set_cellar：看得到東西靠這一盞；提著引黴泥時再亮一半）
const CELLAR_LAMP_ENERGY: float = 5.0
## 下樓／上樓：畫面暗下去、黑著、亮回來
const STAIRS_DIM: Vector3 = Vector3(0.3, 0.15, 0.35)
## 轉錯的那一次：多久之後才能再轉
const VALVE_WRONG_SEC: float = 1.2
## 黴泥滾進酒桶要多久
const ROLL_SEC: float = 1.4
const MERCHANT_KEY: String = "SPK_MERCHANT"
const MERCHANT_POS: Vector3 = TownScenery.MERCHANT_STALL + Vector3(0.2, 0, 1.15)
## 攤子上那只戒指（模型 0.07 m 高：放大一點才看得到）
const RING_ON_STALL: Vector3 = TownScenery.MERCHANT_STALL + Vector3(0.1, 0.97, -0.2)
const RING_SHOW_SCALE: float = 2.2
const PHARMACIST_KEY: String = "SPK_PHARMACIST"
const APPRENTICE_KEY: String = "SPK_APPRENTICE"
## 從公會大門出來站的地方；朝東（yaw −90°：0＝朝 −Z）
const ENTRANCE: Vector3 = Vector3(-6.0, 0.05, -3.4)
const ENTRANCE_YAW_DEG: float = -90.0
## 站到藥房櫃檯前這麼近就開始那段話
const PHARMACY_TALK_DIST: float = 2.6
const PHARMACIST_POS: Vector3 = TownScenery.PHARMACY_COUNTER + Vector3(-0.5, 0, 1.0)
const APPRENTICE_POS: Vector3 = TownScenery.PHARMACY_COUNTER + Vector3(-1.9, 0, -0.9)
## 席菈：藥房門邊的凳子上（蹲著修面具的扣帶）
const SERA_SPOT: Vector3 = TownScenery.PHARMACY_COUNTER + Vector3(2.4, 0, -0.4)
const SERA_FACING_DEG: float = 25.0
## 籃子還沒送到就走到東門：被叫住、拉回來
const GATE_STOP_X: float = TownScenery.GATE_X - 1.2
## 籃子送到之後諾恩走過這裡（往東），席菈就先走了（從小路去林口）
const SERA_GOES_AHEAD_X: float = 30.0
const MURMUR_SFX: String = "hall_murmur"
const MURMUR_DB: float = -24.0

var scenery: TownScenery
var sera: Sera
var pharmacist: Npc
var apprentice: Npc
var merchant: Npc
var merchant_use: Interactable
var sera_use: Interactable
var board_use: Interactable
var board_note: PaperNote
var _board_t: float = 0.0
var vendor: Npc
var vendor_use: Interactable
var cellar_door_use: Interactable
var ladder_use: Interactable
var lamp_use: Interactable
var valve_use: Interactable
var lamp_light: OmniLight3D
## 地下室裡：縮在鐵網後面的黴泥（只是模型）、爬出來的那一隻（真的敵人）
var hiding: Array[Node3D] = []
var lured: MoldSlime
var in_cellar: bool = false
var valve_turns: int = 0
var _valve_wait: float = 0.0
var _rolling: float = -1.0
var barrel_lid: MeshInstance3D
var uncle: Npc
var uncle_use: Interactable
var shield: Node3D
var shield_use: Interactable
var slip_note: PaperNote
var list_note: PaperNote
var ring_prop: Node3D
var talk_camera: TalkCamera
var card: ChapterCard
var azhan: Npc
var core: GolemCore
var cup_lids: Array[MeshInstance3D] = []
var cups_focus: Node3D
var cup_light: OmniLight3D
var basket: Node3D
var basket_mushrooms: Node3D
var receipt_note: PaperNote
var pot_blob: Node3D
var soup_bowls: Array[Node3D] = []
var _leaving: bool = false
var _gate_nag_t: float = 0.0

@onready var _player: PlayerController = $Player
@onready var _hud: Hud = $Hud


## 把這條街跳過（開發旗標直接進森林、測試）：當成籃子送到了、已經從東門出去了
static func skip_town(session: GameSession) -> void:
	for flag: String in TOWN_FLAGS:
		session.set_flag(flag, true)


func _ready() -> void:
	var args: Dictionary = Game.level_args()
	var s: GameSession = Game.session
	# 直接進這一關（開發旗標 `--level=town_street`、測試）：當成公會那一段演過了
	if s.in_story() and stage() in GuildHall.OPENING_STAGES:
		GuildHall.skip_opening(s)
	# 截圖用：`--delivered` 籃子送到了（可以去東門）
	if s.in_story() and args.has("delivered"):
		s.set_flag(FLAG_BASKET, true)
	# 截圖用：`--return` 回程的傍晚（祭壇打完了；`--delivered` 蕈交出去了；`--noodle` 麵票兌過了、當初把黴泥趕進酒桶；
	# `--shield=iou｜taken` 盾補過借據／帶回來）
	if s.in_story() and args.has("return"):
		RuinedAltar.skip_to_altar(s)
		for flag: String in ["ch1.altar_talked", "ch1.golem_down", "ch1.altar_done"]:
			s.set_flag(flag, true)
		if args.has("delivered"):
			s.set_flag(FLAG_DELIVERED, true)
		if args.has("noodle"):
			s.set_flag(FLAG_CELLAR_WAY, "barrel")
			s.set_flag(FLAG_NOODLE_BACK, true)
		if args.has("shield"):
			s.set_flag(FLAG_SHIELD, str(args["shield"]))
	scenery = TownScenery.build(self, is_return())
	_mark("Pharmacy", TownScenery.PHARMACY_COUNTER + Vector3(0, 0, -1.4))
	_mark("EastGate", Vector3(TownScenery.GATE_X, 0, 0))
	_mark("GuildDoor", TownScenery.GUILD_DOOR + Vector3(0, 0, 1.0))
	_player.collision_mask |= GuildScenery.PEOPLE_LAYER
	_player.peaceful = true
	_player.global_position = RETURN_ENTRANCE if is_return() else ENTRANCE
	_player.yaw = deg_to_rad(RETURN_YAW_DEG if is_return() else ENTRANCE_YAW_DEG)
	var at: PackedStringArray = str(args.get("at", "")).split(",")
	if at.size() == 2:
		_player.global_position = Vector3(float(at[0]), ENTRANCE.y, float(at[1]))
	if args.has("cam-yaw"):
		_player.yaw = deg_to_rad(float(str(args["cam-yaw"])))
	_player.snap_camera()
	_spawn_cast()
	_build_interactables()
	Game.dialogue_ended.connect(_on_dialogue_ended)
	Game.dialogue_started.connect(func(r: DialogueRunner) -> void:
		if r.dialogue_id == SERA_LIST_DIALOGUE:
			r.line_shown.connect(_on_list_line)
		elif r.dialogue_id == RETURN_DIALOGUE:
			# 第一句在 dialogue_started 之前就發過了：自己補叫一次
			r.line_shown.connect(_on_return_line)
			_on_return_line("", r.current_text()))
	# 開局的零錢寫進旗標（對話的條件「錢夠不夠」讀旗標）
	if s.in_story():
		Gear.new(s.state).ensure_coins()
	Ambience.play(self, MURMUR_SFX, MURMUR_DB, "StreetMurmur")
	var talk_skip: int = int(str(args.get("talk-skip", "0")))
	if talk_skip > 0:
		Game.dialogue_started.connect(func(r: DialogueRunner) -> void:
			for i: int in talk_skip:
				skip_line.call_deferred(r))
	# 截圖用：`--demo=ring` 站到商人攤前、試戴戒指（裝備面板打開）；`--demo=list` 見下面
	if str(args.get("demo", "")) == "ring":
		_player.global_position = TownScenery.MERCHANT_STALL + Vector3(-0.6, 0.05, -2.2)
		_player.yaw = deg_to_rad(160.0)
		_player.snap_camera()
		get_tree().create_timer(0.3).timeout.connect(try_on_ring)
	elif str(args.get("demo", "")) == "list" and s.in_story():
		# 截圖用：`--demo=list` 籃子送到了、站到席菈旁邊、她攤開藥單（配 `--talk-skip=N`）
		s.set_flag(FLAG_BASKET, true)
		_player.global_position = SERA_SPOT + Vector3(-1.2, 0.05, -1.6)
		_player.yaw = deg_to_rad(150.0)
		_player.snap_camera()
		get_tree().create_timer(0.3).timeout.connect(talk_sera)
	elif args.has("cellar"):
		# 截圖用：`--cellar` 一進來就在麵攤的地下室（`--demo=lure` 再引一團出來）
		in_cellar = true
		scenery.set_cellar(true)
		_player.peaceful = false
		_player.global_position = TownScenery.CELLAR_IN
		_player.yaw = deg_to_rad(-60.0)
		_player.snap_camera()
		_refresh_interactables()
		if str(args.get("demo", "")) == "lure":
			get_tree().create_timer(0.3).timeout.connect(lure_one)
	elif stage() == STAGE_BASKET:
		_hud.show_center_lines("CH1_TOWN_LINE1", "CH1_TOWN_LINE2", 5.5, Hud.CENTER_LINE2_COLOR)
	elif is_return():
		# 扛著魔像核心走回來（公會的結尾接著扛進大廳）
		core = GolemCore.create()
		core.carry_on(_player.get_node("Body") as Node3D, 0.0, _player.puppet())
		_player.burden = GuildHall.CARRY_PACE
		if not _flag(FLAG_DELIVERED):
			_hud.show_center_lines("CH1_TOWN_RETURN_LINE1", "CH1_TOWN_RETURN_LINE2", 5.5, Hud.CENTER_LINE2_COLOR)
	QualityPreset.apply_tree(self, Settings.quality as QualityPreset.Level)


func footstep_surface(_p: Vector3) -> String:
	return "stone"


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


## 回程的傍晚（祭壇打完、還沒回到公會）
func is_return() -> bool:
	return Game.session.in_story() and stage() == STAGE_RETURN


func _flag(key: String) -> bool:
	return bool(Game.session.state.get_flag(key, false))


func _spawn_cast() -> void:
	pharmacist = Npc.create("Pharmacist", "town_pharmacist", PHARMACIST_POS, 0.0)
	pharmacist.doll_colors(Color(0.42, 0.58, 0.44), Color(0.85, 0.8, 0.68))
	add_child(pharmacist)
	apprentice = Npc.create("Apprentice", "town_apprentice", APPRENTICE_POS, 20.0)
	apprentice.doll_colors(Color(0.72, 0.62, 0.44), Color(0.45, 0.3, 0.2))
	add_child(apprentice)
	uncle = Npc.create("WarehouseUncle", "town_warehouse_uncle", UNCLE_POS, 180.0)
	uncle.doll_colors(Color(0.36, 0.48, 0.32), Color(0.42, 0.3, 0.2))
	add_child(uncle)
	shield = _build_shield()
	add_child(shield)
	vendor = Npc.create("NoodleVendor", "town_noodle_vendor", VENDOR_POS, 180.0)
	vendor.doll_colors(Color(0.2, 0.26, 0.45), Color(0.92, 0.9, 0.86))
	add_child(vendor)
	_build_cellar_cast()
	merchant = Npc.create("Merchant", "black_market_merchant", MERCHANT_POS, 0.0)
	add_child(merchant)
	ring_prop = PropModels.instance(Gear.load_data()["accessories"][RING_ID]["model"])
	if ring_prop != null:
		ring_prop.name = "RingOnStall"
		ring_prop.position = RING_ON_STALL
		ring_prop.scale = Vector3.ONE * RING_SHOW_SCALE
		add_child(ring_prop)
	if is_return():
		# 回程：席菈跟在後面、阿展在藥房櫃檯旁邊、櫃檯上擺著五只保溫杯
		sera = Sera.new()
		sera.name = "Sera"
		sera.holstered = true
		sera.target = _player
		sera.collision_mask |= GuildScenery.PEOPLE_LAYER
		sera.position = _player.global_position + SERA_RETURN_OFFSET
		add_child(sera)
		azhan = Npc.create("Azhan", "azhan", AZHAN_POS, -25.0)
		azhan.doll_colors(Color(0.5, 0.42, 0.3), Color(0.3, 0.42, 0.36))
		add_child(azhan)
		_build_cups()
		_build_basket()
		_build_noodle_evening()
	elif not _flag(FLAG_LEFT):
		sera = Sera.new()
		sera.name = "Sera"
		sera.holstered = true
		sera.joined = false
		sera.collision_mask |= GuildScenery.PEOPLE_LAYER
		sera.position = SERA_SPOT
		sera.rotation.y = deg_to_rad(SERA_FACING_DEG)
		add_child(sera)
		_seat_sera(true)
	talk_camera = TalkCamera.new()
	talk_camera.name = "TalkCamera"
	add_child(talk_camera)


func _seat_sera(on: bool) -> void:
	if sera == null:
		return
	var p: Puppet = sera.puppet()
	p.pose = "sit_hunch" if on else ""
	p.position.y = (GuildHall.SERA_STOOL_LIFT if p.uses_model() else GuildHall.SERA_STOOL_LIFT_PUPPET) if on else 0.0


func _physics_process(delta: float) -> void:
	if not Game.session.in_story() or _leaving:
		return
	_gate_nag_t = maxf(_gate_nag_t - delta, 0.0)
	if in_cellar:
		# 地下室裡：只管地下室（街上的那些位置判斷不套，不然會被「拉回東門前」拉出地下室）
		_player.global_position = TownScenery.keep_in_cellar(_player.global_position)
		_tick_cellar(delta)
		return
	_player.global_position = TownScenery.keep_inside(_player.global_position)
	_tick_board(delta)
	match stage():
		STAGE_BASKET:
			if _player.global_position.distance_to(TownScenery.PHARMACY_COUNTER + Vector3(0, 0.05, -1.2)) < PHARMACY_TALK_DIST:
				_talk(PHARMACY_DIALOGUE, ["SPK_NOEN", PHARMACIST_KEY, APPRENTICE_KEY, Sera.NAME_KEY])
			elif _player.global_position.x > GATE_STOP_X:
				# 籃子還沒送：走到東門被叫住
				_player.global_position.x = GATE_STOP_X
				if _gate_nag_t <= 0.0:
					_gate_nag_t = 4.0
					_hud.show_bark(_player, "BARK_NOEN_BASKET_FIRST", 2.6, "SPK_NOEN")
		STAGE_GATE:
			# 席菈說好從小路先去林口：諾恩往街尾走遠了，她就不在凳子上了（走的那一刻不在畫面裡）
			if sera != null and _player.global_position.x > SERA_GOES_AHEAD_X:
				sera.queue_free()
				sera = null
				_refresh_interactables()
			if _player.global_position.x > TownScenery.LEAVE_X:
				_leave()
		STAGE_RETURN:
			_tick_return()


## 櫃檯上的五只保溫杯：杯身＋杯蓋（CupLid1～5；交蕈那段話裡一個接一個亮）
func _build_cups() -> void:
	var body := StandardMaterial3D.new()
	body.albedo_color = Color(0.62, 0.56, 0.5)
	body.metallic = 0.3
	body.roughness = 0.5
	for i: int in CUP_COUNT:
		# 櫃檯面高 0.92；擺在靠街的那一排（後面一排是原本的藥瓶）
		cup_lids.append(_add_cup("%d" % (i + 1), TownScenery.PHARMACY_COUNTER + Vector3(-0.7 + 0.35 * float(i), 0.92, -0.42), body, _flag(FLAG_DELIVERED)))
	# 對話的鏡頭看的地方（那一排杯子的中間；腳下的位置）與杯蓋照出來的一點青綠
	cups_focus = Node3D.new()
	cups_focus.name = "CupsFocus"
	cups_focus.position = TownScenery.PHARMACY_COUNTER + Vector3(0, 0, -0.42)
	cups_focus.set_meta(TalkCamera.HEIGHT_META, 1.1)
	cups_focus.set_meta(TalkCamera.SPOT_META, CUPS_CAMERA)
	add_child(cups_focus)
	cup_light = OmniLight3D.new()
	cup_light.name = "CupLight"
	cup_light.light_color = CUP_GLOW
	cup_light.light_energy = CUP_LIGHT_ENERGY if _flag(FLAG_DELIVERED) else 0.0
	cup_light.omni_range = 2.0
	cup_light.shadow_enabled = false
	cup_light.position = TownScenery.PHARMACY_COUNTER + Vector3(0, 1.4, -0.42)
	add_child(cup_light)


## 一只保溫杯：杯身（Cup<名字>）＋杯蓋（CupLid<名字>，回傳的是杯蓋）。at＝杯底
func _add_cup(cup_name: String, at: Vector3, body: StandardMaterial3D, lit: bool) -> MeshInstance3D:
	var cup := MeshInstance3D.new()
	cup.name = "Cup" + cup_name
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.06
	cyl.height = 0.2
	cyl.material = body
	cup.mesh = cyl
	cup.position = at + Vector3(0, 0.1, 0)
	add_child(cup)
	var lid := MeshInstance3D.new()
	lid.name = "CupLid" + cup_name
	var top := CylinderMesh.new()
	top.top_radius = 0.05
	top.bottom_radius = 0.075
	top.height = 0.05
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.3, 0.3, 0.32)
	glow.emission_enabled = true
	glow.emission = CUP_GLOW
	glow.emission_energy_multiplier = CUP_LIT if lit else 0.0
	top.material = glow
	lid.mesh = top
	lid.position = at + Vector3(0, 0.225, 0)
	add_child(lid)
	return lid


## 回程櫃檯上的那面盾：盾面朝上平放（綁帶在下面）。補過借據的當熱敷盤——上面溫著一只杯（WarmCup）；帶回來的是諾恩推到阿展面前的
func _lay_shield(with_cup: bool) -> void:
	shield.position = SHIELD_ON_COUNTER
	shield.rotation_degrees = Vector3(-90.0, 18.0, 0.0)
	shield.visible = true
	if with_cup and get_node_or_null("CupWarm") == null:
		var body := StandardMaterial3D.new()
		body.albedo_color = Color(0.62, 0.56, 0.5)
		body.metallic = 0.3
		body.roughness = 0.5
		_add_cup("Warm", SHIELD_ON_COUNTER + Vector3(0.05, 0.03, 0.05), body, false)


## 櫃檯上那一籃夜光毒蕈：籃子（模型不在就只有蕈）＋一叢縮小的夜光毒蕈。還沒開口＝不在櫃檯上；交出去了＝空籃
func _build_basket() -> void:
	basket = Node3D.new()
	basket.name = "MushroomBasket"
	basket.position = BASKET_POS
	basket.rotation_degrees.y = -14.0
	var crate: Node3D = PropModels.instance(BASKET_MODEL)
	if crate != null:
		crate.scale = Vector3.ONE * BASKET_SCALE
		basket.add_child(crate)
	basket_mushrooms = ForestScenery.small_prop(ForestScenery.MUSHROOM_MODEL, Vector3(0, 0.03, 0), 0.6, true)
	basket_mushrooms.name = "Mushrooms"
	basket_mushrooms.scale = Vector3.ONE * BASKET_MUSHROOM_SCALE
	var glow: OmniLight3D = basket_mushrooms.get_node("Glow") as OmniLight3D
	glow.light_energy = 0.7
	glow.omni_range = 2.2
	basket.add_child(basket_mushrooms)
	basket.visible = _flag(FLAG_DELIVERED)
	basket_mushrooms.visible = not _flag(FLAG_DELIVERED)
	add_child(basket)


## 回程的麵攤（看的；鍋的蒸氣、火光、紅燈籠在 TownScenery）：黴泥趕進酒桶的那一條，鍋底下縮著一團；兌過麵票的話兩碗熱湯已經在攤車上
func _build_noodle_evening() -> void:
	if str(Game.session.state.get_flag(FLAG_CELLAR_WAY, "")) == "barrel":
		pot_blob = PropModels.instance("tripo/enemy_mold_slime")
		if pot_blob == null:
			pot_blob = _blob_stand_in()
		pot_blob.name = "PotBlob"
		pot_blob.position = TownScenery.POT_POS + Vector3(0.62, 0, 0.5)
		pot_blob.scale = Vector3.ONE * 0.4
		add_child(pot_blob)
		# 打嗝：隔一陣子往上一頂、再攤回去
		var hic: Tween = pot_blob.create_tween().set_loops()
		hic.tween_interval(HICCUP_EVERY)
		hic.tween_property(pot_blob, "scale", Vector3(0.36, 0.52, 0.36), 0.07)
		hic.tween_property(pot_blob, "scale", Vector3.ONE * 0.4, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _flag(FLAG_NOODLE_BACK):
		_serve_soup()


## 兩碗熱湯擺上攤車（兌麵票的那段話講完；讀檔時已經兌過的直接擺好）
func _serve_soup() -> void:
	if not soup_bowls.is_empty():
		return
	for i: int in BOWL_SPOTS.size():
		var bowl := Node3D.new()
		bowl.name = "SoupBowl%d" % (i + 1)
		bowl.position = TownScenery.NOODLE_STALL + BOWL_SPOTS[i]
		var pot: Node3D = PropModels.instance(BOWL_MODEL)
		if pot != null:
			pot.scale = Vector3.ONE * BOWL_SCALE
			bowl.add_child(pot)
		# 湯面：一片暖色的圓（碗的模型不在時就只有這一片）
		var soup := MeshInstance3D.new()
		soup.name = "Soup"
		var disc := CylinderMesh.new()
		disc.top_radius = 0.085
		disc.bottom_radius = 0.085
		disc.height = 0.012
		var sm := StandardMaterial3D.new()
		sm.albedo_color = SOUP_COLOR
		sm.roughness = 0.25
		disc.material = sm
		soup.mesh = disc
		soup.position.y = 0.075
		bowl.add_child(soup)
		var steam: CPUParticles3D = TownScenery.steam(0.16, 5)
		steam.position.y = 0.1
		bowl.add_child(steam)
		add_child(bowl)
		soup_bowls.append(bowl)


## 亮了幾只杯蓋（測試用）
func lids_lit() -> int:
	var n: int = 0
	for lid: MeshInstance3D in cup_lids:
		if ((lid.mesh as CylinderMesh).material as StandardMaterial3D).emission_energy_multiplier > 1.0:
			n += 1
	return n


## 交蕈那段話裡看得到的東西（哪一句做什麼見上面的 RETURN_* 常數）
func _on_return_line(_speaker: String, text_key: String) -> void:
	if text_key == RETURN_BASKET_LINE:
		_show_basket()
	elif text_key == RETURN_LIDS_LINE:
		_light_lids()
	elif text_key == RETURN_SLIP_LINE:
		_show_return_slip()
	elif text_key.begins_with(RETURN_SLIP_AWAY):
		_close_note(slip_note)
		slip_note = null
		if text_key == RETURN_SHIELD_LINE:
			_lay_shield(false)
	elif text_key == RETURN_RECEIPT_LINE:
		receipt_note = PaperNote.create("RECEIPT_TITLE", RECEIPT_LINES, SLIP_PAPER, SLIP_INK)
		_hud.add_child(receipt_note)
		receipt_note.stamp("RECEIPT_STAMP")
	elif text_key == RETURN_RECEIPT_AWAY:
		_close_note(receipt_note)
		receipt_note = null


## 諾恩把一整籃擱上櫃檯（從小彈到原來的大小）
func _show_basket() -> void:
	if basket.visible:
		return
	basket.visible = true
	basket.scale = Vector3.ONE * 0.6
	basket.create_tween().tween_property(basket, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 店主把蕈一朵一朵放進保溫杯：她伸手、籃子裡那一叢越來越小，五只杯蓋一個接一個亮起來，櫃檯上多一點青綠的光
func _light_lids() -> void:
	pharmacist.gesture("reach")
	var all_sec: float = CUP_LIGHT_EVERY * float(cup_lids.size())
	for i: int in cup_lids.size():
		var mat: StandardMaterial3D = (cup_lids[i].mesh as CylinderMesh).material as StandardMaterial3D
		var t: Tween = cup_lids[i].create_tween()
		t.tween_interval(CUP_LIGHT_EVERY * float(i))
		t.tween_property(mat, "emission_energy_multiplier", CUP_LIT, 0.25)
	cup_light.create_tween().tween_property(cup_light, "light_energy", CUP_LIGHT_ENERGY, all_sec)
	var shrink: Tween = basket_mushrooms.create_tween()
	shrink.tween_property(basket_mushrooms, "scale", Vector3.ONE * 0.02, all_sec)
	shrink.tween_callback(basket_mushrooms.hide)


## 阿展的辭工單拿到眼前：下半頁的「獨自採集」劃掉，用另一種墨色補寫「帶學徒認路」
func _show_return_slip() -> void:
	_close_note(slip_note)
	slip_note = PaperNote.create("AZHAN_SLIP_TITLE", RETURN_SLIP_LINES, SLIP_PAPER, SLIP_INK)
	_hud.add_child(slip_note)
	var t: Tween = slip_note.create_tween()
	t.tween_interval(SLIP_STRIKE_AFTER)
	t.tween_callback(slip_note.strike.bind(SLIP_STRIKE_INDEX))
	t.tween_interval(SLIP_WRITE_AFTER - SLIP_STRIKE_AFTER)
	t.tween_callback(slip_note.add_line.bind(SLIP_NEW_LINE, SLIP_NEW_INK))


func _close_note(note: PaperNote, after: float = 0.0) -> void:
	if note != null and is_instance_valid(note):
		note.close(after)


## 回程：走到藥房交蕈 → 走回公會大門，換到大廳的結尾。東門不能再出去
func _tick_return() -> void:
	_player.global_position.x = minf(_player.global_position.x, GATE_STOP_X)
	if not _flag(FLAG_DELIVERED):
		if _player.global_position.distance_to(TownScenery.PHARMACY_COUNTER + Vector3(0, 0.05, -1.2)) < PHARMACY_TALK_DIST:
			_talk(RETURN_DIALOGUE, ["SPK_NOEN", PHARMACIST_KEY, AZHAN_KEY, APPRENTICE_KEY, Sera.NAME_KEY, CUPS_KEY])
	elif not Game.is_in_dialogue() and _player.global_position.distance_to(TownScenery.GUILD_DOOR + Vector3(0, 0.05, 1.0)) < GUILD_ENTER_DIST:
		_leaving = true
		Game.session.set_flag(FLAG_RETURNED, true)
		card = ChapterCard.play(self, "CARD_BACK_SMALL", "CARD_RETURN_TITLE", Game.go_to_checkpoint_level)


## 走出東門：換到腐敗之森（地點卡）
func _leave() -> void:
	_leaving = true
	Game.session.set_flag(FLAG_LEFT, true)
	card = ChapterCard.play(self, "CARD_FOREST_SMALL", "CARD_FOREST_TITLE", Game.go_to_checkpoint_level)


## 開始一段對話。order＝這一段誰跟誰講（說話者的翻譯 key，第一個是諾恩）
func _talk(dialogue_id: String, order: Array[String]) -> bool:
	if Game.is_in_dialogue():
		return false
	var who: Dictionary[String, Node3D] = {}
	for key: String in order:
		var n: Node3D = _speaker_node(key)
		if n != null:
			who[key] = n
	talk_camera.cast = who
	return Game.start_dialogue(dialogue_id)


func _speaker_node(key: String) -> Node3D:
	match key:
		"SPK_NOEN":
			return _player
		PHARMACIST_KEY:
			return pharmacist
		APPRENTICE_KEY:
			return apprentice
		AZHAN_KEY:
			return azhan
		Sera.NAME_KEY:
			return sera
		MERCHANT_KEY:
			return merchant
		UNCLE_KEY:
			return uncle
		VENDOR_KEY:
			return vendor
		CUPS_KEY:
			return cups_focus
	return null


func _build_interactables() -> void:
	merchant_use = Interactable.create("TalkMerchant", TownScenery.MERCHANT_STALL + Vector3(0, 0, -1.2), "HINT_TALK_MERCHANT", 2.4)
	merchant_use.used.connect(func(_by: PlayerController) -> void: talk_merchant())
	add_child(merchant_use)
	board_use = Interactable.create("ReadStreetBoard", TownScenery.BOARD_POS + Vector3(0, 0, 1.0), "HINT_READ_BOARD", 2.2)
	board_use.used.connect(func(_by: PlayerController) -> void: read_board())
	add_child(board_use)
	uncle_use = Interactable.create("TalkUncle", UNCLE_POS + Vector3(0, 0, 1.2), "HINT_TALK_UNCLE", 2.4)
	uncle_use.used.connect(func(_by: PlayerController) -> void: talk_uncle())
	add_child(uncle_use)
	shield_use = Interactable.create("CheckShield", Vector3(SHIELD_POS.x, 0, SHIELD_POS.z - 0.8), "HINT_CHECK_SHIELD", 2.0)
	shield_use.used.connect(func(_by: PlayerController) -> void: check_shield())
	add_child(shield_use)
	vendor_use = Interactable.create("TalkVendor", TownScenery.NOODLE_STALL + Vector3(0, 0, 1.3), "HINT_TALK_VENDOR", 2.4)
	vendor_use.used.connect(func(_by: PlayerController) -> void: talk_vendor())
	add_child(vendor_use)
	cellar_door_use = Interactable.create("CellarDoorUse", TownScenery.CELLAR_DOOR + Vector3(0, 0, 1.3), "HINT_ENTER_CELLAR", 1.8)
	cellar_door_use.used.connect(func(_by: PlayerController) -> void: go_down())
	add_child(cellar_door_use)
	ladder_use = Interactable.create("LadderUse", TownScenery.in_cellar(TownScenery.CELLAR_LADDER), "HINT_LEAVE_CELLAR", 1.6)
	ladder_use.used.connect(func(_by: PlayerController) -> void: go_up())
	add_child(ladder_use)
	lamp_use = Interactable.create("LampUse", TownScenery.in_cellar(TownScenery.CELLAR_LAMP + Vector3(0, 0, 0.6)), "HINT_TAKE_LAMP", 1.8)
	lamp_use.used.connect(func(_by: PlayerController) -> void: lure_one())
	add_child(lamp_use)
	valve_use = Interactable.create("ValveUse", TownScenery.in_cellar(TownScenery.CELLAR_VALVE + Vector3(-0.5, 0, 0)), "HINT_TURN_VALVE", 1.8)
	valve_use.used.connect(func(_by: PlayerController) -> void: turn_valve())
	add_child(valve_use)
	sera_use = Interactable.create("TalkSera", SERA_SPOT + Vector3(-0.6, 0, -1.0), "HINT_TALK_SERA", 2.2)
	sera_use.used.connect(func(_by: PlayerController) -> void: talk_sera())
	add_child(sera_use)
	_refresh_interactables()


func _refresh_interactables() -> void:
	if is_return() or _flag(FLAG_RETURNED):
		for it: Interactable in [merchant_use, sera_use, board_use, cellar_door_use, ladder_use, lamp_use, valve_use, uncle_use, shield_use]:
			it.enabled = false
		var st: GameState = Game.session.state
		vendor_use.enabled = not _leaving and not _flag(FLAG_NOODLE_BACK) and int(st.items.get(NOODLE_TICKET, 0)) > 0
		# 盾：補過借據的在櫃檯上當熱敷盤；帶回來的要到店主那一句才推上櫃檯（交完之後留在那裡）；沒碰過的不在
		var way: String = str(st.get_flag(FLAG_SHIELD, ""))
		shield.visible = false
		if way == "iou" or (way == "taken" and _flag(FLAG_DELIVERED)):
			_lay_shield(way == "iou")
		return
	merchant_use.enabled = Game.session.in_story() and not _leaving
	sera_use.enabled = Game.session.in_story() and not _leaving and sera != null and is_instance_valid(sera) and _flag(FLAG_BASKET)
	if ring_prop != null:
		ring_prop.visible = not Gear.new(Game.session.state).owns(RING_ID)
	board_use.enabled = Game.session.in_story() and not _leaving
	var done: bool = _flag(FLAG_CELLAR_DONE)
	vendor_use.enabled = Game.session.in_story() and not _leaving and not _flag(FLAG_CELLAR_PAID)
	cellar_door_use.enabled = Game.session.in_story() and not _leaving
	ladder_use.enabled = in_cellar
	var busy: bool = (lured != null and is_instance_valid(lured) and not lured.health.is_dead()) or _rolling >= 0.0
	lamp_use.enabled = in_cellar and not done and not busy and not hiding.is_empty()
	lamp_use.hint_key = "HINT_TAKE_LAMP" if hiding.size() == TownScenery.CELLAR_SLIMES.size() else "HINT_LAMP_AGAIN"
	valve_use.enabled = in_cellar and not done and not busy and not hiding.is_empty() and _valve_wait <= 0.0
	uncle_use.enabled = Game.session.in_story() and not _leaving and not _flag(FLAG_SHIELD_PAID)
	shield_use.enabled = Game.session.in_story() and not _leaving and not _flag(FLAG_SHIELD_DONE)
	# 帶走了就不在繩子上；補借據的留在藥房（還掛著）
	shield.visible = str(Game.session.state.get_flag(FLAG_SHIELD, "")) != "taken"


## 曬衣繩上的生鏽鐵盾：方的、生鏽的鐵板，翻過來掛著——兩條皮綁帶在朝外的那一面（拿盾的人是把東西托在前面送來的）
func _build_shield() -> Node3D:
	var root := Node3D.new()
	root.name = "RustyShield"
	root.position = SHIELD_POS
	var rust := StandardMaterial3D.new()
	rust.albedo_color = Color(0.5, 0.33, 0.24)
	rust.metallic = 0.4
	rust.roughness = 0.85
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var box := BoxMesh.new()
	box.size = Vector3(0.62, 0.74, 0.05)
	box.material = rust
	plate.mesh = box
	root.add_child(plate)
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.32, 0.2, 0.12)
	for i: int in 2:
		var strap := MeshInstance3D.new()
		strap.name = "Strap%d" % i
		var sb := BoxMesh.new()
		sb.size = Vector3(0.5, 0.06, 0.03)
		sb.material = leather
		strap.mesh = sb
		strap.position = Vector3(0, -0.14 + 0.28 * float(i), -0.04)
		root.add_child(strap)
	var hook := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.01
	hm.bottom_radius = 0.01
	hm.height = 0.25
	hook.mesh = hm
	hook.position = Vector3(0, 0.48, 0)
	root.add_child(hook)
	return root


## 街上的佈告欄：兩張佈告拿到眼前（離開或過幾秒收起來）
func read_board() -> void:
	if board_note != null and is_instance_valid(board_note):
		_close_board()
		return
	board_note = PaperNote.create("NOTICE_TITLE", NOTICE_LINES, GuildHall.BOARD_PAPER, GuildHall.BOARD_INK)
	_hud.add_child(board_note)
	_board_t = 0.0
	Game.session.set_flag(FLAG_NOTICES, true)
	_hud.show_bark(_player, "BARK_NOEN_NOTICES", 3.0, "SPK_NOEN")


func _tick_board(delta: float) -> void:
	if board_note == null:
		return
	if not is_instance_valid(board_note):
		board_note = null
		return
	_board_t += delta
	if _player.global_position.distance_to(board_use.global_position) > NOTICE_AWAY or _board_t > NOTICE_SHOW_SEC or Game.is_in_dialogue():
		_close_board()


func _close_board() -> void:
	if board_note != null and is_instance_valid(board_note):
		board_note.close()
	board_note = null


## 跟倉庫大叔說話：還沒找到盾＝請你找（別當眾問主人）；找到了＝謝禮（只給一次）
func talk_uncle() -> bool:
	if _flag(FLAG_SHIELD_DONE):
		return _talk(SHIELD_REPORT_DIALOGUE, ["SPK_NOEN", UNCLE_KEY])
	return _talk(SHIELD_ASK_DIALOGUE, ["SPK_NOEN", UNCLE_KEY])


## 摸曬衣繩上的盾：綁帶朝外、背面壓著阿展的辭工單（畫面右邊那張紙）→ 補借據／帶走
func check_shield() -> bool:
	if not _talk(SHIELD_DIALOGUE, ["SPK_NOEN"]):
		return false
	slip_note = PaperNote.create("AZHAN_SLIP_TITLE", SLIP_LINES, SLIP_PAPER, SLIP_INK)
	_hud.add_child(slip_note)
	return true


## 跟門邊的席菈說話：她把調藥的記錄攤在膝上（畫面右邊那張紙），一瓶一瓶問（互動鍵；測試直接叫）
func talk_sera() -> bool:
	if not _talk(SERA_LIST_DIALOGUE, ["SPK_NOEN", Sera.NAME_KEY]):
		return false
	list_note = PaperNote.create("SERA_LIST_TITLE", SERA_LIST_LINES, LIST_PAPER, LIST_INK)
	_hud.add_child(list_note)
	return true


func _on_list_line(_speaker: String, text_key: String) -> void:
	if text_key == SERA_LIST_GIVE_LINE and list_note != null and is_instance_valid(list_note):
		list_note.stamp("SERA_LIST_STAMP")


## 跟街尾的商人說話（互動鍵；測試直接叫）
func talk_merchant() -> bool:
	return _talk(RING_DIALOGUE, ["SPK_NOEN", MERCHANT_KEY])


func _on_dialogue_ended(dialogue_id: String) -> void:
	var g := Gear.new(Game.session.state)
	match dialogue_id:
		RETURN_DIALOGUE:
			# 紙還在畫面上（整段跳過）就收起來
			_close_note(slip_note, 0.4)
			slip_note = null
			_close_note(receipt_note, 0.4)
			receipt_note = null
			if _flag(FLAG_DELIVERED):
				# 帶去問阿展的那面盾，他自己簽名還了
				if str(Game.session.state.get_flag(FLAG_SHIELD, "")) == "taken":
					Game.session.state.items[SHIELD_ITEM] = 0
				_hud.show_banner("CH1_TOWN_DELIVERED", 3.2)
				Game.session.autosave()
		NOODLE_BACK_DIALOGUE:
			if _flag(FLAG_NOODLE_BACK):
				_serve_soup()
				_player.health.heal(_player.health.max_hp, {"source": "noodles"})
				# 當初全砍了的：席菈拿桶壁上剩的黴多調一瓶
				if str(Game.session.state.get_flag(FLAG_CELLAR_WAY, "")) != "barrel":
					Game.session.state.items["sera_poison_vial"] = int(Game.session.state.items.get("sera_poison_vial", 0)) + 1
				_refresh_interactables()
				Game.session.autosave()
		NOODLE_REPORT_DIALOGUE:
			if _flag(FLAG_CELLAR_DONE) and not _flag(FLAG_CELLAR_PAID):
				Game.session.set_flag(FLAG_CELLAR_PAID, true)
				var st: GameState = Game.session.state
				st.items[NOODLE_TICKET] = int(st.items.get(NOODLE_TICKET, 0)) + 2
				st.items[WARM_PLUG] = int(st.items.get(WARM_PLUG, 0)) + 1
				Game.session.autosave()
		SHIELD_DIALOGUE:
			if slip_note != null and is_instance_valid(slip_note):
				slip_note.close(0.6)
			slip_note = null
			if _flag(FLAG_SHIELD_DONE):
				Game.session.autosave()
		SHIELD_REPORT_DIALOGUE:
			if not _flag(FLAG_SHIELD_PAID):
				Game.session.set_flag(FLAG_SHIELD_PAID, true)
				g.add_coins(SHIELD_REWARD)
				_hud.show_bark(_player, "BARK_NOEN_COINS", 2.4, "SPK_NOEN")
				Game.session.autosave()
		SERA_LIST_DIALOGUE:
			if list_note != null and is_instance_valid(list_note):
				list_note.close(0.6)
			list_note = null
			if _flag(FLAG_SERA_LIST):
				Game.session.autosave()
		RING_DIALOGUE:
			if _flag(FLAG_RING_TRY):
				Game.session.set_flag(FLAG_RING_TRY, false)
				try_on_ring()
		RING_BUY_DIALOGUE:
			if _flag(FLAG_RING_BUY):
				g.buy(RING_ID)
			elif g.is_trial():
				g.unequip_accessory()
			Game.session.set_flag(FLAG_RING_BUY, false)
			Game.session.set_flag(FLAG_RING_TRIED, true)
			Game.session.autosave()
	_refresh_interactables()


## 試戴：戴上（還不是自己的）、馬上給一次詛咒、打開裝備面板；面板關掉之後商人問買不買
func try_on_ring() -> void:
	var g := Gear.new(Game.session.state)
	if not g.equip_accessory(RING_ID, true):
		return
	_player.refresh_accessory_curse()
	var panel: GearPanel = _hud.gear_panel
	panel.player = _player
	panel.closed.connect(func() -> void: _talk(RING_BUY_DIALOGUE, ["SPK_NOEN", MERCHANT_KEY]), CONNECT_ONE_SHOT)
	panel.open()


func _mark(node_name: String, at: Vector3) -> void:
	var m := Marker3D.new()
	m.name = node_name
	m.position = at
	add_child(m)


## 地下室裡的東西：牆上的油燈（帶一盞燈）、鐵網後面抱著暖管的三團黴泥（只是模型；解掉的不擺）、酒桶的蓋子（裝進去之後才出現）
func _build_cellar_cast() -> void:
	var lamp: Node3D = PropModels.instance("quaternius/Lantern_Wall")
	var lamp_at: Vector3 = TownScenery.in_cellar(TownScenery.CELLAR_LAMP + Vector3(0, 1.7, -0.95))
	if lamp != null:
		lamp.name = "CellarLamp"
		lamp.position = lamp_at
		add_child(lamp)
		# 燈就在燈籠裡面、燈籠的模型是實心的：燈籠自己不投影子，不然整盞燈被它擋住（以前地下室其實只靠環境光）
		for n: Node in lamp.find_children("*", "MeshInstance3D", true, false):
			(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamp_light = OmniLight3D.new()
	lamp_light.name = "CellarLampLight"
	lamp_light.light_color = Color(1.0, 0.66, 0.34)
	lamp_light.light_energy = CELLAR_LAMP_ENERGY
	lamp_light.omni_range = 9.0
	lamp_light.shadow_enabled = true
	lamp_light.position = lamp_at + Vector3(0, 0.25, 0.8)
	add_child(lamp_light)
	var lid_mat := TownScenery.wood(Color(0.36, 0.24, 0.14), Vector3(1, 0, 0), 0.2)
	barrel_lid = MeshInstance3D.new()
	barrel_lid.name = "BarrelLid"
	var lm := CylinderMesh.new()
	lm.top_radius = 0.36
	lm.bottom_radius = 0.36
	lm.height = 0.05
	lm.material = lid_mat
	barrel_lid.mesh = lm
	barrel_lid.position = TownScenery.in_cellar(TownScenery.CELLAR_BARREL + Vector3(0, 0.92, 0))
	add_child(barrel_lid)
	var done: bool = _flag(FLAG_CELLAR_DONE)
	barrel_lid.visible = done and str(Game.session.state.get_flag(FLAG_CELLAR_WAY, "")) == "barrel"
	if done:
		return
	for i: int in TownScenery.CELLAR_SLIMES.size():
		var blob: Node3D = PropModels.instance("tripo/enemy_mold_slime")
		if blob == null:
			blob = _blob_stand_in()
		blob.name = "HidingMold%d" % i
		blob.position = TownScenery.in_cellar(TownScenery.CELLAR_SLIMES[i])
		blob.scale = Vector3.ONE * 0.6
		add_child(blob)
		hiding.append(blob)


## 黴泥的模型不在時的替身：一團灰綠的扁球
static func _blob_stand_in() -> Node3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.4
	sm.height = 0.5
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.55, 0.38)
	sm.material = m
	mi.mesh = sm
	mi.position.y = 0.25
	var root := Node3D.new()
	root.add_child(mi)
	return root


## 跟麵攤攤主說話：還沒解＝湯沒煮開、拜託下去看看；解了＝謝禮（只給一次）
func talk_vendor() -> bool:
	if is_return():
		return _talk(NOODLE_BACK_DIALOGUE, ["SPK_NOEN", VENDOR_KEY, Sera.NAME_KEY])
	if _flag(FLAG_CELLAR_DONE):
		return _talk(NOODLE_REPORT_DIALOGUE, ["SPK_NOEN", VENDOR_KEY])
	return _talk(NOODLE_ASK_DIALOGUE, ["SPK_NOEN", VENDOR_KEY])


## 走下地下室：畫面暗一下，換到地下室（可以出手）
func go_down() -> void:
	if in_cellar:
		return
	_hud.dim_blink(STAIRS_DIM.x, STAIRS_DIM.y, STAIRS_DIM.z, func() -> void:
		in_cellar = true
		scenery.set_cellar(true)
		_player.peaceful = false
		_player.global_position = TownScenery.CELLAR_IN
		_player.yaw = deg_to_rad(-60.0)
		_player.snap_camera()
		_refresh_interactables()
		if not _flag(FLAG_CELLAR_DONE):
			_hud.show_bark(_player, "BARK_NOEN_CELLAR", 3.0, "SPK_NOEN"))


## 爬上梯子：回到麵攤旁邊
func go_up() -> void:
	if not in_cellar:
		return
	_hud.dim_blink(STAIRS_DIM.x, STAIRS_DIM.y, STAIRS_DIM.z, func() -> void:
		in_cellar = false
		scenery.set_cellar(false)
		_player.peaceful = true
		_player.global_position = TownScenery.CELLAR_DOOR + Vector3(0, 0.05, 1.6)
		_player.yaw = deg_to_rad(180.0)
		_player.snap_camera()
		if lured != null and is_instance_valid(lured) and not lured.health.is_dead():
			# 爬出來的那一團還沒砍：縮回去
			lured.queue_free()
			lured = null
			_unhide_one()
		_refresh_interactables())


## 提燈：引最近的一團爬出鐵網（變成真的敵人，追著諾恩）
func lure_one() -> void:
	if hiding.is_empty() or (lured != null and is_instance_valid(lured) and not lured.health.is_dead()):
		return
	var blob: Node3D = hiding.pop_front()
	var at: Vector3 = blob.global_position
	blob.queue_free()
	lured = MoldSlime.new()
	lured.name = "LuredMold%d" % (TownScenery.CELLAR_SLIMES.size() - hiding.size())
	lured.position = Vector3(at.x, TownScenery.CELLAR_Y, TownScenery.CELLAR_MESH_Z + 0.9)
	lured.focus_player = true
	add_child(lured)
	lured.set_facing(PI)
	lured.health.died.connect(_on_lured_died)
	lamp_light.light_energy = CELLAR_LAMP_ENERGY * 1.5
	_hud.show_bark(_player, "BARK_NOEN_LURED", 2.2, "SPK_NOEN")
	_refresh_interactables()


func _unhide_one() -> void:
	var i: int = TownScenery.CELLAR_SLIMES.size() - hiding.size() - 1
	var blob: Node3D = _blob_stand_in() if PropModels.instance("tripo/enemy_mold_slime") == null else PropModels.instance("tripo/enemy_mold_slime")
	blob.name = "HidingMoldBack%d" % i
	blob.position = TownScenery.in_cellar(TownScenery.CELLAR_SLIMES[maxi(i, 0)])
	blob.scale = Vector3.ONE * 0.6
	add_child(blob)
	hiding.push_front(blob)


func _on_lured_died() -> void:
	lamp_light.light_energy = CELLAR_LAMP_ENERGY
	if hiding.is_empty():
		_finish_cellar("lamp")
	_refresh_interactables.call_deferred()


## 轉備用暖管的閥：第一次轉錯（熱水跑到樓上，客人的茶杯冒一個泡）；再轉一次，熱水進備用管，剩下的黴泥一起滾進空酒桶
func turn_valve() -> void:
	if hiding.is_empty() or _valve_wait > 0.0 or _rolling >= 0.0:
		return
	valve_turns += 1
	if valve_turns == 1:
		_valve_wait = VALVE_WRONG_SEC
		_hud.show_bark(vendor, "BARK_VENDOR_TEA", 3.0, VENDOR_KEY)
		Sfx.play_at(self, "swamp_bubble", _player.global_position + Vector3(0, 2.5, 0), -6.0)
		_refresh_interactables()
		return
	_rolling = 0.0
	_hud.show_bark(_player, "BARK_NOEN_ROLL", 2.4, "SPK_NOEN")
	_refresh_interactables()


func _tick_cellar(delta: float) -> void:
	if _valve_wait > 0.0:
		_valve_wait -= delta
		if _valve_wait <= 0.0:
			_refresh_interactables()
	if _rolling < 0.0:
		return
	_rolling += delta
	var k: float = clampf(_rolling / ROLL_SEC, 0.0, 1.0)
	var barrel: Vector3 = TownScenery.in_cellar(TownScenery.CELLAR_BARREL + Vector3(0, 0.7, 0))
	for i: int in hiding.size():
		var blob: Node3D = hiding[i]
		var from: Vector3 = TownScenery.in_cellar(TownScenery.CELLAR_SLIMES[TownScenery.CELLAR_SLIMES.size() - hiding.size() + i])
		var p: Vector3 = from.lerp(barrel, k)
		p.y += sin(k * PI) * 0.8
		blob.position = p
		blob.rotation.z = -k * TAU * 2.0
		blob.scale = Vector3.ONE * lerpf(0.6, 0.3, k)
	if k >= 1.0:
		for blob: Node3D in hiding:
			blob.queue_free()
		hiding.clear()
		_rolling = -1.0
		barrel_lid.visible = true
		_finish_cellar("barrel")
		_refresh_interactables()


func _finish_cellar(way: String) -> void:
	Game.session.set_flag(FLAG_CELLAR_WAY, way)
	Game.session.set_flag(FLAG_CELLAR_DONE, true)
	Game.session.autosave()
	_hud.show_bark(_player, "BARK_NOEN_CELLAR_DONE", 2.8, "SPK_NOEN")
