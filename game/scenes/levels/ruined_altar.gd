class_name RuinedAltar
extends StoryLevel
## 廢棄祭壇（第一章的 Boss，docs/story/chapter-1.md 節點 3；計畫在 docs/design/13-chapter-1-plan.md）。
## 從腐敗之森的祭壇路口走進來（ForestExplore 設 ch1.altar_gate_reached → 檢查點 ch1_altar 在這一關 → Game 換關卡）。
## 這一關的每一拍：走上石板，雷歐小隊倒在地上、魔像舉著拳頭 → 三人講幾句（ch1_altar_arrive）→ 魔像轉過來，諾恩走進疫病光環
## （全能力下降＋失血 → 全能力提升＋回血）→ Boss 戰 → 生命剩一半魔像狂暴，席菈退到後面裝禁藥 → 石化凝視：地上一道光從魔像連到她，
## 諾恩站上去擋住（石化 → 霸體無敵），沒擋到她被石化、過一陣子再來一次 → 擋住了她射出【混沌大災難藥劑】，砸中之後諾恩的下一刀粉碎核心
## → 戰後三人講幾句（ch1_altar_after，兩個回答）→ 拿到魔像核心。第一章回公會的結尾在下一段（公會大廳）。
## 看得到的場景在 AltarScenery，魔像自己的招式與階段在 PlagueGolem／GolemPhases；這裡放劇情、席菈在這一場要做的事、畫面上的字。
## 任務 data/quests/ch1_main.json 的 altar_arrive、boss、after_boss 三個階段。

const QUEST: String = "ch1_main"
const STAGE_ARRIVE: String = "altar_arrive"
const STAGE_BOSS: String = "boss"
const STAGE_AFTER: String = "after_boss"
## 劇情旗標：ch1.altar_talked（抵達的那段話講完，對話資料自己設）、ch1.golem_down（魔像倒了）、ch1.altar_done（戰後那段話講完，對話資料自己設）
const FLAG_TALKED: String = "ch1.altar_talked"
const FLAG_GOLEM_DOWN: String = "ch1.golem_down"
const FLAG_DONE: String = "ch1.altar_done"
const STAGES: PackedStringArray = [STAGE_ARRIVE, STAGE_BOSS, STAGE_AFTER, StoryLogic.QUEST_DONE]
const ARRIVE_DIALOGUE: String = "ch1_altar_arrive"
const AFTER_DIALOGUE: String = "ch1_altar_after"
const CHAOS_SOURCE: String = "sera_chaos"
const LEO_KEY: String = "SPK_LEO"
## 席菈跟在諾恩左後方一起走進來
const SERA_START_OFFSET: Vector3 = Vector3(-1.5, 0.0, 2.4)
## 魔像一開始站在這裡，舉著拳頭對著倒在地上的雷歐
const GOLEM_START: Vector3 = Vector3(-4.2, 0.0, -1.5)
## 雷歐小隊倒在石板的西邊：節點名、角色 id、位置、頭朝哪（度）、臉朝上還是朝下
const PARTY: Array[Array] = [
	["Leo", "leo", Vector3(-8.2, 0.0, -0.6), 100.0, true],
	["LeoMage", "leo_mage", Vector3(-10.4, 0.0, 2.8), 215.0, true],
	["LeoTank", "leo_tank", Vector3(-8.8, 0.0, -4.4), 20.0, false],
]
## 倒在地上的人比站著矮這麼多（對話鏡頭照這個放低）
const LYING_DROP: float = 0.95
## 走上石板（z 比這個小）雷歐就開口
const ARRIVE_Z: float = 15.0
## 抵達的那段話講完隔多久魔像才轉過來；魔像倒下隔多久戰後那段話才開始（等牠趴下去）；讀檔回到戰後隔多久開始
const WAKE_DELAY: float = 0.9
const AFTER_TALK_DELAY: float = 4.6
const AFTER_TALK_RELOAD: float = 1.4
## 席菈裝禁藥的時候退到石板邊上的這一圈（八個方向挑離魔像最遠的）
const HOLD_RING: float = 12.0
const GOLD: Color = Color(1.0, 0.84, 0.4)

