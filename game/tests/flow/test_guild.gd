extends TestCase
## 公會大廳（第一章的開場與結尾，劇本節點 1 與節點 3 的第 5 拍）：關卡蓋得起來 → 走到櫃檯登錄 → 把手放上水晶：警報、嘲笑 →
## 雷歐走過來羞辱兩人、帶隊離開 → 莉莉絲的綠色委託單 → 席菈走過來問能不能一起去 → 她先走、諾恩走出大門換到森林 → 讀檔。
## 結尾：傍晚回到公會，雷歐小隊先逃回來了、諾恩扛著核心 → 櫃檯前那段話 → 二樓的巡察官 →「第一章　完」→ 回標題。
## 從新遊戲一路走到第一章完的整段測試在 test_chapter1.gd（test_walkthrough_…）。

const LEVEL: String = "res://scenes/levels/guild_hall.tscn"

var _dir: String = ""
var _old_session: GameSession
var _level: GuildHall


func _game() -> Node:
	return tree.root.get_node("Game")


func before_each() -> void:
	_dir = "user://test_guild_%d" % Time.get_ticks_usec()
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


func _load_level() -> GuildHall:
	_level = (load(LEVEL) as PackedScene).instantiate() as GuildHall
	tree.root.add_child(_level)
	return _level


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


func _press_interact() -> void:
	Input.action_press(Interactable.ACTION)
	await tree.physics_frame
	Input.action_release(Interactable.ACTION)
	await tree.physics_frame


