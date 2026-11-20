extends TestCase
## 公會門外的賒帳街（第一章 ⑤，增補劇本「自由時段 A」）：關卡蓋得起來（房子、藥房、東門、人）→ 走得到的範圍 →
## 籃子還沒送就走到東門會被叫住 → 藥房那段話（兩個回答：一起回來收／給做杯子的人開收據）→ 席菈從小路先走 →
## 出東門換到森林 → 讀檔。從新遊戲一路走過這條街的整段測試在 test_chapter1.gd（test_walkthrough_…）。

const LEVEL: String = "res://scenes/levels/town_street.tscn"

var _dir: String = ""
var _old_session: GameSession
var _level: TownStreet


func _game() -> Node:
	return tree.root.get_node("Game")


func before_each() -> void:
	_dir = "user://test_town_%d" % Time.get_ticks_usec()
	_old_session = _game().get("session") as GameSession
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))
	_game().set("change_scenes", false)
	_game().set("last_level_request", "")


func after_each() -> void:
	if _level != null and is_instance_valid(_level):
		_level.free()
	_game().set("change_scenes", true)
	_game().set("session", _old_session)
	_game().set("dialogue", null)
	_game().call("cancel_hit_stop")
	if DirAccess.dir_exists_absolute(_dir):
		for f: String in DirAccess.get_files_at(_dir):
			DirAccess.remove_absolute(_dir.path_join(f))
		DirAccess.remove_absolute(_dir)


func _session() -> GameSession:
	return _game().get("session") as GameSession


func _new_game_at_town() -> void:
	var s: GameSession = _session()
	s.new_game()
	GuildHall.skip_opening(s)


func _load_level() -> TownStreet:
	_level = (load(LEVEL) as PackedScene).instantiate() as TownStreet
	tree.root.add_child(_level)
	return _level


func _player() -> PlayerController:
	return _level.get_node("Player") as PlayerController


func _frames(n: int) -> void:
	for i: int in n:
		await tree.physics_frame


func _until_dialogue(max_frames: int) -> void:
	var frames: int = 0
	while not bool(_game().call("is_in_dialogue")) and frames < max_frames:
		await tree.physics_frame
		frames += 1
	assert_true(bool(_game().call("is_in_dialogue")), "等了 %d 幀對話沒有開始" % frames)


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


func test_leaving_the_guild_lands_on_the_street_with_the_basket_to_deliver() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	assert_eq(s.quests.stage_of("ch1_main"), "deliver_basket")
	assert_eq(s.state.checkpoint, "ch1_town")
	assert_eq(str(_game().call("level_for_checkpoint", "ch1_town")), "town_street")
	assert_eq(str(_game().call("level_for_checkpoint", "ch1_town_gate")), "town_street")
	var level: TownStreet = _load_level()
	await _frames(2)
	assert_true(_player().global_position.distance_to(TownStreet.ENTRANCE) < 0.3, "站在公會大門外")
	assert_eq(level.get_node("Hud").call("center_lines"), PackedStringArray(["CH1_TOWN_LINE1", "CH1_TOWN_LINE2"]))
	assert_not_null(level.get_node_or_null("Pharmacy"), "目標指引指藥房")
	assert_not_null(level.get_node_or_null("EastGate"))


func test_street_is_built_with_houses_shops_and_the_east_gate() -> void:
	_new_game_at_town()
	var level: TownStreet = _load_level()
	await _frames(1)
	for house: String in ["Guild", "Pharmacy", "NoodleHouse", "Warehouse", "MerchantHouse", "WestEnd"]:
		assert_true(level.scenery.buildings.has(house), "有 %s" % house)
	var pharmacy: Node3D = level.scenery.buildings["Pharmacy"] as Node3D
	assert_true(pharmacy.position.z > TownScenery.STREET_HALF, "藥房在南側")
	var roof: MeshInstance3D = pharmacy.get_node("Roof") as MeshInstance3D
	assert_true(roof.mesh is PrismMesh, "三角柱的屋頂")
	assert_true((roof.mesh as PrismMesh).material is ShaderMaterial)
	var scenery_root: Node = level.get_node("Scenery")
	assert_not_null(scenery_root.get_node_or_null("EastGateArch"))
	assert_not_null(scenery_root.get_node_or_null("PharmacyAwning"))
	assert_not_null(level.get_node_or_null("Sun"), "太陽（有影子）")
	assert_true((level.get_node("Sun") as DirectionalLight3D).shadow_enabled)
	var we: WorldEnvironment = level.get_node("WorldEnvironment") as WorldEnvironment
	assert_eq(we.environment.background_mode, Environment.BG_SKY, "白天的天空")
	# 人：藥房的店主與小學徒、門邊凳子上的席菈
	assert_not_null(level.pharmacist)
	assert_not_null(level.apprentice)
	assert_not_null(level.sera)
	assert_eq(level.sera.puppet().pose, "sit_hunch", "蹲坐著修面具的扣帶")
	assert_false(level.sera.joined)


