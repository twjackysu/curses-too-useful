class_name CorruptForest
extends StoryLevel
## 腐敗之森入口（第一章的起點，docs/story/chapter-1.md 節點 2；計畫在 docs/design/13-chapter-1-plan.md）。
## 入口這一段：諾恩一個人走進來 → 席菈先到了、等在瘴氣前面，兩人講幾句就結伴（ch1_sera_joins）→ 一團瘴氣（她戴上防毒面具；
## 諾恩走進去中毒 → 反轉成回血 → 兩人講幾句）→ 林間空地的三隻劇毒史萊姆（席菈跟在後面，開打後往諾恩背上射藥：scenes/actors/sera/）。
## 兩人是在公會大廳認識的（節點 1，GuildHall：她在那裡問能不能一起去，然後先回去拿面具）；這裡是在森林口會合。
## 戰後那段話講完，自由探索（時段 B）開放：那一段的東西在 ForestExplore。
## 地圖（空地、路）在 ForestMap，看得到的場景（天空、地面、樹、草）在 ForestScenery；這裡放規則與劇情。
## 教學戰照劇本：席菈慌了，第一瓶拿錯成【重度麻痺＋防禦歸零】（對諾恩＝出手快 150%＋受傷少 80%）→ 打完兩人講話（兩個選項）。
## 劇情旗標：ch1.sera_joined（結伴了，對話資料自己設）、ch1.reversal_seen（第一次反轉）、ch1.slimes_cleared（三隻都倒了）、ch1.after_slimes_talked（戰後那段話講完，
## 對話資料自己設）——任務 data/quests/ch1_main.json 看這四個；ch1.gate_talked＝瘴氣裡那段對話講過了；
## ch1.misfire_seen＝拿錯的那一瓶射過了。

const MIASMA_POS: Vector3 = Vector3(0, 0, 2)
const MIASMA_RADIUS: float = 5.0
const GLADE_POS: Vector3 = Vector3(0, 0, -15)
const SLIME_SPOTS: Array[Vector3] = [Vector3(-2.5, 0, -15), Vector3(2.5, 0, -16), Vector3(0, 0, -19)]
const FLAG_JOINED: String = "ch1.sera_joined"
const FLAG_REVERSAL: String = "ch1.reversal_seen"
const FLAG_SLIMES: String = "ch1.slimes_cleared"
const FLAG_GATE_TALK: String = "ch1.gate_talked"
const FLAG_MISFIRE: String = "ch1.misfire_seen"
const FLAG_AFTER_TALK: String = "ch1.after_slimes_talked"
const JOIN_DIALOGUE: String = "ch1_sera_joins"
const GATE_DIALOGUE: String = "ch1_forest_gate"
const AFTER_DIALOGUE: String = "ch1_after_slimes"
## 教學戰席菈拿錯的那一瓶（statuses.json 的來源）
const PANIC_VIAL: String = "sera_panic_vial"
## 史萊姆都倒了之後隔多久席菈才開口（等最後一刀的停頓與橫幅）
const AFTER_TALK_DELAY: float = 1.6
## 第一次反轉之後隔多久席菈才開口（等碎裂與金光演完）
const GATE_TALK_DELAY: float = 1.2
## 開場（還沒結伴）諾恩一個人從這裡走進來；結伴之後的檢查點從場景裡的 Spawn 開始
const ENTRANCE_POS: Vector3 = Vector3(0, 0.05, 30)
## 還沒結伴時席菈等在這裡：瘴氣前面、路的左邊，看著那團紫霧
const SERA_WAIT_POS: Vector3 = Vector3(-1.4, 0, 9.5)
## 諾恩走到這麼近（或走過她身邊）她就開口
const SERA_MEET_DIST: float = 3.4
## 結伴之後讀檔：席菈站在諾恩的左前方（玩家的鏡頭一進場就看得到她），之後自己跟在後面
const SERA_START_OFFSET: Vector3 = Vector3(-1.7, 0.0, -2.6)
## 夜晚森林的環境音（風、蟲、遠處的貓頭鷹；整片、不分位置）
const NIGHT_SFX: String = "forest_night"
const NIGHT_DB: float = -15.0

