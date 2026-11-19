extends TestCase
## 第一章的起點（腐敗之森入口）：新遊戲 → 任務與檢查點 → 走進瘴氣反轉 → 兩人講幾句 → 席菈跟著、開打後射藥 → 打倒三隻史萊姆。
## 劇本 docs/story/chapter-1.md，計畫 docs/design/13-chapter-1-plan.md。

const LEVEL: String = "res://scenes/levels/corrupt_forest.tscn"

var _dir: String = ""
var _old_session: GameSession
var _level: CorruptForest
## 這個測試載入的關卡（森林或祭壇）：測試結束時釋放
var _level_node: Node


func _game() -> Node:
	return tree.root.get_node("Game")


func before_each() -> void:
	_dir = "user://test_ch1_%d" % Time.get_ticks_usec()
	_old_session = _game().get("session") as GameSession
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))
	# 關卡是直接掛在 root 底下的：劇情走到下一關時只記下要去哪，不真的換場景
	_game().set("change_scenes", false)
	_game().set("last_level_request", "")


func after_each() -> void:
	if _level_node != null and is_instance_valid(_level_node):
		_level_node.free()
	_game().set("change_scenes", true)
	_game().set("session", _old_session)
	_game().set("dialogue", null)
	_game().call("cancel_hit_stop")
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
	_level_node = _level
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
	assert_eq(s.quests.stage_of("ch1_main"), "register", "從公會大廳的登錄開始")
	assert_eq(s.objective_key(), "Q_CH1_OBJ_REGISTER")
	assert_eq(s.state.checkpoint, "ch1_guild")
	assert_true(s.has_save(), "進第一個檢查點就自動存檔")
	assert_true(bool(_game().call("has_continue")), "標題的「繼續」找得到")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "guild_hall")


func test_quest_follows_the_four_flags_and_continue_restores_it() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	# 公會大廳的開場：登錄 → 水晶與雷歐 → 委託 → 席菈開口 → 出發
	s.set_flag(GuildHall.FLAG_REGISTERED, true)
	assert_eq(s.quests.stage_of("ch1_main"), "aptitude")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:Crystal")
	s.set_flag(GuildHall.FLAG_CRYSTAL, true)
	assert_eq(s.quests.stage_of("ch1_main"), "aptitude", "警報響了還沒完：雷歐還沒講")
	assert_eq(s.state.checkpoint, "ch1_guild", "這一段中途不存檔")
	s.set_flag(GuildHall.FLAG_LEO_LEFT, true)
	assert_eq(s.quests.stage_of("ch1_main"), "take_quest")
	assert_eq(s.state.checkpoint, "ch1_guild_quest")
	s.set_flag(GuildHall.FLAG_QUEST, true)
	assert_eq(s.quests.stage_of("ch1_main"), "sera_asks")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:Sera")
	s.set_flag(GuildHall.FLAG_SERA_ASKED, true)
	assert_eq(s.quests.stage_of("ch1_main"), "leave_guild")
	assert_eq(s.state.checkpoint, "ch1_guild_leave")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "guild_hall")
	s.set_flag(GuildHall.FLAG_LEFT, true)
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera", "走出大門：腐敗之森")
	assert_eq(s.state.checkpoint, "ch1_forest_gate")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "corrupt_forest", "換關卡")
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
	assert_eq(s.quests.stage_of("ch1_main"), "gather", "戰後那段話講完：自由探索")
	assert_eq(s.state.checkpoint, "ch1_explore")
	assert_eq(s.quests.marker_spec("ch1_main"), "nearest:Mushroom", "指引指向最近的夜光毒蕈")
	var list: Array[Dictionary] = s.checklist()
	assert_eq(list.size(), 3, "右上角的清單三項")
	assert_true(int(list[0]["need"]) == 5 and int(list[0]["have"]) == 0 and not bool(list[0]["optional"]), "第一項要採 5 朵")
	assert_true(bool(list[1]["optional"]) and bool(list[2]["optional"]), "另外兩項是可選的")
	s.add_flag(ForestExplore.FLAG_MUSHROOMS, 4)
	assert_eq(s.quests.stage_of("ch1_main"), "gather", "四朵還不夠")
	assert_eq(int(s.checklist()[0]["have"]), 4)
	s.add_flag(ForestExplore.FLAG_MUSHROOMS, 1)
	assert_eq(s.quests.stage_of("ch1_main"), "to_altar", "採滿五朵：慘叫聲，往祭壇")
	assert_eq(s.state.checkpoint, "ch1_scream")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:AltarGate")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "corrupt_forest")
	assert_false(s.quests.is_done("ch1_main"))
	s.set_flag(ForestExplore.FLAG_ALTAR, true)
	assert_eq(s.quests.stage_of("ch1_main"), "altar_arrive", "走到祭壇路口：下一段在廢棄祭壇")
	assert_eq(s.state.checkpoint, "ch1_altar")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "ruined_altar", "換關卡")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:AltarRuins")
	s.set_flag(RuinedAltar.FLAG_TALKED, true)
	assert_eq(s.quests.stage_of("ch1_main"), "boss", "抵達的那段話講完：開打")
	assert_eq(s.state.checkpoint, "ch1_boss")
	assert_eq(s.quests.marker_spec("ch1_main"), "node:Golem")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "ruined_altar")
	s.set_flag(RuinedAltar.FLAG_GOLEM_DOWN, true)
	assert_eq(s.quests.stage_of("ch1_main"), "after_boss", "魔像倒了：還有戰後那段話")
	assert_eq(s.state.checkpoint, "ch1_boss_down")
	assert_false(s.quests.is_done("ch1_main"))
	s.set_flag(RuinedAltar.FLAG_DONE, true)
	assert_eq(s.quests.stage_of("ch1_main"), "report", "戰後那段話講完：回公會")
	assert_eq(s.state.checkpoint, "ch1_guild_return")
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "guild_hall", "換回公會大廳")
	assert_false(s.story_finished())
	s.set_flag(GuildHall.FLAG_CHAPTER_DONE, true)
	assert_true(s.quests.is_done("ch1_main"))
	assert_eq(s.state.get_flag("ch1.complete"), true)
	assert_true(s.story_finished(), "第一章完")


func test_quest_and_dialogue_data_are_valid() -> void:
	var db := QuestDB.load_default()
	assert_true(db.errors.is_empty(), "任務資料：%s" % ", ".join(db.errors))
	var dlg := DialogueDB.load_default()
	assert_true(dlg.errors.is_empty(), "對話資料：%s" % ", ".join(dlg.errors))
	for id: String in ["ch1_guild_register", "ch1_guild_leo", "ch1_guild_quest", "ch1_guild_sera", "ch1_sera_joins", "ch1_forest_gate",
			"ch1_after_slimes", "ch1_campfire", "ch1_altar_arrive", "ch1_altar_after", "ch1_guild_return"]:
		assert_true(dlg.has_dialogue(id), "有對話 %s" % id)
	assert_true(StatusRules.load_default().errors.is_empty(), "狀態資料")


func test_moss_mask_is_white_under_trees_and_black_elsewhere() -> void:
	var edge: float = ForestMap.SIZE * 0.5 - 0.1
	var mask: Image = ForestScenery.moss_mask(PackedVector3Array([Vector3(10, 1.0, -20), Vector3(-edge, 1.3, edge)]))
	var per_meter: float = float(ForestScenery.MOSS_MASK_SIZE) / ForestMap.SIZE
	var half: float = float(ForestScenery.MOSS_MASK_SIZE) * 0.5
	assert_true(mask.get_pixel(int(10.0 * per_meter + half), int(-20.0 * per_meter + half)).r > 0.95, "樹腳下是白的")
	assert_true(mask.get_pixel(int(12.0 * per_meter + half), int(-20.0 * per_meter + half)).r > 0.95, "離樹 2 m 還是白的（土丘在苔裡）")
	assert_eq(mask.get_pixel(int(18.0 * per_meter + half), int(-20.0 * per_meter + half)).r, 0.0, "離樹 8 m 沒有苔")
	assert_eq(mask.get_pixel(int(half), int(half)).r, 0.0, "沒有樹的地方是黑的")
	assert_true(mask.get_pixel(0, ForestScenery.MOSS_MASK_SIZE - 1).r > 0.5, "地圖角落的樹不會畫到圖外面去")


## 地圖（ForestMap）：路與空地不種樹、不長草；地面的遮罩在路上是白的、樹林裡是黑的、毒沼另外記一層；走太遠會被拉回來。
## 外圍的土坡：玩家走得到的地方（離路網 STRAY_LIMIT 以內）一律是平的，走不到的外圍才隆起；樹與草貼著畫出來的地面。
func test_ground_rises_only_where_noen_cannot_walk() -> void:
	for p: Vector2 in [Vector2(0, 20), Vector2(ForestMap.STRAY_LIMIT, 0), Vector2(-24, -46), Vector2(40, -64), Vector2(0, -80)]:
		assert_eq(ForestMap.height(p), 0.0, "路、空地與走丟的界線上是平的：%s" % str(p))
	var stray: Vector3 = ForestMap.keep_inside(Vector3(-60.0, 0.0, 10.0))
	assert_true(ForestMap.ground_y(ForestMap.flat(stray)) < 0.05, "被拉回來的地方腳下還是平的（%.2f m）" % ForestMap.ground_y(ForestMap.flat(stray)))
	var far := Vector2(-60.0, 10.0)
	assert_true(ForestMap.height(far) > ForestMap.RELIEF_MAX * 0.5, "走不到的外圍是坡（%.1f m）" % ForestMap.height(far))
	assert_true(absf(ForestMap.ground_y(far) - ForestMap.height(far)) < 0.6, "照高度圖內插的高度跟算的差不多")
	var img: Image = ForestMap.height_mask()
	assert_eq(img.get_width(), ForestMap.HEIGHT_MASK_SIZE)
	var t: Vector3 = ForestScenery.on_ground(Vector3(-60.0, 0.0, 10.0))
	assert_true(t.y > 0.5 and t.y <= ForestMap.ground_y(far) + 0.001, "坡上的樹墊高、但不高過它腳下的地面（%.2f）" % t.y)


