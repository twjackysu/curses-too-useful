class_name GuildHall
extends StoryLevel
## 奧爾德冒險者公會的大廳：第一章的開場（docs/story/chapter-1.md 節點 1）與結尾（節點 3 的第 5 拍）。新遊戲從這裡開始。
## 開場的每一拍：走到櫃檯，莉莉絲幫諾恩登錄（ch1_guild_register）→ 按鍵把手放到適性測試水晶上：警報、「全屬性：無」、大廳一陣嘲笑
## → 雷歐走過來羞辱他與縮在角落的席菈，帶隊離開（ch1_guild_leo）→ 跟莉莉絲說話，她拿出沒人接的綠色委託單（ch1_guild_quest）
## → 席菈走過來問能不能一起去（ch1_guild_sera，兩個回答），先回去拿面具 → 走出大門，換到腐敗之森（城鎮還沒做）。
## 結尾（傍晚）：打倒魔像之後回到公會——雷歐小隊先逃回來了，諾恩扛著魔像核心走進來、席菈跟在後面 → 走到櫃檯前，
## 幾個人講話（ch1_guild_return，一個回答）、鏡頭帶到二樓陰影裡的王都巡察官 →「第一章　完」→ 回標題。
## 看得到的場景在 GuildScenery，站著的人是 Npc；這裡放劇情與畫面上的字。
## 任務 data/quests/ch1_main.json 最前面的五個階段與最後的 report。

