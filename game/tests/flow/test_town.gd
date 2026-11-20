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


## 一棟房子牆上的材質（town_facade）
func _facade(level: TownStreet, house: String) -> ShaderMaterial:
	var walls: MeshInstance3D = (level.scenery.buildings[house] as Node3D).get_node("Walls") as MeshInstance3D
	return (walls.mesh as BoxMesh).material as ShaderMaterial


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
	assert_eq(level.scenery.lamps.size(), 0, "白天壁燈不點")
	assert_eq(float(_facade(level, "HouseN1").get_shader_parameter("dusk")), 0.0, "白天的窗照舊")
	assert_true(level.scenery.pot_steam == null and level.get_node_or_null("Scenery/StallLantern") == null, "白天麵攤沒有蒸氣與燈籠（湯還沒煮開）")
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


func test_street_board_shows_the_two_notices() -> void:
	_new_game_at_town()
	var level: TownStreet = _load_level()
	await _frames(1)
	level.read_board()
	assert_not_null(level.board_note)
	assert_eq(level.board_note.title_key, "NOTICE_TITLE")
	assert_true(bool(_session().state.get_flag(TownStreet.FLAG_NOTICES, false)))
	assert_true((level.get_node("Hud") as Hud).bark_keys().has("BARK_NOEN_NOTICES"))
	# 走開就收起來
	_player().global_position = Vector3(30.0, 0.05, 0.0)
	await _frames(2)
	assert_true(level.board_note == null)


func test_shield_on_the_drying_line_iou_or_take_then_the_reward() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	assert_true(TownScenery.is_walkable(level.shield_use.global_position), "後院走得到盾旁邊")
	assert_not_null(level.shield.get_node_or_null("Strap0"), "綁帶")
	# 先找大叔：請你找
	assert_true(level.talk_uncle())
	assert_eq((_game().get("dialogue") as DialogueRunner).dialogue_id, TownStreet.SHIELD_ASK_DIALOGUE)
	_finish_dialogue(0)
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_SHIELD_ASKED, false)))
	# 摸盾：辭工單、帶走
	assert_true(level.check_shield())
	assert_not_null(level.slip_note, "阿展的辭工單")
	_finish_dialogue(1)
	assert_eq(str(s.state.get_flag(TownStreet.FLAG_SHIELD, "")), "taken")
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_SHIELD_DONE, false)))
	assert_eq(int(s.state.items.get(TownStreet.SHIELD_ITEM, 0)), 1, "盾帶在身上")
	assert_false(level.shield.visible, "繩子上沒有盾了")
	assert_false(level.shield_use.enabled)
	# 回倉庫：謝禮（只給一次）
	var before: int = Gear.new(s.state).coins()
	assert_true(level.talk_uncle())
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.dialogue_id, TownStreet.SHIELD_REPORT_DIALOGUE)
	assert_eq(runner.current_text(), "DLG_CH1_SHIELD_REPORT_TAKEN")
	_finish_dialogue(0)
	assert_eq(Gear.new(s.state).coins(), before + TownStreet.SHIELD_REWARD)
	assert_false(level.uncle_use.enabled, "謝過了")


func test_shield_iou_keeps_it_hanging() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	level.check_shield()
	_finish_dialogue(0)
	assert_eq(str(s.state.get_flag(TownStreet.FLAG_SHIELD, "")), "iou")
	assert_true(level.shield.visible, "補借據：盾留在藥房")
	assert_eq(int(s.state.items.get(TownStreet.SHIELD_ITEM, 0)), 0)


func _go_down(level: TownStreet) -> void:
	level.go_down()
	var guard: int = 0
	while not level.in_cellar and guard < 120:
		guard += 1
		await tree.physics_frame
	assert_true(level.in_cellar, "下到地下室")


