extends TestCase
## 第一章的起點（腐敗之森入口）：新遊戲 → 任務與檢查點 → 走進瘴氣反轉 → 兩人講幾句 → 席菈跟著、開打後射藥 → 打倒三隻史萊姆。
## 劇本 docs/story/chapter-1.md，計畫 docs/design/13-chapter-1-plan.md。

const LEVEL: String = "res://scenes/levels/corrupt_forest.tscn"

var _dir: String = ""
var _old_session: GameSession
var _level: CorruptForest


func _game() -> Node:
	return tree.root.get_node("Game")


func before_each() -> void:
	_dir = "user://test_ch1_%d" % Time.get_ticks_usec()
	_old_session = _game().get("session") as GameSession
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))


func after_each() -> void:
	if _level != null and is_instance_valid(_level):
		_level.free()
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


## 新遊戲並直接跳到結伴之後（席菈在旁邊）：開場相遇以外的測試從這裡開始
func _new_game_joined() -> void:
	_game().call("new_game", false)
	_session().set_flag(CorruptForest.FLAG_JOINED, true)


func _load_level() -> CorruptForest:
	_level = (load(LEVEL) as PackedScene).instantiate() as CorruptForest
	tree.root.add_child(_level)
	return _level


## 這段字裡有沒有數字（左上的提示平常只有按鍵與字；席菈在裝藥的時候才有倒數）
func _has_digit(text: String) -> bool:
	for i: int in text.length():
		if text[i] >= "0" and text[i] <= "9":
			return true
	return false


func test_new_game_starts_chapter_one_and_autosaves() -> void:
	var s: GameSession = _session()
	assert_false(s.in_story(), "還沒開新遊戲")
	_game().call("new_game", false)
	s = _session()
	assert_true(s.in_story())
	assert_eq(s.state.chapter, "ch1")
	assert_eq(s.main_quest(), "ch1_main")
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera")
	assert_eq(s.objective_key(), "Q_CH1_OBJ_SET_OUT")
	assert_eq(s.state.checkpoint, "ch1_forest_gate")
	assert_true(s.has_save(), "進第一個檢查點就自動存檔")
	assert_true(bool(_game().call("has_continue")), "標題的「繼續」找得到")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "corrupt_forest")


func test_quest_follows_the_four_flags_and_continue_restores_it() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	s.set_flag(CorruptForest.FLAG_REVERSAL, true)
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera", "還沒結伴：先中毒也不會跳過相遇")
	s.set_flag(CorruptForest.FLAG_REVERSAL, false)
	s.set_flag(CorruptForest.FLAG_JOINED, true)
	assert_eq(s.quests.stage_of("ch1_main"), "enter_miasma")
	assert_eq(s.state.checkpoint, "ch1_with_sera")
	s.set_flag(CorruptForest.FLAG_REVERSAL, true)
	assert_eq(s.quests.stage_of("ch1_main"), "slimes")
	assert_eq(s.state.checkpoint, "ch1_slimes")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:SlimeGlade")
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(again.quests.stage_of("ch1_main"), "slimes", "讀檔回到第二段")
	s.set_flag(CorruptForest.FLAG_SLIMES, true)
	assert_eq(s.quests.stage_of("ch1_main"), "after_fight", "打完還有戰後那段話")
	assert_eq(s.state.checkpoint, "ch1_after_slimes")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "corrupt_forest")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:Sera", "指引指向席菈")
	assert_false(s.quests.is_done("ch1_main"))
	s.set_flag(CorruptForest.FLAG_AFTER_TALK, true)
	assert_true(s.quests.is_done("ch1_main"))
	assert_eq(s.state.get_flag("ch1.forest_gate_done"), true)


func test_quest_and_dialogue_data_are_valid() -> void:
	var db := QuestDB.load_default()
	assert_true(db.errors.is_empty(), "任務資料：%s" % ", ".join(db.errors))
	var dlg := DialogueDB.load_default()
	assert_true(dlg.errors.is_empty(), "對話資料：%s" % ", ".join(dlg.errors))
	for id: String in ["ch1_sera_joins", "ch1_forest_gate", "ch1_after_slimes"]:
		assert_true(dlg.has_dialogue(id), "有對話 %s" % id)
	assert_true(StatusRules.load_default().errors.is_empty(), "狀態資料")


func test_moss_mask_is_white_under_trees_and_black_elsewhere() -> void:
	var mask: Image = CorruptForest.moss_mask(PackedVector3Array([Vector3(10, 1.0, -20), Vector3(-69.9, 1.3, 69.9)]))
	var per_meter: float = float(CorruptForest.MOSS_MASK_SIZE) / CorruptForest.GROUND_SIZE
	var half: float = float(CorruptForest.MOSS_MASK_SIZE) * 0.5
	assert_true(mask.get_pixel(int(10.0 * per_meter + half), int(-20.0 * per_meter + half)).r > 0.95, "樹腳下是白的")
	assert_true(mask.get_pixel(int(12.0 * per_meter + half), int(-20.0 * per_meter + half)).r > 0.95, "離樹 2 m 還是白的（土丘在苔裡）")
	assert_eq(mask.get_pixel(int(18.0 * per_meter + half), int(-20.0 * per_meter + half)).r, 0.0, "離樹 8 m 沒有苔")
	assert_eq(mask.get_pixel(int(half), int(half)).r, 0.0, "沒有樹的地方是黑的")
	assert_true(mask.get_pixel(0, CorruptForest.MOSS_MASK_SIZE - 1).r > 0.5, "地圖角落的樹不會畫到圖外面去")