const QUEST: String = "ch1_main"
const STAGE_REGISTER: String = "register"
const STAGE_APTITUDE: String = "aptitude"
const STAGE_TAKE_QUEST: String = "take_quest"
const STAGE_SERA_ASKS: String = "sera_asks"
const STAGE_LEAVE: String = "leave_guild"
const STAGE_REPORT: String = "report"
const OPENING_STAGES: PackedStringArray = [STAGE_REGISTER, STAGE_APTITUDE, STAGE_TAKE_QUEST, STAGE_SERA_ASKS, STAGE_LEAVE]
## 劇情旗標：對話資料自己設的有 registered、leo_left、quest_taken、sera_asked；關卡設的是 crystal_tested、left_guild、chapter_done
const FLAG_REGISTERED: String = "ch1.registered"
const FLAG_CRYSTAL: String = "ch1.crystal_tested"
const FLAG_LEO_LEFT: String = "ch1.leo_left"
const FLAG_QUEST: String = "ch1.quest_taken"
const FLAG_SERA_ASKED: String = "ch1.sera_asked"
const FLAG_LEFT: String = "ch1.left_guild"
const FLAG_CHAPTER_DONE: String = "ch1.chapter_done"
const OPENING_FLAGS: PackedStringArray = [FLAG_REGISTERED, FLAG_CRYSTAL, FLAG_LEO_LEFT, FLAG_QUEST, FLAG_SERA_ASKED, FLAG_LEFT]
const REGISTER_DIALOGUE: String = "ch1_guild_register"
const LEO_DIALOGUE: String = "ch1_guild_leo"
const QUEST_DIALOGUE: String = "ch1_guild_quest"
const SERA_DIALOGUE: String = "ch1_guild_sera"
const RETURN_DIALOGUE: String = "ch1_guild_return"
const LILITH_KEY: String = "SPK_LILITH"
const LEO_KEY: String = "SPK_LEO"
const ADVENTURER_KEY: String = "SPK_ADVENTURER"
const INSPECTOR_KEY: String = "SPK_UNKNOWN"
## 諾恩從大門走進來的地方；之後的檢查點（雷歐走了、可以出發了）站在櫃檯前面
const ENTRANCE: Vector3 = Vector3(0, 0.05, 8.6)
const COUNTER_FRONT: Vector3 = Vector3(0.4, 0.05, -5.9)
## 走到這條線以北莉莉絲就開口（開場的登錄；結尾是大廳的人看到他）
const REGISTER_Z: float = -4.4
const REPORT_Z: float = -1.6
const LILITH_POS: Vector3 = Vector3(0, 0, -8.85)
## 雷歐小隊一開始站在佈告欄前面：節點名、角色 id、位置、面向（度）
const PARTY: Array[Array] = [
	["Leo", "leo", Vector3(-5.6, 0, 0.3), 90.0],
	["LeoMage", "leo_mage", Vector3(-5.4, 0, 1.6), 100.0],
	["LeoTank", "leo_tank", Vector3(-5.9, 0, -0.9), 80.0],
]
## 結尾：他們先逃回來了，圍在櫃檯前面
const PARTY_RETURNED: Array[Vector3] = [Vector3(-1.9, 0, -6.2), Vector3(-3.1, 0, -5.6), Vector3(-2.7, 0, -4.5)]
## 大廳裡的冒險者：節點名、角色 id、開場的位置與面向、結尾的位置
const CROWD: Array[Array] = [
	["AdventurerA", "guild_adventurer_a", Vector3(2.4, 0, 4.5), 180.0, Vector3(1.9, 0, -4.7)],
	["AdventurerB", "guild_adventurer_b", Vector3(2.6, 0, 6.1), 0.0, Vector3(3.0, 0, -5.5)],
]
## 坐在桌邊的客人（開場與結尾都在）：節點名、角色 id（照順序找第一個有模型的；都沒有就不擺——不用別人的模型充數）、
## 坐的位置（長凳上）、面向（度）、樣子（Puppet.POSES）。guild_patron_* 是排給 Tripo 的三個客人，產出來接進 gen_art.sh 就會出現
const PATRONS: Array[Array] = [
	["Merchant", ["black_market_merchant"], Vector3(-5.32, 0, -3.9), -90.0, "sit_drink"],
	["PatronA", ["guild_patron_a"], Vector3(-3.48, 0, 5.7), 90.0, "sit_drink"],
	["PatronB", ["guild_patron_b"], Vector3(-5.32, 0, 4.6), -90.0, "sit"],
	["PatronC", ["guild_patron_c"], Vector3(5.12, 0, 1.4), 90.0, "sit"],
]
## 喝酒的客人手上的杯子：離手腕多遠（他的座標：往上、往前）
const MUG_IN_HAND: Vector3 = Vector3(0.0, -0.06, -0.05)
## 佈告欄前面走到走道上的那一點（直線走會穿過桌子）
const AISLE_WEST: Vector3 = Vector3(-2.3, 0, 0.4)
## 席菈縮在西北的角落，坐在武器架旁邊的凳子上、面向牆角；坐的時候外型往上抬多少（凳子比長凳高，腳會懸空一點）
const SERA_CORNER: Vector3 = GuildScenery.STOOL_POS
const SERA_CORNER_FACING: float = 55.0
const SERA_STOOL_LIFT: float = 0.11
const SERA_STOOL_LIFT_PUPPET: float = 0.16
## 王都巡察官站在二樓欄杆後面
## 站在欄杆後面（x 避開天花板中間那根縱樑：過肩鏡頭在他左後方，不能撞進樑裡）
const INSPECTOR_POS: Vector3 = Vector3(1.6, GuildScenery.LOFT_Y, GuildScenery.LOFT_EDGE_Z - 0.4)
## 他講話時的過肩鏡頭（在他後面多遠、往旁邊多少、離他腳下多高）：貼近他、拉高往下看，欄杆的扶手落到畫面下面當前景，不橫過中間
const INSPECTOR_SHOT: Vector3 = Vector3(0.75, 0.7, 2.65)
## 警報的時間軸（秒）：兩個冒險者先後笑出來、莉莉絲愣住、雷歐走過來；他走到了（或等太久）就開口
const ALARM_LAUGH_A: float = 0.9
const ALARM_LAUGH_B: float = 1.9
const ALARM_LILITH: float = 2.1
const ALARM_LEO_WALKS: float = 2.4
const ALARM_TIMEOUT: float = 11.0
## 席菈走過來的速度（鼓起勇氣慢慢走）；走到離諾恩這麼近就開口
const SERA_APPROACH_SPEED: float = 2.0
const SERA_TALK_DIST: float = 2.3
## 結尾那段話講完隔多久出「第一章　完」
const END_CARD_DELAY: float = 1.4
## 席菈先跑出去的路：大門裡面 → 門外的街上 → 轉進牆後面（走到最後一個點才消失）
const SERA_EXIT: Array[Vector3] = [
	GuildScenery.DOOR_POS + Vector3(0, 0, -0.5),
	GuildScenery.DOOR_POS + Vector3(0, 0, 1.5),
	GuildScenery.DOOR_POS + Vector3(-4.0, 0, 2.2),
]
const END_MUSIC_DB: float = -5.0
const MURMUR_DB: float = -17.0
## 大廳的人聲（整片循環）、「第一章　完」的配樂、警報之後冒險者的笑聲、大門打開的吱嘎
const MURMUR_SFX: String = "hall_murmur"
const END_MUSIC: String = "chapter_end_theme"
const LAUGH_SFX: String = "crowd_laugh"
const LAUGH_DB: float = -4.0
const DOOR_SFX: String = "door_creak"
const DOOR_SHUT_SFX: String = "door_shut"
const DOOR_DB: float = -6.0
## 大廳的配樂（角落的魯特琴＋直笛，小小聲墊在人聲底下）：水晶警報一響就停掉（全場安靜下來看他），雷歐走掉之後慢慢回來；「第一章　完」之前收掉
const HALL_MUSIC: String = "guild_theme"
const HALL_MUSIC_DB: float = -15.0
const HALL_MUSIC_FADE_IN: float = 2.0
const MUSIC_CUT_SEC: float = 0.25
const MUSIC_BACK_SEC: float = 3.0
## 結尾席菈跟在諾恩左後方半步（玩家的鏡頭裡看得到她整個人）
const SERA_FOLLOW_OFFSET: Vector3 = Vector3(-1.3, 0.0, 0.7)
## 有人走到離大門這麼近就開門（走出去的雷歐小隊、席菈、諾恩）；開關的速度（每秒幾成）
const DOOR_NEAR: float = 3.2
const DOOR_SPEED: float = 1.6
## 莉莉絲兩手拿著委託單遞出來，手收回來的時候放到櫃檯上（give 播到這裡）；拿著的時候在右手腕往左多少（兩手中間）
const SLIP_SHOW_SEC: float = 0.95
const SLIP_IN_HANDS: Vector3 = Vector3(-0.15, 0.03, -0.05)
const SLIP_HELD_SCALE: float = 0.7
## 正在走出大門的人（門要為他們開）
const LEAVING_GROUP: String = "guild_leaving"
## 莉莉絲拿出綠色委託單的那一句、蓋章的那一句：畫面右邊拿出那張紙（PaperNote）、蓋上「受理」
const SLIP_SHOW_LINE: String = "DLG_CH1_QUEST_002"
const SLIP_STAMP_LINE: String = "DLG_CH1_QUEST_006"
const SLIP_PAPER: Color = Color(0.62, 0.78, 0.55)
const SLIP_INK: Color = Color(0.1, 0.2, 0.1)
const SLIP_LINES: PackedStringArray = ["SLIP_LINE_1", "SLIP_LINE_2", "SLIP_LINE_3", "SLIP_LINE_4"]
## 佈告欄：走近按互動，畫面右邊攤開上面貼的委託（全都要隊伍、F 級一張都沒有），諾恩嘀咕一句；走開或過一陣子收起來
const BOARD_LINES: PackedStringArray = ["BOARD_NOTE_1", "BOARD_NOTE_2", "BOARD_NOTE_3", "BOARD_NOTE_4"]
const BOARD_PAPER: Color = Color(0.93, 0.87, 0.72)
const BOARD_INK: Color = Color(0.22, 0.15, 0.09)
const BOARD_SHOW_SEC: float = 9.0
const BOARD_AWAY: float = 3.4