func test_hall_builds_with_the_counter_the_crystal_and_everyone_in_place() -> void:
	_game().call("new_game", false)
	var level: GuildHall = _load_level()
	await tree.physics_frame
	var s: GameSession = _session()
	assert_eq(s.quests.stage_of("ch1_main"), "register")
	assert_false(level.is_epilogue(), "開場是早上")
	var player: PlayerController = level.get_node("Player") as PlayerController
	assert_true(player.global_position.distance_to(GuildHall.ENTRANCE) < 0.5, "諾恩從大門走進來")
	assert_true(level.scenery.door_open > 0.9, "剛走進來，門還開著")
	assert_eq(level.scenery.door_hinges.size(), 2, "兩片門板")
	var hall: Node3D = level.get_node("Hall") as Node3D
	for part: String in ["Floor", "WallNorth", "WallSouth", "WallEast", "WallWest", "Ceiling", "Door", "Loft", "Counter", "CrystalLook", "Carpet"]:
		assert_not_null(hall.get_node_or_null(part), "大廳有 %s" % part)
	assert_eq(level.scenery.windows.size(), 6, "東西兩面牆各三扇窗")
	assert_eq(hall.find_children("*", "SpotLight3D", true, false).size(), 3, "受光的那一側每扇窗一道光")
	# 牆沒有鏡頭會撞到的碰撞（第 1 層只有地板）：鏡頭退到牆外的時候不會被推到諾恩背上
	for body: Node in hall.find_children("*", "StaticBody3D", true, false):
		var b := body as StaticBody3D
		if b.name != "Floor":
			assert_eq(b.collision_layer, GuildScenery.PEOPLE_LAYER, "%s 只擋人" % b.name)
	assert_true((player.collision_mask & GuildScenery.PEOPLE_LAYER) != 0, "諾恩會被牆與桌子擋住")
	assert_eq(level.footstep_surface(Vector3.ZERO), "wood")
	# 大廳裡不能動手：按出手鍵諾恩不會揮劍
	assert_true(player.peaceful)
	Input.action_press("attack")
	await _frames(3)
	Input.action_release("attack")
	assert_ne(player.puppet().action, "attack", "在公會裡不揮劍")
	assert_true(player.is_sheathed(), "劍收在背上")
	assert_true(level.sera.holstered and level.sera.crossbow().get_parent() != level.sera.puppet().hand("R"), "席菈的手弩收在腰上")
	# 坐在桌邊的客人：有模型的才擺（Tripo 還沒產的不拿別人的模型充數）
	var seated: int = 0
	var mug_probe: Node3D = PropModels.instance("quaternius/Mug")
	var has_mug: bool = mug_probe != null
	if mug_probe != null:
		mug_probe.free()
	for spec: Array in GuildHall.PATRONS:
		var name: String = str(spec[0])
		if GuildHall._first_with_model(spec[1] as Array) == "":
			assert_false(level.patrons.has(name), "%s 沒有模型就不擺" % name)
			continue
		seated += 1
		var who: Npc = level.patrons[name] as Npc
		assert_eq(who.pose, str(spec[4]))
		assert_eq(who.puppet.pose, str(spec[4]), "%s 坐著" % name)
		if who.pose == "sit_drink" and has_mug:
			assert_not_null(who.get_node_or_null("Held"), "%s 手上拿著杯子" % name)
	assert_eq(level.patrons.size(), seated)
	# 走不出牆、進不去櫃檯裡面
	assert_eq(GuildScenery.keep_inside(Vector3(0, 0, 3)), Vector3(0, 0, 3))
	assert_true(GuildScenery.keep_inside(Vector3(30, 0, 0)).x < GuildScenery.HALF_W)
	assert_true(GuildScenery.keep_inside(Vector3(0, 0, -10)).z > GuildScenery.STAFF_LINE_Z)
	# 人：莉莉絲在櫃檯後面、雷歐小隊在佈告欄前面、兩個冒險者、席菈縮在角落；巡察官早上不在
	assert_true(level.lilith.global_position.z < GuildScenery.COUNTER_POS.z, "莉莉絲在櫃檯後面")
	assert_eq(level.party.size(), 3, "雷歐小隊三個人")
	assert_eq(level.crowd.size(), 2)
	assert_true(level.inspector == null, "巡察官只在結尾出現")
	assert_not_null(level.sera)
	assert_false(level.sera.joined, "席菈還沒結伴")
	assert_true(level.sera.global_position.distance_to(GuildHall.SERA_CORNER) < 0.3, "她縮在角落")
	assert_eq(level.sera.puppet().pose, "sit_hunch", "縮成一團坐在凳子上")
	assert_true(level.sera.global_position.distance_to(player.global_position) > 12.0)
	for marker: String in ["Lilith", "Crystal", "Sera", "GuildDoor"]:
		assert_not_null(level.get_node_or_null(marker), "目標指引找得到 %s" % marker)
	assert_false(level.crystal_use.enabled, "還沒登錄，水晶不能摸")
	assert_false(level.lilith_use.enabled)
	var hud: Hud = level.get_node("Hud") as Hud
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_REGISTER")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_GUILD_LINE1", "CH1_GUILD_LINE2"]), "一進來先說這是哪裡")
	assert_false(hud.guide.shown, "中間的字還在，指引的菱形先不畫（不疊在字上）")
	assert_false(level.scenery.slip.visible, "綠色委託單還沒拿出來")
	assert_true(level.get_node_or_null("HallMurmur") != null or Sfx.stream(GuildHall.MURMUR_SFX) == null, "大廳的人聲")