func test_walkable_area_is_the_street_the_alley_and_the_yard() -> void:
	assert_true(TownScenery.is_walkable(Vector3(0, 0, 0)), "街上")
	assert_true(TownScenery.is_walkable(Vector3(12.0, 0, 8.0)), "藥房旁邊的小巷")
	assert_true(TownScenery.is_walkable(Vector3(7.0, 0, 14.0)), "藥房後院")
	assert_false(TownScenery.is_walkable(Vector3(5.5, 0, 8.0)), "藥房裡面")
	assert_false(TownScenery.is_walkable(Vector3(20.0, 0, -7.0)), "北邊的房子裡")
	var back: Vector3 = TownScenery.keep_inside(Vector3(20.0, 0, -7.0))
	assert_true(TownScenery.is_walkable(back))
	assert_true(absf(back.x - 20.0) < 0.01, "只拉回街上、不往旁邊移")
	assert_true(TownScenery.is_walkable(TownScenery.keep_inside(Vector3(-30.0, 0, 0))), "西頭")


func test_walking_to_the_gate_before_the_basket_gets_pulled_back() -> void:
	_new_game_at_town()
	var level: TownStreet = _load_level()
	await _frames(1)
	_player().global_position = Vector3(TownScenery.LEAVE_X + 1.0, 0.05, 0.0)
	await _frames(2)
	assert_true(_player().global_position.x <= TownStreet.GATE_STOP_X + 0.01, "被叫住")
	assert_true((level.get_node("Hud") as Hud).bark_keys().has("BARK_NOEN_BASKET_FIRST"))
	assert_eq(_session().quests.stage_of("ch1_main"), "deliver_basket")
	assert_true(level.card == null)


func test_pharmacy_talk_records_the_ledger_and_opens_the_gate() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	_player().global_position = TownScenery.PHARMACY_COUNTER + Vector3(0, 0.05, -2.0)
	await _until_dialogue(20)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.dialogue_id, TownStreet.PHARMACY_DIALOGUE)
	assert_eq(runner.current_text(), "DLG_CH1_TOWN_PH_001", "小學徒先量鼻子")
	# 講話的四個人都有登記到鏡頭
	var cam: TalkCamera = level.talk_camera
	for key: String in ["SPK_NOEN", TownStreet.PHARMACIST_KEY, TownStreet.APPRENTICE_KEY, Sera.NAME_KEY]:
		assert_true(cam.cast.has(key), "鏡頭認得 %s" % key)
	var guard: int = 0
	while runner.visible_choices.is_empty() and guard < 30:
		guard += 1
		runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_TOWN_PH_013", "藥錢記在誰名下")
	assert_eq(runner.visible_choices.size(), 2)
	runner.choose(1)
	_finish_dialogue(0)
	assert_eq(str(s.state.get_flag(TownStreet.FLAG_LEDGER, "")), "receipt", "給做杯子的人開收據")
	assert_eq(int(s.state.get_flag("sera.affinity", 0)), 10)
	assert_eq(s.quests.stage_of("ch1_main"), "east_gate")
	assert_eq(s.state.checkpoint, "ch1_town_gate")
	# 不會再講一次
	await _frames(3)
	assert_false(bool(_game().call("is_in_dialogue")))
	# 往街尾走：席菈先從小路走了
	_player().global_position = Vector3(TownStreet.SERA_GOES_AHEAD_X + 2.0, 0.05, 0.0)
	await _frames(2)
	assert_true(level.sera == null, "席菈先去林口")
	# 出東門：一張卡，播完換到森林
	_player().global_position = Vector3(TownScenery.LEAVE_X + 0.5, 0.05, 0.0)
	await _frames(2)
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera")
	assert_eq(s.state.checkpoint, "ch1_forest_gate")
	assert_not_null(level.card)
	assert_eq(level.card.title_text(), tr("CARD_FOREST_TITLE"))
	level.card.finish()
	assert_eq(str(_game().get("last_level_request")), "corrupt_forest")


func test_continue_after_the_basket_starts_on_the_street_without_sera() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	s.set_flag(TownStreet.FLAG_BASKET, true)
	assert_eq(s.state.checkpoint, "ch1_town_gate")
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(str(_game().call("level_for_checkpoint", again.state.checkpoint)), "town_street")
	_game().set("session", again)
	var level: TownStreet = _load_level()
	await _frames(3)
	assert_false(bool(_game().call("is_in_dialogue")), "送過了不再講")
	assert_eq(again.quests.stage_of("ch1_main"), "east_gate")