## 大門從關著被推開幾次（每次吱嘎一聲）、關上幾次（碰一聲）；測試用
## 大廳的配樂（_music_to 調音量）
var hall_music: AudioStreamPlayer
var _music_tween: Tween
var door_creaks: int = 0
var door_shuts: int = 0
var scenery: GuildScenery
var lilith: Npc
var sera: Sera
var inspector: Npc
var talk_camera: TalkCamera
## 雷歐小隊、冒險者：節點名 → 那個人（走出大門的人會被釋放）
var party: Dictionary = {}
var crowd: Dictionary = {}
## 坐著的客人：節點名 → 那個人
var patrons: Dictionary = {}
## 諾恩身上的黑氣（只有二樓的巡察官講話的那一句看得到）
var aura: DarkAura
var crystal_use: Interactable
var lilith_use: Interactable
var board_use: Interactable
## 畫面右邊現在拿著的紙（綠色委託單／佈告欄）；沒有時是 null
var slip_note: PaperNote
var board_note: PaperNote
var _board_t: float = 0.0
var core: GolemCore
var card: ChapterCard
## 「第一章　完」之後的製作名單與下一章的預告（播完回標題；測試叫 credits.finish()）
var credits: EndCredits
## 警報響了幾秒（< 0＝沒有在響）
var _alarm_t: float = -1.0
var _alarm_step: int = 0
var _pulse_t: float = 0.0
## 席菈還沒結伴、站著的時候慢慢轉過去看的地方
var _sera_look: Vector3 = Vector3.INF
var _sera_leaving: bool = false
## 席菈跑出大門走到 SERA_EXIT 的第幾個點了（測試用）
var sera_exit_step: int = -1
var _leaving: bool = false
var _end_in: float = -1.0
var _return_barked: bool = false
var _burst_on: String = ""
var _demo: String = ""

@onready var _player: PlayerController = $Player
@onready var _hud: Hud = $Hud


## 把大廳的開場跳過（開發旗標直接進森林、測試）：當成登錄、警報、雷歐、委託、席菈都演過了、已經走出大門。
static func skip_opening(session: GameSession) -> void:
	for flag: String in OPENING_FLAGS:
		session.set_flag(flag, true)


## 直接跳到結尾「回到公會」（開發旗標 `--level=guild_hall --return` 與測試用）
static func skip_to_return(session: GameSession) -> void:
	RuinedAltar.skip_to_altar(session)
	for flag: String in [RuinedAltar.FLAG_TALKED, RuinedAltar.FLAG_GOLEM_DOWN, RuinedAltar.FLAG_DONE]:
		session.set_flag(flag, true)


