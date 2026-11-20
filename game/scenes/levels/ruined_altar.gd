class_name RuinedAltar
extends StoryLevel
## 廢棄祭壇（第一章的 Boss，docs/story/chapter-1.md 節點 3；計畫在 docs/design/13-chapter-1-plan.md）。
## 從腐敗之森的祭壇路口走進來（ForestExplore 設 ch1.altar_gate_reached → 檢查點 ch1_altar 在這一關 → Game 換關卡）。
## 這一關的每一拍：走上石板，雷歐小隊倒在地上、魔像舉著拳頭 → 三人講幾句（ch1_altar_arrive）→ 魔像轉過來，諾恩走進疫病光環
## （全能力下降＋失血 → 全能力提升＋回血）→ Boss 戰 → 生命剩一半魔像狂暴，席菈退到後面裝禁藥 → 石化凝視：地上一道光從魔像連到她，
## 諾恩站上去擋住（石化 → 霸體無敵），沒擋到她被石化、過一陣子再來一次 → 擋住了她射出【混沌大災難藥劑】，砸中之後諾恩的下一刀粉碎核心
## → 戰後三人講幾句（ch1_altar_after，兩個回答）→ 拿到魔像核心 → 隔一下換到公會大廳演第一章的結尾（GuildHall）。
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
## 魔像倒在哪裡、面向哪裡（讀檔回來那一堆碎石與核心照這個擺；沒存的舊存檔用牠一開始站的地方）
const FLAG_DOWN_X: String = "ch1.golem_down_x"
const FLAG_DOWN_Z: String = "ch1.golem_down_z"
const FLAG_DOWN_YAW: String = "ch1.golem_down_yaw"
const STAGES: PackedStringArray = [STAGE_ARRIVE, STAGE_BOSS, STAGE_AFTER]
const ARRIVE_DIALOGUE: String = "ch1_altar_arrive"
const AFTER_DIALOGUE: String = "ch1_altar_after"
const CHAOS_SOURCE: String = "sera_chaos"
const LEO_KEY: String = "SPK_LEO"
## 席菈跟在諾恩左後方一起走進來
const SERA_START_OFFSET: Vector3 = Vector3(-1.5, 0.0, 2.4)
## 魔像一開始站在這裡，舉著拳頭對著倒在地上的雷歐
const GOLEM_START: Vector3 = Vector3(-4.2, 0.0, -1.5)
## 雷歐小隊倒在石板的西邊：節點名、角色 id、位置、頭朝哪（度）、臉朝上還是朝下、魔像倒了之後會不會撐起上身坐好。
## 仰躺的兩個是被打飛往後倒的：頭朝外、腳朝著魔像——坐起來的時候正好面向魔像與諾恩（以前頭朝著魔像，坐起來會背對大家）。
## 趴著的坦克昏過去了，打完還是趴著
const PARTY: Array[Array] = [
	["Leo", "leo", Vector3(-8.2, 0.0, -0.6), 283.0, true, true],
	["LeoMage", "leo_mage", Vector3(-10.4, 0.0, 2.8), 294.0, true, true],
	["LeoTank", "leo_tank", Vector3(-8.8, 0.0, -4.4), 20.0, false, false],
]
## 倒在地上的人比站著矮這麼多（對話鏡頭照這個放低）；坐起來之後
const LYING_DROP: float = 0.95
const SITTING_DROP: float = 0.7
## 仰躺的人：身體（Puppet，原點在腳底）離地多高、腳底在節點的哪裡（頭往 +Z）
const LIE_Y: float = 0.16
const LIE_FEET_Z: float = -1.25
## 撐起上身：轉的支點是骨盆（站著時離腳底 SIT_PIVOT），坐好之後骨盆離地 SIT_HIP（common.py 的 sit_ground 坐在地上）
const SIT_PIVOT: float = 0.9
const SIT_HIP: float = 0.14
const SIT_POSE: String = "sit_ground"
## 魔像倒下之後隔多久雷歐撐起來（牠跪下、往前垮的那幾秒）、要多久、法師比他晚多久
const SIT_UP_DELAY: float = 2.4
const SIT_UP_SEC: float = 1.2
const SIT_UP_STAGGER: float = 0.7
## 坐起來了（節點上的 meta；測試看這個）
const SAT_META: String = "sat_up"
## 魔像舉著拳頭時最高到多高（抵達的那段話，鏡頭把牠與雷歐框在一起時照這個高度框）
const GOLEM_TALK_HEIGHT: float = 4.8
## 走上石板（z 比這個小）雷歐就開口
const ARRIVE_Z: float = 15.0
## 抵達的那段話講完隔多久魔像才轉過來；魔像倒下隔多久戰後那段話才開始（等牠趴下去）；讀檔回到戰後隔多久開始
const WAKE_DELAY: float = 0.9
const AFTER_TALK_DELAY: float = 4.6
const AFTER_TALK_RELOAD: float = 1.4
## 戰後那段話講完隔多久換到公會大廳（先讓「獲得魔像核心」那一行出來）
const RETURN_DELAY: float = 2.6
## 席菈裝禁藥的時候退到石板邊上的這一圈（八個方向挑離魔像最遠的）
const HOLD_RING: float = 12.0
## 粉碎核心的那一刀：先定格多久、再用幾倍速的慢動作演多久（真實時間）；鏡頭切到兩人的側面停多久才滑回來（停到魔像倒地）、
## 離兩人多遠、多高、看著多高的地方（放低往上看：魔像才顯得大）
const FINISH_STOP_SEC: float = 0.35
const FINISH_SLOW_SEC: float = 1.1
const FINISH_SLOW_SCALE: float = 0.25
const FINISH_HOLD_SEC: float = 3.5
const FINISH_CAM_DIST: float = 5.4
const FINISH_CAM_HEIGHT: float = 1.3
const FINISH_AIM_HEIGHT: float = 1.8
## 戰後那段話講完、等卡出來的那幾秒：鏡頭切到兩人的側面（席菈 → 諾恩的連線旁邊），看核心飛到他肩上
const OUTRO_DIST: float = 4.2
const OUTRO_HEIGHT: float = 1.45
const OUTRO_AIM: float = 1.3
const PLAYER_CAMERA: NodePath = ^"CameraRig/Pitch/SpringArm3D/Camera3D"
## 滾出來的核心離躺在地上的人至少多遠（節點在胸口附近）
const CORE_PARTY_GAP: float = 1.6
## 戰後那段話講完，核心飛到諾恩肩上要多久
const CORE_TAKE_SEC: float = 0.7
## 第一次走進光環的那兩行說明出來之後，隔多久席菈才喊面具的那一句（開打的頭幾秒字太多：說明、雷歐的一句、魔像的第一拳都擠在這時候）
const AURA_BARK_GAP: float = 7.0
const GOLD: Color = Color(1.0, 0.84, 0.4)
## 祭壇的環境音（石柱間的風、水滴、低低的疫病嗡嗡聲；整片）與 Boss 戰的配樂（魔像醒來淡入、粉碎核心之後淡出）
const AIR_SFX: String = "altar_air"
const AIR_DB: float = -14.0
const BOSS_MUSIC: String = "boss_theme"
const BOSS_MUSIC_DB: float = -6.0
const BOSS_MUSIC_FADE_IN: float = 1.5
const BOSS_MUSIC_FADE_OUT: float = 3.0
## 狂暴之後配樂整首升半音、快 6%（不另外做一首：同一首聽得出「變急了」），大聲一點
const BOSS_RAGE_PITCH: float = 1.06
const BOSS_RAGE_DB: float = 2.0
const BOSS_RAGE_SHIFT_SEC: float = 1.5