func test_skipping_straight_to_the_forest_counts_the_street_as_done() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	TownStreet.skip_town(s)
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera")


func test_trying_on_the_ring_opens_the_gear_panel_then_buying_keeps_it() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	var start: int = Gear.new(s.state).coins()
	assert_eq(int(s.state.get_flag(Gear.COINS_FLAG, -1)), start, "開局的零錢寫進旗標")
	assert_not_null(level.merchant, "街尾的商人")
	assert_true(level.merchant_use.enabled)
	assert_true(level.talk_merchant())
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.dialogue_id, TownStreet.RING_DIALOGUE)
	_finish_dialogue(0)
	# 試戴：戴上、身上馬上有刺痛、裝備面板打開
	var g := Gear.new(s.state)
	assert_eq(g.accessory(), TownStreet.RING_ID)
	assert_true(g.is_trial())
	var player: PlayerController = _player()
	assert_true(player.status_effects.has("ache"), "戴上的那一刻就刺痛")
	var panel: GearPanel = (level.get_node("Hud") as Hud).gear_panel
	assert_true(panel.is_open(), "裝備面板打開")
	assert_eq(panel.text_of("AccessoryName"), tr("GEAR_PAIN_RING") + "　" + tr("GEAR_TRIAL"))
	await _frames(30)
	assert_true(panel.text_of("AccessoryActual") != tr("GEAR_ACTUAL_WAIT"), "寫著實際每秒回多少")
	# 關掉面板：商人問買不買
	panel.close()
	assert_true(bool(_game().call("is_in_dialogue")))
	runner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.dialogue_id, TownStreet.RING_BUY_DIALOGUE)
	var guard: int = 0
	while runner.visible_choices.is_empty() and guard < 10:
		guard += 1
		runner.advance()
	assert_eq(runner.visible_choices.size(), 2, "錢夠：買／還給他")
	_finish_dialogue(0)
	assert_true(g.owns(TownStreet.RING_ID), "買下來了")
	assert_false(g.is_trial())
	assert_eq(g.accessory(), TownStreet.RING_ID, "繼續戴著")
	assert_eq(g.coins(), start - 5)
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_RING_TRIED, false)), "右上角的清單：試戴過")
	assert_false(level.ring_prop != null and level.ring_prop.visible, "攤子上的戒指不見了")


func test_giving_the_ring_back_takes_it_off() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	level.talk_merchant()
	_finish_dialogue(0)
	(level.get_node("Hud") as Hud).gear_panel.close()
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	var guard: int = 0
	while runner.visible_choices.is_empty() and guard < 10:
		guard += 1
		runner.advance()
	_finish_dialogue(1)
	var g := Gear.new(s.state)
	assert_eq(g.accessory(), "", "還回去了")
	assert_false(g.owns(TownStreet.RING_ID))
	assert_eq(g.coins(), int(g.data["start_coins"]), "沒花錢")


func test_sera_shows_her_potion_notes_and_gives_three_vials() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	assert_false(level.sera_use.enabled, "籃子還沒送：還不能跟她聊")
	s.set_flag(TownStreet.FLAG_BASKET, true)
	level.call("_refresh_interactables")
	assert_true(level.sera_use.enabled, "籃子送到了：門邊的她可以說話")
	assert_true(level.talk_sera())
	assert_not_null(level.list_note, "她的調藥記錄攤在畫面右邊")
	assert_eq(level.list_note.title_key, "SERA_LIST_TITLE")
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	var guard: int = 0
	while runner.visible_choices.is_empty() and guard < 10:
		guard += 1
		runner.advance()
	assert_eq(runner.visible_choices.size(), 4, "兩瓶、抄給我、走吧")
	var before: int = int(s.state.get_flag("sera.affinity", 0))
	runner.choose(2)
	while runner.is_running() and guard < 30:
		guard += 1
		if runner.current_text() == TownStreet.SERA_LIST_GIVE_LINE:
			assert_eq(level.list_note.stamp_key, "SERA_LIST_STAMP", "紙上蓋「抄好了」")
		runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")))
	assert_eq(int(s.state.items.get("sera_poison_vial", 0)), 3, "三瓶免費的毒藥")
	assert_eq(int(s.state.get_flag("sera.affinity", 0)), before + 10)
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_SERA_LIST, false)))
	assert_true(level.list_note == null, "紙收起來了")
	# 再聊一次：不會再給
	level.talk_sera()
	runner = _game().get("dialogue") as DialogueRunner
	guard = 0
	while runner.visible_choices.is_empty() and guard < 10:
		guard += 1
		runner.advance()
	assert_eq(runner.visible_choices.size(), 3, "抄過了：沒有那個選項")
	_finish_dialogue(2)
	assert_eq(int(s.state.items.get("sera_poison_vial", 0)), 3)