func _ready() -> void:
	var args: Dictionary = Game.level_args()
	var s: GameSession = Game.session
	# 截圖用：`--registered`（登錄那段話講過了：站在櫃檯前，可以摸水晶）、`--after-leo`（雷歐走了：跟莉莉絲說話）、
	# `--quest-taken`（接了委託：席菈走過來）、`--ready`（可以出發了）、`--return`（結尾：傍晚回到公會）
	if s.in_story():
		if args.has("return"):
			skip_to_return(s)
		for spec: Array in [["registered", 1], ["after-leo", 3], ["quest-taken", 4], ["ready", 5]]:
			if args.has(str(spec[0])):
				for i: int in int(spec[1]):
					s.set_flag(OPENING_FLAGS[i], true)
	# `--talk-skip=N`：對話一開始先按掉 N 句（遇到選項選第一個），拍第 N+1 句的鏡位
	var talk_skip: int = int(str(args.get("talk-skip", "0")))
	if talk_skip > 0:
		Game.dialogue_started.connect(func(r: DialogueRunner) -> void:
			for i: int in talk_skip:
				_skip_line.call_deferred(r))
	scenery = GuildScenery.build(self, is_epilogue())
	_mark("GuildDoor", GuildScenery.DOOR_POS + Vector3(0, 0, -0.6))
	_player.collision_mask |= GuildScenery.PEOPLE_LAYER
	_player.peaceful = true
	_player.global_position = ENTRANCE if stage() in [STAGE_REGISTER, STAGE_APTITUDE, STAGE_REPORT, ""] else COUNTER_FRONT
	var at: PackedStringArray = str(args.get("at", "")).split(",")
	if at.size() == 2:
		_player.global_position = Vector3(float(at[0]), ENTRANCE.y, float(at[1]))
	if args.has("cam-yaw"):
		_player.yaw = deg_to_rad(float(str(args["cam-yaw"])))
	_player.snap_camera()
	# 從大門走進來：門還開著，走開了才關上
	scenery.set_door_open(1.0 if _player.global_position.distance_to(GuildScenery.DOOR_POS) < DOOR_NEAR else 0.0)
	_spawn_cast()
	_build_interactables()
	Game.dialogue_ended.connect(_on_dialogue_ended)
	Game.dialogue_started.connect(func(r: DialogueRunner) -> void:
		if r.dialogue_id == QUEST_DIALOGUE:
			r.line_shown.connect(_on_quest_line))
	Ambience.play(self, MURMUR_SFX, MURMUR_DB, "HallMurmur")
	# 淡入也走 _music_to（同一個 tween）：一進來馬上摸水晶，停掉的那一下不會被還沒淡完的淡入蓋回去
	hall_music = Ambience.music(self, HALL_MUSIC, Ambience.MUTED_DB, 0.0, "HallMusic")
	_music_to(HALL_MUSIC_DB, HALL_MUSIC_FADE_IN)
	if is_epilogue() and stage() == STAGE_REPORT:
		_attach_core()
	elif stage() == STAGE_REGISTER:
		# 開場：這是哪裡、來做什麼
		_hud.show_center_lines("CH1_GUILD_LINE1", "CH1_GUILD_LINE2", 6.5, Hud.CENTER_LINE2_COLOR)
	# 連拍用（scripts/burst.sh）：`--registered --burst-on=alarm` 進場 1.2 秒後把手放上水晶，從那一刻開始拍。
	# 截圖用：`--registered --demo=leo` 進場就摸水晶、雷歐直接站到旁邊開口（不等警報的那幾秒；配 `--talk-skip`）；
	# `--registered --demo=alarm` 進場就摸水晶、照平常的時間軸（伸手、大家笑、雷歐走過來）；
	# `--after-leo --demo=quest` 進場就跟莉莉絲說話（她兩手遞出委託單）；
	# `--quest-taken --demo=sera` 席菈一開始就站在幾步外（不等她從角落走過來）；`--return --demo=end` 直接停在「第一章　完」（`--demo=credits` 製作名單、`--demo=preview` 下一章的預告）；
	# `--demo=board` 站到佈告欄前面、攤開上面的委託
	_burst_on = str(args.get("burst-on", ""))
	_demo = str(args.get("demo", ""))
	if _burst_on == "alarm":
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			App.burst_start_in(1)
			touch_crystal())
	if _demo == "leo" or _demo == "alarm":
		get_tree().create_timer(0.2).timeout.connect(touch_crystal)
	elif _demo == "quest":
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			if _talk(QUEST_DIALOGUE, ["SPK_NOEN", LILITH_KEY]):
				_hand_over_slip())
	elif _demo == "sera" and sera != null:
		sera.position = _beside_player(Vector3(-3.0, 0, 0.6))
	elif _demo == "end":
		_play_end_card()
		card.hold_still.call_deferred()
	elif _demo == "credits" or _demo == "preview":
		# 截圖用：製作名單捲到第 12 秒／下一章的預告
		_play_credits()
		credits.hold_at.call_deferred(EndCredits.Part.ROLL if _demo == "credits" else EndCredits.Part.PREVIEW, 12.0)
	elif _demo == "board":
		_player.global_position = board_use.global_position + Vector3(0.5, 0, 0.2)
		_player.yaw = deg_to_rad(-90.0)
		_player.snap_camera()
		get_tree().create_timer(0.3).timeout.connect(read_board)
	QualityPreset.apply_tree(self, Settings.quality as QualityPreset.Level)


func footstep_surface(_p: Vector3) -> String:
	return "wood"


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


## 結尾的那一段（傍晚）：主線走到 report，或整章做完之後再進來
func is_epilogue() -> bool:
	return stage() == STAGE_REPORT or Game.session.story_finished()


func _flag(key: String) -> bool:
	return bool(Game.session.state.get_flag(key, false))


func _physics_process(delta: float) -> void:
	_pulse_t += delta
	_tick_crystal()
	_tick_door(delta)
	_tick_board(delta)
	_turn_sera(delta)
	if not Game.session.in_story() or _leaving:
		return
	_player.global_position = GuildScenery.keep_inside(_player.global_position)
	match stage():
		STAGE_REGISTER:
			if _player.global_position.z < REGISTER_Z:
				_talk(REGISTER_DIALOGUE, ["SPK_NOEN", LILITH_KEY])
		STAGE_APTITUDE:
			_tick_alarm(delta)
		STAGE_SERA_ASKS:
			_tick_sera_asks()
		STAGE_LEAVE:
			_tick_leave()
		STAGE_REPORT:
			_tick_report()
	if aura != null:
		aura.emitting = _current_speaker() == INSPECTOR_KEY
	if _end_in >= 0.0 and not Game.is_in_dialogue():
		_end_in -= delta
		if _end_in < 0.0:
			_play_end_card()


## 開始一段對話。order＝這一段誰跟誰講（說話者的翻譯 key，第一個是諾恩）：TalkCamera 把第二個當成諾恩面對的人。
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