func test_level_builds_with_markers_miasma_slimes_and_a_clear_path() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	for marker: String in ["MiasmaEdge", "SlimeGlade", "Spawn", "Player", "Hud", "Miasma", "Forest", "Sera"]:
		assert_not_null(level.get_node_or_null(marker), "有節點 %s" % marker)
	assert_eq(level.slimes.size(), 3, "三隻史萊姆")
	assert_eq(level.slimes_alive(), 3)
	assert_true(level.get_node("Forest").get_child_count() >= CorruptForest.TREE_COUNT, "樹與路邊的小東西都種了")
	assert_false(CorruptForest.tree_spot_ok(Vector3(0, 0, 8)), "路上不種樹")
	assert_false(CorruptForest.tree_spot_ok(CorruptForest.GLADE_POS), "空地不種樹")
	assert_false(CorruptForest.tree_spot_ok(CorruptForest.MIASMA_POS), "瘴氣裡不種樹")
	assert_true(CorruptForest.tree_spot_ok(Vector3(12, 0, 8)))
	var grass: MultiMeshInstance3D = level.get_node_or_null("Forest/GrassTufts") as MultiMeshInstance3D
	assert_not_null(grass, "有草叢")
	assert_true(grass.multimesh.instance_count > 1000, "草叢不只幾叢（%d）" % grass.multimesh.instance_count)
	assert_false(CorruptForest.grass_spot_ok(Vector3(0, 0, 8)), "路中間不長草")
	assert_false(CorruptForest.grass_spot_ok(CorruptForest.GLADE_POS), "空地不長草")
	assert_true(CorruptForest.grass_spot_ok(Vector3(12, 0, 8)))
	var player: PlayerController = level.get_node("Player") as PlayerController
	assert_true(player.global_position.distance_to((level.get_node("Spawn") as Node3D).global_position) < 0.5, "諾恩在出生點")
	assert_not_null(player.weapon(), "手上有劍")
	assert_true(player.puppet().hand("R").has_node("Weapon"), "劍在右手")


## Jacky 11/14：「一開始應該要先只有男主角，後面遇到女主角才結伴」「她沒有免疫，經過毒物卻也沒事？」
## 開場諾恩一個人從森林口走進來；席菈等在瘴氣前面（沒戴面具、不跟、不射）；走近她先出聲，再近就開口問能不能一起去；
## 答應之後她才跟上來，靠近瘴氣就把防毒面具戴上。
func test_noen_starts_alone_meets_sera_at_the_miasma_and_she_joins_with_her_mask() -> void:
	_game().call("new_game", false)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var s: GameSession = _session()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var sera: Sera = level.sera
	var hud: Hud = level.get_node("Hud") as Hud
	assert_true(player.global_position.distance_to(CorruptForest.ENTRANCE_POS) < 0.5, "從森林口開始")
	assert_true(sera.global_position.distance_to(player.global_position) > 15.0, "開場身邊沒有人（席菈在 %.0f m 外）" % sera.global_position.distance_to(player.global_position))
	assert_false(sera.joined)
	assert_false(sera.masked, "她等在瘴氣外面，沒戴面具（看得到臉）")
	for i: int in 90:
		await tree.physics_frame
	assert_true(sera.global_position.distance_to(CorruptForest.SERA_WAIT_POS) < 0.3, "還沒結伴不會跟過來")
	assert_eq(sera.vials_fired, 0)
	assert_false(bool(_game().call("is_in_dialogue")), "離得遠不會開口")
	# 走近：她先出聲、轉過來
	player.global_position = CorruptForest.SERA_WAIT_POS + Vector3(0.6, 0.05, 7.0)
	for i: int in 40:
		await tree.physics_frame
	assert_true(hud.bark_keys().has("BARK_SERA_NOTICE"), "看到諾恩先出聲")
	var to_noen: Vector3 = (player.global_position - sera.global_position).normalized()
	assert_true((-sera.global_basis.z).dot(to_noen) > 0.8, "轉過來面向諾恩")
	assert_false(bool(_game().call("is_in_dialogue")))
	# 再近一點：開口
	player.global_position = CorruptForest.SERA_WAIT_POS + Vector3(0.6, 0.05, 2.5)
	for i: int in 3:
		await tree.physics_frame
	assert_true(bool(_game().call("is_in_dialogue")), "走到她面前就開口")
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_JOIN_001")
	runner.advance()
	runner.advance()
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_JOIN_004", "劇本那一句：能讓我跟你一起去嗎？")
	assert_eq(runner.visible_choices.size(), 2)
	assert_false(sera.joined, "還沒答應")
	assert_true(runner.choose(1))
	runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")))
	assert_eq(s.state.get_flag(CorruptForest.FLAG_JOINED), true)
	assert_eq(int(s.state.get_flag("sera.affinity", 0)), 10)
	assert_eq(s.quests.stage_of("ch1_main"), "enter_miasma", "結伴之後才是「走進瘴氣裡」")
	assert_eq(s.state.checkpoint, "ch1_with_sera")
	for i: int in 3:
		await tree.physics_frame
	assert_true(sera.joined, "答應了才結伴")
	assert_false(bool(_game().call("is_in_dialogue")), "只問一次")
	# 諾恩走進瘴氣，她跟上來：到邊上先戴面具
	player.global_position = CorruptForest.MIASMA_POS + Vector3(0, 0.05, -3.0)
	var frames: int = 0
	while not sera.masked and frames < 360:
		await tree.physics_frame
		frames += 1
	assert_true(sera.masked, "靠近瘴氣就戴上面具")
	assert_true(sera.near_miasma())
	if sera.mask() != null:
		assert_true(sera.mask().visible, "面具看得到")
	assert_true(hud.bark_keys().has("BARK_SERA_MASK"), "第一次戴的時候講一句")
	# 離開瘴氣一下子才拿下來
	var runner2: DialogueRunner = _game().get("dialogue") as DialogueRunner
	if runner2 != null:
		while runner2.advance():
			pass
	sera.global_position = CorruptForest.ENTRANCE_POS
	player.global_position = CorruptForest.ENTRANCE_POS + Vector3(0, 0.05, -3.0)
	for i: int in 30:
		await tree.physics_frame
	assert_true(sera.masked, "剛離開還戴著")
	for i: int in int(Sera.MASK_OFF_DELAY * 60.0) + 20:
		await tree.physics_frame
	assert_false(sera.masked, "離開一下子就拿下來")