func test_cellar_with_the_lamp_lures_them_out_one_by_one() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	assert_true(level.talk_vendor())
	_finish_dialogue(0)
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_CELLAR_ASKED, false)))
	await _go_down(level)
	var player: PlayerController = _player()
	assert_true(TownScenery.is_in_cellar(player.global_position))
	assert_false(player.peaceful, "地下室裡可以出手")
	assert_eq(level.hiding.size(), 3, "三團縮在鐵網後面")
	assert_true(level.lamp_use.enabled)
	assert_true(level.valve_use.enabled)
	for i: int in 3:
		level.lure_one()
		assert_not_null(level.lured, "第 %d 團爬出來" % (i + 1))
		assert_false(level.lamp_use.enabled, "砍掉之前不能再引")
		await _frames(2)
		level.lured.health.apply_damage(9999.0, {"source": player})
		await _frames(2)
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_CELLAR_DONE, false)))
	assert_eq(str(s.state.get_flag(TownStreet.FLAG_CELLAR_WAY, "")), "lamp")
	assert_false(level.barrel_lid.visible)
	# 爬上去、回麵攤領謝禮
	level.go_up()
	var guard: int = 0
	while level.in_cellar and guard < 120:
		guard += 1
		await tree.physics_frame
	assert_false(level.in_cellar)
	assert_true(player.peaceful)
	assert_true(level.talk_vendor())
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_NOODLE_REPORT_LAMP")
	_finish_dialogue(0)
	assert_eq(int(s.state.items.get(TownStreet.NOODLE_TICKET, 0)), 2, "兩張麵票")
	assert_eq(int(s.state.items.get(TownStreet.WARM_PLUG, 0)), 1, "一瓶暖泥塞")
	assert_false(level.vendor_use.enabled, "謝過了")


func test_cellar_valve_first_turn_is_wrong_then_they_roll_into_the_barrel() -> void:
	_new_game_at_town()
	var s: GameSession = _session()
	var level: TownStreet = _load_level()
	await _frames(1)
	await _go_down(level)
	level.turn_valve()
	assert_true((level.get_node("Hud") as Hud).bark_keys().has("BARK_VENDOR_TEA"), "樓上的茶杯冒泡")
	assert_eq(level.hiding.size(), 3, "轉錯：還在")
	assert_false(level.valve_use.enabled, "等一下才能再轉")
	await _frames(int(TownStreet.VALVE_WRONG_SEC * 60.0) + 5)
	assert_true(level.valve_use.enabled)
	level.turn_valve()
	await _frames(int(TownStreet.ROLL_SEC * 60.0) + 5)
	assert_eq(level.hiding.size(), 0, "全部滾進酒桶")
	assert_true(level.barrel_lid.visible, "扣上桶蓋")
	assert_eq(str(s.state.get_flag(TownStreet.FLAG_CELLAR_WAY, "")), "barrel")
	assert_false(level.lamp_use.enabled)
	level.talk_vendor()
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_NOODLE_REPORT_BARREL", "養在保溫鍋底")
	_finish_dialogue(0)


func test_return_to_the_guild_remembers_whose_name_the_money_is_under() -> void:
	var db: DialogueDB = DialogueDB.load_default()
	var led: Dictionary = db.node("ch1_guild_return", "led")
	assert_false(led.is_empty(), "回公會那段話有記帳的那一句")
	var st := GameState.new()
	st.set_flag(TownStreet.FLAG_LEDGER, "together")
	assert_eq(DialogueRunner.text_for(led, st), "DLG_CH1_RETURN_LEDGER_TOGETHER", "兩人一起領")
	st.set_flag(TownStreet.FLAG_LEDGER, "receipt")
	assert_eq(DialogueRunner.text_for(led, st), "DLG_CH1_RETURN_LEDGER_RECEIPT", "席菈的第一張收據")
	assert_eq(str(db.node("ch1_guild_return", "a").get("next", "")), "led")
	assert_eq(str(db.node("ch1_guild_return", "b").get("next", "")), "led")