func test_tree_variation_stays_in_range_and_differs_by_spot() -> void:
	var seen: Dictionary = {}
	for i: int in 50:
		var v: Vector3 = ForestScenery.variation(Vector3(float(i) * 3.7 - 80.0, 0.0, float(i * 7 % 23) * 4.1 - 40.0))
		assert_true(v.x >= 0.86 and v.x <= 1.06 and v.y >= 0.9 and v.y <= 1.28 and v.z >= 0.0 and v.z < 1.0, "寬高倍數與顏色的數在範圍裡：%s" % str(v))
		seen[snappedf(v.y, 0.02)] = true
		var tint: Color = ForestScenery.tree_tint(v.z)
		assert_true(tint.r > 0.7 and tint.g > 0.7 and tint.b > 0.7, "顏色只偏一點、不會變黑：%s" % str(tint))
	assert_true(seen.size() > 10, "不同位置的樹不一樣高（%d 種）" % seen.size())
	assert_eq(ForestScenery.variation(Vector3(3, 0, -5)), ForestScenery.variation(Vector3(3, 0, -5)), "同一個位置每次都一樣")


func test_forest_map_keeps_trails_clear_and_pulls_strays_back() -> void:
	assert_false(ForestMap.tree_ok(Vector2(0, 8)), "森林口的路上不種樹")
	assert_false(ForestMap.tree_ok(Vector2(0, -15)), "史萊姆空地不種樹")
	assert_false(ForestMap.tree_ok(Vector2(-12, -41)), "往營火的岔路上不種樹")
	assert_false(ForestMap.tree_ok(ForestMap.flat(ForestMap.at(ForestMap.SWAMP))), "毒沼裡不種樹")
	assert_true(ForestMap.tree_ok(Vector2(12, 8)))
	assert_false(ForestMap.grass_ok(Vector2(0, 8)), "路中間不長草")
	assert_false(ForestMap.grass_ok(Vector2(0, -15)), "空地不長草")
	assert_true(ForestMap.grass_ok(Vector2(12, 8)))
	var mask: Image = ForestMap.trail_mask()
	var per_meter: float = float(ForestMap.MASK_SIZE) / ForestMap.SIZE
	var half: float = float(ForestMap.MASK_SIZE) * 0.5
	var px: Callable = func(p: Vector2) -> Color: return mask.get_pixel(int(p.x * per_meter + half), int(p.y * per_meter + half))
	assert_true((px.call(Vector2(0, 10)) as Color).r > 0.8, "路上是土")
	assert_true((px.call(Vector2(-24, -46)) as Color).r > 0.9, "營火的空地是土")
	assert_eq((px.call(Vector2(30, 10)) as Color).r, 0.0, "樹林裡不是")
	assert_true((px.call(Vector2(40, -64)) as Color).g > 0.9 and (px.call(Vector2(0, -15)) as Color).g < 0.05, "只有毒沼是濕的")
	for c: Vector3 in ForestMap.CLEARINGS:
		assert_true(absf(c.x) + c.z < ForestMap.SIZE * 0.5 - 5.0 and absf(c.y) + c.z < ForestMap.SIZE * 0.5 - 5.0, "空地都在地面裡面：%s" % str(c))
	var on_path := Vector3(1.0, 0.05, -50.0)
	assert_eq(ForestMap.keep_inside(on_path), on_path, "在路上不會被動到")
	var back: Vector3 = ForestMap.keep_inside(Vector3(-60.0, 0.05, 10.0))
	assert_true(absf(ForestMap.flat(back).distance_to(ForestMap.nearest_on_trail(ForestMap.flat(back))) - ForestMap.STRAY_LIMIT) < 0.01 and back.x > -25.0,
		"走進樹林太深被拉回離路 %.0f m 的地方：%s" % [ForestMap.STRAY_LIMIT, str(back)])