## 對話時鏡頭帶到講話的人臉上：相遇那一段先看席菈、換諾恩講就切到他（他已經轉過去面向她）、講完回到玩家的鏡頭。
func test_talk_camera_shows_whoever_is_speaking_then_hands_back() -> void:
	_game().call("new_game", false)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var sera: Sera = level.sera
	var cam: TalkCamera = level.talk_camera
	var own: Camera3D = tree.root.get_viewport().get_camera_3d()
	assert_true(own != null and own != cam, "平常是玩家自己的鏡頭")
	assert_false(cam.is_talking())
	# 走到她旁邊、背對著她：開口
	player.global_position = CorruptForest.SERA_WAIT_POS + Vector3(1.4, 0.05, 2.6)
	for i: int in 3:
		await tree.physics_frame
	assert_true(bool(_game().call("is_in_dialogue")))
	assert_true(cam.is_talking() and cam.current, "對話一開始就接手")
	assert_eq(cam.speaker(), sera as Node3D, "第一句是她（？？？）")
	for i: int in int(TalkCamera.BLEND_SEC * 60.0) + 12:
		await tree.physics_frame
	assert_eq(tree.root.get_viewport().get_camera_3d(), cam as Camera3D)
	var to_sera: Vector3 = (TalkCamera.aim_point(sera.global_position) - cam.global_position).normalized()
	assert_true((-cam.global_basis.z).dot(to_sera) > 0.999, "滑到位之後對著席菈")
	assert_true(cam.global_position.distance_to(sera.global_position) < 3.4, "是近景（離她 %.1f m）" % cam.global_position.distance_to(sera.global_position))
	assert_true(absf(cam.fov - TalkCamera.TALK_FOV) < 0.1)
	var sera_face: Vector3 = -sera.global_basis.z
	assert_true(sera_face.dot((cam.global_position - sera.global_position).normalized()) > 0.5, "拍到的是她的臉，不是後腦勺")
	var to_her: Vector3 = sera.global_position - player.global_position
	to_her.y = 0.0
	assert_true(player.facing().dot(to_her.normalized()) > 0.95, "諾恩轉過去面向她")
	# 換諾恩講：直接切到他那邊
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	runner.advance()
	await tree.physics_frame
	await tree.physics_frame
	assert_eq(cam.speaker(), player as Node3D)
	var to_noen: Vector3 = (TalkCamera.aim_point(player.global_position) - cam.global_position).normalized()
	assert_true((-cam.global_basis.z).dot(to_noen) > 0.999, "換人講就切過去，不是慢慢搖")
	assert_true(player.facing().dot((cam.global_position - player.global_position).normalized()) > 0.5, "拍到的是他的臉")
	# 講完：滑回玩家的鏡頭
	runner.advance()
	runner.advance()
	runner.choose(0)
	runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")))
	for i: int in int(TalkCamera.BLEND_SEC * 60.0) + 6:
		await tree.physics_frame
	assert_false(cam.is_talking())
	assert_eq(tree.root.get_viewport().get_camera_3d(), own, "講完鏡頭還給玩家")


## 結伴之後讀檔（或倒下重來）：從原本的出生點開始，席菈在旁邊，不會再問一次。
func test_continue_after_joining_starts_with_sera_beside_noen() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	assert_true(player.global_position.distance_to((level.get_node("Spawn") as Marker3D).global_position) < 0.5)
	assert_true(level.sera.joined)
	assert_true(level.sera.global_position.distance_to(player.global_position) < 4.0)
	for i: int in 30:
		await tree.physics_frame
	assert_false(bool(_game().call("is_in_dialogue")))


func test_walking_into_the_miasma_reverses_poison_into_healing() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	player.health.hp = 40.0
	player.global_position = CorruptForest.MIASMA_POS + Vector3(0, 0.05, 0)
	for i: int in 30:
		await tree.physics_frame
	assert_true(player.status_effects.has("poison"), "站在瘴氣裡中毒了")
	assert_true(player.reversal_cue.is_playing(), "反轉的回饋在播（紫紅 → 碎裂 → 金光）")
	assert_true(player.heal_fx.bursts >= 1, "0.3 秒後碎成金光")
	assert_true((level.get_node("Hud") as Hud).reversal.visible, "畫面邊緣那一層亮著")
	assert_true(player.health.hp > 40.0, "中毒變成回血（%.1f）" % player.health.hp)
	var s: GameSession = _session()
	assert_eq(s.state.get_flag(CorruptForest.FLAG_REVERSAL), true)
	assert_eq(s.quests.stage_of("ch1_main"), "slimes", "任務往下一段")


