extends TestCase
## 廢棄祭壇（第一章的 Boss，劇本節點 3）：關卡蓋得起來 → 雷歐小隊倒地、魔像舉拳 → 抵達的那段話 → 魔像醒來、疫病光環反轉 →
## 兩招、核心還在打不死 → 狂暴、席菈裝禁藥 → 石化凝視：沒擋到她被石化、擋住了她射出禁藥 → 粉碎核心 → 戰後那段話 → 讀檔。
## 從新遊戲一路走到這裡的整段測試在 test_chapter1.gd（test_walkthrough_…）。

const LEVEL: String = "res://scenes/levels/ruined_altar.tscn"

var _dir: String = ""
var _old_session: GameSession
var _level: RuinedAltar


func _game() -> Node:
	return tree.root.get_node("Game")


func before_each() -> void:
	_dir = "user://test_altar_%d" % Time.get_ticks_usec()
	_old_session = _game().get("session") as GameSession
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))
	_game().set("change_scenes", false)


func after_each() -> void:
	if _level != null and is_instance_valid(_level):
		_level.free()
	_game().set("change_scenes", true)
	_game().set("session", _old_session)
	_game().set("dialogue", null)
	Engine.time_scale = 1.0
	CombatTuning.load_tuning()
	if DirAccess.dir_exists_absolute(_dir):
		for f: String in DirAccess.get_files_at(_dir):
			DirAccess.remove_absolute(_dir.path_join(f))
		DirAccess.remove_absolute(_dir)


func _session() -> GameSession:
	return _game().get("session") as GameSession


## 新遊戲並直接跳到剛走進祭壇那一關
func _load_altar() -> RuinedAltar:
	_game().call("new_game", false)
	RuinedAltar.skip_to_altar(_session())
	return _load_level()


func _load_level() -> RuinedAltar:
	_level = (load(LEVEL) as PackedScene).instantiate() as RuinedAltar
	tree.root.add_child(_level)
	return _level


## 直接從開打開始（抵達的那段話講過了），等魔像醒來。席菈先不動（要她的測試自己打開）。
func _load_fight() -> RuinedAltar:
	_game().call("new_game", false)
	RuinedAltar.skip_to_altar(_session())
	_session().set_flag(RuinedAltar.FLAG_TALKED, true)
	var level: RuinedAltar = _load_level()
	level.sera.set_physics_process(false)
	for i: int in 90:
		await tree.physics_frame
		if level.golem.awake:
			break
	# 第一次走進光環的那兩行說明當成看過了（不然會蓋掉測試要看的字）
	_session().state.grant_once("ch1.aura_seen")
	return level


func _frames(n: int) -> void:
	for i: int in n:
		await tree.physics_frame


func _finish_dialogue(pick: int) -> void:
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	var guard: int = 0
	while runner != null and runner.is_running() and guard < 40:
		guard += 1
		if not runner.visible_choices.is_empty():
			runner.choose(pick)
		else:
			runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")), "對話按得完")