func test_level_builds_with_markers_miasma_slimes_and_a_clear_path() -> void:
	_new_game_joined()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	for marker: String in ["MiasmaEdge", "SlimeGlade", "Spawn", "Player", "Hud", "Miasma", "Forest", "Sera"]:
		assert_not_null(level.get_node_or_null(marker), "有節點 %s" % marker)
	assert_eq(level.slimes.size(), 3, "三隻史萊姆")
	assert_eq(level.slimes_alive(), 3)
	assert_true(level.get_node("Forest").get_child_count() >= ForestScenery.TREE_COUNT + ForestScenery.DEEP_TREE_COUNT - 20, "樹與路邊的小東西都種了（%d）" % level.get_node("Forest").get_child_count())
	for tree_node: Node in level.get_node("Forest").get_children():
		if tree_node is StaticBody3D:
			assert_true(ForestMap.tree_ok(ForestMap.flat((tree_node as Node3D).position)), "樹不擋路：%s" % str((tree_node as Node3D).position))
	assert_true(level._no_tree_here(CorruptForest.MIASMA_POS), "瘴氣裡不種樹")
	# 認得出來的地方：祭壇路口的斷柱與倒下的橫樑、營火旁坐的圓木
	var ruins: Node3D = level.get_node_or_null("AltarRuins") as Node3D
	assert_not_null(ruins, "祭壇路口有遺跡")
	assert_true(ruins.get_node_or_null("GatePillar1") is StaticBody3D and ruins.get_node_or_null("GatePillar2") is StaticBody3D, "兩根斷柱，擋人")
	for pillar: Node in [ruins.get_node("GatePillar1"), ruins.get_node("GatePillar2")]:
		var at: Vector2 = ForestMap.flat((pillar as Node3D).global_position)
		assert_true(at.y < ForestMap.ALTAR_GATE.y - 2.0 and absf(at.x) > 2.0, "斷柱在路的盡頭、夾著路（不擋在路中間）：%s" % str(at))
	var camp: Node3D = level.get_node_or_null("CampSite") as Node3D
	assert_not_null(camp, "營火的空地有坐的地方")
	assert_true(camp.get_node_or_null("Log1") is StaticBody3D and camp.get_node_or_null("Log2") is StaticBody3D, "兩根圓木")
	for log_name: String in ["Log1", "Log2"]:
		var d: float = ForestMap.flat((camp.get_node(log_name) as Node3D).global_position).distance_to(Vector2(ForestMap.CAMP.x, ForestMap.CAMP.y))
		assert_true(d > 1.5 and d < ForestMap.CAMP.z - 2.0, "圓木圍著火、不擋住走到火旁邊（%.1f m）" % d)
	# 天空：星星與月亮（forest_sky.gdshader），月亮在北邊、地平線上面；霧只蓋天空的一部分
	var env: Environment = (level.get_node("WorldEnvironment") as WorldEnvironment).environment
	var night := env.sky.sky_material as ShaderMaterial
	assert_true(night != null and night.shader == ForestScenery.SKY_SHADER, "天空是自己畫的夜空（星星、月亮）")
	var moon_dir: Vector3 = night.get_shader_parameter("moon_dir")
	assert_true(moon_dir.z < -0.8 and moon_dir.y > 0.15 and moon_dir.y < 0.4, "月亮在北邊、低低的（往北走看得到）：%s" % str(moon_dir))
	assert_true(env.volumetric_fog_sky_affect < 0.5, "霧不把星星蓋掉")
	# 樹隨風擺、每棵高矮胖瘦與顏色不一樣
	var heights: Dictionary = {}
	var swaying: int = 0
	var trees_seen: int = 0
	for tree_node: Node in level.get_node("Forest").get_children():
		if not tree_node is StaticBody3D:
			continue
		trees_seen += 1
		var look: Node3D = (tree_node as Node3D).get_child(1) as Node3D
		heights[Vector2(look.scale.x, look.scale.y).snappedf(0.001)] = true
		for mi: Node in look.find_children("*", "MeshInstance3D", true, false):
			var mat := (mi as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
			if mat != null and mat.shader == ForestScenery.SWAY_SHADER:
				swaying += 1
				break
	if PropModels.scene_for(ForestScenery.TREE_MODEL) != null:
		assert_eq(swaying, trees_seen, "每一棵樹都會隨風擺")
		assert_true(heights.size() > trees_seen / 2, "樹的高矮胖瘦每棵不一樣（%d 種／%d 棵）" % [heights.size(), trees_seen])
	var grass: MultiMeshInstance3D = level.get_node_or_null("Forest/GrassTufts") as MultiMeshInstance3D
	assert_not_null(grass, "有草叢")
	assert_true(grass.multimesh.instance_count > 3000, "草叢不只幾叢（%d）" % grass.multimesh.instance_count)
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
	# 一個人等的時候：往瘴氣走幾步、停下來看、轉身走回原位、再回頭看（想進去又不敢）
	var home: Vector3 = CorruptForest.SERA_WAIT_POS
	var to_mist: Vector3 = (CorruptForest.MIASMA_POS - home).normalized()
	var nearest: float = 0.0
	var farthest: float = 0.0
	var walked: bool = false
	var turned_away: bool = false
	var ever_masked: bool = false
	for i: int in int(SeraBrain.HESITATE_CYCLE_SEC * 60.0) - 6:
		await tree.physics_frame
		var off: Vector3 = sera.global_position - home
		nearest = maxf(nearest, off.dot(to_mist))
		farthest = maxf(farthest, Vector2(off.x, off.z).length())
		walked = walked or sera.puppet().move_speed > 0.0
		turned_away = turned_away or (-sera.global_basis.z).dot(to_mist) < -0.6
		ever_masked = ever_masked or sera.masked
	assert_true(walked and nearest > SeraBrain.HESITATE_STEP - 0.2, "往瘴氣走了幾步（最近走到 %.2f m）" % nearest)
	assert_true(farthest < SeraBrain.HESITATE_STEP + 0.2, "還沒結伴不會跟過來，只在瘴氣前面來回（最遠離原位 %.2f m）" % farthest)
	assert_true(turned_away, "轉身走回去")
	assert_false(ever_masked, "走到最近也還不到要戴面具的地方")
	assert_true(Vector2(sera.global_position.x - home.x, sera.global_position.z - home.z).length() < 0.3, "一輪走完回到原位")
	assert_true((-sera.global_basis.z).dot(to_mist) > 0.8, "又回頭看著瘴氣")
	assert_eq(sera.vials_fired, 0)
	assert_false(bool(_game().call("is_in_dialogue")), "離得遠不會開口")
	# 走近：她先出聲、轉過來
	player.global_position = CorruptForest.SERA_WAIT_POS + Vector3(0.6, 0.05, Sera.NOTICE_DIST - 1.5)
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
	assert_eq(str(runner.current().get("speaker", "")), Sera.NAME_KEY, "兩人在公會認識了：她不是「？？？」")
	runner.advance()
	assert_false(sera.joined, "話還沒講完")
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_JOIN_003")
	assert_true(runner.visible_choices.is_empty(), "能不能一起去在公會問過了，這裡只是會合")
	runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")), "三句就講完")
	assert_eq(s.state.get_flag(CorruptForest.FLAG_JOINED), true)
	assert_eq(s.quests.stage_of("ch1_main"), "enter_miasma", "會合之後才是「走進瘴氣裡」")
	assert_eq(s.state.checkpoint, "ch1_with_sera")
	for i: int in 3:
		await tree.physics_frame
	assert_true(sera.joined, "講完才開始跟")
	assert_false(bool(_game().call("is_in_dialogue")), "只問一次")
	# 諾恩走進瘴氣，她跟上來：到邊上先戴面具
	player.global_position = CorruptForest.MIASMA_POS + Vector3(0, 0.05, -3.0)
	var frames: int = 0
	var fumbled_at: Vector3 = Vector3.INF
	var sweat: bool = false
	var fumble_moved: float = 0.0
	while not sera.masked and frames < 360:
		await tree.physics_frame
		frames += 1
		if sera.is_fumbling():
			if not fumbled_at.is_finite():
				fumbled_at = sera.global_position
			fumble_moved = maxf(fumble_moved, sera.global_position.distance_to(fumbled_at))
			sweat = sweat or sera.has_node("MangaMark_sweat")
	assert_true(sera.masked, "靠近瘴氣就戴上面具")
	assert_true(fumbled_at.is_finite(), "戴上之前先慌張地找了一下")
	assert_eq(sera.puppet().action, "fumble", "找面具的動作還在播（面具在動作的後半戴上）")
	assert_true(fumble_moved < 0.1, "找的時候停在原地（%.2f m）" % fumble_moved)
	assert_true(sweat, "頭上冒一滴汗")
	assert_false(sera.near_miasma(0.0), "停在瘴氣外面找，不是走進去才找")
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
	assert_eq(cam.speaker(), sera as Node3D, "第一句是她")
	# 滑過去的路上不擦過諾恩的頭
	var closest: float = 99.0
	for i: int in int(TalkCamera.BLEND_SEC * 60.0) + 12:
		await tree.physics_frame
		closest = minf(closest, Vector2(cam.global_position.x - player.global_position.x, cam.global_position.z - player.global_position.z).length())
	var arrived: float = Vector2(cam.global_position.x - player.global_position.x, cam.global_position.z - player.global_position.z).length()
	assert_true(closest > minf(arrived, TalkCamera.HEAD_CLEAR) - 0.1, "鏡頭滑過去時離諾恩的頭最近 %.2f m（到位之後 %.2f m）" % [closest, arrived])
	assert_eq(tree.root.get_viewport().get_camera_3d(), cam as Camera3D)
	# 第一句是兩人同框（對話資料 shot: two）：兩個人都在畫面裡、看得到她的臉
	var fwd: Vector3 = -cam.global_basis.z
	for who: Node3D in [sera as Node3D, player as Node3D]:
		var v: Vector3 = who.global_position + Vector3.UP * 1.3 - cam.global_position
		assert_true(v.normalized().dot(fwd) > cos(deg_to_rad(TalkCamera.TALK_FOV * 0.85)), "%s 在畫面裡" % who.name)
	var sera_face: Vector3 = -sera.global_basis.z
	assert_true(sera_face.dot((cam.global_position - sera.global_position).normalized()) > 0.3, "拍得到她的臉，不是後腦勺")
	assert_true(absf(cam.fov - TalkCamera.TALK_FOV) < 0.1)
	assert_true(cam.acting.marks().size() == 1 and cam.acting.marks()[0].kind == "sweat", "她頭上冒一滴汗")
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
	# 再換她講（沒有寫鏡位）：她的上半身近景
	runner.advance()
	await tree.physics_frame
	await tree.physics_frame
	var to_sera: Vector3 = (TalkCamera.aim_point(sera.global_position) - cam.global_position).normalized()
	assert_true((-cam.global_basis.z).dot(to_sera) > 0.999, "切到她的近景")
	assert_true(cam.global_position.distance_to(sera.global_position) < 3.4, "是近景（離她 %.1f m）" % cam.global_position.distance_to(sera.global_position))
	assert_true(sera_face.dot((cam.global_position - sera.global_position).normalized()) > 0.5, "拍到的是她的臉")
	# 講完：滑回玩家的鏡頭
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
	var facing_before: Vector3 = player.facing()
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
	# 貼在他肩膀旁邊（0.25 m，平常這麼近她不轉）：對話中照樣轉過去面向他
	level.sera.global_position = player.global_position + Vector3(0.2, 0.0, 0.15)
	for i: int in 40:
		await tree.physics_frame
	var to_noen: Vector3 = player.global_position - level.sera.global_position
	to_noen.y = 0.0
	assert_true((-level.sera.global_basis.z).dot(to_noen.normalized()) > 0.9, "對話中再近也面向他")
	var hud: Hud = level.get_node("Hud") as Hud
	assert_true(player.status_effects.has("poison"), "身上還有毒")
	assert_true(hud.status.visible and hud.combat.visible, "對話中左下的狀態列與生命條照樣看得到（講的就是「你的血在回」）")
	var box: DialogueBox = level.get_node("DialogueBox") as DialogueBox
	var view_h: float = hud.get_viewport().get_visible_rect().size.y
	assert_true(hud.combat.lift > 0.0, "往上讓開")
	assert_true(view_h - 142.0 - hud.combat.lift < box.panel_top(), "生命條在對話框上面（生命條 %.0f、框 %.0f）" % [view_h - 142.0 - hud.combat.lift, box.panel_top()])
	assert_true(hud.status.position.y + hud.status.size.y < box.panel_top(), "狀態列也在對話框上面")
	for i: int in 4:
		runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")), "四句講完")
	for i: int in 120:
		await tree.physics_frame
	assert_true(hud.status.visible and hud.combat.visible and hud.combat.lift == 0.0, "講完就回到原位")
	assert_false(player.is_turning_back(), "諾恩轉回去了")
	assert_true(player.facing().dot(facing_before) > 0.98, "講完面向對話前的方向，不是一直對著身後的席菈（%s → %s）" % [str(facing_before), str(player.facing())])
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
	assert_true(sera.footsteps.count > 0 and sera.footsteps.last_surface == "dirt", "走過來有腳步聲、是森林的土（%d 步，%s）" % [sera.footsteps.count, sera.footsteps.last_surface])
	assert_eq(player.footstep_surface(), "dirt", "諾恩踩在森林裡也是土")
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
	assert_true(hud.hint_text().contains(tr("VIAL_BLIND_SMOKE")), "提示寫要的是哪一瓶：%s" % hud.hint_text())
	assert_false(sera.switch_pick(), "教學戰只有煙霧彈可以要：換一瓶的按鍵沒作用")
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
	assert_true(_playing(sera, "vial_shot"), "射出去是弓弦的聲音（不是閃避的風聲）")
	var vial: SeraVial = sera.last_vial
	assert_eq(vial.source, Sera.ASK_SOURCE, "射的是致盲煙霧彈")
	assert_true(vial.liquid != SeraVial.LIQUID, "顏色跟平常的紫色藥瓶不一樣")
	for i: int in int(CombatTuning.num("sera.vial_flight") * 60.0) + 6:
		await tree.physics_frame
	assert_true(vial.landed and player.status_effects.strikes_weakpoint(), "落在諾恩身上：致盲 → 鷹眼")
	assert_true(_playing(player, "vial_shatter"), "砸在身上是藥瓶碎掉的聲音")
	assert_true(vial.smoky and vial.smoke != null, "煙霧彈砸開有煙")
	if vial.smoke != null:
		assert_true(absf(vial.smoke.global_position.y - player.global_position.y - SeraVial.SMOKE_Y) < 0.05
			and Vector2(vial.smoke.global_position.x - player.global_position.x, vial.smoke.global_position.z - player.global_position.z).length() < 0.3,
			"煙從他腳邊往外滾（不是從胸口往上冒，不擋住人）：%s" % str(vial.smoke.global_position - player.global_position))
		assert_eq(vial.smoke.gravity.x, 0.0)
		assert_true(vial.smoke.flatness == 1.0 and vial.smoke.gravity.y < 1.0, "貼著地面往四面八方")
		assert_eq(vial.smoke.explosiveness, 1.0, "一次全部出來（還沒出來的粒子會在腳邊畫成一團黑的）")
		assert_eq(ParticleLook.untextured(vial).size(), 0, "煙是圓的軟邊，不是方塊")
		var smat: StandardMaterial3D = vial.smoke.mesh.surface_get_material(0) as StandardMaterial3D
		assert_true(smat.billboard_keep_scale and vial.smoke.scale_amount_curve.sample(1.0) > vial.smoke.scale_amount_curve.sample(0.0) * 1.5,
			"每一團邊滾邊變大（看板材質要留粒子的縮放）")
		assert_true(smat.proximity_fade_enabled, "插進地面的地方淡掉（沒有一條平的邊）")
		assert_eq(vial.smoke.color_ramp.get_color(0).a, 0.0, "剛冒出來還貼在他腳邊時是透明的（不蓋到小腿）")
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
	assert_true(_playing(sera, "vial_load"), "裝好的那一刻喀一聲")
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


## 自動攻擊開著（預設）：玩家只要走過去——往最近的史萊姆小跑，一次都不按出手，三隻照樣清得掉；左上的操作提示改寫「靠近敵人會自己砍」。
func test_with_auto_attack_walking_up_to_the_slimes_is_enough() -> void:
	var settings: Node = tree.root.get_node("Settings")
	_new_game_joined()
	_session().set_flag(CorruptForest.FLAG_REVERSAL, true)
	_session().set_flag(CorruptForest.FLAG_MISFIRE, true)  # 席菈不插手：這裡只量諾恩自己
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	level.sera.set_physics_process(false)
	assert_eq(hud.hint_key_now(), "Q_CH1_HINT_FIGHT", "自動攻擊關著：提示寫按哪個鍵攻擊")
	var manual_hint: String = hud.hint_text()
	settings.set("auto_attack", true)
	settings.emit_signal("changed")
	assert_eq(hud.hint_key_now(), "Q_CH1_HINT_FIGHT_AUTO", "開著：改寫「靠近敵人會自己砍」")
	assert_ne(hud.hint_text(), manual_hint, "設定一改，畫面上的提示跟著換")
	assert_false(hud.hint_text().contains("{"), "按鍵都換好了：%s" % hud.hint_text())
	player.global_position = CorruptForest.GLADE_POS + Vector3(0, 0.05, 4.0)
	var frames: int = -1
	for f: int in 1800:
		if level.slimes_alive() == 0:
			frames = f
			break
		var nearest: Slime = null
		for sl: Slime in level.slimes:
			if is_instance_valid(sl) and not sl.health.is_dead() and (nearest == null or sl.global_position.distance_to(player.global_position) < nearest.global_position.distance_to(player.global_position)):
				nearest = sl
		var to: Vector3 = nearest.global_position - player.global_position
		to.y = 0.0
		if to.length() > 1.6 and player.hurt_left <= 0.0:
			player.global_position += to.normalized() * (PlayerController.WALK_SPEED / 60.0)
		await tree.physics_frame
	_game().call("cancel_hit_stop")
	print("    自動攻擊：只走過去、不按出手，三隻史萊姆 %d 幀清完" % frames)
	assert_true(frames > 0, "只靠走位就清得掉")
	assert_true(frames < 60 * 12, "不比自己按慢太多（%d 幀）" % frames)
	assert_true(player.on_hit_applied > 0, "砍中照樣給自己流血＋中毒")
	assert_false(player.health.is_dead())


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
	assert_true(_playing(slime, Slime.HOP_SFX), "撲過來是濕濕的「啵嚶」（不再借閃避的風聲）")
	assert_eq(slime.last_notice_sfx, "", "史萊姆發現人不叫")
	slime._on_fall_impact()
	assert_eq(slime.last_fall_sfx, Slime.SPLAT_SFX, "被砍爛是「啪嘰」")


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
	var peak_range: float = 0.0
	for i: int in 240:
		await tree.physics_frame
		peak = maxf(peak, slime.glow_level())
		peak_range = maxf(peak_range, glow.omni_range)
		if slime.brain.state == EnemyBrain.State.STRIKE:
			break
	assert_true(peak > EnemyActor.GLOW_WINDUP * 0.8, "蓄力要撲的時候越來越亮（最亮 %.2f 倍）" % peak)
	assert_true(absf(glow.light_energy - EnemyActor.GLOW_ENERGY * slime.glow_level()) < 0.001, "腳下的燈跟身上的邊一起亮")
	assert_true(peak_range > EnemyActor.GLOW_RANGE * 1.5, "蓄力的時候腳下那一圈綠光照得更大（最大 %.1f m）" % peak_range)
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
			assert_true(paint != null and paint.shader == ForestScenery.MUSHROOM_SHADER, "毒蕈的顏色照形狀算（模型的顏色貼圖是灰的）")
		assert_true(lamp.light_cull_mask & 1 == 1, "照得到地面與旁邊的東西")
	assert_true(lamps > 0, "有會發光的毒蕈（%d 叢）" % lamps)


func test_clearing_the_slimes_leads_to_the_talk_and_opens_the_forest() -> void:
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
	assert_eq(s.quests.stage_of("ch1_main"), "gather", "講完之後自由探索開放")
	for i: int in 3:
		await tree.physics_frame
	assert_false(s.story_finished(), "後面還有")
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_GATHER")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_EXPLORE_LINE1", "CH1_EXPLORE_LINE2"]), "劇本的系統提示：探索解鎖")
	assert_true(hud.hint_text().contains("[F]") and hud.hint_text().contains("[Q]"), "操作提示有互動與向席菈要藥：%s" % hud.hint_text())
	assert_eq(hud.checklist_lines().size(), 3, "右上角有目標清單：%s" % str(hud.checklist_lines()))
	assert_true(hud.checklist_lines()[0].begins_with("[0/5]"), "第一行寫採了幾朵：%s" % hud.checklist_lines()[0])


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
	assert_eq(_session().quests.stage_of("ch1_main"), "gather")
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
	assert_eq(str(_game().call("level_for_checkpoint", _session().state.checkpoint)), "guild_hall", "從公會大廳開始")
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