func test_after_the_first_reversal_sera_and_noen_talk_once() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	player.global_position = CorruptForest.MIASMA_POS + Vector3(0, 0.05, 0)
	assert_false(bool(_game().call("is_in_dialogue")), "一進場可以直接走，不先講話")
	var frames: int = 0
	while not bool(_game().call("is_in_dialogue")) and frames < 240:
		await tree.physics_frame
		frames += 1
	assert_true(bool(_game().call("is_in_dialogue")), "反轉之後席菈開口")
	assert_true(frames > int(CorruptForest.GATE_TALK_DELAY * 60.0), "等碎裂與金光演完才講（%d 幀）" % frames)
	var s: GameSession = _session()
	assert_eq(s.state.get_flag(CorruptForest.FLAG_GATE_TALK), true)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_GATE_001")
	var before: Vector3 = level.sera.global_position
	for i: int in 20:
		await tree.physics_frame
	assert_true(level.sera.global_position.distance_to(before) < 0.05, "講話的時候席菈站著")
	for i: int in 4:
		runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")), "四句講完")
	for i: int in 120:
		await tree.physics_frame
	assert_false(bool(_game().call("is_in_dialogue")), "只講一次")


func test_sera_starts_in_view_and_follows_behind_noen() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var sera: Sera = level.sera
	assert_true(sera.global_position.z < player.global_position.z, "開場站在諾恩前面（鏡頭看得到）")
	assert_eq(sera.collision_layer, 0, "不擋路")
	assert_not_null(sera.crossbow(), "手上有手弩")
	assert_true(sera.puppet().hand("R").has_node("Crossbow"), "手弩在右手")
	for slime: Slime in level.slimes:
		slime.set_physics_process(false)
	player.global_position = Vector3(0, 0.05, 3)
	for i: int in 300:
		await tree.physics_frame
	var dist: float = sera.global_position.distance_to(player.global_position)
	assert_true(dist > 3.5 and dist <= CombatTuning.num("sera.follow_far"), "跟上來停在後面 4～6 m（%.1f）" % dist)
	assert_true(sera.global_position.z > player.global_position.z, "在諾恩後面")
	assert_eq(sera.vials_fired, 0, "附近沒有敵人不射")
	sera.global_position = player.global_position + Vector3(0, 0, 30)
	for i: int in 3:
		await tree.physics_frame
	assert_true(sera.global_position.distance_to(player.global_position) < CombatTuning.num("sera.follow_far"), "被甩太遠就直接出現在後面")


## 拿錯的那一瓶演完之後，玩家可以按鍵向席菈要【致盲煙霧彈】（劇本節點 3 的「索取特定藥水」）：附近沒有敵人她也射，
## 砸開在腳邊冒一圈煙、落在諾恩身上反轉成鷹眼；剛要過一瓶她還在裝填，會回一句、左上那一行改寫還要等幾秒，裝好了她喊一聲。
func test_norn_can_ask_sera_for_a_blinding_smoke_vial() -> void:
	_new_game_joined()
	_session().set_flag(CorruptForest.FLAG_REVERSAL, true)
	_session().set_flag(CorruptForest.FLAG_MISFIRE, true)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var sera: Sera = level.sera
	var hud: Hud = level.get_node("Hud") as Hud
	assert_false(sera.threat_near(), "史萊姆還很遠")
	assert_true(sera.ask_enabled)
	assert_false(_has_digit(hud.hint_text()), "還沒要：提示寫按哪個鍵，沒有倒數：%s" % hud.hint_text())
	Input.action_press(Sera.ASK_ACTION)
	await tree.physics_frame
	Input.action_release(Sera.ASK_ACTION)
	await tree.physics_frame
	assert_true(sera.brain.is_aiming(), "按了她就舉弩")
	assert_true(hud.bark_keys().has("BARK_SERA_ASK"), "她應了一聲")
	assert_false(sera.ask(), "還在裝這一瓶")
	assert_true(hud.bark_keys().has("BARK_SERA_RELOADING"), "按了沒射也有回應")
	await tree.physics_frame
	assert_true(hud.hint_text().contains("[Q]") and hud.hint_text().contains(str(int(CombatTuning.num("sera.ask_cooldown")))),
		"提示改寫她還要裝幾秒：%s" % hud.hint_text())
	var frames: int = 0
	while sera.vials_fired == 0 and frames < 120:
		await tree.physics_frame
		frames += 1
	assert_eq(sera.vials_fired, 1, "沒有敵人也射")
	var vial: SeraVial = sera.last_vial
	assert_eq(vial.source, Sera.ASK_SOURCE, "射的是致盲煙霧彈")
	assert_true(vial.liquid != SeraVial.LIQUID, "顏色跟平常的紫色藥瓶不一樣")
	for i: int in int(CombatTuning.num("sera.vial_flight") * 60.0) + 6:
		await tree.physics_frame
	assert_true(vial.landed and player.status_effects.strikes_weakpoint(), "落在諾恩身上：致盲 → 鷹眼")
	assert_true(vial.smoky and vial.smoke != null, "煙霧彈砸開有煙")
	if vial.smoke != null:
		assert_true(absf(vial.smoke.global_position.y - player.global_position.y - SeraVial.SMOKE_Y) < 0.05
			and Vector2(vial.smoke.global_position.x - player.global_position.x, vial.smoke.global_position.z - player.global_position.z).length() < 0.3,
			"煙從他腳邊往外滾（不是從胸口往上冒，不擋住人）：%s" % str(vial.smoke.global_position - player.global_position))
		assert_eq(vial.smoke.gravity.x, 0.0)
		assert_true(vial.smoke.flatness == 1.0 and vial.smoke.gravity.y < 1.0, "貼著地面往四面八方")
		assert_eq(vial.smoke.explosiveness, 1.0, "一次全部出來（還沒出來的粒子會在腳邊畫成一團黑的）")
		assert_eq(ParticleLook.untextured(vial).size(), 0, "煙是圓的軟邊，不是方塊")
	assert_true(player.reversal_cue.is_playing(), "反轉的回饋自己播了")
	for i: int in 3:
		await tree.physics_frame
	assert_eq(hud.status.rows.size(), 1)
	for i: int in 200:
		await tree.physics_frame
	assert_eq(sera.vials_fired, 1, "只射要的那一瓶")
	assert_true(_has_digit(hud.hint_text()) and not hud.bark_keys().has("BARK_SERA_READY"), "還在裝：%s" % hud.hint_text())
	sera.brain.ask_left = 0.05
	for i: int in 6:
		await tree.physics_frame
	assert_true(hud.bark_keys().has("BARK_SERA_READY"), "裝好了她喊一聲")
	assert_false(_has_digit(hud.hint_text()), "提示改回按哪個鍵：%s" % hud.hint_text())
	assert_true(sera.ask(), "可以再要一瓶")