func test_altar_level_builds_a_paved_ring_with_pillars_and_the_altar() -> void:
	var level: RuinedAltar = _load_altar()
	await tree.physics_frame
	var s: GameSession = _session()
	assert_eq(s.quests.stage_of("ch1_main"), "altar_arrive")
	assert_eq(s.state.checkpoint, "ch1_altar")
	var player: PlayerController = level.get_node("Player") as PlayerController
	assert_true(player.global_position.distance_to(AltarScenery.ENTRANCE) < 0.5, "諾恩從南邊的路走進來")
	assert_true(level.sera.joined and level.sera.global_position.distance_to(player.global_position) < 4.0, "席菈跟在旁邊")
	assert_true(level.sera.global_position.z > player.global_position.z, "她在他後面（鏡頭這一側）")
	assert_not_null(level.get_node_or_null("AltarRuins"), "目標指引的標記")
	var altar: Node3D = level.get_node("Altar") as Node3D
	assert_true(altar.global_position.distance_to(AltarScenery.ALTAR_POS) < 0.01)
	assert_not_null(altar.get_node_or_null("Omen"), "祭壇上面那盞紅光")
	assert_eq(level.get_node("Ruins").get_child_count(), AltarScenery.PILLARS.size() + AltarScenery.FALLEN.size(), "一圈斷柱＋倒在地上的兩截")
	assert_true(level.get_node("Forest").get_child_count() > 30, "外圍有樹")
	for tree_node: Node in level.get_node("Forest").get_children():
		if tree_node is StaticBody3D:
			var at: Vector3 = (tree_node as Node3D).global_position
			assert_true(Vector2(at.x, at.z).length() > AltarScenery.PLAZA_RADIUS + 2.0, "石板上沒有樹")
			assert_false(at.z > 0.0 and absf(at.x) < AltarScenery.PATH_WALK_HALF, "路上沒有樹")
	assert_true(level.scenery.stones.size() >= AltarScenery.PILLARS.size() + 2, "每一塊石頭有自己的符文材質")
	# 走得到的範圍：石板＋南邊那條路
	assert_eq(AltarScenery.keep_inside(Vector3(3, 0, -5)), Vector3(3, 0, -5))
	assert_eq(AltarScenery.keep_inside(AltarScenery.ENTRANCE), AltarScenery.ENTRANCE)
	assert_true(Vector2(AltarScenery.keep_inside(Vector3(-40, 0, -3)).x, AltarScenery.keep_inside(Vector3(-40, 0, -3)).z).length() <= AltarScenery.WALK_RADIUS + 0.01, "往西走太遠拉回來")
	assert_true(AltarScenery.keep_inside(Vector3(0, 0, 60)).z <= AltarScenery.PATH_END_Z + 0.01, "往回走也有盡頭")
	assert_true(absf(AltarScenery.keep_inside(Vector3(9, 0, 28)).x) <= AltarScenery.PATH_WALK_HALF + 0.01, "路的兩邊是樹林")
	assert_eq(level.footstep_surface(Vector3.ZERO), "stone", "石板上是石頭的腳步聲")
	# 標題的「繼續」回到這一關
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(str(_game().call("level_for_checkpoint", again.state.checkpoint)), "ruined_altar")