var slimes: Array[Slime] = []
var miasma: PoisonMist
var sera: Sera
var talk_camera: TalkCamera
## 自由探索（時段 B）的東西：夜光毒蕈、陷阱、野外的敵人、營火、寶箱
var explore: ForestExplore
var _talk_skip: int = 0
## 離瘴氣裡那段對話還有幾秒（< 0＝沒有在等）
var _gate_talk_in: float = -1.0
## 離戰後那段對話還有幾秒（< 0＝沒有在等）
var _after_talk_in: float = -1.0
## 拿錯的那一瓶演到哪：0＝還沒舉弩、1＝舉弩喊過了，等藥瓶砸中
var _misfire_step: int = 0
## 還沒結伴：她看到諾恩、出聲叫過了沒
var _sera_called: bool = false
var _rng := RandomNumberGenerator.new()
var _spores: CPUParticles3D

@onready var _player: PlayerController = $Player
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_rng.seed = 20261114
	ForestScenery.build_environment(self)
	var trees: PackedVector3Array = ForestScenery.build_forest(self, _rng, _no_tree_here)
	ForestScenery.build_ground(self, trees)
	SlopeClutter.build(self, trees)
	ForestScenery.build_landmarks(self)
	_build_miasma()
	_spores = ForestScenery.build_spores(self)
	Ambience.play(self, NIGHT_SFX, NIGHT_DB, "ForestNight")
	_mark("MiasmaEdge", MIASMA_POS + Vector3(0, 0, MIASMA_RADIUS))
	_mark("SlimeGlade", GLADE_POS)
	var spawn: Marker3D = $Spawn
	var args: Dictionary = Game.level_args()
	# 新遊戲是從公會大廳開始的：直接進這一關（開發旗標 `--level=corrupt_forest`、測試）就當成大廳那一段演過了
	if Game.session.in_story() and Game.session.quests.stage_of(GuildHall.QUEST) in GuildHall.OPENING_STAGES:
		GuildHall.skip_opening(Game.session)
	# 截圖用：`--joined` 直接從結伴之後開始（席菈在旁邊）；`--burst-on=vial` 要她射藥，也要加這個
	if args.has("joined"):
		Game.session.set_flag(FLAG_JOINED, true)
	# 截圖用：`--explore` 直接從自由探索開始（教學戰與戰後那段話都過了）；配 `--at=x,z` 去看後面的森林
	if args.has("explore"):
		for flag: String in [FLAG_JOINED, FLAG_REVERSAL, FLAG_GATE_TALK, FLAG_MISFIRE, FLAG_SLIMES, FLAG_AFTER_TALK]:
			Game.session.set_flag(flag, true)
	# 截圖用：`--cleared` 直接從三隻史萊姆都倒了、戰後那段話還沒講開始（進場約一秒半那段話開始；配 `--talk-skip=N`）
	if args.has("cleared"):
		for flag: String in [FLAG_JOINED, FLAG_REVERSAL, FLAG_GATE_TALK, FLAG_MISFIRE, FLAG_SLIMES]:
			Game.session.set_flag(flag, true)
	# 截圖用：`--explore --scream` 再跳到採滿五朵、聽到慘叫之後（配 `--at=0,-74`：往北走幾步就到祭壇路口，換到祭壇那一關）
	if args.has("scream"):
		Game.session.add_flag(ForestExplore.FLAG_MUSHROOMS, ForestExplore.MUSHROOM_NEED)
	var st0: GameState = Game.session.state
	_player.global_position = spawn.global_position if bool(st0.get_flag(FLAG_JOINED, false)) else ENTRANCE_POS
	if ForestExplore.unlocked(st0):
		_player.global_position = ForestExplore.spawn_point(st0)
	# 截圖用：`-- --level=corrupt_forest --cam-yaw=90` 鏡頭繞到諾恩的側面（180＝正面）
	if args.has("cam-yaw"):
		_player.yaw = deg_to_rad(float(str(args["cam-yaw"])))
	# 截圖用：`--at=x,z` 把諾恩放到別的地方（空地前面＝--at=0,-5）
	var at: PackedStringArray = str(args.get("at", "")).split(",")
	if at.size() == 2:
		_player.global_position = Vector3(float(at[0]), spawn.global_position.y, float(at[1]))
	# 截圖用：`--weapon=split_blade` 直接拿另一把武器（PlayerController.WEAPONS 的 id）
	if args.has("weapon"):
		_player.equip(str(args["weapon"]))
	_player.snap_camera()
	_spawn_sera()
	explore = ForestExplore.create(self, _player, _hud, sera)
	add_child(explore)
	# 截圖用：`--talk-skip=N` 對話一開始就先按掉 N 句（拍第 N+1 句的鏡位；相遇那一段配 `--at=-0.3,12.2`）
	_talk_skip = int(str(args.get("talk-skip", "0")))
	if _talk_skip > 0:
		Game.dialogue_started.connect(_skip_lines)
	# 連拍用（scripts/burst.sh）：`--burst-on=reversal` 進場 1.5 秒後讓諾恩吸到瘴氣、`--burst-on=vial` 讓席菈射一瓶，從那一刻開始拍
	var burst_on: String = str(args.get("burst-on", ""))
	if burst_on == "reversal" or burst_on == "vial" or burst_on == "ask":
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			App.burst_start_in(1)
			if burst_on == "vial":
				sera.brain.request()
			elif burst_on == "ask":
				# 玩家按鍵要的那一瓶（致盲煙霧彈）：跳過教學戰拿錯的那一瓶
				sera.vial_source = Sera.VIAL_SOURCE
				sera.ask_enabled = true
				sera.ask()
			else:
				_player.status_effects.apply_source("miasma"))
	# `--burst-on=mask`：進場 1.5 秒後把席菈放到瘴氣的邊上（背對瘴氣、面向諾恩），她停下來慌張地找面具；從那一刻開始拍。
	# 配 `--joined --at=1.5,12`：諾恩在瘴氣外面，鏡頭從他背後看過去，她在前面幾步、臉朝鏡頭
	if burst_on == "mask":
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			sera.global_position = MIASMA_POS + Vector3(-1.2, 0.0, MIASMA_RADIUS + 0.6)
			sera.rotation.y = PI
			App.burst_start_in(1))
	# `--burst-on=reload`：進場 1.5 秒後當成剛射出向她要的那一瓶、冷卻只剩裝填那一段——她停下來裝下一瓶（1.6 秒）；從那一刻開始拍。
	# `--burst-on=swap`：同時給她第二瓶（劇毒大紅水）、按一次換的按鍵——她低頭撥一下藥匣，弩上那一瓶變紅（0.8 秒）。都配 `--joined`
	if burst_on == "reload" or burst_on == "swap":
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			sera.vial_source = Sera.VIAL_SOURCE
			sera.ask_enabled = true
			if burst_on == "reload":
				sera.slot_full = false
				sera.brain.ask_left = float(Puppet.ACTION_TIME["reload"]) * Sera.RELOAD_CLICK_AT + 0.02
			else:
				sera.ask_extra = "sera_weak_vial"
				sera.switch_pick()
			App.burst_start_in(1))
	# `--burst-on=combo`：進場 1.5 秒後連砍三下（一下收招就接下一下），從第一下開始拍
	if burst_on == "combo":
		for i: int in PlayerController.COMBO_LEN:
			get_tree().create_timer(1.5 + (float(Puppet.ACTION_TIME["attack"]) + 0.02) * float(i)).timeout.connect(func() -> void:
				if i == 0:
					App.burst_start_in(1)
				_player.start_attack())
	if not bool(Game.session.state.get_flag(FLAG_SLIMES, false)):
		_spawn_slimes()
		# `--burst-on=hit`：第一次有史萊姆挨打的那一刻開始拍（看刀痕、命中的閃光）。
		# 配 `--joined --at=0,-12 --tap=attack`：不加 `--joined` 會先跳相遇的對話，諾恩不會出手。
		# 再加 `--eagle`：一進場就吃到致盲煙霧彈（鷹眼：每一刀都是黃色的準星）
		if burst_on == "hit" and args.has("eagle"):
			_player.status_effects.apply_source(Sera.ASK_SOURCE)
		if burst_on == "hit":
			var waiting: Array[bool] = [true]
			for s: Slime in slimes:
				s.health.damaged.connect(func(_amount: float, _info: Dictionary) -> void:
					if waiting[0]:
						waiting[0] = false
						App.burst_start_in(1))
	elif not bool(Game.session.state.get_flag(FLAG_AFTER_TALK, false)):
		_after_talk_in = AFTER_TALK_DELAY  # 打完、話還沒講就離開的存檔：讀回來接著講
	QualityPreset.apply_tree(self, Settings.quality as QualityPreset.Level)