func test_registering_then_the_crystal_alarms_and_leo_humiliates_them_both() -> void:
	_game().call("new_game", false)
	var level: GuildHall = _load_level()
	await tree.physics_frame
	var s: GameSession = _session()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	await _frames(20)
	assert_false(bool(_game().call("is_in_dialogue")), "還沒走到櫃檯不會開口")
	# 走到櫃檯：莉莉絲幫他登錄
	player.global_position = Vector3(0.4, 0.05, GuildHall.REGISTER_Z - 0.6)
	await _until_dialogue(10)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(str(runner.current().get("speaker", "")), "SPK_LILITH")
	await _frames(3)
	assert_eq(level.talk_camera.speaker(), level.lilith as Node3D, "鏡頭拍莉莉絲")
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "aptitude")
	await tree.physics_frame
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_CRYSTAL")
	assert_true(level.crystal_use.enabled, "可以摸水晶了")
	assert_false(level.is_alarm_ringing())
	# 把手放上去：警報、畫面中間寫「全屬性：無」
	player.global_position = Vector3(GuildScenery.CRYSTAL_POS.x, 0.05, GuildScenery.STAFF_LINE_Z + 0.6)
	await tree.physics_frame
	assert_false(level.crystal_use.interact_hint().is_empty(), "走近有提示")
	await _press_interact()
	assert_true(level.is_alarm_ringing(), "按下去警報就響")
	assert_eq(player.puppet().action, "reach", "諾恩伸手摸水晶")
	assert_true(hud.objective_held, "左上的「把手放到水晶上」先收起來")
	assert_eq(s.state.get_flag(GuildHall.FLAG_CRYSTAL), true)
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_CRYSTAL_LINE1", "CH1_CRYSTAL_LINE2"]))
	assert_false(level.crystal_use.enabled, "只測一次")
	await _frames(2)
	assert_true(level.scenery.crystal_light.light_color.r > level.scenery.crystal_light.light_color.b, "水晶變紅")
	assert_eq(s.quests.stage_of("ch1_main"), "aptitude", "雷歐還沒講話")
	# 大廳一陣嘲笑，雷歐走過來
	var leo: Npc = level.party["Leo"] as Npc
	var leo_start: Vector3 = leo.global_position
	await _frames(int(GuildHall.ALARM_LEO_WALKS * 60.0) + 10)
	assert_true(hud.bark_keys().has("BARK_ADV_LAUGH_A") or hud.bark_keys().has("BARK_ADV_LAUGH_B"), "冒險者笑出來")
	var laugh: AudioStream = Sfx.stream(GuildHall.LAUGH_SFX)
	var laughing: int = 0
	for c: Node in level.get_children():
		laughing += 1 if c is AudioStreamPlayer3D and (c as AudioStreamPlayer3D).stream == laugh else 0
	assert_true(laugh == null or laughing >= 1, "聽得到笑聲")
	assert_true(leo.is_walking(), "雷歐走過來")
	for key: String in ["AdventurerA", "AdventurerB"]:
		assert_eq((level.crowd[key] as Npc).pose, "laugh", "%s 在笑" % key)
	for key: String in ["LeoMage", "LeoTank"]:
		assert_eq((level.party[key] as Npc).pose, "laugh", "%s 也在笑" % key)
	await _until_dialogue(int(GuildHall.ALARM_TIMEOUT * 60.0))
	assert_eq((level.crowd["AdventurerA"] as Npc).pose, "", "雷歐開口，大家安靜下來")
	assert_true(leo.global_position.distance_to(leo_start) > 3.0, "他離開佈告欄了")
	assert_true(leo.global_position.distance_to(player.global_position) < 3.5, "走到諾恩旁邊（%.1f m）" % leo.global_position.distance_to(player.global_position))
	runner = _game().get("dialogue") as DialogueRunner
	assert_eq(str(runner.current().get("speaker", "")), "SPK_LEO")
	runner.advance()
	runner.advance()
	assert_eq(str(runner.current().get("speaker", "")), Sera.NAME_KEY, "角落的席菈道歉")
	await _frames(3)
	assert_eq(level.talk_camera.speaker(), level.sera as Node3D, "鏡頭帶到角落的她")
	_finish_dialogue(0)
	assert_eq(s.state.get_flag(GuildHall.FLAG_LEO_LEFT), true)
	assert_eq(s.quests.stage_of("ch1_main"), "take_quest")
	assert_eq(s.state.checkpoint, "ch1_guild_quest")
	assert_false(hud.objective_held, "下一個目標出來了")
	# 雷歐小隊走出大門、消失；水晶暗掉
	assert_true(leo.is_walking() and leo.leave_on_arrival)
	assert_true(level.party.is_empty())
	await _frames(3)
	assert_false(level.is_alarm_ringing())
	assert_true(level.scenery.crystal_light.light_energy < 0.5, "水晶暗掉了")
	var door_opened: bool = false
	for i: int in 900:
		await tree.physics_frame
		door_opened = door_opened or level.scenery.door_open > 0.9
		if not is_instance_valid(leo):
			break
	assert_false(is_instance_valid(leo), "雷歐走出去了")
	assert_true(door_opened, "大門為他們打開")
	assert_true(level.door_creaks >= 1, "門被推開的時候吱嘎一聲")
	await _frames(int(60.0 / GuildHall.DOOR_SPEED) + 30)
	assert_true(level.scenery.door_open < 0.05, "人走了，門關上")
	assert_true(level.door_shuts >= 1, "關上的時候碰一聲")
	assert_true(level.lilith_use.enabled, "可以跟莉莉絲說話")