var scenery: AltarScenery
var sera: Sera
var golem: PlagueGolem
var aura: PlagueAura
var talk_camera: TalkCamera
var chatter: SeraChatter
## 雷歐小隊：節點名 → 那個人
var party: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _spores: CPUParticles3D
var _wake_in: float = -1.0
var _after_talk_in: float = -1.0
## 飛在半路上的那一瓶禁藥（砸中才開核心）
var _chaos_vial: SeraVial
var _plague_level: float = 0.0
var _pulse_t: float = 0.0
## 開發用（連拍）：凝視一開始就把諾恩放到那道光上、核心一開就去砍
var _demo: String = ""
var _burst_on: String = ""

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
	var args: Dictionary = App.parse_user_args(OS.get_cmdline_user_args())
	if Game.session.in_story() and not stage() in STAGES:
		skip_to_altar(Game.session)
	# 截圖用：`--boss` 跳過抵達的那段話直接開打；`--phase2` 魔像一醒來就只剩一半的生命（馬上狂暴）
	if args.has("boss") or args.has("phase2") or args.has("after"):
		Game.session.set_flag(FLAG_TALKED, true)
	# `--after`：魔像已經倒了，進場一秒多之後戰後那段話開始；`--talk-skip=N` 對話一開始先按掉 N 句（拍第 N+1 句的鏡位）
	if args.has("after"):
		Game.session.set_flag(FLAG_GOLEM_DOWN, true)
	var talk_skip: int = int(str(args.get("talk-skip", "0")))
	if talk_skip > 0:
		Game.dialogue_started.connect(func(r: DialogueRunner) -> void:
			for i: int in talk_skip:
				r.advance.call_deferred())
	scenery = AltarScenery.build(self, _rng)
	_spores = ForestScenery.build_spores(self)
	_mark("AltarRuins", Vector3(0, 0, 6.0))
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
	_spawn_party()
	_spawn_sera()
	var st: GameState = Game.session.state
	if not bool(st.get_flag(FLAG_GOLEM_DOWN, false)):
		_spawn_golem()
		if args.has("phase2"):
			golem.health.hp = golem.health.max_hp * golem.phases.enrage_at
	elif stage() == STAGE_AFTER:
		_after_talk_in = AFTER_TALK_RELOAD  # 魔像倒了、話還沒講就離開的存檔：讀回來接著講
	Game.dialogue_ended.connect(_on_dialogue_ended)
	# 連拍用（scripts/burst.sh）：`--burst-on=enrage|gaze|fire|chaos|shatter` 那一刻開始拍；`--demo=block` 凝視一開始就把諾恩放到那道光上、
	# 核心一開就走過去砍（拍「擋住 → 禁藥 → 粉碎」那一串，不用真的打）
	_burst_on = str(args.get("burst-on", ""))
	_demo = str(args.get("demo", ""))
	if (_burst_on != "" or _demo != "") and golem != null:
		# 拍的時候諾恩站著不閃：不要讓他倒下（倒下會重來，等的那一拍永遠等不到）。
		# 吼與狂暴的那一段縮短（軟體算圖一幀要半秒，等十幾秒的遊戲時間要十分鐘）；`--demo=block` 連凝視的前兆也縮短
		_player.health.min_hp = 1.0
		golem.phases.roar_sec = 0.4
		golem.phases.rage_sec = 0.5
		if _demo == "block":
			golem.phases.gaze_sec = 1.2
	QualityPreset.apply_tree(self, Settings.quality as QualityPreset.Level)


func footstep_surface(p: Vector3) -> String:
	# 石板上是石頭的腳步聲；外圍跟森林一樣（借用雪的）
	return "stone" if Vector2(p.x, p.z).length() < AltarScenery.PLAZA_RADIUS else "snow"


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


## 石板的縫與符文現在多亮（0＝魔像沒醒或倒了、1＝醒著；測試用）
func plague_level() -> float:
	return _plague_level


func _physics_process(delta: float) -> void:
	if not Game.session.in_story():
		return
	_player.global_position = AltarScenery.keep_inside(_player.global_position)
	_spores.global_position = Vector3(_player.global_position.x, 1.5, _player.global_position.z)
	# 魔像的疫病醒著：石板的縫與柱子上的符文一下一下跳
	_pulse_t += delta
	# 光環掛在魔像身上：牠倒下幾秒後連光環一起被釋放，所以每次都先確認還在
	var plagued: bool = is_instance_valid(aura) and aura.active
	_plague_level = move_toward(_plague_level, 1.0 if plagued else 0.0, delta * 0.8)
	scenery.set_plague(_plague_level, 0.5 + 0.5 * sin(_pulse_t * 2.6))
	sera.force_mask = plagued and aura.contains(sera.global_position)
	match stage():
		STAGE_ARRIVE:
			if _player.global_position.z < ARRIVE_Z:
				Game.start_dialogue(ARRIVE_DIALOGUE)
		STAGE_BOSS:
			_tick_fight(delta)
		STAGE_AFTER:
			if _after_talk_in >= 0.0 and not Game.is_in_dialogue():
				_after_talk_in -= delta
				if _after_talk_in < 0.0 and not Game.start_dialogue(AFTER_DIALOGUE):
					_after_talk_in = 0.2