## 現在這一句是誰講的（說話者的翻譯 key；沒有在對話就是空的）
func _current_speaker() -> String:
	var r: DialogueRunner = Game.dialogue
	return str(r.current().get("speaker", "")) if r != null and r.is_running() else ""


static func _skip_line(r: DialogueRunner) -> void:
	if not r.visible_choices.is_empty():
		r.choose(0)
	else:
		r.advance()


func _speaker_node(key: String) -> Node3D:
	match key:
		"SPK_NOEN":
			return _player
		LILITH_KEY:
			return lilith
		LEO_KEY:
			return party.get("Leo") as Node3D
		Sera.NAME_KEY:
			return sera
		ADVENTURER_KEY:
			return crowd.get("AdventurerA") as Node3D
		INSPECTOR_KEY:
			return inspector
	return null


func _spawn_cast() -> void:
	var evening: bool = is_epilogue()
	lilith = Npc.create("Lilith", "lilith", LILITH_POS, 180.0)
	add_child(lilith)
	for i: int in CROWD.size():
		var spec: Array = CROWD[i]
		var who: Npc = Npc.create(str(spec[0]), str(spec[1]), (spec[4] if evening else spec[2]) as Vector3, float(spec[3]))
		add_child(who)
		crowd[str(spec[0])] = who
		if evening:
			who.face(LILITH_POS)
	# 雷歐小隊：開場在佈告欄前面（羞辱完就走了）；結尾先逃回來、圍在櫃檯前
	if evening or not _flag(FLAG_LEO_LEFT):
		for i: int in PARTY.size():
			var spec: Array = PARTY[i]
			var who: Npc = Npc.create(str(spec[0]), str(spec[1]), PARTY_RETURNED[i] if evening else spec[2] as Vector3, float(spec[3]))
			add_child(who)
			party[str(spec[0])] = who
			if evening:
				who.face(LILITH_POS)
	for spec: Array in PATRONS:
		var id: String = _first_with_model(spec[1] as Array)
		if id == "":
			continue
		var who: Npc = Npc.create(str(spec[0]), id, spec[2] as Vector3, float(spec[3]))
		who.pose = str(spec[4])
		add_child(who)
		patrons[str(spec[0])] = who
		var mug: Node3D = PropModels.instance("quaternius/Mug") if who.pose == "sit_drink" else null
		if mug != null and who.puppet.hand("R") != null:
			UprightHeld.attach(mug, who.puppet.hand("R"), who, MUG_IN_HAND)
	if evening:
		# 逃回來的雷歐小隊：累垮了，駝著背喘氣
		for key: String in party:
			(party[key] as Npc).pose = "slump"
		inspector = Npc.create("Inspector", "royal_inspector", INSPECTOR_POS, 180.0)
		inspector.set_meta(TalkCamera.LOOK_META, _player)
		inspector.set_meta(TalkCamera.LOOK_OFFSET_META, INSPECTOR_SHOT)
		add_child(inspector)
		aura = DarkAura.attach(_player)
	# 席菈：開場縮在角落（問完就先回去拿面具）；結尾跟在諾恩後面
	if evening or not _flag(FLAG_SERA_ASKED):
		sera = Sera.new()
		sera.name = "Sera"
		sera.holstered = true
		sera.collision_mask |= GuildScenery.PEOPLE_LAYER
		if evening:
			sera.target = _player
			sera.position = _player.global_position + SERA_FOLLOW_OFFSET
		else:
			sera.joined = false
			sera.position = SERA_CORNER
			sera.rotation.y = deg_to_rad(SERA_CORNER_FACING)
		add_child(sera)
		_seat_sera(not evening)
	talk_camera = TalkCamera.new()
	talk_camera.name = "TalkCamera"
	add_child(talk_camera)


func _build_interactables() -> void:
	crystal_use = Interactable.create("Crystal", Vector3(GuildScenery.CRYSTAL_POS.x, 0.0, GuildScenery.CRYSTAL_POS.z), "HINT_TOUCH_CRYSTAL", 2.4)
	crystal_use.used.connect(func(_by: PlayerController) -> void: touch_crystal())
	add_child(crystal_use)
	lilith_use = Interactable.create("TalkLilith", Vector3(0.0, 0.0, GuildScenery.STAFF_LINE_Z), "HINT_TALK_LILITH", 2.6)
	lilith_use.used.connect(func(_by: PlayerController) -> void:
		if _talk(QUEST_DIALOGUE, ["SPK_NOEN", LILITH_KEY]):
			_hand_over_slip())
	add_child(lilith_use)
	board_use = Interactable.create("ReadBoard", GuildScenery.BOARD_POS + Vector3(1.1, 0, 0), "HINT_READ_BOARD", 2.2)
	board_use.used.connect(func(_by: PlayerController) -> void: read_board())
	add_child(board_use)
	_refresh_interactables()


func _refresh_interactables() -> void:
	crystal_use.enabled = stage() == STAGE_APTITUDE and _alarm_t < 0.0
	lilith_use.enabled = stage() == STAGE_TAKE_QUEST
	board_use.enabled = _alarm_t < 0.0 and not _leaving
	# 綠色委託單：莉莉絲拿出來之後就放在櫃檯上，到諾恩出發為止
	scenery.slip.visible = Game.session.in_story() and _flag(FLAG_QUEST) and not is_epilogue()