## 教學戰照劇本：席菈慌了，第一瓶拿錯成【重度麻痺＋防禦歸零】→ 落在諾恩身上變成出手快 150%＋受傷少 80%；之後她射平常的那一瓶。
func test_in_a_fight_sera_panics_and_her_wrong_vial_reverses_into_two_boons() -> void:
	_new_game_joined()
	_session().set_flag(CorruptForest.FLAG_REVERSAL, true)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var sera: Sera = level.sera
	for slime: Slime in level.slimes:
		slime.set_physics_process(false)
	player.global_position = CorruptForest.GLADE_POS + Vector3(0, 0.05, 6)
	sera.global_position = player.global_position + Vector3(0, 0, 5)
	assert_true(sera.threat_near(), "史萊姆就在前面")
	assert_eq(player.status_effects.attack_speed(), 1.0)
	assert_eq(sera.vial_source, CorruptForest.PANIC_VIAL, "第一瓶是拿錯的那一瓶")
	var hud: Hud = level.get_node("Hud") as Hud
	assert_false(sera.ask(), "拿錯的那一瓶還沒演：還不能向她要藥")
	assert_false(hud.hint_text().contains("[Q]"), "提示也還沒有那一行")
	var frames: int = 0
	var aimed: bool = false
	while sera.vials_fired == 0 and frames < 400:
		await tree.physics_frame
		frames += 1
		aimed = aimed or sera.puppet().current_state() == "shoot"
	assert_eq(sera.vials_fired, 1, "開打後射出第一瓶")
	assert_true(aimed, "先舉弩瞄準")
	assert_true(hud.bark_keys().has("BARK_SERA_PANIC"), "舉弩的時候她喊了一句")
	assert_true(frames >= int(CombatTuning.num("sera.first_vial_delay") * 60.0), "不是一開打的那一幀就射（%d 幀）" % frames)
	var vial: SeraVial = sera.last_vial
	assert_false(player.status_effects.has("paralysis"), "藥瓶還在飛")
	for i: int in int(CombatTuning.num("sera.vial_flight") * 60.0) + 6:
		await tree.physics_frame
	assert_true(vial.landed, "藥瓶砸在諾恩身上")
	assert_true(vial.smoke == null, "她自己射的藥瓶沒有煙（只有煙霧彈有）")
	assert_true(player.status_effects.has("paralysis") and player.status_effects.has("defense_zero"), "麻痺與防禦歸零一起上身")
	assert_eq(player.status_effects.source_of("paralysis"), CorruptForest.PANIC_VIAL)
	assert_false(player.status_effects.blocks_attack(), "不會被麻痺定住")
	assert_true(absf(player.status_effects.attack_speed() - 2.5) < 0.01, "出手快 150%%（×%.2f）" % player.status_effects.attack_speed())
	assert_true(player.reversal_cue.is_playing(), "反轉的回饋自己播了（不用另外接）")
	assert_true(hud.bark_keys().has("BARK_SERA_MISFIRE"), "砸中之後她抱頭道歉")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_MISFIRE_LINE1", "CH1_MISFIRE_LINE2"]), "畫面中間寫這兩種狀態反轉成什麼")
	assert_eq(_session().state.get_flag(CorruptForest.FLAG_MISFIRE), true)
	assert_eq(sera.vial_source, Sera.VIAL_SOURCE, "只拿錯一次，之後是平常的那一瓶")
	assert_eq(hud.status.rows.size(), 2, "狀態列兩格")
	assert_true(sera.ask_enabled, "拿錯的那一瓶演完，可以按鍵向她要藥了")
	await tree.physics_frame
	assert_true(hud.hint_text().contains("[Q]"), "操作提示多一行向席菈要藥：%s" % hud.hint_text())
	var hp0: float = player.health.hp
	player.health.apply_damage(10.0, {})
	assert_true(absf(hp0 - player.health.hp - 2.0) < 0.01, "這時候挨打只扣兩成（扣了 %.1f）" % (hp0 - player.health.hp))