func footstep_surface(_p: Vector3) -> String:
	return "dirt"


func _physics_process(delta: float) -> void:
	if not Game.session.in_story():
		return
	var st: GameState = Game.session.state
	# 走進樹林太深就拉回來（地圖只有路與空地附近有東西）；孢子跟著玩家飄。
	# 敵人與席菈也一樣：外圍的土坡只是畫的（碰撞是平的），追人、被擊退走出去會被埋在坡裡
	_player.global_position = ForestMap.keep_inside(_player.global_position)
	sera.global_position = ForestMap.keep_inside(sera.global_position)
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		var body := e as Node3D
		if body != null:
			body.global_position = ForestMap.keep_inside(body.global_position)
	_spores.global_position = Vector3(_player.global_position.x, 1.5, _player.global_position.z)
	_tick_meeting(st)
	if not bool(st.get_flag(FLAG_REVERSAL, false)) and _player.status_effects.has("poison"):
		Game.session.set_flag(FLAG_REVERSAL, true)
		_hud.show_center_lines("CH1_REVERSAL_LINE1", "CH1_REVERSAL_LINE2")
		# 在瘴氣裡反轉的才講那段話（先被史萊姆撞到中毒的話，正在打架，不打斷）
		if not bool(st.get_flag(FLAG_GATE_TALK, false)) and miasma.global_position.distance_to(_player.global_position) < MIASMA_RADIUS + 1.0:
			_gate_talk_in = GATE_TALK_DELAY
	if _gate_talk_in >= 0.0:
		_gate_talk_in -= delta
		if _gate_talk_in < 0.0 and Game.start_dialogue(GATE_DIALOGUE):
			Game.session.set_flag(FLAG_GATE_TALK, true)
	_tick_misfire()
	if not slimes.is_empty() and not bool(st.get_flag(FLAG_SLIMES, false)) and slimes_alive() == 0:
		Game.session.set_flag(FLAG_SLIMES, true)
		_hud.show_banner("CH1_SLIMES_CLEARED", 4.0)
		# 打得太快，拿錯的那一瓶還沒舉起來就清場了：那一拍不演了，之後照平常的來
		if _misfire_step == 0 and sera.vial_source == PANIC_VIAL:
			sera.vial_source = Sera.VIAL_SOURCE
			sera.ask_enabled = true
		_after_talk_in = AFTER_TALK_DELAY
	if _after_talk_in >= 0.0:
		_after_talk_in -= delta
		if _after_talk_in < 0.0 and not Game.start_dialogue(AFTER_DIALOGUE):
			_after_talk_in = 0.2  # 別的對話還沒講完：等一下再試