## 回程（第一章 ⑥，增補稿「祭壇與回程」）：傍晚從東門回來、扛著核心、席菈跟著、阿展在藥房 → 走到櫃檯交蕈：五只杯蓋亮起來、
## 盾與藥錢照之前選的各一句 → 想的話去麵攤兌麵票 → 走回公會大門換到大廳的結尾。街上其他的事都收起來了
func test_return_trip_delivers_the_mushrooms_then_walks_back_to_the_guild() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	RuinedAltar.skip_to_altar(s)
	for flag: String in [RuinedAltar.FLAG_TALKED, RuinedAltar.FLAG_GOLEM_DOWN, RuinedAltar.FLAG_DONE]:
		s.set_flag(flag, true)
	assert_eq(s.quests.stage_of("ch1_main"), TownStreet.STAGE_RETURN)
	s.set_flag(TownStreet.FLAG_SHIELD, "taken")
	s.state.items[TownStreet.SHIELD_ITEM] = 1
	s.set_flag(TownStreet.FLAG_LEDGER, "receipt")
	s.set_flag(TownStreet.FLAG_CELLAR_WAY, "lamp")
	s.state.items[TownStreet.NOODLE_TICKET] = 2
	var level: TownStreet = _load_level()
	await _frames(2)
	var hud: Hud = level.get_node("Hud") as Hud
	var player: PlayerController = _player()
	assert_true(level.is_return() and level.scenery.dusk, "傍晚的街")
	assert_true(level.scenery.lamps.size() >= 8, "傍晚的壁燈點著")
	assert_true(level.scenery.lamps[0].light != null and level.scenery.lamps[0].light.light_energy > 1.0, "照得到地")
	assert_eq(float(_facade(level, "HouseN1").get_shader_parameter("dusk")), 1.0, "窗亮起來")
	assert_false(level.basket.visible, "還沒開口：籃子不在櫃檯上")
	assert_false(level.shield.visible, "帶回來的盾還在諾恩身上")
	assert_not_null(level.scenery.pot_steam, "麵攤的鍋煮開了")
	assert_not_null(level.get_node_or_null("Scenery/StallLantern/LanternFlame"), "麵攤掛出紅燈籠")
	assert_true(level.pot_blob == null, "全砍了的：鍋底下沒有那一團")
	assert_true(player.global_position.distance_to(TownStreet.RETURN_ENTRANCE) < 1.0, "從東門裡面開始")
	assert_true(level.core != null and level.core.is_carried_by(player.get_node("Body") as Node3D), "扛著魔像核心")
	assert_true(level.sera != null and level.sera.joined and level.sera.target == player, "席菈跟在後面")
	assert_not_null(level.azhan, "阿展在藥房")
	assert_eq(level.cup_lids.size(), TownStreet.CUP_COUNT, "櫃檯上五只保溫杯")
	assert_eq(level.lids_lit(), 0, "杯蓋還沒亮")
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_RETURN_TOWN")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_TOWN_RETURN_LINE1", "CH1_TOWN_RETURN_LINE2"]))
	assert_false(level.merchant_use.enabled or level.board_use.enabled or level.cellar_door_use.enabled or level.uncle_use.enabled, "街上其他的事收起來了")
	assert_true(level.vendor_use.enabled, "帶著麵票：麵攤可以兌")
	# 東門不能再出去；還沒交蕈走到公會門口不會進去
	player.global_position = Vector3(TownScenery.LEAVE_X + 1.0, 0.05, 0.0)
	await _frames(2)
	assert_true(player.global_position.x <= TownStreet.GATE_STOP_X + 0.01, "東門出不去")
	player.global_position = TownScenery.GUILD_DOOR + Vector3(0, 0.05, 1.5)
	await _frames(3)
	assert_true(level.card == null and s.quests.stage_of("ch1_main") == TownStreet.STAGE_RETURN, "蕈還沒交")
	# 交蕈
	player.global_position = TownScenery.PHARMACY_COUNTER + Vector3(0, 0.05, -2.0)
	await _until_dialogue(20)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.dialogue_id, TownStreet.RETURN_DIALOGUE)
	assert_true(level.talk_camera.cast.has(TownStreet.AZHAN_KEY), "鏡頭認得阿展")
	assert_eq(level.talk_camera.cast.get(TownStreet.CUPS_KEY), level.cups_focus, "鏡頭認得那一排杯子")
	assert_eq(level.cups_focus.get_meta(TalkCamera.SPOT_META), TownStreet.CUPS_CAMERA, "看杯子的鏡頭站在指定的地方")
	assert_true(level.basket.visible and level.basket_mushrooms.visible, "開口的那一句：一籃毒蕈擱上櫃檯")
	runner.advance()
	assert_eq(runner.current_text(), TownStreet.RETURN_LIDS_LINE)
	assert_eq(str(runner.current().get("look", "")), TownStreet.CUPS_KEY, "這一句鏡頭看杯子")
	await _frames(int(TownStreet.CUP_LIGHT_EVERY * 60.0 * 5.0) + 30)
	assert_eq(level.lids_lit(), TownStreet.CUP_COUNT, "五只杯蓋一個接一個亮起來")
	assert_false(level.basket_mushrooms.visible, "蕈都放進杯子了：只剩空籃")
	assert_true(level.basket.visible)
	assert_true(level.cup_light.light_energy > 0.3, "櫃檯上多一點青綠的光")
	runner.advance()
	assert_eq(str(runner.current()["speaker"]), TownStreet.AZHAN_KEY, "阿展改辭工單")
	var slip: PaperNote = level.slip_note
	assert_not_null(slip, "辭工單拿到眼前")
	assert_eq(slip.title_key, "AZHAN_SLIP_TITLE")
	assert_true(slip.struck.is_empty(), "還沒劃")
	await _frames(int(TownStreet.SLIP_WRITE_AFTER * 60.0) + 12)
	assert_true(slip.struck.has(TownStreet.SLIP_STRIKE_INDEX), "「獨自採集」劃掉")
	assert_eq(slip.line_keys[TownStreet.SLIP_STRIKE_INDEX], "AZHAN_SLIP_ALONE")
	assert_eq(slip.line_keys[slip.line_keys.size() - 1], TownStreet.SLIP_NEW_LINE, "補寫「帶學徒認路」")
	assert_eq(TownStreet.RETURN_SLIP_LINES.size(), 4, "補寫不動到原本那幾行的清單")
	runner.advance()
	assert_not_null(level.slip_note, "小學徒那一句紙還在")
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_TRET_005_TAKEN", "帶回來的盾：他自己簽名還")
	assert_true(level.shield.visible and level.shield.position.distance_to(TownStreet.SHIELD_ON_COUNTER) < 0.01, "盾推上櫃檯")
	assert_true(level.get_node_or_null("CupWarm") == null, "帶回來的：上面沒有溫著的杯")
	assert_true(level.slip_note == null, "紙收起來了")
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_TRET_006_RECEIPT", "給席菈的收據")
	assert_not_null(level.receipt_note, "收據拿到眼前")
	assert_eq(level.receipt_note.stamp_key, "RECEIPT_STAMP")
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_TRET_007_RECEIPT")
	assert_true(level.receipt_note == null, "她收進手套裡")
	runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")))
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_DELIVERED, false)))
	assert_eq(int(s.state.items.get(TownStreet.SHIELD_ITEM, 0)), 0, "盾還了")
	assert_eq(hud.banner_text(), "CH1_TOWN_DELIVERED")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:GuildDoor")
	# 麵攤：兩張麵票換熱湯；當初全砍了的，席菈多調一瓶
	player.health.hp = 10.0
	assert_true(level.talk_vendor())
	runner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_NBACK_001", "鍋底放回普通的柴")
	_finish_dialogue(0)
	assert_true(bool(s.state.get_flag(TownStreet.FLAG_NOODLE_BACK, false)))
	assert_eq(int(s.state.items.get(TownStreet.NOODLE_TICKET, 0)), 0, "麵票用掉了")
	assert_eq(int(s.state.items.get("sera_poison_vial", 0)), 1, "席菈多調一瓶")
	assert_true(player.health.is_full(), "喝了熱湯")
	assert_eq(level.soup_bowls.size(), 2, "攤車上兩碗熱湯")
	assert_false(level.vendor_use.enabled)
	# 走回公會
	player.global_position = TownScenery.GUILD_DOOR + Vector3(0, 0.05, 1.5)
	await _frames(3)
	assert_eq(s.quests.stage_of("ch1_main"), "report")
	assert_not_null(level.card, "進公會的那張卡")
	level.card.finish()
	assert_eq(str(_game().get("last_level_request")), "guild_hall")
	# 讀檔（交蕈之後存的）：杯蓋是亮的
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_true(bool(again.state.get_flag(TownStreet.FLAG_DELIVERED, false)))