## 抵達（劇本節點 3 的 1～3）：雷歐小隊倒在地上、魔像舉著拳頭還沒醒；走上石板雷歐開口（鏡頭放低拍倒在地上的他），
## 講完魔像醒來；諾恩走進疫病光環：全能力下降＋失血 → 全能力提升＋回血。
func test_arriving_finds_leos_party_down_then_the_golem_wakes_and_its_plague_feeds_norn() -> void:
	var level: RuinedAltar = _load_altar()
	await tree.physics_frame
	var s: GameSession = _session()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var golem: PlagueGolem = level.golem
	assert_eq(level.party.size(), 3, "雷歐小隊三個人")
	for who_name: String in level.party:
		var who: Node3D = level.party[who_name] as Node3D
		assert_true(Vector2(who.global_position.x, who.global_position.z).length() < AltarScenery.PLAZA_RADIUS, "%s 倒在石板上" % who_name)
		assert_true(absf(absf((who.get_node("Puppet") as Node3D).rotation.x) - PI * 0.5) < 0.01, "%s 是躺平的" % who_name)
	assert_true(golem != null and not golem.awake, "魔像還沒醒")
	assert_true(golem.is_in_group("boss") and str(golem.name) == "Golem")
	assert_eq(golem.health.max_hp, CombatTuning.num("plague_golem.max_hp"), "數值在資料表裡")
	assert_true(golem.rim_surface_count() > 0 or not golem.puppet().uses_model(), "身上有毒的螢光綠")
	await _frames(3)
	assert_eq(golem.puppet().current_state(), "attack", "舉著拳頭停在那裡")
	var raised: float = golem.puppet().action_time
	await _frames(20)
	assert_eq(golem.puppet().action_time, raised, "動作停在同一刻")
	assert_true(golem.global_position.distance_to(RuinedAltar.GOLEM_START) < 0.3, "站在原地")
	assert_false(level.aura.active, "光環還沒開")
	assert_false(golem.health.apply_damage(500.0, {"source": player, "cut": Vector3.RIGHT}), "醒來之前打不到")
	assert_false(hud.boss_bar.shown, "Boss 的生命條還沒出現")
	# 走上石板：雷歐開口
	player.global_position = Vector3(0, 0.05, RuinedAltar.ARRIVE_Z - 0.5)
	await _frames(2)
	assert_true(bool(_game().call("is_in_dialogue")), "抵達的那段話開始了")
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(str(runner.current().get("speaker", "")), RuinedAltar.LEO_KEY, "第一句是雷歐")
	await _frames(40)
	assert_true(level.talk_camera.is_talking() and level.talk_camera.speaker() == level.party["Leo"], "鏡頭拍倒在地上的雷歐")
	assert_true(level.talk_camera.global_position.y < 1.2, "鏡頭放低（高 %.2f m）" % level.talk_camera.global_position.y)
	assert_false(golem.awake, "對話中魔像不動")
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "boss", "講完：開打")
	assert_eq(s.state.checkpoint, "ch1_boss")
	assert_true(s.has_save())
	await _frames(int(RuinedAltar.WAKE_DELAY * 60.0) + 8)
	assert_true(golem.awake and level.aura.active, "魔像醒了、光環打開")
	await tree.process_frame
	hud.boss_bar.refresh(golem)
	assert_true(hud.boss_bar.shown, "Boss 的生命條出現")
	assert_eq(hud.boss_bar.boss_name_key(), PlagueGolem.NAME_KEY)
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_GOLEM")
	# 光環外面沒事；走進去：疫病 → 全部反轉
	golem.set_physics_process(false)
	level.aura.global_position = golem.global_position
	player.global_position = golem.global_position + Vector3(level.aura.radius + 3.0, 0.05, 0)
	await _frames(3)
	assert_false(player.status_effects.has("plague"), "光環外面沒事")
	player.health.hp = 40.0
	player.global_position = golem.global_position + Vector3(level.aura.radius - 2.0, 0.05, 0)
	await _frames(3)
	assert_eq(player.status_effects.source_of("plague"), "plague_aura", "走進光環：疫病上身")
	assert_true(player.status_effects.attack_speed() > 1.4 and player.status_effects.damage_dealt_scale() > 1.4, "對諾恩是全能力提升")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_AURA_LINE1", "CH1_AURA_LINE2"]), "畫面中間寫反轉成什麼")
	assert_true(hud.bark_keys().has("BARK_LEO_AURA"), "雷歐看傻了")
	await _frames(60)
	assert_true(player.health.hp > 44.0, "一秒回了 %.1f 點血" % (player.health.hp - 40.0))
	assert_true(hud.status.rows.size() >= 1 and str(hud.status.rows[0]["id"]) == "plague", "狀態列有疫病的圖示")
	# 席菈沒有他的體質：進到光環裡戴著面具
	level.sera.set_physics_process(true)
	level.sera.global_position = golem.global_position + Vector3(4.0, 0.0, 3.0)
	await _frames(4)
	assert_true(level.sera.masked, "席菈在光環裡戴著防毒面具")
	assert_true(hud.bark_keys().has("BARK_SERA_AURA"))


