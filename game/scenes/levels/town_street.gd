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
const SERA_FACING_DEG: float = -150.0
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
	Ambience.play(self, MURMUR_SFX, MURMUR_DB, "StreetMurmur")
	var talk_skip: int = int(str(args.get("talk-skip", "0")))
	if talk_skip > 0:
		Game.dialogue_started.connect(func(r: DialogueRunner) -> void:
			for i: int in talk_skip:
				skip_line.call_deferred(r))
	if stage() == STAGE_BASKET:
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
	_player.global_position = TownScenery.keep_inside(_player.global_position)
	_gate_nag_t = maxf(_gate_nag_t - delta, 0.0)
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
	return null


func _mark(node_name: String, at: Vector3) -> void:
	var m := Marker3D.new()
	m.name = node_name
	m.position = at
	add_child(m)