## 回程讀檔（蕈交了、麵票兌了、當初把黴泥趕進酒桶）：空籃、亮著的杯蓋、兩碗湯、鍋底下那一團都在
func test_return_trip_reloaded_keeps_what_was_done_on_the_counter_and_the_stall() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	RuinedAltar.skip_to_altar(s)
	for flag: String in [RuinedAltar.FLAG_TALKED, RuinedAltar.FLAG_GOLEM_DOWN, RuinedAltar.FLAG_DONE]:
		s.set_flag(flag, true)
	s.set_flag(TownStreet.FLAG_CELLAR_WAY, "barrel")
	s.set_flag(TownStreet.FLAG_SHIELD, "iou")
	s.set_flag(TownStreet.FLAG_DELIVERED, true)
	s.set_flag(TownStreet.FLAG_NOODLE_BACK, true)
	var level: TownStreet = _load_level()
	await _frames(2)
	assert_true(level.is_return())
	assert_eq(level.lids_lit(), TownStreet.CUP_COUNT, "杯蓋是亮的")
	assert_true(level.cup_light.light_energy > 0.3)
	assert_true(level.basket.visible and not level.basket_mushrooms.visible, "空籃留在櫃檯上")
	assert_true(level.shield.visible and level.shield.position.distance_to(TownStreet.SHIELD_ON_COUNTER) < 0.01, "補過借據的盾在櫃檯上當熱敷盤")
	assert_not_null(level.get_node_or_null("CupWarm"), "盾面上溫著一只杯")
	assert_eq(level.soup_bowls.size(), 2, "兩碗湯已經在攤車上")
	assert_not_null(level.pot_blob, "鍋底下縮著那一團")
	assert_true(level.pot_blob.position.distance_to(TownScenery.POT_POS) < 1.2)
	assert_eq(ParticleLook.untextured(level).size(), 0, "蒸氣不是方塊")