## 魔像的兩招：重拳（前方一塊）與震地（身邊一大圈）輪流出；核心被粉碎之前生命扣到底線就扣不下去。
func test_golem_punches_and_slams_and_cannot_die_while_its_core_holds() -> void:
	var level: RuinedAltar = await _load_fight()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var golem: PlagueGolem = level.golem
	assert_true(golem.awake)
	assert_true(golem.brain.flinch_sec <= 0.0, "Boss 不會後仰")
	assert_eq(golem.brain.pattern, PackedStringArray(["punch", "punch", "slam"]))
	player.global_position = golem.global_position + Vector3(0, 0.05, 3.0)
	var seen: Dictionary = {}
	var walked: bool = false
	for i: int in 900:
		await tree.physics_frame
		# 一直站在牠面前 3 m（被打退也拉回來），生命補滿：只看牠出了哪幾招、打不打得到
		player.global_position = golem.global_position + golem.forward() * 3.0 + Vector3(0, 0.05, 0)
		if golem.brain.state == EnemyBrain.State.STRIKE:
			seen[golem.brain.move_id] = int(player.hurt_count)
		player.health.hp = player.health.max_hp
		walked = walked or golem.puppet().current_state() == "attack"
		if seen.has("punch") and seen.has("slam"):
			break
	assert_true(seen.has("punch") and seen.has("slam"), "兩招都出過：%s" % str(seen.keys()))
	assert_true(player.hurt_count >= 2, "站在面前會被打到（%d 下）" % player.hurt_count)
	assert_true(walked, "出手的時候有揮下來的動作")
	# 站得夠遠就打不到
	golem.set_physics_process(false)
	var before: int = player.hurt_count
	player.global_position = golem.global_position + Vector3(0, 0.05, 9.0)
	golem.brain.move_id = "slam"
	golem._on_strike()
	assert_eq(player.hurt_count, before, "震地的範圍外沒事")
	player.global_position = golem.global_position + Vector3(3.0, 0.05, -3.0)
	golem._on_strike()
	assert_eq(player.hurt_count, before + 1, "震地：站在牠背後也會被震到")
	# 核心還在：再痛的一刀也只能扣到底線（先讓牠狂暴完：席菈那時候喊的是別的）
	golem.set_physics_process(true)
	golem.health.hp = golem.health.max_hp * 0.45
	await _frames(4)
	assert_true(golem.health.apply_damage(999999.0, {"source": player, "cut": Vector3.RIGHT}), "照樣算打中")
	assert_false(golem.health.is_dead(), "核心還在，打不死")
	assert_true(absf(golem.health.ratio() - golem.phases.hp_floor) < 0.001, "生命停在 %.0f%%" % (golem.health.ratio() * 100.0))
	level.sera.set_physics_process(true)
	await _frames(3)
	assert_true((level.get_node("Hud") as Hud).bark_keys().has("BARK_SERA_CORE"), "席菈喊：核心還撐著")
	assert_true(golem.phases.is_enraged(), "生命過半就狂暴")


## 一直按出手（像玩家那樣站在面前砍、不閃）：只靠疫病光環與自己的劍，要砍多久才會把魔像砍到狂暴。印出來給調數值的人看。
func test_mashing_under_the_aura_takes_a_while_to_enrage_the_golem() -> void:
	var level: RuinedAltar = await _load_fight()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var golem: PlagueGolem = level.golem
	player.global_position = golem.global_position + Vector3(0, 0.05, 2.4)
	var frames: int = -1
	var swings: int = 0
	for f: int in 60 * 180:
		if golem.phases.is_enraged():
			frames = f
			break
		if player.health.is_dead():
			break
		if player.puppet().action != "attack" and player.hurt_left <= 0.0:
			var to: Vector3 = golem.global_position - player.global_position
			to.y = 0.0
			player.yaw = atan2(-to.x, -to.z)
			if to.length() > 2.6:
				player.global_position += to.normalized() * (PlayerController.WALK_SPEED / 60.0)
			else:
				player.start_attack()
				swings += 1
		await tree.physics_frame
	print("    只靠光環與鐵劍，站著一直砍：%d 幀（%.0f 秒）／%d 刀把魔像砍到狂暴；諾恩剩 %.0f 點生命、挨了 %d 下" % [frames, float(frames) / 60.0, swings, player.health.hp, player.hurt_count])
	assert_false(player.health.is_dead(), "站著硬砍、一下都不閃，也撐得到第二階段（光環一直在回血）")
	assert_true(player.hurt_count >= 3, "但是會挨打（%d 下）" % player.hurt_count)
	assert_true(frames > 60 * 15, "不會幾秒就進第二階段（%d 幀）" % frames)
	assert_true(frames > 0 and frames < 60 * 120, "也不會砍兩分鐘還沒進第二階段（%d 幀）" % frames)