## 還沒會合：席菈等在瘴氣前面。諾恩走近她先出聲，再近一點（或從旁邊走過去）兩人講幾句；
## 對話最後一句把 ch1.sera_joined 設起來，她才開始跟。
func _tick_meeting(st: GameState) -> void:
	if sera.joined:
		return
	if bool(st.get_flag(FLAG_JOINED, false)):
		sera.joined = true
		return
	var dist: float = sera.global_position.distance_to(_player.global_position)
	if not _sera_called and dist < Sera.NOTICE_DIST:
		_sera_called = true
		_hud.show_bark(sera, "BARK_SERA_NOTICE", 2.6, Sera.NAME_KEY)
	if dist < SERA_MEET_DIST or _player.global_position.z < SERA_WAIT_POS.z + 1.0:
		Game.start_dialogue(JOIN_DIALOGUE)


func _on_sera_mask_changed(on: bool) -> void:
	if on and sera.joined and Game.session.state.grant_once("ch1.sera_mask_bark"):
		_hud.show_bark(sera, "BARK_SERA_MASK", 2.8, Sera.NAME_KEY)


## 教學戰的誤射（劇本節點 2）：舉弩的時候喊一句；藥瓶砸中之後抱頭道歉，畫面中間寫這兩種狀態反轉成什麼。
## 只演一次——之後她射平常的那一瓶。倒下重來（旗標跟著退回檢查點）會再演。
func _tick_misfire() -> void:
	if sera.vial_source != PANIC_VIAL:
		return
	if _misfire_step == 0:
		if sera.brain.is_aiming():
			_misfire_step = 1
			_hud.show_bark(sera, "BARK_SERA_PANIC", 2.4, Sera.NAME_KEY)
	elif sera.last_vial != null and (not is_instance_valid(sera.last_vial) or sera.last_vial.landed):
		sera.vial_source = Sera.VIAL_SOURCE
		sera.ask_enabled = true
		Game.session.set_flag(FLAG_MISFIRE, true)
		_hud.show_bark(sera, "BARK_SERA_MISFIRE", 3.4, Sera.NAME_KEY)
		_hud.show_center_lines("CH1_MISFIRE_LINE1", "CH1_MISFIRE_LINE2", 5.0, Hud.CENTER_LINE2_COLOR)