## Boss 戰中每一幀：魔像醒來、第一次走進光環的說明、核心還在的提示、禁藥砸中
func _tick_fight(delta: float) -> void:
	if golem == null or not is_instance_valid(golem) or golem.health.is_dead():
		return
	var st: GameState = Game.session.state
	if _demo == "block" and golem.phases.phase == GolemPhases.Phase.GAZE:
		# 開發用：凝視的前兆中一直站在那道光上（席菈還在跑也跟著）
		_player.global_position = golem.global_position.lerp(sera.global_position, 0.6) + Vector3(0, 0.05, 0)
	if not golem.awake:
		if _wake_in < 0.0:
			_wake_in = WAKE_DELAY
		if not Game.is_in_dialogue():
			_wake_in -= delta
			if _wake_in < 0.0:
				golem.wake()
		return
	if _player.status_effects.has(StatusEffects.PLAGUE) and st.grant_once("ch1.aura_seen"):
		_hud.show_center_lines("CH1_AURA_LINE1", "CH1_AURA_LINE2", 6.0)
		_hud.show_bark(party["Leo"] as Node3D, "BARK_LEO_AURA", 3.2, LEO_KEY, Hud.BARK_COLOR, 0.9)
	if sera.masked and sera.force_mask and st.grant_once("ch1.aura_mask_bark"):
		_hud.show_bark(sera, "BARK_SERA_AURA", 3.2, Sera.NAME_KEY)
	# 生命扣到底線就扣不下去了（核心還在）：第一次的時候席菈喊一聲，不然像壞掉
	if golem.health.min_hp > 0.0 and golem.health.hp <= golem.health.min_hp + 0.5 and st.grant_once("ch1.core_bark"):
		_hud.show_bark(sera, "BARK_SERA_CORE", 3.0, Sera.NAME_KEY)
	if _chaos_vial != null and (not is_instance_valid(_chaos_vial) or _chaos_vial.landed):
		_chaos_vial = null
		golem.open_core()
		_hud.show_center_lines("CH1_CHAOS_LINE1", "CH1_CHAOS_LINE2", 8.0)
		if _burst_on == "chaos":
			App.burst_start_in(1)
		if _demo == "block":
			# 走到魔像面前砍一刀
			var to_golem: Vector3 = golem.global_position - _player.global_position
			_player.global_position = golem.global_position - to_golem.normalized() * 2.2
			_player.yaw = atan2(-to_golem.x, -to_golem.z)
			get_tree().create_timer(0.9).timeout.connect(func() -> void:
				if _burst_on == "shatter":
					App.burst_start_in(1)
				_player.start_attack())


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
	sera.fired.connect(_on_sera_fired)
	sera.unpetrified.connect(_on_sera_freed)
	add_child(sera)
	chatter = SeraChatter.attach(self, sera, _hud)
	talk_camera = TalkCamera.new()
	talk_camera.name = "TalkCamera"
	talk_camera.cast = {"SPK_NOEN": _player, Sera.NAME_KEY: sera, LEO_KEY: party["Leo"] as Node3D}
	add_child(talk_camera)


## 雷歐小隊：三個人倒在石板西邊（模型躺平；沒有倒地的動作，用站著的姿勢整個放倒）。不擋路。
func _spawn_party() -> void:
	for spec: Array in PARTY:
		var who := Node3D.new()
		who.name = str(spec[0])
		who.position = spec[2] as Vector3
		who.rotation.y = deg_to_rad(float(spec[3]))
		who.set_meta(TalkCamera.DROP_META, LYING_DROP)
		var body := Puppet.new()
		body.name = "Puppet"
		body.character_id = str(spec[1])
		# 節點的原點在胸口附近（對話鏡頭對著這裡）：臉朝上＝頭往 +Z 躺、臉朝下＝頭往 −Z 趴
		var face_up: bool = bool(spec[4])
		body.rotation.x = PI * 0.5 if face_up else -PI * 0.5
		body.position = Vector3(0.0, 0.16, -1.25 if face_up else 1.25)
		who.add_child(body)
		add_child(who)
		ContactShadow.attach(who, 1.6, 0.4)
		party[str(spec[0])] = who