func test_lilith_hands_over_the_green_request_then_sera_asks_to_come_along() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	for flag: String in [GuildHall.FLAG_REGISTERED, GuildHall.FLAG_CRYSTAL, GuildHall.FLAG_LEO_LEFT]:
		s.set_flag(flag, true)
	var level: GuildHall = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	assert_true(player.global_position.distance_to(GuildHall.COUNTER_FRONT) < 0.5, "讀檔：站在櫃檯前面")
	assert_true(level.party.is_empty(), "雷歐小隊已經走了")
	assert_true(level.sera.global_position.distance_to(GuildHall.SERA_CORNER) < 0.3)
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_LILITH")
	# 跟莉莉絲說話：綠色委託單
	assert_false(level.lilith_use.interact_hint().is_empty(), "櫃檯前有「說話」的提示")
	await _press_interact()
	assert_true(bool(_game().call("is_in_dialogue")))
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_QUEST_001")
	assert_eq(level.lilith.puppet.action, "give", "莉莉絲兩手把委託單遞出來")
	assert_false(level.scenery.slip.visible, "還在她手上")
	assert_not_null(level.lilith.get_node_or_null("HeldSlip"), "她兩手拿著委託單")
	await _frames(int(GuildHall.SLIP_SHOW_SEC * 60.0) + 6)
	assert_true(level.scenery.slip.visible, "綠色委託單放到櫃檯上")
	await tree.process_frame
	assert_true(level.lilith.get_node_or_null("HeldSlip") == null, "手上的那張收掉了")
	_finish_dialogue(0)
	assert_eq(s.state.get_flag(GuildHall.FLAG_QUEST), true)
	assert_eq(s.quests.stage_of("ch1_main"), "sera_asks")
	assert_false(level.lilith_use.enabled)
	# 席菈從角落走過來
	var sera: Sera = level.sera
	var far: float = sera.global_position.distance_to(player.global_position)
	await _frames(30)
	assert_true(sera.puppet().move_speed > 0.0 and sera.puppet().move_speed < 3.0, "她用走的（%.1f m/s）" % sera.puppet().move_speed)
	assert_eq(sera.puppet().pose, "", "站起來了")
	assert_eq(sera.puppet().position.y, 0.0)
	assert_true(sera.global_position.distance_to(player.global_position) < far - 0.5, "朝諾恩走過來")
	await _until_dialogue(600)
	assert_true(sera.global_position.distance_to(player.global_position) < GuildHall.SERA_TALK_DIST + 0.3)
	runner = _game().get("dialogue") as DialogueRunner
	runner.advance()
	runner.advance()
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_ASK_004", "劇本那一句：能讓我跟你一起去嗎？")
	assert_eq(runner.visible_choices.size(), 2)
	assert_true(runner.choose(1))
	runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")))
	assert_eq(int(s.state.get_flag("sera.affinity", 0)), 10, "回答加好感度")
	assert_eq(s.quests.stage_of("ch1_main"), "leave_guild")
	assert_eq(s.state.checkpoint, "ch1_guild_leave")
	assert_eq(s.state.get_flag(CorruptForest.FLAG_JOINED, false), false, "要到森林口會合才開始跟")
	# 她先跑出大門（回去拿面具）
	await _frames(20)
	assert_true(hud.bark_keys().has("BARK_SERA_GUILD_GO"))
	assert_true(sera.puppet().move_speed > 3.0, "用跑的")
	for i: int in 600:
		await tree.physics_frame
		if level.sera == null:
			break
	assert_true(level.sera == null, "席菈出去了")
	# 諾恩走出大門：一張卡，播完換到腐敗之森
	assert_eq(str(_game().get("last_level_request")), "")
	player.global_position = GuildScenery.DOOR_POS + Vector3(0.2, 0.05, -0.8)
	await _frames(3)
	assert_eq(s.state.get_flag(GuildHall.FLAG_LEFT), true)
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera")
	assert_eq(s.state.checkpoint, "ch1_forest_gate")
	assert_not_null(level.card, "換關卡的那張卡")
	assert_eq(level.card.title_text(), tr("CARD_FOREST_TITLE"))
	assert_eq(str(_game().get("last_level_request")), "", "卡還沒播完")
	level.card.finish()
	assert_eq(str(_game().get("last_level_request")), "corrupt_forest")
	# 存檔在森林口：按繼續不會回到大廳
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(str(_game().call("level_for_checkpoint", again.state.checkpoint)), "corrupt_forest")