## 回程的另一種：盾留在藥房（補借據）、藥錢一起領、黴泥趕進桶裡——各換一句
func test_return_trip_lines_follow_the_other_choices() -> void:
	var db: DialogueDB = DialogueDB.load_default()
	var st := GameState.new()
	st.set_flag(TownStreet.FLAG_SHIELD, "iou")
	st.set_flag(TownStreet.FLAG_LEDGER, "together")
	st.set_flag(TownStreet.FLAG_CELLAR_WAY, "barrel")
	var r := DialogueRunner.new(db, st)
	r.start(TownStreet.RETURN_DIALOGUE)
	var seen: PackedStringArray = []
	while r.is_running() and seen.size() < 20:
		seen.append(r.current_text())
		r.advance()
	assert_true(seen.has("DLG_CH1_TRET_005_IOU") and seen.has("DLG_CH1_TRET_006") and seen.has("DLG_CH1_TRET_007"), "借出去的盾當熱敷盤、藥錢一起領：%s" % str(seen))
	r = DialogueRunner.new(db, st)
	r.start(TownStreet.NOODLE_BACK_DIALOGUE)
	assert_eq(r.current_text(), "DLG_CH1_NBACK_001_BARREL", "趕進桶裡的那一團養在鍋底")
	r.advance()
	assert_eq(r.current_text(), "DLG_CH1_NBACK_002_BARREL")
