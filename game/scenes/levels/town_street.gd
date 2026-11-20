class_name TownStreet
extends StoryLevel
## 公會門外的賒帳街（docs/story/chapter-1-expanded.md「自由時段 A」；第一章 ⑤）。
## 主線：替莉莉絲把空籃子送回藥房（小學徒與兩副防毒面具、店主的五只保溫杯、藥錢記在誰名下）→ 從東門出發，換到腐敗之森。
## 看得到的東西在 TownScenery；這裡放人、劇情與規則。劇情只透過 Game.session.set_flag() 推進。

const QUEST: String = "ch1_main"
const STAGE_BASKET: String = "deliver_basket"
const STAGE_GATE: String = "east_gate"
const TOWN_STAGES: PackedStringArray = [STAGE_BASKET, STAGE_GATE]
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
	scenery = TownScenery.build(self)
	_mark("Pharmacy", TownScenery.PHARMACY_COUNTER + Vector3(0, 0, -1.4))
	_mark("EastGate", Vector3(TownScenery.GATE_X, 0, 0))
	_player.collision_mask |= GuildScenery.PEOPLE_LAYER
	_player.peaceful = true
	_player.global_position = ENTRANCE
	_player.yaw = deg_to_rad(ENTRANCE_YAW_DEG)
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
			r.line_shown.connect(_on_list_line))
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
		_player.peaceful = false
		_player.global_position = TownScenery.CELLAR_IN
		_player.yaw = deg_to_rad(-60.0)
		_player.snap_camera()
		_refresh_interactables()
		if str(args.get("demo", "")) == "lure":
			get_tree().create_timer(0.3).timeout.connect(lure_one)
	elif stage() == STAGE_BASKET:
		_hud.show_center_lines("CH1_TOWN_LINE1", "CH1_TOWN_LINE2", 5.5, Hud.CENTER_LINE2_COLOR)
	QualityPreset.apply_tree(self, Settings.quality as QualityPreset.Level)


func footstep_surface(_p: Vector3) -> String:
	return "stone"


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


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
	if not _flag(FLAG_LEFT):
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
		Sera.NAME_KEY:
			return sera
		MERCHANT_KEY:
			return merchant
		UNCLE_KEY:
			return uncle
		VENDOR_KEY:
			return vendor
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
	slip_note = PaperNote.create("AZHAN_SLIP_TITLE", SLIP_LINES, Color(0.9, 0.88, 0.8), Color(0.2, 0.18, 0.16))
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
	lamp_light = OmniLight3D.new()
	lamp_light.name = "CellarLampLight"
	lamp_light.light_color = Color(1.0, 0.66, 0.34)
	lamp_light.light_energy = 1.6
	lamp_light.omni_range = 7.0
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
	if _flag(FLAG_CELLAR_DONE):
		return _talk(NOODLE_REPORT_DIALOGUE, ["SPK_NOEN", VENDOR_KEY])
	return _talk(NOODLE_ASK_DIALOGUE, ["SPK_NOEN", VENDOR_KEY])


## 走下地下室：畫面暗一下，換到地下室（可以出手）
func go_down() -> void:
	if in_cellar:
		return
	_hud.dim_blink(STAIRS_DIM.x, STAIRS_DIM.y, STAIRS_DIM.z, func() -> void:
		in_cellar = true
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
	lamp_light.light_energy = 2.4
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
	lamp_light.light_energy = 1.6
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