## 莉莉絲兩手拿著綠色委託單遞出來，手收回來的時候放到櫃檯上
func _hand_over_slip() -> void:
	lilith.gesture("give")
	var held: UprightHeld = null
	var hand: Node3D = lilith.puppet.hand("R")
	if hand != null:
		var copy := scenery.slip.duplicate() as Node3D
		copy.visible = true
		# 拿在手上的那張小一點（放在櫃檯上的那張要在玩的距離看得到；拿在手上的在近景裡會大得像托盤）
		copy.transform = Transform3D.IDENTITY.scaled(Vector3.ONE * SLIP_HELD_SCALE)
		held = UprightHeld.attach(copy, hand, lilith, SLIP_IN_HANDS)
		held.name = "HeldSlip"
	get_tree().create_timer(SLIP_SHOW_SEC).timeout.connect(func() -> void:
		if held != null and is_instance_valid(held):
			held.queue_free()
		scenery.slip.visible = true)


## 把手放到水晶上：警報、畫面中間寫結果；之後的事照 _tick_alarm 的時間軸
func touch_crystal() -> void:
	if stage() != STAGE_APTITUDE or _alarm_t >= 0.0:
		return
	_alarm_t = 0.0
	_alarm_step = 0
	Game.session.set_flag(FLAG_CRYSTAL, true)
	_refresh_interactables()
	_player.gesture("reach", GuildScenery.CRYSTAL_POS)
	# 「把手放到水晶上」做了：雷歐講完、走掉之前左上不寫下一步
	_hud.objective_held = true
	Sfx.play_flat(self, "crystal_alarm", -3.0)
	_music_to(Ambience.MUTED_DB, MUSIC_CUT_SEC)
	_player.shake(0.35)
	_hud.show_center_lines("CH1_CRYSTAL_LINE1", "CH1_CRYSTAL_LINE2", 7.0)
	if _demo == "leo":
		# 開發用：不等嘲笑與走路的那幾秒
		var leo: Npc = party.get("Leo") as Npc
		leo.global_position = _beside_player(Vector3(-1.5, 0, 1.3))
		leo.face(_player.global_position)
		_alarm_step = 4


func is_alarm_ringing() -> bool:
	return _alarm_t >= 0.0


func _tick_alarm(delta: float) -> void:
	if _alarm_t < 0.0 or Game.is_in_dialogue():
		return
	_alarm_t += delta
	var a: Npc = crowd.get("AdventurerA") as Npc
	var b: Npc = crowd.get("AdventurerB") as Npc
	var leo: Npc = party.get("Leo") as Npc
	if _alarm_step == 0 and _alarm_t >= ALARM_LAUGH_A:
		_alarm_step = 1
		a.face(_player.global_position)
		b.face(_player.global_position)
		a.pose = "laugh"
		_hud.show_bark(a, "BARK_ADV_LAUGH_A", 3.0, ADVENTURER_KEY)
		Sfx.play_at(self, LAUGH_SFX, a.global_position + Vector3.UP * 1.5, LAUGH_DB, 0.05, 6.0)
	elif _alarm_step == 1 and _alarm_t >= ALARM_LAUGH_B:
		_alarm_step = 2
		b.pose = "laugh"
		_hud.show_bark(b, "BARK_ADV_LAUGH_B", 3.0, ADVENTURER_KEY)
		# 第二陣比較多人（雷歐小隊也跟著笑）：音高換一點，不要聽起來是同一段
		Sfx.play_at(self, LAUGH_SFX, b.global_position + Vector3.UP * 1.5, LAUGH_DB + 1.0, 0.12, 7.0)
		for key: String in party:
			(party[key] as Npc).face(_player.global_position)
			if key != "Leo":
				(party[key] as Npc).pose = "laugh"
	elif _alarm_step == 2 and _alarm_t >= ALARM_LILITH:
		_alarm_step = 3
		_hud.show_bark(lilith, "BARK_LILITH_ALARM", 2.6, LILITH_KEY)
	elif _alarm_step == 3 and _alarm_t >= ALARM_LEO_WALKS:
		_alarm_step = 4
		# 雷歐從佈告欄前面走到走道上，再走到諾恩旁邊
		leo.walk_path([AISLE_WEST, _beside_player(Vector3(-1.5, 0, 1.3))], 2.5)
	elif _alarm_step == 4 and (not leo.is_walking() or _alarm_t >= ALARM_TIMEOUT):
		if _talk(LEO_DIALOGUE, ["SPK_NOEN", LEO_KEY, Sera.NAME_KEY]):
			_alarm_step = 5
			_sera_look = _player.global_position
			# 雷歐開口，大家安靜下來聽（笑到一半停住）
			for who: Npc in [a, b, party.get("LeoMage") as Npc, party.get("LeoTank") as Npc]:
				if who != null:
					who.pose = ""


## 諾恩旁邊的一個位置（offset 是相對他的位移；不會落在櫃檯裡面或牆外）
func _beside_player(offset: Vector3) -> Vector3:
	var p: Vector3 = GuildScenery.keep_inside(_player.global_position + offset)
	return Vector3(p.x, 0.0, maxf(p.z, GuildScenery.STAFF_LINE_Z + 0.9))