func test_continue_after_sera_left_starts_at_the_counter_ready_to_go() -> void:
	# 存檔停在「可以出發了」的那個檢查點
	var s := GameSession.new(QuestDB.load_default(), _dir)
	s.new_game()
	for flag: String in [GuildHall.FLAG_REGISTERED, GuildHall.FLAG_CRYSTAL, GuildHall.FLAG_LEO_LEFT, GuildHall.FLAG_QUEST, GuildHall.FLAG_SERA_ASKED]:
		s.set_flag(flag, true)
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))
	assert_eq(_session().load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(_session().quests.stage_of("ch1_main"), "leave_guild")
	var level: GuildHall = _load_level()
	await _frames(5)
	assert_true(level.sera == null, "席菈已經先走了")
	assert_true(level.party.is_empty())
	var player: PlayerController = level.get_node("Player") as PlayerController
	assert_true(player.global_position.distance_to(GuildHall.COUNTER_FRONT) < 0.5)
	assert_false(bool(_game().call("is_in_dialogue")))
	assert_eq((level.get_node("Hud") as Hud).objective_text_key(), "Q_CH1_OBJ_LEAVE")
	assert_true(level.scenery.crystal_light.light_energy < 0.5, "測過的水晶是暗的")


func test_epilogue_returns_to_the_guild_at_dusk_and_ends_the_chapter() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	GuildHall.skip_to_return(s)
	assert_eq(s.quests.stage_of("ch1_main"), "report")
	assert_eq(s.state.checkpoint, "ch1_guild_return")
	var level: GuildHall = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	assert_true(level.is_epilogue() and level.scenery.evening, "傍晚")
	assert_true(player.global_position.distance_to(GuildHall.ENTRANCE) < 0.5, "從大門走進來")
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_REPORT")
	# 雷歐小隊先逃回來了、圍在櫃檯前；巡察官在二樓；席菈跟在後面；諾恩扛著核心
	assert_eq(level.party.size(), 3)
	for key: String in level.party:
		assert_true((level.party[key] as Npc).global_position.z < -4.0, "%s 在櫃檯前" % key)
	assert_not_null(level.inspector)
	assert_true(absf(level.inspector.global_position.y - GuildScenery.LOFT_Y) < 0.01, "巡察官站在二樓")
	assert_true(level.sera != null and level.sera.joined and level.sera.target == player, "席菈跟著諾恩")
	assert_true(level.sera.global_position.distance_to(player.global_position) < 3.0)
	for key: String in level.party:
		assert_eq((level.party[key] as Npc).pose, "slump", "%s 累垮了" % key)
	assert_true(player.is_sheathed())
	assert_true(level.sera.holstered)
	assert_not_null(level.core, "扛著魔像核心")
	assert_true(level.core.is_carried_by(player.get_node("Body") as Node3D))
	if player.puppet().uses_model():
		assert_true(player.puppet().carry, "左手扶著扛在肩上的核心")
	assert_true(level.core.is_inside_tree() and level.core.global_position.distance_to(player.global_position + Vector3(0, 1.6, 0)) < 0.6)
	await _frames(5)
	assert_true(hud.bark_keys().has("BARK_LEO_RETURN"), "雷歐還在說那兩個人回不來了")
	assert_false(bool(_game().call("is_in_dialogue")))
	# 走近櫃檯：幾個人講話，最後鏡頭帶到二樓
	player.global_position = Vector3(0.2, 0.05, GuildHall.REPORT_Z - 0.5)
	await _until_dialogue(10)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(str(runner.current().get("speaker", "")), "SPK_LEO")
	var seen: Array[String] = []
	var guard: int = 0
	while runner.is_running() and guard < 40:
		guard += 1
		var spk: String = str(runner.current().get("speaker", ""))
		if not seen.has(spk):
			seen.append(spk)
		if spk == GuildHall.INSPECTOR_KEY:
			await _frames(int(TalkCamera.BLEND_SEC * 60.0) + 4)
			assert_eq(level.talk_camera.speaker(), level.inspector as Node3D, "最後一句：鏡頭帶到二樓的巡察官")
			assert_true(level.talk_camera.global_position.y > GuildScenery.LOFT_Y, "鏡頭升到二樓的高度")
			assert_true(level.talk_camera.global_position.z < level.inspector.global_position.z, "從他背後往下看諾恩")
			assert_true(level.aura.emitting, "諾恩身上冒出黑氣")
		elif level.aura != null:
			assert_false(level.aura.emitting, "其他句沒有黑氣")
		if not runner.visible_choices.is_empty():
			runner.choose(0)
		else:
			runner.advance()
	for spk: String in ["SPK_LEO", "SPK_ADVENTURER", "SPK_NOEN", "SPK_LILITH", Sera.NAME_KEY, GuildHall.INSPECTOR_KEY]:
		assert_true(seen.has(spk), "%s 有講話" % spk)
	assert_false(bool(_game().call("is_in_dialogue")))
	assert_eq(str(s.state.get_flag("ch1.return_answer", "")), "credit")
	assert_true(s.story_finished(), "第一章完")
	assert_eq(s.state.get_flag("ch1.complete"), true)
	# 隔一下「第一章　完」，播完回標題
	assert_true(level.card == null)
	await _frames(int(GuildHall.END_CARD_DELAY * 60.0) + 10)
	assert_not_null(level.card, "章節卡")
	assert_eq(level.card.title_text(), tr("CARD_END_TITLE"))
	level.card.finish()
	assert_eq(str(_game().get("last_level_request")), "title", "播完回標題")
	# 「繼續」：回到傍晚的大廳，不會再演一次
	level.free()
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))
	assert_eq(_session().load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_true(_session().story_finished())
	assert_eq(str(_game().call("level_for_checkpoint", _session().state.checkpoint)), "guild_hall")
	level = _load_level()
	await _frames(30)
	assert_true(level.is_epilogue())
	assert_false(bool(_game().call("is_in_dialogue")), "演過了")
	assert_true(level.card == null)
	assert_eq((level.get_node("Hud") as Hud).objective_text_key(), Hud.STORY_END_KEY)