## 席菈平常跟在鏡頭後面：她喊的話以前不在畫面裡就不顯示，教學戰那兩句玩家根本看不到。
## 現在看不到她的時候，那一句改成畫面下方的「席菈：……」；看得到她就照舊浮在她頭上（不寫名字）。
func test_sera_line_moves_to_the_bottom_with_her_name_when_she_is_off_screen() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var sera: Sera = level.sera
	sera.set_physics_process(false)
	player.snap_camera()
	var cam: Camera3D = tree.root.get_camera_3d()
	assert_not_null(cam, "有鏡頭")
	var view: Vector2 = tree.root.get_visible_rect().size
	var back: Vector3 = cam.global_basis.z
	back.y = 0.0
	# 她在鏡頭後面 3 m
	sera.global_position = Vector3(cam.global_position.x, player.global_position.y, cam.global_position.z) + back.normalized() * 3.0
	hud.show_bark(sera, "BARK_SERA_PANIC", 30.0, Sera.NAME_KEY)
	await tree.process_frame
	var texts: PackedStringArray = hud.bark_texts()
	assert_eq(texts.size(), 1, "看不到她：那一句還是顯示")
	if texts.size() == 1:
		assert_true(texts[0].begins_with(tr("SPK_SHEILA")) and texts[0].ends_with(tr("BARK_SERA_PANIC")), "寫了是誰講的（%s）" % texts[0])
		var rect: Rect2 = hud.bark_rects()[0]
		assert_true(rect.position.y > view.y * 0.55 and rect.end.y < view.y - 100.0, "在畫面下方、生命條上面（y %.0f～%.0f，畫面高 %.0f）" % [rect.position.y, rect.end.y, view.y])
		assert_true(absf(rect.get_center().x - view.x * 0.5) < 2.0, "左右置中")
		assert_true(hud.bark_backed("BARK_SERA_PANIC"), "下方那一行後面墊了暗底")
	# 沒給名字的照舊不顯示（貼在邊上的一句話看不出是誰講的）
	hud.show_bark(sera, "BARK_SERA_PANIC", 30.0)
	await tree.process_frame
	assert_eq(hud.bark_texts().size(), 0, "沒給名字、又看不到人：不顯示")
	# 她走到鏡頭前面 6 m、離諾恩遠一點（不被他擋住）：回到她頭上，不寫名字
	var right: Vector3 = cam.global_basis.x
	right.y = 0.0
	sera.global_position = Vector3(cam.global_position.x, player.global_position.y, cam.global_position.z) - back.normalized() * 6.0 + right.normalized() * 1.5
	hud.show_bark(sera, "BARK_SERA_PANIC", 30.0, Sera.NAME_KEY)
	await tree.process_frame
	texts = hud.bark_texts()
	assert_eq(texts, PackedStringArray(["BARK_SERA_PANIC"]), "看得到她：字在她頭上，不寫名字")
	assert_false(hud.bark_backed("BARK_SERA_PANIC"), "頭上的話不墊底")
	if texts.size() == 1:
		var on: Vector2 = cam.unproject_position(sera.global_position + Vector3.UP * 2.1)
		assert_true(hud.bark_rects()[0].get_center().distance_to(on) < 80.0, "貼著她的頭（差 %.0f px）" % hud.bark_rects()[0].get_center().distance_to(on))
	level.queue_free()
	await tree.process_frame


## 「趁現在砍」：像玩家那樣——往最近的那一隻小跑過去，夠得到就一直按出手。量三隻史萊姆全倒要幾幀；回傳 -1＝時間內沒清完。
var _mash_swings: int = 0


func _mash_until_clear(level: CorruptForest, player: PlayerController, max_frames: int) -> int:
	_mash_swings = 0
	for f: int in max_frames:
		if level.slimes_alive() == 0:
			return f
		if player.puppet().action != "attack":
			var nearest: Slime = null
			for sl: Slime in level.slimes:
				if is_instance_valid(sl) and not sl.health.is_dead() and (nearest == null or sl.global_position.distance_to(player.global_position) < nearest.global_position.distance_to(player.global_position)):
					nearest = sl
			var to: Vector3 = nearest.global_position - player.global_position
			to.y = 0.0
			player.yaw = atan2(-to.x, -to.z)
			if to.length() > CombatTuning.num("noen.strike_range") - 0.3:
				player.global_position += to.normalized() * (PlayerController.WALK_SPEED / 60.0)
			else:
				player.start_attack()
				_mash_swings += 1
		await tree.physics_frame
	return -1


## 劇本：超頻的諾恩一刀秒殺史萊姆群。吃了拿錯的那一瓶之後一直按出手：一刀一隻（出手越快砍得越重），三隻 2.5 秒內清掉，
## 而且明顯比沒吃的時候快、出的刀也少。
## （這個測試量出過一個真的問題：出手會自動轉向最近的敵人，以前連剛倒下的也算——打完第一隻之後一直砍屍體，旁邊活的打不到。）
func test_overdrive_from_the_wrong_vial_clears_the_glade_in_seconds() -> void:
	var frames: Array[int] = []
	var swings: Array[int] = []
	for buffed: bool in [false, true]:
		_new_game_joined()
		_session().set_flag(CorruptForest.FLAG_REVERSAL, true)
		_session().set_flag(CorruptForest.FLAG_MISFIRE, true)  # 席菈不插手：這裡只量諾恩自己
		var level: CorruptForest = _load_level()
		await tree.physics_frame
		var player: PlayerController = level.get_node("Player") as PlayerController
		level.sera.set_physics_process(false)
		player.global_position = CorruptForest.GLADE_POS + Vector3(0, 0.05, 1.5)
		if buffed:
			player.status_effects.apply_source(CorruptForest.PANIC_VIAL)
		frames.append(await _mash_until_clear(level, player, 1800))
		swings.append(_mash_swings)
		assert_false(player.health.is_dead(), "諾恩沒倒")
		level.queue_free()
		await tree.process_frame
	print("    三隻史萊姆全倒：沒吃藥 %d 幀／%d 刀、吃了拿錯的那一瓶 %d 幀／%d 刀" % [frames[0], swings[0], frames[1], swings[1]])
	assert_true(frames[0] > 0 and frames[1] > 0, "兩次都清得掉：%s" % str(frames))
	assert_true(frames[1] <= 150, "超頻：2.5 秒內清場（%d 幀）" % frames[1])
	assert_true(swings[1] <= 4, "超頻：一刀一隻（三隻最多容許揮空一次，出了 %d 刀）" % swings[1])
	assert_true(swings[0] >= swings[1] + 2, "沒吃藥要多砍好幾刀（%d 對 %d 刀）" % [swings[0], swings[1]])
	assert_true(float(frames[1]) <= float(frames[0]) * 0.7, "比沒吃藥快三成以上（%d 對 %d 幀）" % [frames[1], frames[0]])