## 把階段的時間縮短（測試不用真的等十幾秒）
func _quick_phases(golem: PlagueGolem) -> void:
	golem.phases.roar_sec = 0.3
	golem.phases.rage_sec = 0.6
	golem.phases.gaze_sec = 0.8
	golem.phases.spent_sec = 4.0


## 狂暴 → 石化凝視，沒擋到（劇本節點 3 的 4）：席菈退到後面裝禁藥；凝視的前兆是地上一道從魔像連到她的光；
## 諾恩沒站上去：他照樣被石化（對他是霸體無敵），席菈變成石頭動不了，過一陣子魔像再凝視一次。
func test_enraged_golem_gazes_and_an_unshielded_sera_turns_to_stone() -> void:
	var level: RuinedAltar = await _load_fight()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var golem: PlagueGolem = level.golem
	var sera: Sera = level.sera
	sera.set_physics_process(true)
	_quick_phases(golem)
	var events: Array[String] = []
	golem.enraged.connect(func() -> void: events.append("enraged"))
	golem.gaze_started.connect(func() -> void: events.append("gaze"))
	golem.gaze_fired.connect(func(blocked: bool) -> void: events.append("fire:%s" % blocked))
	player.global_position = Vector3(6.0, 0.05, 6.0)
	sera.global_position = Vector3(5.0, 0.0, 9.0)
	golem.health.hp = golem.health.max_hp * 0.5
	await _frames(2)
	assert_eq(events, ["enraged"] as Array[String], "生命剩一半：狂暴")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_ENRAGE_LINE1", "CH1_ENRAGE_LINE2"]))
	assert_true(hud.bark_keys().has("BARK_SERA_FORBIDDEN"), "席菈喊她還有一瓶禁藥")
	assert_true(sera.hold_at.is_finite() and sera.hands_full, "她退到後面去裝，手上沒空")
	assert_true(sera.hold_at.distance_to(golem.global_position) > 10.0, "挑離魔像遠的地方（%.1f m）" % sera.hold_at.distance_to(golem.global_position))
	var at_roar: Vector3 = golem.global_position
	await _frames(10)
	assert_true(golem.global_position.distance_to(at_roar) < 0.05 and golem.brain.state != EnemyBrain.State.TELEGRAPH, "吼的時候不追人、不出招")
	assert_true(golem.glow_light().light_color.r > 0.9 and golem.glow_light().light_color.g < 0.5, "身上的光變成橘紅")
	# 等凝視的前兆
	for i: int in 200:
		await tree.physics_frame
		if events.has("gaze"):
			break
	assert_true(events.has("gaze"), "狂暴一陣子之後擺石化凝視")
	await _frames(3)
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_GAZE_LINE1", "CH1_GAZE_LINE2"]))
	assert_eq(str(hud.get("_extra_hint_key")), "HINT_GAZE", "左上多一行：擋在席菈前面")
	assert_true(golem.is_beam_shown(), "地上有一道光從魔像連到席菈")
	# 諾恩站在線外面
	player.global_position = golem.global_position + (sera.global_position - golem.global_position).normalized().rotated(Vector3.UP, PI * 0.5) * 6.0 + Vector3(0, 0.05, 0)
	assert_false(golem.is_gaze_blocked())
	var moved_from: Vector3 = golem.global_position
	for i: int in 200:
		await tree.physics_frame
		player.health.hp = player.health.max_hp
		if events.size() >= 3:
			break
	assert_eq(events[2], "fire:false", "凝視打出去，沒擋到")
	assert_true(golem.global_position.distance_to(moved_from) < 0.05, "擺凝視的時候站著不動")
	assert_true(sera.is_petrified(), "席菈被石化")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_STONED_LINE1", "CH1_STONED_LINE2"]))
	assert_true(player.status_effects.is_unstoppable(), "諾恩也中了——對他是霸體無敵")
	await _frames(2)
	assert_true(player.is_body_glowing(), "整個人蓋一層金光")
	assert_false(player.health.apply_damage(50.0, {"source": golem}), "霸體無敵：打不動")
	assert_false(golem.phases.core_open, "禁藥還沒射：核心打不碎")
	var frozen_at: Vector3 = sera.global_position
	await _frames(30)
	assert_true(sera.global_position.distance_to(frozen_at) < 0.01 and sera.vials_fired == 0, "石化中不動、不射")
	assert_eq(str(hud.get("_extra_hint_key")), "", "那一行收掉")
	# 過一陣子再凝視一次；她的石化先解開
	sera.stoned_left = 0.05
	await _frames(6)
	assert_false(sera.is_petrified())
	assert_true(hud.bark_keys().has("BARK_SERA_FREED"), "她喊：能動了")
	for i: int in 300:
		await tree.physics_frame
		player.health.hp = player.health.max_hp
		if events.count("gaze") >= 2:
			break
	assert_eq(events.count("gaze"), 2, "沒擋到：魔像再凝視一次")


