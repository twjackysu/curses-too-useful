class_name RuinedAltar
extends StoryLevel
## 廢棄祭壇（第一章的 Boss，docs/story/chapter-1.md 節點 3；計畫在 docs/design/13-chapter-1-plan.md）。
## 從腐敗之森的祭壇路口走進來（ForestExplore 設 ch1.altar_gate_reached → 檢查點 ch1_altar 在這一關 → Game 換關卡）。
## 看得到的場景在 AltarScenery；這裡放規則與劇情。任務 data/quests/ch1_main.json 的 altar_arrive、boss、after_boss 三個階段。

const QUEST: String = "ch1_main"
const STAGE_ARRIVE: String = "altar_arrive"
const STAGE_BOSS: String = "boss"
const STAGE_AFTER: String = "after_boss"
## 劇情旗標：ch1.altar_talked（抵達的那段話講完，對話資料自己設）、ch1.golem_down（魔像倒了）、ch1.altar_done（戰後那段話講完，對話資料自己設）
const FLAG_TALKED: String = "ch1.altar_talked"
const FLAG_GOLEM_DOWN: String = "ch1.golem_down"
const FLAG_DONE: String = "ch1.altar_done"
const STAGES: PackedStringArray = [STAGE_ARRIVE, STAGE_BOSS, STAGE_AFTER, StoryLogic.QUEST_DONE]
## 席菈跟在諾恩左後方一起走進來
const SERA_START_OFFSET: Vector3 = Vector3(-1.5, 0.0, 2.4)

var scenery: AltarScenery
var sera: Sera
var talk_camera: TalkCamera
var chatter: SeraChatter
var _rng := RandomNumberGenerator.new()
var _spores: CPUParticles3D

@onready var _player: PlayerController = $Player
@onready var _hud: Hud = $Hud


## 把前面的劇情跳過，直接到「剛走進祭壇」（開發旗標 `--level=ruined_altar` 與測試用）。
static func skip_to_altar(session: GameSession) -> void:
	for flag: String in [CorruptForest.FLAG_JOINED, CorruptForest.FLAG_REVERSAL, CorruptForest.FLAG_GATE_TALK,
			CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		session.set_flag(flag, true)
	session.add_flag(ForestExplore.FLAG_MUSHROOMS, ForestExplore.MUSHROOM_NEED)
	session.set_flag(ForestExplore.FLAG_ALTAR, true)


func _ready() -> void:
	_rng.seed = 20261116
	if Game.session.in_story() and not stage() in STAGES:
		skip_to_altar(Game.session)
	scenery = AltarScenery.build(self, _rng)
	_spores = ForestScenery.build_spores(self)
	_mark("AltarRuins", Vector3(0, 0, 4.0))
	var args: Dictionary = App.parse_user_args(OS.get_cmdline_user_args())
	_player.global_position = AltarScenery.ENTRANCE
	# 截圖用：`--at=x,z` 把諾恩放到別的地方、`--cam-yaw=90` 鏡頭繞到側面、`--weapon=split_blade` 換一把武器
	var at: PackedStringArray = str(args.get("at", "")).split(",")
	if at.size() == 2:
		_player.global_position = Vector3(float(at[0]), AltarScenery.ENTRANCE.y, float(at[1]))
	if args.has("cam-yaw"):
		_player.yaw = deg_to_rad(float(str(args["cam-yaw"])))
	if args.has("weapon"):
		_player.equip(str(args["weapon"]))
	_player.snap_camera()
	_spawn_sera()
	QualityPreset.apply_tree(self, Settings.quality as QualityPreset.Level)


func footstep_surface(p: Vector3) -> String:
	# 石板上是石頭的腳步聲；外圍跟森林一樣（借用雪的）
	return "stone" if Vector2(p.x, p.z).length() < AltarScenery.PLAZA_RADIUS else "snow"


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


func _physics_process(_delta: float) -> void:
	if not Game.session.in_story():
		return
	_player.global_position = AltarScenery.keep_inside(_player.global_position)
	_spores.global_position = Vector3(_player.global_position.x, 1.5, _player.global_position.z)


func _spawn_sera() -> void:
	sera = Sera.new()
	sera.name = "Sera"
	sera.target = _player
	sera.position = _player.global_position + SERA_START_OFFSET
	sera.ask_enabled = true
	# 跟森林裡一樣：她自己輪流射兩種藥；營火聊過的話，向她要的是連攜的那一瓶
	sera.vial_cycle = ForestExplore.SERA_VIALS
	if bool(Game.session.state.get_flag(ForestExplore.FLAG_DUO, false)):
		sera.ask_source = ForestExplore.DUO_SOURCE
	add_child(sera)
	chatter = SeraChatter.attach(self, sera, _hud)
	talk_camera = TalkCamera.new()
	talk_camera.name = "TalkCamera"
	talk_camera.cast = {"SPK_NOEN": _player, Sera.NAME_KEY: sera}
	add_child(talk_camera)


func _mark(node_name: String, at: Vector3) -> void:
	var m := Marker3D.new()
	m.name = node_name
	m.position = at
	add_child(m)