func test_slime_chases_bumps_and_its_poison_heals_noen() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var slime: Slime = level.slimes[0]
	assert_eq(slime.tuning_id(), "poison_slime")
	assert_eq(slime.health.max_hp, CombatTuning.num("poison_slime.max_hp"))
	assert_true(slime.is_in_group("enemies") and slime.is_in_group("damageable"))
	for other: Slime in [level.slimes[1], level.slimes[2]]:
		other.set_physics_process(false)
	player.global_position = slime.global_position + Vector3(0, 0.05, 1.2)
	var hp0: float = player.health.hp
	var struck: bool = false
	for i: int in 240:
		await tree.physics_frame
		if player.health.hp < hp0 or player.status_effects.has("poison"):
			struck = true
			break
	assert_true(struck, "史萊姆撞到諾恩")
	assert_true(player.status_effects.has("poison"), "撞到會中毒（對諾恩是回血）")


## 史萊姆是紫的、霧也是紫的：牠身上一圈螢光綠的邊、腳下一盞綠燈，蓄力時變亮、倒下就熄。
## 夜光毒蕈的顏色照形狀算，自己的燈不照毒蕈（照到會整叢變成一片白）。
func test_slimes_glow_green_in_the_purple_fog_and_mushrooms_have_colour() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var slime: Slime = level.slimes[0]
	for other: Slime in [level.slimes[1], level.slimes[2]]:
		other.set_physics_process(false)
	assert_true(slime.rim_surface_count() > 0, "身上有綠邊（%d 塊）" % slime.rim_surface_count())
	var glow: OmniLight3D = slime.glow_light()
	assert_true(glow.light_color.g > glow.light_color.r * 2.0 and glow.light_color.g > glow.light_color.b * 2.0, "腳下的光是綠的（霧是紫的）")
	assert_false(glow.shadow_enabled, "小燈不算影子")
	await tree.physics_frame
	assert_true(absf(slime.glow_level() - 1.0) < 0.001, "還沒蓄力：平常的亮度（%.2f）" % slime.glow_level())
	player.global_position = slime.global_position + Vector3(0, 0.05, 1.2)
	var peak: float = 1.0
	for i: int in 240:
		await tree.physics_frame
		peak = maxf(peak, slime.glow_level())
		if slime.brain.state == EnemyBrain.State.STRIKE:
			break
	assert_true(peak > Slime.GLOW_WINDUP * 0.8, "蓄力要撲的時候越來越亮（最亮 %.2f 倍）" % peak)
	assert_true(absf(glow.light_energy - Slime.GLOW_ENERGY * slime.glow_level()) < 0.001, "腳下的燈跟身上的邊一起亮")
	slime.health.apply_damage(9999.0, {"source": player})
	for i: int in 90:
		await tree.process_frame
		if slime.glow_level() <= 0.0:
			break
	assert_true(slime.glow_level() <= 0.0 and glow.light_energy <= 0.0, "倒下之後綠光熄掉（%.2f）" % slime.glow_level())
	var lamps: int = 0
	for prop: Node in level.get_node("Forest").get_children():
		var lamp: OmniLight3D = prop.get_node_or_null("Glow") as OmniLight3D
		if lamp == null:
			continue
		lamps += 1
		for n: Node in prop.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			assert_eq(mi.layers & lamp.light_cull_mask, 0, "夜光毒蕈自己的燈不照毒蕈")
			var paint := mi.get_surface_override_material(0) as ShaderMaterial
			assert_true(paint != null and paint.shader == CorruptForest.MUSHROOM_SHADER, "毒蕈的顏色照形狀算（模型的顏色貼圖是灰的）")
		assert_true(lamp.light_cull_mask & 1 == 1, "照得到地面與旁邊的東西")
	assert_true(lamps > 0, "有會發光的毒蕈（%d 叢）" % lamps)