## 擋住了（劇本節點 3 的 4 後半）：諾恩站到那道光上 → 席菈沒事、魔像力竭跪下 → 她射出【混沌大災難藥劑】，
## 砸中之後所有狀態一次上身、全部反轉 → 諾恩的下一刀粉碎核心 → 戰後那段話（兩個回答）→ 這一段結束。
func test_shielding_sera_brings_the_chaos_brew_and_one_cut_shatters_the_core() -> void:
	var level: RuinedAltar = await _load_fight()
	var s: GameSession = _session()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var golem: PlagueGolem = level.golem
	var sera: Sera = level.sera
	sera.set_physics_process(true)
	_quick_phases(golem)
	var fired: Array[bool] = []
	golem.gaze_fired.connect(func(blocked: bool) -> void: fired.append(blocked))
	var shattered: Array[bool] = []
	golem.core_shattered.connect(func() -> void: shattered.append(true))
	player.global_position = Vector3(6.0, 0.05, 6.0)
	golem.health.hp = golem.health.max_hp * 0.4
	for i: int in 400:
		await tree.physics_frame
		player.health.hp = player.health.max_hp
		if golem.phases.phase == GolemPhases.Phase.GAZE:
			break
	assert_eq(golem.phases.phase, GolemPhases.Phase.GAZE)
	# 席菈已經退到後面站好了（測試把階段縮短了，她來不及跑到）；諾恩站到魔像與她中間
	sera.global_position = sera.hold_at
	player.global_position = golem.global_position.lerp(sera.global_position, 0.6) + Vector3(0, 0.05, 0)
	await tree.physics_frame
	assert_true(golem.is_gaze_blocked(), "站在那道光上：擋住了")
	for i: int in 120:
		await tree.physics_frame
		if not fired.is_empty():
			break
	assert_eq(fired, [true] as Array[bool], "凝視被擋下來")
	assert_false(sera.is_petrified(), "席菈沒事")
	assert_true(player.status_effects.is_unstoppable(), "諾恩：石化 → 霸體無敵")
	assert_eq(golem.brain.state, EnemyBrain.State.STAGGERED, "魔像力竭跪下")
	assert_eq(golem.weakpoint_exposed_to(player.global_position), "kneel", "這時候砍牠算砍在破綻上")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_BLOCKED_LINE1", "CH1_BLOCKED_LINE2"]))
	assert_true(hud.bark_keys().has("BARK_SERA_CHAOS"))
	assert_false(golem.phases.core_open, "禁藥還在路上")
	# 她舉弩、射出禁藥、砸中
	for i: int in 180:
		await tree.physics_frame
		if golem.phases.core_open:
			break
	assert_true(golem.phases.core_open, "禁藥砸中：核心可以粉碎了")
	assert_eq(sera.last_vial.source if is_instance_valid(sera.last_vial) else RuinedAltar.CHAOS_SOURCE, RuinedAltar.CHAOS_SOURCE)
	for id: String in ["paralysis", "defense_zero", "blind", "weakness", "slow", "bleed", "petrify"]:
		assert_true(player.status_effects.has(id), "身上有 %s" % id)
	assert_true(player.status_effects.attack_speed() >= 3.0, "出手快到 ×%.1f" % player.status_effects.attack_speed())
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_CHAOS_LINE1", "CH1_CHAOS_LINE2"]))
	assert_false(golem.health.is_dead())
	# 下一刀：粉碎核心
	var to: Vector3 = golem.global_position - player.global_position
	player.global_position = golem.global_position - to.normalized() * 2.0
	player.yaw = atan2(-to.x, -to.z)
	await _frames(2)
	player.start_attack()
	for i: int in 60:
		await tree.physics_frame
		if golem.health.is_dead():
			break
	assert_true(golem.health.is_dead(), "一刀粉碎核心")
	assert_eq(shattered, [true] as Array[bool])
	assert_eq(s.state.get_flag(RuinedAltar.FLAG_GOLEM_DOWN), true)
	assert_eq(s.quests.stage_of("ch1_main"), "after_boss")
	assert_eq(s.state.checkpoint, "ch1_boss_down")
	assert_false(level.aura.active, "光環消失")
	assert_true(not sera.hold_at.is_finite() and not sera.hands_full, "席菈回到諾恩身邊")
	assert_eq(hud.banner_text(), "CH1_GOLEM_DOWN")
	Engine.time_scale = 1.0
	# 隔一下三個人講話；兩個回答
	for i: int in int(RuinedAltar.AFTER_TALK_DELAY * 60.0) + 60:
		await tree.physics_frame
		if bool(_game().call("is_in_dialogue")):
			break
	assert_true(bool(_game().call("is_in_dialogue")), "戰後那段話開始了")
	var affinity: int = int(s.state.get_flag("sera.affinity", 0))
	_finish_dialogue(1)
	assert_eq(int(s.state.get_flag("sera.affinity", 0)), affinity + 10, "回答加好感度")
	assert_eq(str(s.state.get_flag("ch1.altar_answer", "")), "share")
	assert_eq(s.state.get_flag(RuinedAltar.FLAG_DONE), true)
	assert_eq(s.state.get_flag("ch1.golem_core"), true, "拿到魔像核心")
	assert_true(s.story_finished(), "主線做到底了")
	await _frames(3)
	assert_eq(hud.banner_text(), "CH1_GOT_CORE")
	assert_eq(hud.objective_text_key(), Hud.STORY_END_KEY, "左上寫「目前的內容到這裡」")
	assert_false(player.health.is_dead())
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_true(again.story_finished(), "存檔停在這一段的結尾")