func slimes_alive() -> int:
	var n: int = 0
	for s: Slime in slimes:
		if is_instance_valid(s) and not s.health.is_dead():
			n += 1
	return n


func _skip_lines(r: DialogueRunner) -> void:
	for i: int in _talk_skip:
		r.advance.call_deferred()


func _spawn_sera() -> void:
	sera = Sera.new()
	sera.name = "Sera"
	sera.target = _player
	sera.mask_changed.connect(_on_sera_mask_changed)
	if bool(Game.session.state.get_flag(FLAG_JOINED, false)):
		sera.position = _player.global_position + SERA_START_OFFSET
		# 面向諾恩（一進場看得到她的臉）
		sera.rotation.y = atan2(SERA_START_OFFSET.x, SERA_START_OFFSET.z)
	else:
		sera.joined = false
		sera.position = SERA_WAIT_POS  # 面向 −Z：看著瘴氣
		sera.hesitate_at = MIASMA_POS  # 想進去又不敢：在瘴氣前面走近幾步又退回來
	# 教學戰那一瓶拿錯的演完（或是那一場已經打完了），玩家才可以按鍵向她要藥——在那之前他還不知道她的藥落在自己身上是好東西
	var st: GameState = Game.session.state
	if not bool(st.get_flag(FLAG_MISFIRE, false)) and not bool(st.get_flag(FLAG_SLIMES, false)):
		sera.vial_source = PANIC_VIAL
	else:
		sera.ask_enabled = true
	add_child(sera)
	SeraChatter.attach(self, sera, _hud)
	# 對話時鏡頭帶到講話的人臉上
	talk_camera = TalkCamera.new()
	talk_camera.name = "TalkCamera"
	talk_camera.cast = {"SPK_NOEN": _player, Sera.NAME_KEY: sera}
	add_child(talk_camera)


func _spawn_slimes() -> void:
	for i: int in SLIME_SPOTS.size():
		var s := Slime.new()
		s.name = "Slime%d" % (i + 1)
		s.position = SLIME_SPOTS[i]
		s.focus_player = true
		add_child(s)
		slimes.append(s)


func _mark(node_name: String, at: Vector3) -> void:
	var m := Marker3D.new()
	m.name = node_name
	m.position = at
	add_child(m)


## 瘴氣裡不種樹（ForestScenery.build_forest 問這個）
func _no_tree_here(p: Vector3) -> bool:
	return Vector2(p.x - MIASMA_POS.x, p.z - MIASMA_POS.z).length() <= MIASMA_RADIUS + 1.0


func _build_miasma() -> void:
	miasma = PoisonMist.create(MIASMA_RADIUS, "miasma")
	miasma.name = "Miasma"
	miasma.position = MIASMA_POS
	add_child(miasma)