var scenery: AltarScenery
var sera: Sera
var golem: PlagueGolem
var aura: PlagueAura
var talk_camera: TalkCamera
var chatter: SeraChatter
## 換到公會大廳之前的那張卡（還沒到那一拍是 null）
var card: ChapterCard
## 魔像倒地之後滾出來的核心（還沒倒是 null）；粉碎那一刀的側面鏡頭（演完自己收掉）
var core: GolemCore
var finisher: FinisherCamera
## 戰後那段話講完、等卡出來的那幾秒的鏡頭（還沒到那一拍是 null）
var outro_camera: FinisherCamera
## 雷歐小隊：節點名 → 那個人
var party: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _spores: CPUParticles3D
var _wake_in: float = -1.0
var _after_talk_in: float = -1.0
var _return_in: float = -1.0
var _party_sit_in: float = -1.0
## 諾恩的霸體金光現在收成細的輪廓嗎（_process）
var _glow_calmed: bool = false
## 飛在半路上的那一瓶禁藥（砸中才開核心）
var _chaos_vial: SeraVial
var _plague_level: float = 0.0
var _pulse_t: float = 0.0
var _aura_bark_in: float = 0.0
## 開發用（連拍）：凝視一開始就把諾恩放到那道光上、核心一開就去砍
var _demo: String = ""
## Boss 戰的配樂（魔像醒來才有；粉碎核心之後淡掉、釋放）
var boss_music: AudioStreamPlayer
var _burst_on: String = ""