## 大門：有人走近就開、走開了就關
func _tick_door(delta: float) -> void:
	if scenery == null:
		return
	var near: bool = false
	var who: Array[Node3D] = [_player, sera]
	for key: String in party:
		who.append(party[key] as Node3D)
	for n: Node3D in get_tree().get_nodes_in_group(LEAVING_GROUP):
		who.append(n)
	for n: Node3D in who:
		if n != null and is_instance_valid(n) and n.is_inside_tree() and n.global_position.distance_to(GuildScenery.DOOR_POS) < DOOR_NEAR:
			near = true
			break
	var was: float = scenery.door_open
	if near and was <= 0.01:
		door_creaks += 1
		Sfx.play_at(self, DOOR_SFX, GuildScenery.DOOR_POS + Vector3.UP * 1.5, DOOR_DB, 0.05, 5.0)
	scenery.set_door_open(move_toward(was, 1.0 if near else 0.0, delta * DOOR_SPEED))
	if was > 0.01 and scenery.door_open <= 0.01:
		door_shuts += 1
		Sfx.play_at(self, DOOR_SHUT_SFX, GuildScenery.DOOR_POS + Vector3.UP * 1.2, DOOR_DB, 0.05, 5.0)


## 水晶的光：警報中紅的一閃一閃；測過了就暗掉
func _tick_crystal() -> void:
	if scenery == null:
		return
	if _alarm_t >= 0.0 and not _flag(FLAG_LEO_LEFT):
		scenery.set_crystal(0.75 + 0.25 * sin(_pulse_t * 14.0), false)
	else:
		scenery.set_crystal(0.0, Game.session.in_story() and _flag(FLAG_CRYSTAL))


## 還沒結伴的席菈沒有在跟誰（target 是空的，她自己不會動）：關卡讓她慢慢轉過去看 _sera_look
func _turn_sera(delta: float) -> void:
	if sera == null or not is_instance_valid(sera) or sera.target != null or not _sera_look.is_finite():
		return
	var to: Vector3 = _sera_look - sera.global_position
	sera.rotation.y = lerp_angle(sera.rotation.y, atan2(-to.x, -to.z), minf(delta * 3.0, 1.0))


## 席菈縮成一團坐在角落的凳子上（開場）／站起來（走過來問能不能一起去）
func _seat_sera(on: bool) -> void:
	if sera == null:
		return
	var p: Puppet = sera.puppet()
	p.pose = "sit_hunch" if on else ""
	p.position.y = (SERA_STOOL_LIFT if p.uses_model() else SERA_STOOL_LIFT_PUPPET) if on else 0.0


## 席菈從角落走過來，走到諾恩旁邊就開口
func _tick_sera_asks() -> void:
	if sera == null or not is_instance_valid(sera) or Game.is_in_dialogue():
		return
	if sera.target == null:
		_seat_sera(false)
		sera.target = _player
		sera.hold_speed = SERA_APPROACH_SPEED
	var from_player: Vector3 = sera.global_position - _player.global_position
	from_player.y = 0.0
	sera.hold_at = _beside_player(from_player.normalized() * (SERA_TALK_DIST - 0.5))
	if from_player.length() < SERA_TALK_DIST:
		_talk(SERA_DIALOGUE, ["SPK_NOEN", Sera.NAME_KEY])


## 可以出發了：席菈先跑出去；諾恩走到大門就換到腐敗之森
func _tick_leave() -> void:
	if sera != null and is_instance_valid(sera):
		if not _sera_leaving:
			_sera_leaving = true
			sera_exit_step = 0
			sera.target = _player
			sera.hold_speed = 0.0
			sera.hold_at = SERA_EXIT[0]
			_hud.show_bark(sera, "BARK_SERA_GUILD_GO", 2.6, Sera.NAME_KEY)
		elif Vector2(sera.global_position.x - sera.hold_at.x, sera.global_position.z - sera.hold_at.z).length() < 0.6:
			# 跑出大門到街上、往左手邊轉進牆後面才消失（跟雷歐小隊一樣）；出門那一步不撞擋人的那一層（南牆整面都是）
			sera_exit_step += 1
			if sera_exit_step == 1:
				sera.collision_mask &= ~GuildScenery.PEOPLE_LAYER
			if sera_exit_step >= SERA_EXIT.size():
				sera.queue_free()
				sera = null
			else:
				sera.hold_at = SERA_EXIT[sera_exit_step]
	var p: Vector3 = _player.global_position
	if p.z > GuildScenery.HALF_L - GuildScenery.WALL_MARGIN - 0.7 and absf(p.x) < GuildScenery.DOOR_SIZE.x * 0.5 + 0.3:
		_leaving = true
		Game.session.set_flag(FLAG_LEFT, true)
		card = ChapterCard.play(self, "CARD_FOREST_SMALL", "CARD_FOREST_TITLE", Game.go_to_checkpoint_level)


## 結尾：諾恩扛著核心走進來，雷歐還在跟大家說那兩個人回不來了；走近櫃檯，所有人轉過來
func _tick_report() -> void:
	var leo: Npc = party.get("Leo") as Npc
	if not _return_barked and leo != null:
		_return_barked = true
		_hud.show_bark(leo, "BARK_LEO_RETURN", 4.5, LEO_KEY)
	if _player.global_position.z < REPORT_Z:
		_talk(RETURN_DIALOGUE, ["SPK_NOEN", LILITH_KEY, LEO_KEY, ADVENTURER_KEY, Sera.NAME_KEY, INSPECTOR_KEY])