## 自由探索（劇本時段 B）：戰後那段話講完才開放——之前往北走不過去、毒蕈不能採。
## 採一朵：右上角的清單加一、那一朵不見、存檔；讀檔之後採過的不會再長出來。採滿五朵：慘叫聲、目標換成往祭壇；走到祭壇路口這一段結束。
func test_gathering_five_mushrooms_brings_the_scream_and_the_road_to_the_altar() -> void:
	_new_game_joined()
	var s: GameSession = _session()
	s.set_flag(CorruptForest.FLAG_REVERSAL, true)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var explore: ForestExplore = level.explore
	level.sera.set_physics_process(false)
	for slime: Slime in level.slimes:
		slime.set_physics_process(false)
	assert_eq(explore.mushrooms_left(), ForestExplore.MUSHROOM_SPOTS.size(), "七朵都在")
	for m: Interactable in explore.mushrooms:
		assert_not_null(m.get_node_or_null("PickupRing"), "可以採的腳下有一圈光（路邊當擺設的沒有）：%s" % m.name)
	for child: Node in level.get_node("Forest").get_children():
		assert_true(child.get_node_or_null("PickupRing") == null, "路邊當擺設的毒蕈與灌木沒有光圈")
	assert_not_null(level.get_node_or_null("AltarGate"), "祭壇路口有標記")
	assert_true(hud.checklist_lines().is_empty(), "還沒開放：右上角沒有清單")
	# 還沒打完史萊姆：往北走不過去，毒蕈也不能採
	player.global_position = Vector3(0, 0.05, -30.0)
	for i: int in 3:
		await tree.physics_frame
	assert_true(player.global_position.z >= ForestExplore.NORTH_GATE_Z - 0.01, "教學戰打完之前過不去（z＝%.1f）" % player.global_position.z)
	assert_true(hud.bark_keys().has("BARK_SERA_NOT_YET"), "席菈喊一聲")
	var first: Interactable = explore.mushrooms[0]
	player.global_position = first.global_position + Vector3(0.8, 0.05, 0.0)
	await tree.physics_frame
	assert_true(first.interact_hint().is_empty(), "還沒開放：沒有提示")
	# 直接跳到戰後那段話講完
	for flag: String in [CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		s.set_flag(flag, true)
	assert_eq(s.quests.stage_of("ch1_main"), "gather")
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	for i: int in 4:
		await tree.physics_frame
	runner = _game().get("dialogue") as DialogueRunner
	assert_true(runner == null, "戰後那段話已經講過，不會再跳出來")
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_GATHER")
	assert_false(first.interact_hint().is_empty(), "走近可以採的毒蕈：下方出現提示")
	assert_true(str(first.interact_hint()["fmt"]).contains("{key}"))
	assert_true(ObjectiveGuide.resolve_target(level, s.quests.marker_spec("ch1_main"), player.global_position).distance_to(first.global_position) < 0.1, "目標指引指向最近的一朵")
	Input.action_press(Interactable.ACTION)
	await tree.physics_frame
	Input.action_release(Interactable.ACTION)
	await tree.physics_frame
	assert_eq(int(s.state.get_flag(ForestExplore.FLAG_MUSHROOMS, 0)), 1, "按互動採了一朵")
	assert_true(_playing(level, ForestExplore.PICK_SFX), "採下來是蕈柄折斷＋叮鈴的聲音（不再借藥瓶的玻璃聲）")
	assert_true(hud.checklist_lines()[0].begins_with("[1/5]"), "清單跟著加：%s" % hud.checklist_lines()[0])
	assert_true(hud.banner_text().contains("1/5"), "上方閃一行：%s" % hud.banner_text())
	assert_false(first.enabled, "採過的不能再採")
	assert_true(ObjectiveGuide.resolve_target(level, s.quests.marker_spec("ch1_main"), player.global_position).distance_to(first.global_position) > 3.0, "指引換到下一朵")
	# 採到東西就存檔：讀回來採過的那一朵不在、數量還在、從空地開始
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(int(again.state.get_flag(ForestExplore.FLAG_MUSHROOMS, 0)), 1, "存檔裡有這一朵")
	assert_true(ForestExplore.unlocked(again.state))
	assert_true(ForestExplore.spawn_point(again.state).distance_to(CorruptForest.GLADE_POS) < 6.0, "重來的位置在史萊姆空地")
	# 再採四朵（直接用，不走過去）
	for i: int in [1, 2, 3]:
		explore.mushrooms[i].use(player)
	assert_eq(s.quests.stage_of("ch1_main"), "gather", "四朵還不夠")
	var last: Interactable = explore.mushrooms[6]
	last.use(player)
	last.use(player)
	assert_eq(int(s.state.get_flag(ForestExplore.FLAG_MUSHROOMS, 0)), 5, "同一朵按兩次只算一次")
	assert_eq(s.quests.stage_of("ch1_main"), "to_altar", "採滿五朵")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_SCREAM_LINE1", "CH1_SCREAM_LINE2"]), "慘叫聲")
	assert_true(_playing(level, ForestExplore.SCREAM_SFX), "真的聽得到慘叫（遠遠的，不分位置）")
	assert_true(hud.bark_keys().has("BARK_SERA_SCREAM"))
	await tree.physics_frame
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_SCREAM")
	assert_eq(hud.checklist_lines().size(), 2, "清單剩兩個可選的：%s" % str(hud.checklist_lines()))
	for i: int in 30:
		await tree.physics_frame
	assert_eq(explore.mushrooms_left(), 2, "剩兩朵沒採")
	# 走到祭壇路口：這一段結束
	assert_false(s.quests.is_done("ch1_main"))
	player.global_position = ForestMap.at(ForestMap.ALTAR_GATE) + Vector3(0.5, 0.05, 2.0)
	for i: int in 3:
		await tree.physics_frame
	assert_eq(s.state.get_flag(ForestExplore.FLAG_ALTAR), true)
	assert_eq(s.quests.stage_of("ch1_main"), "altar_arrive", "下一段：廢棄祭壇")
	assert_eq(str(_game().get("last_level_request")), "ruined_altar", "換到祭壇那一關")
	assert_true(s.has_save() and s.state.checkpoint == "ch1_altar", "換關卡之前存檔")
	await tree.physics_frame
	assert_true(hud.checklist_lines().is_empty(), "清單收起來")


## 探索開放之後讀檔（或倒下重來）：從史萊姆空地開始，席菈在旁邊，採過的毒蕈不會再長出來。
func test_continue_during_exploration_starts_at_the_glade_without_picked_mushrooms() -> void:
	_new_game_joined()
	var s: GameSession = _session()
	for flag: String in [CorruptForest.FLAG_REVERSAL, CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		s.set_flag(flag, true)
	s.state.set_flag("ch1.mushroom_2", true)
	s.add_flag(ForestExplore.FLAG_MUSHROOMS, 1)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	assert_true(player.global_position.distance_to(ForestExplore.RESPAWNS["glade"] as Vector3) < 0.5, "從空地開始：%s" % str(player.global_position))
	assert_true(level.sera.global_position.distance_to(player.global_position) < 4.0, "席菈在旁邊")
	assert_eq(level.explore.mushrooms_left(), ForestExplore.MUSHROOM_SPOTS.size() - 1, "採過的那一朵不在")
	assert_true(level.explore.mushrooms[1] == null)
	assert_eq(level.slimes.size(), 0)
	for i: int in 5:
		await tree.physics_frame
	assert_true((level.get_node("Hud") as Hud).checklist_lines()[0].begins_with("[1/5]"))
	# 探索中可以往北走
	player.global_position = Vector3(0, 0.05, -30.0)
	for i: int in 3:
		await tree.physics_frame
	assert_true(player.global_position.z < -29.0, "探索開放之後過得去")


## 劇本時段 B 的三種陷阱——都要故意踩進去：毒氣噴發口（中毒 → 回血）、麻痺蜘蛛網（麻痺＋緩速 → 出手加速＋跑得更快）、
## 腐敗野果（衰弱＋中毒 → 砍得更重＋回血）。第一次踩席菈各喊一句。
func test_traps_are_supplies_vent_web_and_rotten_fruit() -> void:
	_new_game_joined()
	var s: GameSession = _session()
	for flag: String in [CorruptForest.FLAG_REVERSAL, CorruptForest.FLAG_GATE_TALK, CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		s.set_flag(flag, true)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var explore: ForestExplore = level.explore
	assert_eq(explore.vents.size(), ForestExplore.VENT_SPOTS.size())
	assert_eq(explore.webs.size(), ForestExplore.WEB_SPOTS.size())
	assert_eq(explore.bushes.size(), ForestExplore.BUSH_SPOTS.size())
	for trap: Node3D in explore.vents + explore.webs + explore.bushes:
		assert_true(ForestMap.trail_distance(ForestMap.flat(trap.global_position)) < 3.5, "陷阱在路邊或空地上，不在樹林深處：%s" % trap.name)
	# 毒氣噴發口
	player.health.hp = 30.0
	player.global_position = explore.vents[0].global_position + Vector3(0.3, 0.05, 0.0)
	for i: int in 40:
		await tree.physics_frame
	assert_eq(player.status_effects.source_of("poison"), "vent_gas", "站在噴發口上中毒")
	assert_true(player.health.hp > 30.0, "對諾恩是回血（%.1f）" % player.health.hp)
	assert_true(hud.bark_keys().has("BARK_SERA_VENT"), "席菈喊一句")
	assert_true(level.sera.masked or not explore.vents[0].contains(level.sera.global_position), "席菈不會沒戴面具站在毒氣裡")
	# 麻痺蜘蛛網：穿過去黏一次；站在網裡不會一直疊；走開再回來才再黏
	var web: WebTrap = explore.webs[0]
	var across: Vector3 = web.global_basis.x
	player.global_position = web.global_position + across * 2.5 + Vector3(0, 0.05, 0)
	for i: int in 3:
		await tree.physics_frame
	assert_eq(web.snares, 0, "還沒碰到")
	player.global_position = web.global_position + across * 0.2 + Vector3(0, 0.05, 0)
	for i: int in 30:
		await tree.physics_frame
	assert_eq(web.snares, 1, "碰到網黏一次，站著不會一直疊")
	assert_true(_playing(web, WebTrap.SNARE_SFX), "黏住是絲被扯開的聲音")
	assert_true(player.status_effects.has("paralysis") and player.status_effects.has("slow"), "麻痺＋緩速")
	assert_false(player.status_effects.blocks_attack(), "諾恩不會被定住")
	assert_true(player.status_effects.attack_speed() > 1.4 and player.status_effects.move_speed_scale() > 1.1,
		"出手加速＋跑得更快（×%.2f、×%.2f）" % [player.status_effects.attack_speed(), player.status_effects.move_speed_scale()])
	assert_true(hud.bark_keys().has("BARK_SERA_WEB"))
	player.global_position = web.global_position + across * 3.0 + Vector3(0, 0.05, 0)
	for i: int in 3:
		await tree.physics_frame
	player.global_position = web.global_position + Vector3(0, 0.05, 0)
	for i: int in 3:
		await tree.physics_frame
	assert_eq(web.snares, 2, "走開再撞一次：再黏一次")
	assert_true(player.status_effects.rate("slow") >= 2.0, "緩速疊到兩層")
	# 跑得更快是真的：往前跑一秒，比沒有緩速的時候遠
	var bush: Interactable = explore.bushes[0]
	player.global_position = bush.global_position + Vector3(1.2, 0.05, 0.0)
	await tree.physics_frame
	assert_false(bush.interact_hint().is_empty(), "走近野果叢有提示")
	bush.use(player)
	assert_true(player.status_effects.has("weakness"), "吃了衰弱")
	assert_true(player.status_effects.damage_dealt_scale() > 1.1, "對諾恩是砍得更重（×%.2f）" % player.status_effects.damage_dealt_scale())
	assert_true(hud.bark_keys().has("BARK_SERA_FRUIT"))
	assert_true(_playing(level, ForestExplore.FRUIT_SFX), "吃下去是咬一口的聲音（不再借噴毒的嘶聲）")
	await tree.physics_frame
	assert_false(bush.enabled, "剛吃過，要等它再長")
	assert_false((bush.get_node("PickupRing") as Node3D).visible, "吃過的那一叢腳下的光圈收起來")
	bush.use(player)
	assert_true(absf(player.status_effects.rate("weakness") - 1.0) < 0.01, "還沒長出來不能連吃")
	explore._regrow[0] = 0.02
	for i: int in 4:
		await tree.physics_frame
	assert_true(bush.enabled, "過一下子再長出來")
	assert_true((bush.get_node("PickupRing") as Node3D).visible, "長出來了光圈又出現")
	assert_eq(hud.status.rows.size(), 4, "狀態列四格：中毒、麻痺、緩速、衰弱")


## 野外的三種新敵人，各餵諾恩一種不同的增益：黴菌史萊姆（衰弱 → 砍得更重）、瘴氣狼（流血 → 出手加速）、
## 孢子樹人（緩速＋致盲 → 跑得更快＋刀刀砍中要害）。一群打倒就記下來、存檔，讀檔不會再生。
func test_forest_enemies_each_feed_norn_a_different_boon() -> void:
	_new_game_joined()
	var s: GameSession = _session()
	for flag: String in [CorruptForest.FLAG_REVERSAL, CorruptForest.FLAG_GATE_TALK, CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		s.set_flag(flag, true)
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	var player: PlayerController = level.get_node("Player") as PlayerController
	var explore: ForestExplore = level.explore
	level.sera.set_physics_process(false)
	assert_eq(explore.packs.size(), ForestExplore.PACKS.size(), "四群都在")
	var everyone: Array[EnemyActor] = []
	for pack_id: String in explore.packs:
		for e: EnemyActor in (explore.packs[pack_id] as Array):
			everyone.append(e)
			e.set_physics_process(false)
			assert_true(e.rim_surface_count() > 0 and e.glow_light() != null, "%s 身上有毒的螢光綠" % e.name)
			assert_true(e.health.max_hp == CombatTuning.num(e.tuning_id() + ".max_hp"), "%s 的數值在資料表裡" % e.name)
			assert_true(ForestMap.clearing_distance(ForestMap.flat(e.global_position)) < 0.0, "%s 站在空地上" % e.name)
	# 黴菌史萊姆：撞到衰弱
	var mold: MoldSlime = (explore.packs["traps"] as Array)[0] as MoldSlime
	mold.set_physics_process(true)
	player.global_position = mold.global_position + Vector3(0, 0.05, 1.2)
	for i: int in 300:
		await tree.physics_frame
		if player.status_effects.has("weakness"):
			break
	assert_eq(player.status_effects.source_of("weakness"), "mold_touch", "被黴菌史萊姆撞到：衰弱")
	assert_true(player.status_effects.damage_dealt_scale() > 1.0, "對諾恩是砍得更重")
	# 打倒牠再試下一種（停在出招那一格的敵人會一直佔著「同時只有一個人出手」的名額）
	mold.health.apply_damage(9999.0, {"source": player})
	# 瘴氣狼：從遠處追上來（比諾恩小跑快），咬到流血
	var wolf: MiasmaWolf = (explore.packs["wolves"] as Array)[0] as MiasmaWolf
	wolf.set_physics_process(true)
	player.global_position = wolf.global_position + Vector3(0, 0.05, 9.0)
	var start: float = wolf.global_position.distance_to(player.global_position)
	var trotted: bool = false
	for i: int in 60:
		await tree.physics_frame
		trotted = trotted or wolf.is_trotting()
	var closed: float = start - wolf.global_position.distance_to(player.global_position)
	assert_true(closed > PlayerController.WALK_SPEED * 1.05, "一秒追近 %.1f m，比諾恩小跑快" % closed)
	if PropModels.scene_for(MiasmaWolf.MODEL) != null:
		assert_true(trotted, "跑的時候在播走路的動作")
	for i: int in 300:
		await tree.physics_frame
		if player.status_effects.has("bleed"):
			break
	assert_eq(player.status_effects.source_of("bleed"), "wolf_bite", "被狼咬到：流血")
	assert_true(_playing(wolf, MiasmaWolf.BITE_SFX), "撲上來是低吼＋咬合的聲音（不再借爪擊）")
	assert_eq(wolf.last_notice_sfx, MiasmaWolf.GROWL_SFX, "發現諾恩時低吼一聲")
	assert_eq(wolf.fall_sfx(), MiasmaWolf.YELP_SFX, "倒下時哀叫")
	assert_true(player.status_effects.attack_speed() > 1.0, "對諾恩是出手加速")
	wolf.health.apply_damage(9999.0, {"source": player})
	# 孢子樹人：前兆很長、打不斷，砸到緩速＋致盲
	var treant: SporeTreant = (explore.packs["hollow"] as Array)[0] as SporeTreant
	assert_true(treant.brain.telegraph_sec >= 1.0 and treant.brain.flinch_sec <= 0.0, "樹人前兆長、不會後仰")
	treant.set_physics_process(true)
	player.status_effects.clear("slow")
	player.global_position = treant.global_position + Vector3(0, 0.05, 2.0)
	var swung: bool = false
	var held: bool = false
	for i: int in 400:
		await tree.physics_frame
		swung = swung or treant.puppet().current_state() == "hammer"
		held = held or (treant.brain.state == EnemyBrain.State.TELEGRAPH and treant.puppet().is_holding())
		if player.status_effects.has("blind"):
			break
	assert_true(player.status_effects.has("slow") and player.status_effects.has("blind"), "被樹人砸到：緩速＋致盲")
	assert_true(player.status_effects.strikes_weakpoint() and player.status_effects.move_speed_scale() > 1.0, "對諾恩是刀刀砍中要害＋跑得更快")
	assert_true(swung and held, "前兆是兩手舉過頭停著、再砸下來（有沒有舉到頂停著：%s）" % str(held))
	treant.set_physics_process(false)
	assert_eq(treant.last_notice_sfx, SporeTreant.GROAN_SFX, "醒來時整棵樹被扭的一聲")
	assert_eq(treant.fall_sfx(), SporeTreant.FALL_SFX, "倒下是樹幹裂開砸地")
	# 整群打倒：記旗標、存檔；讀回來那一群不在
	for e: EnemyActor in (explore.packs["wolves"] as Array):
		e.health.apply_damage(9999.0, {"source": player})
	await tree.physics_frame
	await tree.physics_frame
	assert_eq(s.state.get_flag(ForestExplore.pack_flag("wolves")), true, "狼群清掉了")
	assert_false(explore.packs.has("wolves"))
	assert_eq(s.state.get_flag(ForestExplore.pack_flag("hollow"), false), false, "別群不受影響")
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(again.state.get_flag(ForestExplore.pack_flag("wolves")), true, "存檔裡記著")


## 探索開放之後的關卡（教學戰與戰後那段話都過了）：後面幾個測試從這裡開始
## 森林有自己的聲音：整片的夜晚（風、蟲、貓頭鷹），營火、每個噴發口、毒沼各自發出循環的聲音（走近才聽得到）。
func test_forest_has_night_ambience_and_fire_vents_and_bog_make_sound() -> void:
	var level: CorruptForest = _load_exploring()
	await tree.physics_frame
	if Sfx.stream(CorruptForest.NIGHT_SFX) == null:
		return
	var night: AudioStreamPlayer = level.get_node_or_null("ForestNight") as AudioStreamPlayer
	assert_not_null(night, "整片的夜晚森林")
	if night != null:
		assert_eq(Ambience.sfx_of(night), "forest_night")
		assert_true(night.playing)
		assert_eq(night.bus, &"SFX", "跟著「音效」音量")
	var explore: ForestExplore = level.explore
	var spots: Array = [[explore.campfire, "FireSound", "campfire_crackle"], [explore.swamp_miasma, "SwampBubble", "swamp_bubble"]]
	for vent: PoisonMist in explore.vents:
		spots.append([vent, "VentHiss", "vent_hiss"])
	for spot: Array in spots:
		var p: AudioStreamPlayer3D = (spot[0] as Node).get_node_or_null(str(spot[1])) as AudioStreamPlayer3D
		assert_not_null(p, "%s 有 %s" % [(spot[0] as Node).name, spot[1]])
		if p != null:
			assert_eq(Ambience.sfx_of(p), str(spot[2]))
			assert_true(p.playing, "%s 在播" % spot[1])
			assert_true(p.global_position.distance_to((spot[0] as Node3D).global_position) < 1.0, "從那個東西發出來")
			assert_eq((p.stream as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD, "會循環")


func _load_exploring() -> CorruptForest:
	_new_game_joined()
	for flag: String in [CorruptForest.FLAG_REVERSAL, CorruptForest.FLAG_GATE_TALK, CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		_session().set_flag(flag, true)
	return _load_level()


## 營火（劇本的營火休息事件）：休息補滿血、之後從營火重來；第一次席菈講她被工坊趕出來的事，兩個回答；
## 講完解鎖連攜——向她要的煙霧彈多一份麻痺（鷹眼＋出手加速）。右上角可選的那一項打勾。
func test_campfire_rest_tells_seras_past_and_unlocks_the_double_brew() -> void:
	var level: CorruptForest = _load_exploring()
	await tree.physics_frame
	var s: GameSession = _session()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var explore: ForestExplore = level.explore
	var sera: Sera = level.sera
	for pack_id: String in explore.packs:
		for e: EnemyActor in (explore.packs[pack_id] as Array):
			e.set_physics_process(false)
	assert_true(explore.campfire.global_position.distance_to(ForestMap.at(ForestMap.CAMP)) < 0.1, "營火在營地中間")
	assert_eq(sera.ask_source, Sera.ASK_SOURCE, "還沒講過：要的是平常的煙霧彈")
	player.health.hp = 35.0
	player.global_position = explore.campfire.global_position + Vector3(1.6, 0.05, 0.6)
	sera.global_position = player.global_position + Vector3(2.0, 0, 1.0)
	await tree.physics_frame
	assert_false(explore.campfire.interact_hint().is_empty(), "走近營火有提示")
	explore.campfire.use(player)
	assert_eq(player.health.hp, player.health.max_hp, "休息補滿血")
	assert_eq(s.state.get_flag(ForestExplore.FLAG_RESPAWN), "camp")
	assert_true(ForestExplore.spawn_point(s.state).distance_to(explore.campfire.global_position) < 5.0, "之後從營火重來")
	assert_true(bool(_game().call("is_in_dialogue")), "第一次休息：席菈開口")
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_eq(runner.current_text(), "DLG_CH1_CAMP_001")
	await tree.physics_frame
	assert_true(explore.campfire.interact_hint().is_empty(), "講話中沒有提示")
	for i: int in 4:
		runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_CAMP_005")
	assert_eq(runner.visible_choices.size(), 2, "安慰或鼓勵")
	assert_true(runner.choose(1))
	assert_eq(runner.current_text(), "DLG_CH1_CAMP_B")
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_CAMP_END")
	runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")))
	assert_eq(s.state.get_flag(ForestExplore.FLAG_CAMP_TALK), true)
	assert_eq(s.state.get_flag("ch1.campfire_answer"), "encourage")
	assert_eq(int(s.state.get_flag("sera.affinity", 0)), 10, "好感度加了")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_DUO_LINE1", "CH1_DUO_LINE2"]), "解鎖連攜")
	for i: int in 3:
		await tree.physics_frame
	assert_true(hud.checklist_lines()[1].begins_with(tr("HUD_LIST_DONE").get_slice(" ", 0)), "清單上營火那一項完成：%s" % hud.checklist_lines()[1])
	assert_eq(sera.ask_source, ForestExplore.DUO_SOURCE, "向她要的煙霧彈換成連攜的")
	assert_true(sera.ask())
	var frames: int = 0
	while sera.vials_fired == 0 and frames < 120:
		await tree.physics_frame
		frames += 1
	var vial: SeraVial = sera.last_vial
	assert_eq(vial.source, ForestExplore.DUO_SOURCE)
	for i: int in int(CombatTuning.num("sera.vial_flight") * 60.0) + 6:
		await tree.physics_frame
	assert_true(player.status_effects.strikes_weakpoint() and player.status_effects.attack_speed() > 1.5,
		"連攜：刀刀砍中要害＋出手加速（×%.2f）" % player.status_effects.attack_speed())
	# 探索的時候向她要的有兩瓶：換一瓶的按鍵換成【劇毒大紅水】；射的是按下去時選的那一瓶
	assert_eq(sera.ask_extra, ForestExplore.SERA_VIALS[1], "探索的時候也可以要紅的那一瓶")
	sera.brain.ask_left = 0.0
	for i: int in 3:
		await tree.physics_frame
	assert_true(hud.hint_text().contains(tr("VIAL_DOUBLE_BREW")) and hud.hint_text().contains("[E]"),
		"左上寫現在要的是連攜的那一瓶、換一瓶按哪個鍵：%s" % hud.hint_text())
	assert_true(sera.switch_pick(), "有第二瓶可以換")
	await tree.physics_frame
	assert_true(hud.hint_text().contains(tr("VIAL_DEADLY_RED")), "換成紅的那一瓶：%s" % hud.hint_text())
	var before: int = sera.vials_fired
	assert_true(sera.ask())
	assert_true(hud.bark_keys().has("BARK_SERA_ASK_RED"), "她回的是紅的那一瓶的話")
	assert_true(sera.switch_pick(), "舉弩的時候換回來")
	frames = 0
	while sera.vials_fired == before and frames < 120:
		await tree.physics_frame
		frames += 1
	assert_eq(sera.last_vial.source, ForestExplore.SERA_VIALS[1], "射的還是按下去時選的那一瓶")
	assert_eq(sera.ask_choice(), ForestExplore.DUO_SOURCE, "下一次要的是換回來的那一瓶")
	# 再休息一次：不再講，只是休息
	explore.campfire.use(player)
	assert_false(bool(_game().call("is_in_dialogue")), "只講一次")
	assert_eq(hud.banner_text(), "CH1_RESTED")
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_eq(again.state.get_flag(ForestExplore.FLAG_DUO), true, "存檔裡記著連攜")


## 毒沼最深處的詛咒寶箱（劇本）：打開中【衰弱詛咒】（三層衰弱 → 砍得更重）、拿到【不祥的裂刃】（每砍中一刀流血＋衰弱）。
## 讀檔之後手上還是裂刃、寶箱不能再開。席菈在探索時輪流射兩種藥。
func test_cursed_chest_in_the_bog_curses_norn_and_hands_him_the_split_blade() -> void:
	var level: CorruptForest = _load_exploring()
	await tree.physics_frame
	var s: GameSession = _session()
	var player: PlayerController = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	var explore: ForestExplore = level.explore
	var sera: Sera = level.sera
	for pack_id: String in explore.packs:
		for e: EnemyActor in (explore.packs[pack_id] as Array):
			e.set_physics_process(false)
	await tree.physics_frame
	# 席菈：探索的時候輪流射兩種
	assert_eq(sera.vial_cycle, ForestExplore.SERA_VIALS, "探索開放之後她有兩種藥輪流射")
	var first: SeraVial = sera.fire()
	var second: SeraVial = sera.fire()
	assert_eq(first.source, ForestExplore.SERA_VIALS[0])
	assert_eq(second.source, ForestExplore.SERA_VIALS[1], "第二瓶是劇毒大紅水")
	assert_true(second.liquid != first.liquid, "顏色不一樣")
	assert_true(hud.bark_keys().has("BARK_SERA_RED"), "第一次射紅的喊一句")
	for i: int in 50:
		await tree.physics_frame
	player.status_effects.clear("weakness")
	# 毒沼
	assert_eq(player.weapon_id, PlayerController.DEFAULT_WEAPON, "一開始拿的是生鏽鐵劍")
	assert_true(ForestMap.in_swamp(ForestMap.flat(explore.chest.global_position)), "寶箱在毒沼裡")
	player.status_effects.clear("poison")
	player.global_position = ForestMap.at(ForestMap.SWAMP) + Vector3(1.0, 0.05, 0.0)
	for i: int in 30:
		await tree.physics_frame
	assert_eq(player.status_effects.source_of("poison"), "swamp_miasma", "毒沼上面是瘴氣")
	# 寶箱
	player.global_position = explore.chest.global_position + Vector3(-1.2, 0.05, 1.0)
	await tree.physics_frame
	assert_false(explore.chest.interact_hint().is_empty(), "走近寶箱有提示")
	var old_weapon: Node3D = player.weapon()
	explore.chest.use(player)
	assert_eq(player.status_effects.source_of("weakness"), ForestExplore.CHEST_SOURCE, "中了衰弱詛咒")
	assert_true(absf(player.status_effects.rate("weakness") - 3.0) < 0.01, "一次三層")
	assert_true(player.status_effects.damage_dealt_scale() > 1.3, "對諾恩是砍得更重（×%.2f）" % player.status_effects.damage_dealt_scale())
	assert_true(player.reversal_cue.is_playing(), "反轉的回饋自己播了")
	assert_eq(player.weapon_id, ForestExplore.CHEST_WEAPON, "拿到不祥的裂刃")
	assert_eq(player.on_hit_source, "split_blade_cut")
	assert_true(player.weapon() != null and player.weapon() != old_weapon and player.puppet().hand("R").has_node("Weapon"), "手上換了一把")
	assert_true(player.weapon_damage_mult() > 1.0, "裂刃比較痛（×%.2f）" % player.weapon_damage_mult())
	assert_eq(s.state.get_flag(ForestExplore.FLAG_CHEST), true)
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_CHEST_LINE1", "CH1_CHEST_LINE2"]))
	assert_true(hud.bark_keys().has("BARK_SERA_CHEST"))
	assert_true(_playing(level, ForestExplore.CHEST_SFX), "掀開箱蓋的聲音")
	await tree.physics_frame
	assert_true(hud.checklist_lines()[2].begins_with(tr("HUD_LIST_DONE").get_slice(" ", 0)), "清單上「異常波動」完成：%s" % hud.checklist_lines()[2])
	assert_false(explore.chest.enabled, "開過了")
	explore.chest.use(player)
	assert_true(absf(player.status_effects.rate("weakness") - 3.0) < 0.01, "不能再開一次")
	# 用裂刃砍中東西：流血＋衰弱各多一層
	var mold: EnemyActor = (explore.packs["swamp"] as Array)[0] as EnemyActor
	player.global_position = mold.global_position + Vector3(0, 0.05, 1.3)
	player.yaw = 0.0
	await tree.physics_frame
	var hp0: float = mold.health.hp
	player.start_attack()
	for i: int in 30:
		await tree.physics_frame
	assert_true(mold.health.hp < hp0, "砍中了")
	assert_true(player.status_effects.has("bleed") and absf(player.status_effects.rate("weakness") - 4.0) < 0.01,
		"裂刃每砍中一刀：流血＋一層衰弱（衰弱 %.0f 層）" % player.status_effects.rate("weakness"))
	# 讀檔：手上還是裂刃，寶箱開過了
	level.free()
	_level = null
	_game().set("session", GameSession.new(QuestDB.load_default(), _dir))
	assert_eq(_session().load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	var level2: CorruptForest = _load_level()
	await tree.physics_frame
	var player2: PlayerController = level2.get_node("Player") as PlayerController
	assert_eq(player2.weapon_id, ForestExplore.CHEST_WEAPON, "讀檔之後還拿著裂刃")
	assert_eq(player2.on_hit_source, "split_blade_cut")
	assert_false(level2.explore.chest.enabled, "寶箱不能再開")


## 從頭走一遍（不直接設旗標，只搬動諾恩、按掉對話、把敵人打倒）：新遊戲 → 遇到席菈結伴 → 瘴氣反轉 → 兩人講話 → 三隻史萊姆 →
## 戰後對話 → 探索解鎖 → 採五朵夜光毒蕈 → 慘叫 → 走到祭壇路口 →「未完待續」。每一段接得起來、中間不會卡住。
func test_walkthrough_from_new_game_to_the_end_of_chapter_one() -> void:
	_game().call("new_game", false)
	var s: GameSession = _session()
	# 公會大廳：登錄 → 水晶警報 → 雷歐 → 委託 → 席菈開口 → 走出大門
	assert_eq(str(_game().call("level_for_checkpoint", s.state.checkpoint)), "guild_hall")
	var hall: GuildHall = (load("res://scenes/levels/guild_hall.tscn") as PackedScene).instantiate() as GuildHall
	_level_node = hall
	tree.root.add_child(hall)
	await tree.physics_frame
	var player: PlayerController = hall.get_node("Player") as PlayerController
	assert_eq(s.quests.stage_of("ch1_main"), "register")
	player.global_position = Vector3(0.4, 0.05, GuildHall.REGISTER_Z - 0.6)
	await _until_dialogue(10)
	_finish_dialogue(0)
	player.global_position = Vector3(GuildScenery.CRYSTAL_POS.x, 0.05, GuildScenery.STAFF_LINE_Z + 0.6)
	await tree.physics_frame
	await _press_interact()
	assert_true(hall.is_alarm_ringing(), "水晶的警報")
	await _until_dialogue(int(GuildHall.ALARM_TIMEOUT * 60.0) + 60)
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "take_quest", "雷歐走了")
	player.global_position = GuildHall.COUNTER_FRONT
	await tree.physics_frame
	await _press_interact()
	assert_true(bool(_game().call("is_in_dialogue")), "跟莉莉絲說話")
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "sera_asks", "接了委託")
	await _until_dialogue(900)
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "leave_guild", "席菈問過了")
	player.global_position = GuildScenery.DOOR_POS + Vector3(0, 0.05, -0.8)
	for i: int in 3:
		await tree.physics_frame
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera", "走出大門")
	hall.card.finish()
	assert_eq(str(_game().get("last_level_request")), "corrupt_forest")
	# 換到腐敗之森（遊戲裡是 Game 換場景；這裡把大廳放掉、載入森林）
	hall.free()
	var level: CorruptForest = _load_level()
	await tree.physics_frame
	player = level.get_node("Player") as PlayerController
	var hud: Hud = level.get_node("Hud") as Hud
	assert_eq(s.quests.stage_of("ch1_main"), "meet_sera")
	assert_false(level.sera.joined, "席菈先到了、等在瘴氣前面")
	# 會合
	player.global_position = CorruptForest.SERA_WAIT_POS + Vector3(0.6, 0.05, 2.5)
	await _until_dialogue(60)
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "enter_miasma", "結伴了")
	# 走進瘴氣：反轉 → 兩人講幾句
	player.global_position = CorruptForest.MIASMA_POS + Vector3(0, 0.05, 0)
	await _until_dialogue(240)
	assert_eq(s.quests.stage_of("ch1_main"), "slimes", "第一次反轉")
	_finish_dialogue(0)
	# 三隻史萊姆
	player.global_position = CorruptForest.GLADE_POS + Vector3(0, 0.05, 4.0)
	for i: int in 5:
		await tree.physics_frame
	for slime: Slime in level.slimes:
		slime.health.apply_damage(9999.0, {"source": player})
	await _until_dialogue(240)
	assert_eq(s.quests.stage_of("ch1_main"), "after_fight")
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "gather", "探索解鎖")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_EXPLORE_LINE1", "CH1_EXPLORE_LINE2"]))
	# 採五朵（走到每一朵旁邊按互動；路上的敵人先不動）
	for pack_id: String in level.explore.packs:
		for e: EnemyActor in (level.explore.packs[pack_id] as Array):
			e.set_physics_process(false)
	var picked: int = 0
	for i: int in [0, 1, 2, 3, 6]:
		var m: Interactable = level.explore.mushrooms[i]
		player.global_position = m.global_position + Vector3(0.9, 0.05, 0.4)
		await tree.physics_frame
		Input.action_press(Interactable.ACTION)
		await tree.physics_frame
		Input.action_release(Interactable.ACTION)
		await tree.physics_frame
		picked += 1
		assert_eq(int(s.state.get_flag(ForestExplore.FLAG_MUSHROOMS, 0)), picked, "第 %d 朵" % picked)
	assert_eq(s.quests.stage_of("ch1_main"), "to_altar", "採滿：慘叫聲")
	# 往祭壇：走到路口換關卡
	player.global_position = ForestMap.at(ForestMap.ALTAR_GATE) + Vector3(0, 0.05, 1.5)
	for i: int in 4:
		await tree.physics_frame
	assert_eq(s.quests.stage_of("ch1_main"), "altar_arrive", "走到祭壇路口")
	assert_eq(str(_game().get("last_level_request")), "ruined_altar")
	assert_false(player.health.is_dead())
	# 換到廢棄祭壇那一關（遊戲裡是 Game 換場景；這裡把森林放掉、載入祭壇）
	level.free()
	var altar: RuinedAltar = (load("res://scenes/levels/ruined_altar.tscn") as PackedScene).instantiate() as RuinedAltar
	_level_node = altar
	tree.root.add_child(altar)
	await tree.physics_frame
	player = altar.get_node("Player") as PlayerController
	hud = altar.get_node("Hud") as Hud
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_ALTAR")
	# 走上石板：雷歐開口，講完魔像醒來
	player.global_position = Vector3(0, 0.05, RuinedAltar.ARRIVE_Z - 0.5)
	await _until_dialogue(30)
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "boss", "抵達的那段話講完：開打")
	var golem: PlagueGolem = altar.golem
	for i: int in 120:
		await tree.physics_frame
		if golem.awake:
			break
	assert_true(golem.awake, "魔像醒了")
	# 砍到剩一半：狂暴 → 石化凝視，擋在席菈前面 → 她射出禁藥 → 一刀粉碎核心（階段的時間縮短，不真的等十幾秒）
	golem.phases.roar_sec = 0.3
	golem.phases.rage_sec = 0.6
	golem.phases.gaze_sec = 0.8
	golem.health.hp = golem.health.max_hp * 0.5
	for i: int in 400:
		await tree.physics_frame
		player.health.hp = player.health.max_hp
		if golem.phases.phase == GolemPhases.Phase.GAZE:
			break
	assert_eq(golem.phases.phase, GolemPhases.Phase.GAZE, "狂暴之後擺石化凝視")
	altar.sera.global_position = altar.sera.hold_at
	player.global_position = golem.global_position.lerp(altar.sera.global_position, 0.6) + Vector3(0, 0.05, 0)
	for i: int in 400:
		await tree.physics_frame
		if golem.phases.core_open:
			break
	assert_true(golem.phases.blocked and golem.phases.core_open, "擋住了凝視，禁藥砸中")
	var to_golem: Vector3 = golem.global_position - player.global_position
	player.global_position = golem.global_position - to_golem.normalized() * 2.0
	player.yaw = atan2(-to_golem.x, -to_golem.z)
	await tree.physics_frame
	player.start_attack()
	for i: int in 60:
		await tree.physics_frame
		if golem.health.is_dead():
			break
	assert_true(golem.health.is_dead(), "粉碎核心")
	assert_eq(s.quests.stage_of("ch1_main"), "after_boss")
	_game().call("cancel_hit_stop")
	# 戰後那段話講完：拿到核心，一張卡，換回公會大廳
	await _until_dialogue(int(RuinedAltar.AFTER_TALK_DELAY * 60.0) + 90)
	_finish_dialogue(0)
	assert_eq(s.quests.stage_of("ch1_main"), "report", "打倒魔像、講完話：回公會")
	assert_false(player.health.is_dead())
	for i: int in int(RuinedAltar.RETURN_DELAY * 60.0) + 30:
		await tree.physics_frame
		if altar.card != null:
			break
	assert_not_null(altar.card, "換回公會的那張卡")
	altar.card.finish()
	assert_eq(str(_game().get("last_level_request")), "guild_hall")
	altar.free()
	hall = (load("res://scenes/levels/guild_hall.tscn") as PackedScene).instantiate() as GuildHall
	_level_node = hall
	tree.root.add_child(hall)
	await tree.physics_frame
	player = hall.get_node("Player") as PlayerController
	hud = hall.get_node("Hud") as Hud
	assert_true(hall.is_epilogue(), "傍晚的公會")
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_REPORT")
	# 走到櫃檯前：結尾那段話 →「第一章　完」→ 回標題
	player.global_position = Vector3(0.2, 0.05, GuildHall.REPORT_Z - 0.5)
	await _until_dialogue(10)
	_finish_dialogue(0)
	assert_true(s.story_finished(), "第一章完")
	for i: int in int(GuildHall.END_CARD_DELAY * 60.0) + 30:
		await tree.physics_frame
		if hall.card != null:
			break
	assert_not_null(hall.card, "章節卡")
	hall.card.finish()
	assert_eq(str(_game().get("last_level_request")), "title")
	# 標題的「繼續」讀得回來
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_true(again.story_finished(), "存檔停在第一章的結尾")
	assert_eq(str(_game().call("level_for_checkpoint", again.state.checkpoint)), "guild_hall")


func _press_interact() -> void:
	Input.action_press(Interactable.ACTION)
	await tree.physics_frame
	Input.action_release(Interactable.ACTION)
	await tree.physics_frame


## 等到有對話開始（最多 max_frames 幀）
func _until_dialogue(max_frames: int) -> void:
	var frames: int = 0
	while not bool(_game().call("is_in_dialogue")) and frames < max_frames:
		await tree.physics_frame
		frames += 1
	assert_true(bool(_game().call("is_in_dialogue")), "等了 %d 幀對話沒有開始" % frames)


## 把現在這段對話按到完（遇到選項選第 pick 個）
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


## node 底下（一層）有沒有正在播 sfx_name 的聲音
## node 底下有沒有正在播這個音效的播放器（3D 的或不分位置的）。音檔沒有產生（缺檔安靜跳過）的時候當成有。
func _playing(node: Node, sfx_name: String) -> bool:
	var want: AudioStream = Sfx.stream(sfx_name)
	if want == null:
		return true
	for c: Node in node.get_children():
		if (c is AudioStreamPlayer3D or c is AudioStreamPlayer) and c.get("stream") == want:
			return true
	return false