func _spawn_golem() -> void:
	golem = PlagueGolem.new()
	golem.name = "Golem"
	golem.position = GOLEM_START
	golem.gaze_target = sera
	add_child(golem)
	# 面向倒在地上的雷歐
	var to_leo: Vector3 = (party["Leo"] as Node3D).global_position - GOLEM_START
	golem.set_facing(atan2(-to_leo.x, -to_leo.z))
	aura = PlagueAura.create(CombatTuning.num("plague_golem.aura_radius", 13.0))
	golem.add_child(aura)
	golem.aura = aura
	golem.enraged.connect(_on_golem_enraged)
	golem.gaze_started.connect(_on_gaze_started)
	golem.gaze_fired.connect(_on_gaze_fired)
	golem.core_shattered.connect(_on_core_shattered)
	golem.health.died.connect(_on_golem_down)


## 狂暴：席菈退到離魔像最遠的石板邊上，開始裝禁藥（不跟、不射平常的藥、玩家也要不到）
func _on_golem_enraged() -> void:
	_hud.show_center_lines("CH1_ENRAGE_LINE1", "CH1_ENRAGE_LINE2", 6.0)
	_hud.show_bark(sera, "BARK_SERA_FORBIDDEN", 3.6, Sera.NAME_KEY)
	sera.hold_at = hold_spot(golem.global_position)
	sera.hands_full = true
	chatter.hint_paused = true
	_hud.set_extra_hint("")
	if _burst_on == "enrage":
		App.burst_start_in(1)


## 石板邊上離 from 最遠的那一個位置
static func hold_spot(from: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_d: float = -1.0
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0
		var p := Vector3(cos(a), 0.0, sin(a)) * HOLD_RING
		# 北邊是祭壇的台階，不站那裡
		if p.distance_to(AltarScenery.ALTAR_POS) < 5.0:
			continue
		var d: float = Vector2(p.x - from.x, p.z - from.z).length()
		if d > best_d:
			best_d = d
			best = p
	return best


func _on_gaze_started() -> void:
	_hud.show_center_lines("CH1_GAZE_LINE1", "CH1_GAZE_LINE2", golem.phases.gaze_sec + 0.5)
	_hud.set_extra_hint("HINT_GAZE")
	if _burst_on == "gaze":
		App.burst_start_in(1)


## 凝視打出去：擋住了＝席菈把禁藥射出來；沒擋住＝她被石化，等魔像下一次凝視
func _on_gaze_fired(blocked: bool) -> void:
	_hud.set_extra_hint("")
	if _burst_on == "fire":
		App.burst_start_in(1)
	if blocked:
		_hud.show_center_lines("CH1_BLOCKED_LINE1", "CH1_BLOCKED_LINE2", 5.0, GOLD)
		_hud.show_bark(sera, "BARK_SERA_CHAOS", 3.0, Sera.NAME_KEY)
		sera.shoot(CHAOS_SOURCE)
	else:
		sera.petrify(CombatTuning.num("plague_golem.sera_stoned_sec", 6.0))
		_hud.show_center_lines("CH1_STONED_LINE1", "CH1_STONED_LINE2", 6.0)


func _on_sera_fired(vial: SeraVial) -> void:
	if vial.source == CHAOS_SOURCE:
		_chaos_vial = vial


func _on_sera_freed() -> void:
	if golem != null and is_instance_valid(golem) and not golem.health.is_dead():
		_hud.show_bark(sera, "BARK_SERA_FREED", 2.8, Sera.NAME_KEY)


## 核心被粉碎的那一刀：停久一點
func _on_core_shattered() -> void:
	Game.hit_stop(0.35)
	_player.shake(0.8)


## 魔像倒了：光環消失、席菈回到諾恩身邊，隔一下三個人講話
func _on_golem_down() -> void:
	Game.session.set_flag(FLAG_GOLEM_DOWN, true)
	_hud.show_banner("CH1_GOLEM_DOWN", 4.0)
	_hud.set_extra_hint("")
	sera.hold_at = Vector3.INF
	sera.hands_full = false
	chatter.hint_paused = false
	_after_talk_in = AFTER_TALK_DELAY


func _on_dialogue_ended(dialogue_id: String) -> void:
	if dialogue_id == AFTER_DIALOGUE:
		_hud.show_banner("CH1_GOT_CORE", 4.0)


func _mark(node_name: String, at: Vector3) -> void:
	var m := Marker3D.new()
	m.name = node_name
	m.position = at
	add_child(m)