func test_clearing_the_slimes_finishes_the_slice() -> void:
	_new_game_joined()
	var s: GameSession = _session()
	s.set_flag(CorruptForest.FLAG_REVERSAL, true)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	for slime: Slime in level.slimes:
		slime.health.apply_damage(9999.0, {"source": level.get_node("Player")})
	assert_eq(level.slimes_alive(), 0)
	for i: int in 3:
		await tree.physics_frame
	assert_eq(s.state.get_flag(CorruptForest.FLAG_SLIMES), true)
	var hud: Hud = level.get_node("Hud") as Hud
	assert_eq(hud.banner_text(), "CH1_SLIMES_CLEARED")
	assert_eq(s.quests.stage_of("ch1_main"), "after_fight", "還有戰後那段話")
	assert_true(level.sera.ask_enabled and level.sera.vial_source == Sera.VIAL_SOURCE, "拿錯的那一瓶還沒射就清場了：那一拍不演，之後可以向她要藥")
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_AFTER")
	assert_false(bool(_game().call("is_in_dialogue")), "不是最後一刀的那一幀就講")
	var frames: int = 0
	while not bool(_game().call("is_in_dialogue")) and frames < 240:
		await tree.physics_frame
		frames += 1
	assert_true(frames >= int(CorruptForest.AFTER_TALK_DELAY * 60.0) - 4, "等一下才開口（%d 幀）" % frames)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_AFTER_001")
	runner.advance()
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_AFTER_003", "席菈問：你真的不會因為我的能力而受傷嗎？")
	assert_eq(runner.visible_choices.size(), 2, "兩個回答")
	assert_true(runner.advance(), "有選項的時候不能直接跳過")
	assert_true(runner.choose(0))
	assert_eq(runner.current_text(), "DLG_CH1_AFTER_A")
	assert_eq(int(s.state.get_flag("sera.affinity", 0)), 10, "回答記進好感度")
	assert_eq(s.state.get_flag("ch1.after_slimes_answer"), "medicine")
	runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")), "講完了")
	assert_eq(s.state.get_flag(CorruptForest.FLAG_AFTER_TALK), true)
	assert_true(s.quests.is_done("ch1_main"))
	for i: int in 3:
		await tree.physics_frame
	assert_true(s.story_finished(), "目前的內容到底了")
	assert_true(hud.is_objective_shown(), "做完之後左上還是有字")
	assert_eq(hud.objective_text_key(), Hud.STORY_END_KEY, "寫的是「目前的內容到這裡」")
	assert_true(hud.hint_text().contains("[Q]") and not hud.hint_text().contains("\n"), "操作提示只剩向席菈要藥的那一行：%s" % hud.hint_text())


## 左上的目標一直在畫面上（不會過幾秒就淡掉），下面一行寫現在用得到的按鍵。
func test_objective_stays_on_screen_with_a_controls_hint() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var hud: Hud = level.get_node("Hud") as Hud
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_SET_OUT")
	assert_eq(s.hint_key(), "Q_CH1_HINT_MOVE")
	assert_true(hud.hint_text().contains("[WASD]"), "移動的提示寫 WASD：%s" % hud.hint_text())
	assert_false(hud.hint_text().contains("{"), "動作名都換成按鍵了：%s" % hud.hint_text())
	s.set_flag(CorruptForest.FLAG_JOINED, true)
	await tree.physics_frame
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_MIASMA")
	s.set_flag(CorruptForest.FLAG_REVERSAL, true)
	await tree.physics_frame
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_SLIMES")
	assert_eq(s.hint_key(), "Q_CH1_HINT_FIGHT")
	assert_false(hud.hint_text().contains("{"), "動作名都換成按鍵了：%s" % hud.hint_text())
	assert_true(hud.is_objective_shown())


func test_cleared_glade_stays_cleared_after_reload() -> void:
	_new_game_joined()
	_session().set_flag(CorruptForest.FLAG_REVERSAL, true)
	_session().set_flag(CorruptForest.FLAG_SLIMES, true)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	assert_eq(level.slimes.size(), 0, "打完之後重進關卡不會再生")
	# 打完、話還沒講就離開：讀回來席菈接著講，選另一個回答
	var frames: int = 0
	while not bool(_game().call("is_in_dialogue")) and frames < 240:
		await tree.physics_frame
		frames += 1
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_true(runner != null and runner.current_text() == "DLG_CH1_AFTER_001", "戰後那段話接著講")
	runner.advance()
	runner.advance()
	assert_true(runner.choose(1))
	assert_eq(runner.current_text(), "DLG_CH1_AFTER_B")
	assert_eq(int(_session().state.get_flag("sera.affinity", 0)), 5)
	runner.advance()
	assert_true(_session().quests.is_done("ch1_main"))
	for i: int in 120:
		await tree.physics_frame
	assert_false(bool(_game().call("is_in_dialogue")), "只講一次")


func test_title_menu_has_four_entries_and_new_game_works() -> void:
	var boot: Control = (load("res://scenes/boot/boot.tscn") as PackedScene).instantiate() as Control
	boot.set("load_levels", false)
	tree.root.add_child(boot)
	await tree.process_frame
	var names: Array[String] = []
	for c: Node in boot.get_node("%Menu").get_children():
		names.append(str(c.name))
	assert_eq(names, ["NewGame", "Continue", "Settings", "Quit"] as Array[String])
	assert_true((boot.get_node("%Continue") as Button).disabled, "沒有存檔：繼續是灰的")
	assert_eq((boot.get_node("%Title") as Label).text, "GAME_TITLE")
	(boot.get_node("%NewGame") as Button).pressed.emit()
	assert_true(_session().in_story(), "按新遊戲開了第一章")
	boot.free()


func test_enemy_brain_cycle_with_slime_numbers() -> void:
	var b: EnemyBrain = EnemyBrain.new().configure("poison_slime", "standard")
	var struck: bool = false
	var seen: Dictionary = {}
	for i: int in 400:
		if b.tick(1.0 / 60.0, 1.0):
			struck = true
		seen[b.state] = true
	assert_true(struck, "在出手距離內會出招")
	for st: EnemyBrain.State in [EnemyBrain.State.TELEGRAPH, EnemyBrain.State.STRIKE, EnemyBrain.State.RECOVER]:
		assert_true(seen.has(st), "經過 %s" % EnemyBrain.State.keys()[st])
	var far: EnemyBrain = EnemyBrain.new().configure("poison_slime", "standard")
	for i: int in 120:
		assert_false(far.tick(1.0 / 60.0, 20.0), "太遠不出招")
	assert_true(far.add_stagger(CombatTuning.num("poison_slime.stagger_max")), "失衡滿了會跪")
	assert_eq(far.state, EnemyBrain.State.STAGGERED)
	far.kill()
	assert_eq(far.state, EnemyBrain.State.DEAD)