@onready var _player: PlayerController = $Player
@onready var _hud: Hud = $Hud


## 把前面的劇情跳過，直接到「剛走進祭壇」（開發旗標 `--level=ruined_altar` 與測試用）。
static func skip_to_altar(session: GameSession) -> void:
	GuildHall.skip_opening(session)
	TownStreet.skip_town(session)
	for flag: String in [CorruptForest.FLAG_JOINED, CorruptForest.FLAG_REVERSAL, CorruptForest.FLAG_GATE_TALK,
			CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		session.set_flag(flag, true)
	session.add_flag(ForestExplore.FLAG_MUSHROOMS, ForestExplore.MUSHROOM_NEED)
	session.set_flag(ForestExplore.FLAG_ALTAR, true)


func _ready() -> void:
	_rng.seed = 20261116
	var args: Dictionary = Game.level_args()
	if Game.session.in_story() and not stage() in STAGES:
		skip_to_altar(Game.session)
	# 截圖用：`--boss` 跳過抵達的那段話直接開打；`--phase2` 魔像一醒來就只剩一半的生命（馬上狂暴）
	if args.has("boss") or args.has("phase2") or args.has("after") or args.has("floor"):
		Game.session.set_flag(FLAG_TALKED, true)
	# `--after`：魔像已經倒了，進場一秒多之後戰後那段話開始；`--talk-skip=N` 對話一開始先按掉 N 句（遇到選項選第一個；拍第 N+1 句的鏡位，
	# 例：`--after --talk-skip=8` 整段講完、直接看等卡的鏡頭）
	if args.has("after"):
		Game.session.set_flag(FLAG_GOLEM_DOWN, true)
	var talk_skip: int = int(str(args.get("talk-skip", "0")))
	if talk_skip > 0:
		Game.dialogue_started.connect(func(r: DialogueRunner) -> void:
			for i: int in talk_skip:
				skip_line.call_deferred(r))
	_burst_on = str(args.get("burst-on", ""))
	_demo = str(args.get("demo", ""))
	scenery = AltarScenery.build(self, _rng)
	_spores = ForestScenery.build_spores(self)
	Ambience.play(self, AIR_SFX, AIR_DB, "AltarAir")
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
		# `--floor`：生命一開始就在底線（核心還在、扣不下去）——配 `--tap=attack --burst-on=hit` 拍「打不下去」的那一圈
		if args.has("floor"):
			golem.health.hp = golem.health.max_hp * golem.phases.hp_floor
	else:
		# 魔像倒了之後讀檔回來：牠崩成的那一堆碎石還在倒下的地方
		var pile: RubblePile = RubblePile.create()
		add_child(pile)
		pile.position = golem_down_spot() - golem_down_facing() * PlagueGolem.RUBBLE_BACK
		pile.face_along(golem_down_facing())
	if bool(st.get_flag(FLAG_GOLEM_DOWN, false)) and stage() == STAGE_AFTER:
		_after_talk_in = AFTER_TALK_RELOAD  # 魔像倒了、話還沒講就離開的存檔：讀回來接著講
		core = GolemCore.create()
		core.position = PlagueGolem.core_rest_spot(golem_down_spot(), golem_down_facing(), core_spot_clear)
		add_child(core)
	Game.dialogue_ended.connect(_on_dialogue_ended)
	# 連拍用（scripts/burst.sh）：`--burst-on=hit|enrage|gaze|fire|chaos|shatter|down` 那一刻開始拍（hit＝魔像第一次被砍中、down＝魔像倒下）；`--demo=block` 凝視一開始就把諾恩放到那道光上、
	# 核心一開就走過去砍（拍「擋住 → 禁藥 → 粉碎」那一串，不用真的打）；`--demo=miss` 只把凝視的前兆縮短（拍沒擋到的那一次）
	if (_burst_on != "" or _demo != "") and golem != null:
		# 拍的時候諾恩站著不閃：不要讓他倒下（倒下會重來，等的那一拍永遠等不到）。
		# 吼與狂暴的那一段縮短（軟體算圖一幀要半秒，等十幾秒的遊戲時間要十分鐘）；`--demo=block` 連凝視的前兆也縮短
		_player.health.min_hp = 1.0
		# 第一次走進光環的那幾行字當成看過了（不然會蓋在要拍的東西上）
		Game.session.state.grant_once("ch1.aura_seen")
		Game.session.state.grant_once("ch1.aura_mask_bark")
		golem.phases.roar_sec = 0.4
		golem.phases.rage_sec = 0.5
		if _demo in ["block", "miss"]:
			golem.phases.gaze_sec = 1.2
	QualityPreset.apply_tree(self, Settings.quality as QualityPreset.Level)


## 魔像倒在哪裡（存檔裡的；沒存就是牠一開始站的地方）
static func golem_down_spot() -> Vector3:
	var st: GameState = Game.session.state
	return Vector3(float(st.get_flag(FLAG_DOWN_X, GOLEM_START.x)), 0.0, float(st.get_flag(FLAG_DOWN_Z, GOLEM_START.z)))


## 魔像倒下時面向哪裡（水平；沒存就是一開始面向雷歐的方向）
static func golem_down_facing() -> Vector3:
	var yaw: float = float(Game.session.state.get_flag(FLAG_DOWN_YAW, atan2(-(PARTY[0][2] as Vector3).x + GOLEM_START.x, -(PARTY[0][2] as Vector3).z + GOLEM_START.z)))
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


## 滾出來的核心可以停在這裡嗎：空著的石板（不在斷柱、倒著的那兩截、祭壇的台階上，不在石板邊上），不壓到躺著的雷歐小隊
static func core_spot_clear(p: Vector3) -> bool:
	if not AltarScenery.open_floor(p, GolemCore.RADIUS):
		return false
	for spec: Array in PARTY:
		# 倒在地上的人：節點在胸口附近，從頭到腳約 1.8 m
		if Vector2(p.x, p.z).distance_to(Vector2((spec[2] as Vector3).x, (spec[2] as Vector3).z)) < CORE_PARTY_GAP:
			return false
	return true


func footstep_surface(p: Vector3) -> String:
	# 石板上是石頭的腳步聲；外圍跟森林一樣是土
	return "stone" if Vector2(p.x, p.z).length() < AltarScenery.PLAZA_RADIUS else "dirt"


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


## 石板的縫與符文現在多亮（0＝魔像沒醒或倒了、1＝醒著；測試用）
func plague_level() -> float:
	return _plague_level


func _process(_delta: float) -> void:
	# 粉碎那一刀的側面鏡頭停著的那幾秒：HUD 收起來（只看得到兩個人與炸開的核心）
	var holding: bool = finisher != null and is_instance_valid(finisher) and finisher.is_holding()
	_hud.cinematic = holding
	# 諾恩的霸體金光收成細的輪廓（看得出他的樣子）：核心變成金色、等著被砍的時候（他站在金色的核心前面，兩個都金的會糊成一片）
	# 與那一刀的側面鏡頭裡
	var calm: bool = holding or (golem != null and is_instance_valid(golem) and golem.is_core_marked())
	if calm != _glow_calmed:
		_glow_calmed = calm
		_player.calm_body_glow(calm)


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
	if _party_sit_in >= 0.0:
		_party_sit_in -= delta
		if _party_sit_in < 0.0:
			_sit_up_party()
	if _return_in >= 0.0:
		_return_in -= delta
		if _return_in < 0.0:
			card = ChapterCard.play(self, "CARD_RETURN_SMALL", "CARD_RETURN_TITLE", Game.go_to_checkpoint_level)
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
		_set_brew(-1.0)
		return
	# 席菈的禁藥裝到幾成：她跪著裝、生命條下面那一條（凝視打出去的那一刻剛好裝滿）
	_set_brew(golem.phases.brew_progress())
	var st: GameState = Game.session.state
	if _demo == "block" and golem.phases.phase == GolemPhases.Phase.GAZE:
		# 開發用：凝視的前兆中一直站在那道光上（席菈還在跑也跟著），鏡頭斜斜地看著魔像
		_player.global_position = golem.global_position.lerp(sera.global_position, 0.6) + Vector3(0, 0.05, 0)
		var to_eye: Vector3 = golem.global_position - _player.global_position
		_player.yaw = atan2(-to_eye.x, -to_eye.z) + deg_to_rad(25.0)
	if not golem.awake:
		if _wake_in < 0.0:
			_wake_in = WAKE_DELAY
		if not Game.is_in_dialogue():
			_wake_in -= delta
			if _wake_in < 0.0:
				golem.wake()
				if boss_music == null:
					boss_music = Ambience.music(self, BOSS_MUSIC, BOSS_MUSIC_DB, BOSS_MUSIC_FADE_IN, "BossMusic")
		return
	if _player.status_effects.has(StatusEffects.PLAGUE) and st.grant_once("ch1.aura_seen"):
		_hud.show_center_lines("CH1_AURA_LINE1", "CH1_AURA_LINE2", 6.0)
		_hud.show_bark(party["Leo"] as Node3D, "BARK_LEO_AURA", 3.2, LEO_KEY, Hud.BARK_COLOR, 0.9)
		_aura_bark_in = AURA_BARK_GAP
	_aura_bark_in = maxf(_aura_bark_in - delta, 0.0)
	if _aura_bark_in <= 0.0 and sera.masked and sera.force_mask and st.grant_once("ch1.aura_mask_bark"):
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
	# 跟森林裡一樣：她自己輪流射兩種藥、向她要的有兩瓶（煙霧彈、紅的那一瓶）；營火聊過的話，煙霧彈是連攜的那一瓶
	sera.vial_cycle = ForestExplore.SERA_VIALS
	sera.ask_extra = ForestExplore.SERA_VIALS[1]
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
		# 倒在地上的樣子（兩手攤開、膝蓋立起來／一手往前伸、臉側貼地），不是站著的人整個放倒
		body.pose = "down_back" if face_up else "down_front"
		body.position = Vector3(0.0, LIE_Y, LIE_FEET_Z if face_up else -LIE_FEET_Z)
		who.add_child(body)
		add_child(who)
		ContactShadow.attach(who, 1.6, 0.4)
		party[str(spec[0])] = who
		# 魔像倒了之後讀檔回來：已經坐起來了
		if bool(spec[5]) and bool(Game.session.state.get_flag(FLAG_GOLEM_DOWN, false)):
			sit_up(who, 0.0)


## 倒在地上的人撐起上身坐好：整個人從躺平（繞 X 轉 90°）轉回直立、同時換成坐在地上的動作，轉的支點在骨盆（骨盆留在原地、腳一直在地上）。
## sec＝要多久（0＝直接坐好：讀檔回來）
func sit_up(who: Node3D, sec: float) -> void:
	var body: Puppet = who.get_node("Puppet") as Puppet
	who.set_meta(TalkCamera.DROP_META, SITTING_DROP)
	who.set_meta(SAT_META, true)
	body.set_pose(SIT_POSE, sec)
	if sec <= 0.0:
		body.transform = sitting_up(1.0)
		return
	var t: Tween = body.create_tween()
	t.tween_method(func(k: float) -> void: body.transform = sitting_up(k), 0.0, 1.0, sec)


## 撐起上身到 k（0＝躺平、1＝坐好）的那一刻，身體在節點裡擺在哪（純函式，測試用）：
## 轉的角度與骨盆離腳底的高度（坐著的動作把骨盆往下拉）照 k 一起變，骨盆一直在同一點
static func sitting_up(k: float) -> Transform3D:
	var angle: float = PI * 0.5 * (1.0 - k)
	var pivot := Vector3(0.0, lerpf(LIE_Y, SIT_HIP, k), LIE_FEET_Z + SIT_PIVOT)
	var hip: float = lerpf(SIT_PIVOT, SIT_HIP, k)
	var b := Basis(Vector3.RIGHT, angle)
	return Transform3D(b, pivot - b * Vector3(0.0, hip, 0.0))


## 魔像倒了：會坐起來的那幾個一個接一個撐起來
func _sit_up_party() -> void:
	var delay: float = 0.0
	for spec: Array in PARTY:
		if not bool(spec[5]):
			continue
		var who: Node3D = party[str(spec[0])] as Node3D
		if delay <= 0.0:
			sit_up(who, SIT_UP_SEC)
		else:
			get_tree().create_timer(delay).timeout.connect(func() -> void:
				if is_instance_valid(who):
					sit_up(who, SIT_UP_SEC))
		delay += SIT_UP_STAGGER


func _spawn_golem() -> void:
	golem = PlagueGolem.new()
	golem.name = "Golem"
	golem.position = GOLEM_START
	golem.gaze_target = sera
	golem.core_clear = core_spot_clear
	# 抵達的那段話「大家一起看著牠」的那一句（look）：鏡頭照牠舉著拳頭的高度框
	golem.set_meta(TalkCamera.HEIGHT_META, GOLEM_TALK_HEIGHT)
	add_child(golem)
	talk_camera.cast[PlagueGolem.NAME_KEY] = golem
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
	golem.core_dropped.connect(func(dropped: GolemCore) -> void: core = dropped)
	golem.health.died.connect(_on_golem_down)
	if _burst_on == "hit":
		golem.health.damaged.connect(func(_amount: float, _info: Dictionary) -> void: App.burst_start_in(1), CONNECT_ONE_SHOT)


func _set_brew(progress: float) -> void:
	sera.brew = progress
	_hud.boss_bar.set_brew(progress, sera.is_petrified())


## 狂暴：席菈退到離魔像最遠的石板邊上，開始裝禁藥（不跟、不射平常的藥、玩家也要不到）
func _on_golem_enraged() -> void:
	_hud.show_center_lines("CH1_ENRAGE_LINE1", "CH1_ENRAGE_LINE2", 6.0)
	_hud.show_bark(sera, "BARK_SERA_FORBIDDEN", 3.6, Sera.NAME_KEY)
	sera.hold_at = hold_spot(golem.global_position)
	sera.hands_full = true
	chatter.hint_paused = true
	_hud.set_extra_hint("")
	if boss_music != null and is_instance_valid(boss_music):
		var t: Tween = boss_music.create_tween().set_parallel(true)
		t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		t.tween_property(boss_music, "pitch_scale", BOSS_RAGE_PITCH, BOSS_RAGE_SHIFT_SEC)
		t.tween_property(boss_music, "volume_db", BOSS_MUSIC_DB + BOSS_RAGE_DB, BOSS_RAGE_SHIFT_SEC)
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
	if _demo == "miss":
		# 開發用：前兆縮短了，席菈來不及跑到後面——直接放過去，諾恩才不會剛好站在線上
		sera.global_position = sera.hold_at
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


## 核心被粉碎的那一刀：定格 → 碎片用慢動作飛出來；鏡頭切到兩人的側面（過肩鏡頭裡這一刻只看得到魔像的肚子），看牠跪下、往前垮，再還給玩家。
## 那幾秒 HUD 收起來、玩家不能動（FinisherCamera 是過場）、音效悶下去放慢（SlowMoSound）
func _on_core_shattered() -> void:
	_fade_out_music()
	Game.hit_stop(FINISH_STOP_SEC, FINISH_SLOW_SEC, FINISH_SLOW_SCALE)
	SlowMoSound.play(self, FINISH_STOP_SEC + FINISH_SLOW_SEC)
	_player.shake(0.8)
	_hud.hide_center_lines()
	finisher = FinisherCamera.play(self, _player.global_position, golem.global_position, FINISH_HOLD_SEC,
		FINISH_CAM_DIST, FINISH_CAM_HEIGHT, FINISH_AIM_HEIGHT, [_player.get_rid(), golem.get_rid()])
	_hud.cinematic = finisher != null


## 粉碎核心之後配樂慢慢收掉（不跟著慢動作變慢：照真的時間收）
func _fade_out_music() -> void:
	if boss_music == null or not is_instance_valid(boss_music):
		return
	var p: AudioStreamPlayer = boss_music
	boss_music = null
	var t: Tween = p.create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.set_ignore_time_scale(true)
	t.tween_property(p, "volume_db", Ambience.MUTED_DB, BOSS_MUSIC_FADE_OUT)
	t.tween_callback(p.queue_free)


## 魔像倒了：光環消失、席菈回到諾恩身邊，隔一下三個人講話
func _on_golem_down() -> void:
	if _burst_on == "down":
		App.burst_start_in(1)
	# 倒在哪裡、面向哪裡先存起來（下一個旗標會自動存檔）：讀檔回來那一堆碎石與核心擺在同一個地方
	var fwd: Vector3 = golem.fall_direction()
	Game.session.set_flag(FLAG_DOWN_X, golem.global_position.x)
	Game.session.set_flag(FLAG_DOWN_Z, golem.global_position.z)
	Game.session.set_flag(FLAG_DOWN_YAW, atan2(-fwd.x, -fwd.z))
	Game.session.set_flag(FLAG_GOLEM_DOWN, true)
	_hud.show_banner("CH1_GOLEM_DOWN", 4.0)
	_hud.set_extra_hint("")
	sera.hold_at = Vector3.INF
	sera.hands_full = false
	chatter.hint_paused = false
	_after_talk_in = AFTER_TALK_DELAY
	_party_sit_in = SIT_UP_DELAY


## 戰後那段話講完：拿到核心，隔一下「當天傍晚——奧爾德冒險者公會」，換到大廳演結尾
func _on_dialogue_ended(dialogue_id: String) -> void:
	if dialogue_id == AFTER_DIALOGUE:
		_hud.show_banner("CH1_GOT_CORE", 4.0)
		_return_in = RETURN_DELAY
		# 等卡出來的這幾秒是過場：站著看核心飛到肩上（不能在石板上走）
		lock_for_cutscene()
		# 地上的核心飛到諾恩的左肩旁邊（結尾他就是這樣扛回公會的）
		if core != null and is_instance_valid(core):
			core.carry_on(_player.get_node("Body") as Node3D, CORE_TAKE_SEC, _player.puppet())
		# 鏡頭切到兩人的側面停著，一直到換關卡的卡把畫面蓋掉（不晃；HUD 照樣在：「獲得魔像核心」那一行要看得到）
		outro_camera = FinisherCamera.play(self, sera.global_position, _player.global_position, 60.0,
			OUTRO_DIST, OUTRO_HEIGHT, OUTRO_AIM, [_player.get_rid(), sera.get_rid()], _player.get_node(PLAYER_CAMERA) as Camera3D)
		if outro_camera != null:
			outro_camera.name = "OutroCamera"
			outro_camera.shake = 0.0


func _mark(node_name: String, at: Vector3) -> void:
	var m := Marker3D.new()
	m.name = node_name
	m.position = at
	add_child(m)