func _on_dialogue_ended(dialogue_id: String) -> void:
	_refresh_interactables()
	match dialogue_id:
		QUEST_DIALOGUE:
			if slip_note != null and is_instance_valid(slip_note):
				slip_note.close(0.9)
			slip_note = null
		LEO_DIALOGUE:
			_party_leaves()
			_alarm_t = -1.0
			_music_to(HALL_MUSIC_DB, MUSIC_BACK_SEC)
			_hud.objective_held = false
			_sera_look = sera.global_position + Vector3(-1.0, 0, -1.4) if sera != null else Vector3.INF
			get_tree().create_timer(1.6).timeout.connect(func() -> void:
				_hud.show_bark(lilith, "BARK_LILITH_SIGH", 2.2, LILITH_KEY))
		RETURN_DIALOGUE:
			# 講完才算做完（不是最後一句一出來就算：巡察官那一句還在畫面上的時候，HUD 不要跳「未完待續」）
			Game.session.set_flag(FLAG_CHAPTER_DONE, true)
			_end_in = END_CARD_DELAY


## 莉莉絲那段話：拿出委託單的那一句，畫面右邊出現那張綠色的紙；蓋章的那一句蓋上「受理」（講完收起來）
func _on_quest_line(_speaker: String, text_key: String) -> void:
	if text_key == SLIP_SHOW_LINE and slip_note == null:
		_close_board()
		slip_note = PaperNote.create("SLIP_TITLE", SLIP_LINES, SLIP_PAPER, SLIP_INK)
		_hud.add_child(slip_note)
	elif text_key == SLIP_STAMP_LINE and slip_note != null and is_instance_valid(slip_note):
		slip_note.stamp("SLIP_STAMP")


## 讀佈告欄：再按一次收起來
func read_board() -> void:
	if board_note != null and is_instance_valid(board_note):
		_close_board()
		return
	board_note = PaperNote.create("BOARD_TITLE", BOARD_LINES, BOARD_PAPER, BOARD_INK)
	_hud.add_child(board_note)
	_board_t = 0.0
	_hud.show_bark(_player, "BARK_NOEN_BOARD", 3.2, "SPK_NOEN")


func _tick_board(delta: float) -> void:
	if board_note == null:
		return
	if not is_instance_valid(board_note):
		board_note = null
		return
	_board_t += delta
	var away: bool = _player.global_position.distance_to(board_use.global_position) > BOARD_AWAY
	if away or _board_t > BOARD_SHOW_SEC or Game.is_in_dialogue():
		_close_board()


func _close_board() -> void:
	if board_note != null and is_instance_valid(board_note):
		board_note.close()
	board_note = null


## 雷歐小隊走出大門（走到就消失）
func _party_leaves() -> void:
	var door: Vector3 = GuildScenery.DOOR_POS + Vector3(0, 0, -0.4)
	var i: int = 0
	for key: String in party:
		var who: Npc = party[key] as Npc
		who.leave_on_arrival = true
		who.add_to_group(LEAVING_GROUP)
		var lane := Vector3(-0.5 + 0.5 * float(i), 0, 0)
		# 走出大門到街上、往右手邊轉進牆後面才消失（門開著的時候看得到外面）
		var out: Array[Vector3] = [door + lane, GuildScenery.DOOR_POS + lane + Vector3(0, 0, 1.6), GuildScenery.DOOR_POS + Vector3(-3.6 - float(i) * 0.6, 0, 2.2)]
		if key == "Leo":
			who.walk_path(out, 2.2)
		else:
			var path: Array[Vector3] = [AISLE_WEST + lane + Vector3(0, 0, 0.8 * float(i))]
			path.append_array(out)
			who.walk_path(path, 2.0)
		i += 1
	party.clear()


## 大廳的配樂慢慢轉到這個音量（停掉＝MUTED_DB；播放器留著，之後還能回來）
func _music_to(volume_db: float, sec: float) -> void:
	if hall_music == null or not is_instance_valid(hall_music):
		return
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = hall_music.create_tween()
	_music_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_music_tween.tween_property(hall_music, "volume_db", volume_db, sec)


## 「第一章　完」：整個畫面淡成黑、出章名，接著製作名單與下一章的預告，播完回標題
func _play_end_card() -> void:
	if card != null:
		return
	_music_to(Ambience.MUTED_DB, 1.0)
	Ambience.music(self, END_MUSIC, END_MUSIC_DB, 1.2, "EndTheme")
	card = ChapterCard.play(self, "CARD_END_SMALL", "CARD_END_TITLE", _play_credits, 1.0, false)


func _play_credits() -> void:
	if credits == null:
		credits = EndCredits.play(self, Game.back_to_title)


## 魔像核心：扛在諾恩的左肩上、左手扶著（GolemCore：祭壇那一關從魔像胸口滾出來的那一顆）
func _attach_core() -> void:
	core = GolemCore.create()
	core.carry_on(_player.get_node("Body") as Node3D, 0.0, _player.puppet())


## 照順序第一個有模型的角色 id；都沒有回傳 ""
static func _first_with_model(ids: Array) -> String:
	for id: Variant in ids:
		if CharacterModels.scene_for(str(id)) != null:
			return str(id)
	return ""


func _mark(node_name: String, at: Vector3) -> void:
	var m := Marker3D.new()
	m.name = node_name
	m.position = at
	add_child(m)