## 倒下重來、讀檔：開打之後從走進石板的地方重來，魔像自己醒來（不用再聽一次那段話）；魔像倒了之後讀檔，牠不在、戰後那段話接著講。
func test_retry_restarts_the_fight_and_a_save_after_the_golem_fell_resumes_the_talk() -> void:
	var level: RuinedAltar = await _load_fight()
	var s: GameSession = _session()
	var player: PlayerController = level.get_node("Player") as PlayerController
	assert_eq(s.state.checkpoint, "ch1_boss")
	level.golem.health.hp = level.golem.health.max_hp * 0.3
	await _frames(3)
	assert_true(level.golem.phases.is_enraged())
	# 倒下重來：重讀自動存檔、重新載入關卡
	_game().call("retry", false)
	level.free()
	level = _load_level()
	s = _session()
	assert_eq(s.quests.stage_of("ch1_main"), "boss", "回到開打的地方")
	player = level.get_node("Player") as PlayerController
	assert_true(player.global_position.distance_to(AltarScenery.ENTRANCE) < 0.5)
	assert_true(level.golem != null and not level.golem.awake and level.golem.health.is_full(), "魔像回到滿血、還沒醒")
	await _frames(int(RuinedAltar.WAKE_DELAY * 60.0) + 8)
	assert_false(bool(_game().call("is_in_dialogue")), "不用再聽一次抵達的那段話")
	assert_true(level.golem.awake, "牠自己醒來")
	assert_false(level.golem.phases.is_enraged(), "從第一階段重打")
	# 魔像倒了、話還沒講：讀回來接著講
	level.golem.open_core()
	level.golem.health.apply_damage(999999.0, {"source": player, "cut": Vector3.RIGHT})
	await _frames(2)
	assert_eq(s.quests.stage_of("ch1_main"), "after_boss")
	Engine.time_scale = 1.0
	level.free()
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))
	assert_eq(_session().load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(str(_game().call("level_for_checkpoint", _session().state.checkpoint)), "ruined_altar")
	level = _load_level()
	assert_true(level.golem == null, "魔像不在了")
	assert_not_null(level.party.get("Leo"), "雷歐小隊還在")
	for i: int in int(RuinedAltar.AFTER_TALK_RELOAD * 60.0) + 30:
		await tree.physics_frame
		if bool(_game().call("is_in_dialogue")):
			break
	assert_true(bool(_game().call("is_in_dialogue")), "戰後那段話接著講")
	_finish_dialogue(0)
	assert_true(_session().story_finished())


## 整場照真的時間打一遍（階段不縮短）：一個不會閃的「玩家」——平常站在魔像面前一直砍；凝視的前兆一開始就跑到那道光上站著；
## 禁藥砸中之後回去砍。要贏得了、第一次凝視就擋得住，印出整場打了多久。
func test_a_player_who_never_dodges_can_still_win_the_whole_fight_in_real_time() -> void:
	var level: RuinedAltar = await _load_fight()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var golem: PlagueGolem = level.golem
	var sera: Sera = level.sera
	sera.set_physics_process(true)
	player.global_position = golem.global_position + Vector3(0, 0.05, 2.4)
	var frames: int = -1
	var enraged_at: int = -1
	var low: float = player.health.max_hp
	for f: int in 60 * 240:
		if golem.health.is_dead():
			frames = f
			break
		if player.health.is_dead():
			break
		low = minf(low, player.health.hp)
		if enraged_at < 0 and golem.phases.is_enraged():
			enraged_at = f
		if golem.phases.phase == GolemPhases.Phase.GAZE:
			# 跑到魔像與席菈中間（離魔像三成的地方）站著
			var spot: Vector3 = golem.global_position.lerp(sera.global_position, 0.3)
			var step: Vector3 = spot - player.global_position
			step.y = 0.0
			if step.length() > 0.2:
				player.global_position += step.normalized() * minf(PlayerController.SPRINT_SPEED / 60.0, step.length())
		elif player.puppet().action != "attack" and player.hurt_left <= 0.0:
			var to: Vector3 = golem.global_position - player.global_position
			to.y = 0.0
			player.yaw = atan2(-to.x, -to.z)
			if to.length() > 2.6:
				player.global_position += to.normalized() * (PlayerController.WALK_SPEED / 60.0)
			else:
				player.start_attack()
		await tree.physics_frame
	Engine.time_scale = 1.0
	print("    整場照真的時間打（不閃、只靠光環＋鐵劍＋席菈的藥）：%d 幀（%.0f 秒）打倒魔像；第 %.0f 秒狂暴；凝視 %d 次；諾恩最低剩 %.0f 點生命" % [frames, float(frames) / 60.0, float(enraged_at) / 60.0, golem.phases.gazes, low])
	assert_false(player.health.is_dead(), "不閃也不會死")
	assert_true(frames > 0, "打得贏")
	assert_eq(golem.phases.gazes, 1, "第一次凝視就擋住了（前兆夠長，跑得到那道光上）")
	assert_true(frames < 60 * 150, "整場不超過兩分半（%d 幀）" % frames)
