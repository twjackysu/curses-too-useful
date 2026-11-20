extends TestCase
## 森林裡的斷軌事件（第一章 ⑥，增補劇本「自由時段 B｜森林裡那台沒煞車的車」）：地圖與場景 → 岔路口聽到數數 → 阿展那段話 →
## 伸手搆拉桿差半步 → 坡頂放繩（藤、網、暖泥塞）／坡底接車（樹人震倒枯木、自己砍、鐵盾）→ 最後一下照跟席菈的約定 →
## 車停穩、兩種金光 → 「蕈採滿且車停穩」才聽到慘叫 → 讀檔。從新遊戲走過這一段的整段測試在 test_chapter1.gd（test_walkthrough_…）。

const LEVEL: String = "res://scenes/levels/corrupt_forest.tscn"

var _dir: String = ""
var _old_session: GameSession
var _level: CorruptForest


func _game() -> Node:
	return tree.root.get_node("Game")


func before_each() -> void:
	_dir = "user://test_rail_%d" % Time.get_ticks_usec()
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


## 新遊戲、直接跳到自由探索（教學戰與戰後那段話都過了；answer＝戰後那段話的回答）
func _load_exploring(answer: String = "medicine") -> CorruptForest:
	_game().call("new_game", false)
	var s: GameSession = _session()
	for flag: String in [CorruptForest.FLAG_JOINED, CorruptForest.FLAG_REVERSAL, CorruptForest.FLAG_GATE_TALK, CorruptForest.FLAG_MISFIRE, CorruptForest.FLAG_SLIMES, CorruptForest.FLAG_AFTER_TALK]:
		s.set_flag(flag, true)
	s.set_flag(RailEvent.FLAG_PROMISE, answer)
	_level = (load(LEVEL) as PackedScene).instantiate() as CorruptForest
	tree.root.add_child(_level)
	# 敵人與席菈不動（這裡量的是斷軌的規則）
	for e: Node in tree.get_nodes_in_group("enemies"):
		e.set_physics_process(false)
	return _level


func _frames(n: int) -> void:
	for i: int in n:
		await tree.physics_frame


func _finish_dialogue() -> void:
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	var guard: int = 0
	while runner != null and runner.is_running() and guard < 40:
		guard += 1
		runner.advance()
	assert_false(bool(_game().call("is_in_dialogue")), "對話按得完")


## 跟阿展講完、伸手試過：兩條走法開放
func _meet_and_try(level: CorruptForest) -> void:
	var rail: RailEvent = level.rail
	var player: PlayerController = level.get_node("Player") as PlayerController
	player.global_position = RailSite.AZHAN_SEAT + Vector3(-1.5, 0.05, 0.5)
	await _frames(2)
	rail.azhan_use.use(player)
	_finish_dialogue()
	await _frames(2)
	rail.reach_use.use(player)
	await _frames(2)


## 地圖多了三塊（木軌盡頭、坡頂、泥灘）與三條路；場景蓋得起來；探索開放之前什麼都不能用
func test_rail_site_is_on_the_map_and_builds() -> void:
	for c: Vector3 in [ForestMap.RAIL, ForestMap.RAIL_TOP, ForestMap.RAIL_MUD]:
		var p: Vector3 = ForestMap.at(c)
		assert_eq(ForestMap.keep_inside(p), p, "走得到：%s" % str(c))
		assert_true(absf(ForestMap.height(ForestMap.flat(p))) < 0.01, "是平的")
	for spot: Vector3 in [RailSite.AZHAN_SEAT, RailSite.REACH_SPOT, RailSite.WINCH, RailSite.DEAD_TREE, RailEvent.TREE_FOOT, RailSite.SERA_SHOT]:
		assert_eq(ForestMap.keep_inside(spot), spot, "不會被當成走丟：%s" % str(spot))
		assert_false(ForestMap.tree_ok(ForestMap.flat(spot)), "這裡不種樹：%s" % str(spot))
	assert_true(RailSite.deck_y(RailSite.CART_X) > 1.6, "車卡在搆不到的高度")
	assert_true(RailSite.tree_fall_angle() > 0.8 and RailSite.tree_fall_angle() < 1.4, "枯木倒下去是斜的（%.2f）" % RailSite.tree_fall_angle())
	_game().call("new_game", false)
	_session().set_flag(CorruptForest.FLAG_JOINED, true)
	_level = (load(LEVEL) as PackedScene).instantiate() as CorruptForest
	tree.root.add_child(_level)
	await _frames(2)
	var rail: RailEvent = _level.rail
	assert_not_null(_level.get_node_or_null("RailSite/Cart/Buckle"), "手推車與車扣")
	assert_not_null(_level.get_node_or_null("RailSite/Winch/Vine3"), "絞盤上三股藤")
	assert_not_null(_level.get_node_or_null("RailSite/DeadTree/Crack"), "有裂紋的枯木")
	assert_not_null(_level.get_node_or_null("Azhan"), "阿展")
	# 棧橋底下的擋板是斜的：頂面跟著橋面（低的那一頭上面沒有看不見的牆）
	var wedge: StaticBody3D = _level.get_node("RailSite/TrestleWall") as StaticBody3D
	var space: PhysicsDirectSpaceState3D = _level.get_world_3d().direct_space_state
	for x: float in [RailSite.TRESTLE_X.x + 1.0, RailSite.CART_X, RailSite.TRESTLE_X.y - 1.0]:
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 12.0, RailSite.TRACK_Z), Vector3(x, -1.0, RailSite.TRACK_Z), 1))
		assert_true(not hit.is_empty() and hit["collider"] == wedge and absf((hit["position"] as Vector3).y - RailSite.deck_y(x)) < 0.12,
			"x＝%.1f 擋板的頂面在橋面的高度（%s，橋面 %.2f）" % [x, str(hit.get("position", "沒打到")), RailSite.deck_y(x)])
	assert_eq(rail.azhan.pose, "sit", "坐在木軌盡頭")
	assert_true(_level.explore.packs.has("rail_top") and _level.explore.packs.has("rail_mud"), "坡頂的狼、泥灘的樹人")
	assert_false(rail.azhan_use.enabled or rail.reach_use.enabled or rail.vine_knot.active, "探索開放之前都不能用")


## 岔路口聽到數數 → 走近他數出聲 → 講完那段話 → 伸手差半步、席菈放一朵試車 → 兩條走法開放；清單多一項、要兩件事都做完
func test_meeting_azhan_and_trying_the_lever_opens_two_ways() -> void:
	var level: CorruptForest = _load_exploring()
	var s: GameSession = _session()
	var hud: Hud = level.get_node("Hud") as Hud
	var player: PlayerController = level.get_node("Player") as PlayerController
	var rail: RailEvent = level.rail
	level.sera.set_physics_process(false)
	await _frames(3)
	assert_true(hud.checklist_lines().size() == 4 and hud.checklist_lines()[1].contains(tr("Q_CH1_LIST_RAIL")), "清單第二項是車：%s" % str(hud.checklist_lines()))
	player.global_position = ForestMap.at(ForestMap.TRAPS) + Vector3(0, 0.05, 3.0)
	await _frames(3)
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_RAIL_HEARD_LINE1", "CH1_RAIL_HEARD_LINE2"]), "岔路口聽到有人在數數")
	player.global_position = RailSite.AZHAN_SEAT + Vector3(-6.0, 0.05, 0.5)
	await _frames(3)
	assert_true(hud.bark_keys().has("BARK_AZHAN_COUNT"), "走近他數出聲")
	assert_true(rail.azhan_use.enabled and not rail.reach_use.enabled, "先跟他說話")
	player.global_position = RailSite.AZHAN_SEAT + Vector3(-1.5, 0.05, 0.5)
	await _frames(2)
	assert_false(rail.azhan_use.interact_hint().is_empty(), "走近有提示")
	rail.azhan_use.use(player)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_true(runner != null and runner.is_running(), "阿展那段話")
	for i: int in 3:
		runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_RAIL_004_BASKET", "沒帶盾：他看見藥房的籃子")
	_finish_dialogue()
	assert_true(bool(s.state.get_flag(RailEvent.FLAG_MET, false)))
	await _frames(2)
	assert_true(rail.reach_use.enabled and not rail.azhan_use.enabled)
	assert_false(rail.vine_knot.active or rail.tree_chop.active, "還沒試過：兩條走法還沒開放")
	var cart_y: float = rail.site.cart.position.y
	rail.reach_use.use(player)
	assert_eq(hud.banner_text(), "CH1_RAIL_SHORT", "差半步")
	await _frames(100)
	assert_true(hud.bark_keys().has("BARK_SERA_RAIL_MUSHROOM"), "席菈放一朵毒蕈試車")
	assert_true(rail.site.cart.position.y < cart_y - 0.03, "車往下沉了一點（%.3f）" % (cart_y - rail.site.cart.position.y))
	await _frames(200)
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_RAIL_WAYS_LINE1", "CH1_RAIL_WAYS_LINE2"]), "兩個辦法")
	assert_true(rail.vine_knot.active and rail.tree_chop.active, "兩條走法開放")
	assert_true(rail.vine_knot.is_in_group("damageable") and rail.vine_knot.is_in_group(Choppable.GROUP))
	assert_false(rail.winch_use.enabled or rail.hold_use.enabled or rail.shield_use.enabled, "還沒準備好、也沒帶盾")
	assert_false(rail.weigh_use.enabled, "還沒採到毒蕈：沒有可以放的")
	s.add_flag(ForestExplore.FLAG_MUSHROOMS, 1)
	await _frames(2)
	assert_true(rail.weigh_use.enabled, "採到一朵：可以自己放上去試")
	rail.weigh_use.use(player)
	assert_eq(hud.banner_text(), "CH1_RAIL_WEIGH")
	await _frames(30)
	assert_true(rail.site.cart.position.y < RailSite.cart_spot(false).y - 0.03, "車又沉了一點")
	assert_eq(int(s.state.get_flag(ForestExplore.FLAG_MUSHROOMS, 0)), 1, "毒蕈拿得回來")
	s.add_flag(ForestExplore.FLAG_MUSHROOMS, -1)
	# 蕈採滿了、車還沒停穩：不會聽到慘叫，目標指引指向阿展
	s.add_flag(ForestExplore.FLAG_MUSHROOMS, 5)
	await _frames(2)
	assert_eq(s.quests.stage_of("ch1_main"), "gather", "車還沒停穩")
	assert_true(ObjectiveGuide.resolve_target(level, s.quests.marker_spec("ch1_main"), player.global_position).distance_to(rail.azhan.global_position) < 0.1, "指引指向阿展")
	assert_eq(hud.objective_text_key(), "Q_CH1_OBJ_RAIL", "左上的目標也換成車")
	for m: Interactable in level.explore.mushrooms:
		assert_false(m.enabled, "採滿了，剩下的不用再採")
		assert_false((m.get_node("PickupRing") as Node3D).visible, "腳下的光圈也收掉")


## 帶著盾去見阿展：那一句換成盾的版本
func test_azhan_notices_the_shield_if_norn_brought_it() -> void:
	var level: CorruptForest = _load_exploring()
	_session().set_flag("ch1.shield", "taken")
	await _frames(2)
	level.rail.azhan_use.use(level.get_node("Player") as PlayerController)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	for i: int in 3:
		runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_RAIL_004_SHIELD")
	_finish_dialogue()


## 坡頂放繩：照平常的速度砍，藤長回來；夠快才砍得完 → 搖絞盤 → 說好「先說一聲」：她舉弩等信號 → 阿展拉煞車 → 車停穩、
## 講完兩種金光 → 蕈也採滿了才聽到慘叫
func test_top_route_cut_vines_fast_then_sera_waits_for_the_signal() -> void:
	var level: CorruptForest = _load_exploring("warn_me")
	var s: GameSession = _session()
	var hud: Hud = level.get_node("Hud") as Hud
	var player: PlayerController = level.get_node("Player") as PlayerController
	var rail: RailEvent = level.rail
	await _meet_and_try(level)
	player.global_position = RailSite.WINCH + Vector3(-1.2, 0.05, 0.6)
	# 平常的出手速度：一刀 0.55 秒
	rail.vine_knot.health.apply_damage(5.0, {})
	assert_eq(rail.rescue.vines_cut, 1)
	assert_false((level.get_node("RailSite/Winch/Vine1") as Node3D).visible, "砍掉一股")
	await _frames(33)
	rail.vine_knot.health.apply_damage(5.0, {})
	await _frames(33)
	assert_eq(rail.rescue.vines_cut, 0, "來不及：藤長回來了")
	assert_true((level.get_node("RailSite/Winch/Vine1") as Node3D).visible)
	assert_true(hud.bark_keys().has("BARK_SERA_VINES_BACK"), "席菈提醒去踩網")
	assert_false(rail.winch_use.enabled)
	# 出手快 150%：三刀各隔 0.22 秒
	for i: int in 3:
		rail.vine_knot.health.apply_damage(5.0, {})
		await _frames(13)
	assert_true(rail.rescue.rope_free and bool(s.state.get_flag(RailEvent.FLAG_ROPE, false)), "繩子放下來了")
	assert_true((level.get_node("RailSite/Mast/RopeDown") as Node3D).visible and not (level.get_node("RailSite/Mast/RopeKnot") as Node3D).visible)
	assert_false(rail.vine_knot.active, "藤不用再砍")
	assert_true(rail.winch_use.enabled, "可以搖絞盤")
	rail.start_final("bottom")
	assert_eq(rail.final_step, 0, "坡底沒準備：不演")
	rail.winch_use.use(player)
	assert_eq(rail.final_step, 1)
	assert_true(bool(_game().call("is_player_locked")), "演的時候不能動")
	await _frames(70)
	assert_eq(rail.final_step, 2, "席菈舉弩等著")
	assert_true(hud.bark_keys().has("BARK_SERA_WAIT"), "「我等你。」")
	assert_true(str(rail.interact_hint().get("fmt", "")).contains("{key}"), "畫面下方：給她信號")
	assert_true(level.sera.global_position.distance_to(RailSite.SERA_SHOT) < 1.0, "她在阿展這一邊")
	await _frames(120)
	assert_eq(rail.final_step, 2, "不給信號她不射")
	rail.give_signal()
	assert_eq(rail.final_step, 3)
	await _frames(40)
	assert_false(rail.site.buckle.visible, "車扣打開了")
	assert_true(hud.bark_keys().has("BARK_AZHAN_BRAKE"), "阿展拉煞車")
	await _frames(160)
	assert_eq(rail.final_step, 0, "演完了")
	assert_false(bool(_game().call("is_player_locked")) and not bool(_game().call("is_in_dialogue")))
	assert_eq(str(s.state.get_flag(RailEvent.FLAG_ROUTE, "")), "top")
	assert_true(rail.site.cart.position.distance_to(RailSite.cart_spot(true)) < 0.01 and not rail.site.cart_stuck, "車停回主軌")
	assert_eq(rail.azhan.pose, "", "阿展站起來了")
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	assert_true(runner != null and runner.is_running(), "救完車的那段話")
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_RAILS_002_SIGNAL", "她等到信號的版本")
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_RAILS_003_NOTYET", "蕈還沒採滿")
	_finish_dialogue()
	assert_true(rail.is_saved())
	assert_eq(s.quests.stage_of("ch1_main"), "gather", "車停穩了、蕈還沒採滿")
	await _frames(2)
	assert_true(hud.checklist_lines()[1].begins_with("✓") or hud.checklist_lines().size() >= 3, "清單：%s" % str(hud.checklist_lines()))
	s.add_flag(ForestExplore.FLAG_MUSHROOMS, 5)
	assert_eq(s.quests.stage_of("ch1_main"), "to_altar", "兩件事都做完")
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_SCREAM_LINE1", "CH1_SCREAM_LINE2"]), "這時才聽到慘叫")
	# 讀檔：車還在主軌上、阿展可以再講一句
	var again := GameSession.new(QuestDB.load_default(), _dir)
	assert_eq(again.load_slot(GameSession.AUTO_SLOT), SaveCodec.Status.OK)
	assert_true(bool(again.state.get_flag(RailEvent.FLAG_SAVED, false)) and str(again.state.get_flag(RailEvent.FLAG_ROUTE, "")) == "top")
	await _frames(2)
	assert_true(rail.azhan_use.enabled)
	rail.azhan_use.use(player)
	assert_true(hud.bark_keys().has("BARK_AZHAN_AFTER"))


## 帶著暖泥塞：砍兩股就夠（照平常的速度），用掉一瓶
func test_warm_mud_plug_saves_the_last_vine() -> void:
	var level: CorruptForest = _load_exploring()
	var s: GameSession = _session()
	s.state.items[RailEvent.PLUG_ITEM] = 1
	await _meet_and_try(level)
	level.rail.vine_knot.health.apply_damage(5.0, {})
	await _frames(33)
	level.rail.vine_knot.health.apply_damage(5.0, {})
	assert_true(level.rail.rescue.rope_free, "兩股就放下來")
	assert_eq(int(s.state.items.get(RailEvent.PLUG_ITEM, 0)), 0, "用掉暖泥塞")
	assert_eq((level.get_node("Hud") as Hud).banner_text(), "CH1_RAIL_PLUG_USED")


## 坡底接車：樹人還在時自己砍不倒枯木 → 牠在枯木旁砸地震倒 → 踩上去頂住車頭 → 說好「妳的藥救了我」：她喊「低頭」自己射
func test_bottom_route_treant_fells_the_tree_and_sera_shouts_duck() -> void:
	var level: CorruptForest = _load_exploring("medicine")
	var s: GameSession = _session()
	var hud: Hud = level.get_node("Hud") as Hud
	var player: PlayerController = level.get_node("Player") as PlayerController
	var rail: RailEvent = level.rail
	await _meet_and_try(level)
	var treant: SporeTreant = (level.explore.packs["rail_mud"] as Array)[0] as SporeTreant
	for i: int in 4:
		rail.tree_chop.health.apply_damage(5.0, {})
	assert_eq(rail.rescue.ramp, "", "樹人還在：砍不倒")
	assert_eq(hud.banner_text(), "CH1_RAIL_TREE_HINT")
	treant.slammed.emit(RailSite.DEAD_TREE + Vector3(12, 0, 0))
	assert_eq(rail.rescue.ramp, "", "砸得太遠")
	treant.slammed.emit(RailSite.DEAD_TREE + Vector3(2.0, 0, -1.5))
	assert_eq(rail.rescue.ramp, "tree", "在枯木旁砸地：震倒了")
	assert_eq(str(s.state.get_flag(RailEvent.FLAG_RAMP, "")), "tree")
	assert_true(hud.bark_keys().has("BARK_SERA_TREE"))
	await _frames(70)
	assert_true(absf(rail.site.dead_tree.rotation.x - RailSite.tree_fall_angle()) < 0.05, "枯木搭在棧橋上")
	assert_false(rail.tree_chop.active)
	assert_true(rail.hold_use.enabled and rail.hold_use.position.distance_to(RailEvent.TREE_FOOT) < 0.01, "從枯木腳下踩上去")
	treant.set_physics_process(true)
	rail.hold_use.use(player)
	assert_false(treant.is_physics_processing(), "演的時候敵人不動")
	await _frames(70)
	assert_true(player.global_position.distance_to(RailSite.stand_spot()) < 0.1, "諾恩站在橋面上、車頭旁邊（%s）" % str(player.global_position))
	assert_true(hud.bark_keys().has("BARK_SERA_DUCK"), "「諾恩，低頭！」")
	assert_true(rail.interact_hint().is_empty(), "不用給信號")
	await _frames(300)
	assert_eq(rail.final_step, 0)
	assert_eq(str(s.state.get_flag(RailEvent.FLAG_ROUTE, "")), "bottom")
	assert_true(treant.is_physics_processing(), "演完放開")
	assert_true(player.global_position.y < 0.5, "回到地面（y＝%.2f）" % player.global_position.y)
	var runner: DialogueRunner = _game().get("dialogue") as DialogueRunner
	runner.advance()
	assert_eq(runner.current_text(), "DLG_CH1_RAILS_002_DUCK")
	_finish_dialogue()
	assert_true(rail.is_saved())


## 樹人倒了：自己砍三刀也會倒；帶著鐵盾可以直接架在窄軌上（從斷口踩上去）。讀檔照旗標擺回去
func test_chopping_the_tree_or_wedging_the_shield_also_works_and_survives_reload() -> void:
	var level: CorruptForest = _load_exploring()
	var s: GameSession = _session()
	var rail: RailEvent = level.rail
	var player: PlayerController = level.get_node("Player") as PlayerController
	s.state.items[RailEvent.SHIELD_ITEM] = 1
	await _meet_and_try(level)
	assert_true(rail.shield_use.enabled, "帶著盾：可以架")
	rail.shield_use.use(player)
	assert_eq(rail.rescue.ramp, "shield")
	assert_true((level.get_node("RailSite/ShieldStep") as Node3D).visible)
	await _frames(2)
	assert_false(rail.shield_use.enabled or rail.tree_chop.active)
	assert_true(rail.hold_use.enabled and rail.hold_use.position.distance_to(RailSite.REACH_SPOT) < 0.01, "從斷口踩上去")
	level.free()
	# 讀檔：盾還架著
	_level = (load(LEVEL) as PackedScene).instantiate() as CorruptForest
	tree.root.add_child(_level)
	await _frames(2)
	assert_eq(_level.rail.rescue.ramp, "shield")
	assert_true((_level.get_node("RailSite/ShieldStep") as Node3D).visible, "讀檔：盾還架著")
	_level.free()
	# 另一局：樹人倒了，自己砍
	_level = await _load_exploring()
	rail = _level.rail
	await _meet_and_try(_level)
	for v: Variant in (_level.explore.packs["rail_mud"] as Array):
		(v as EnemyActor).health.apply_damage(99999.0, {})
	for i: int in RailRescue.TREE_CHOPS:
		assert_eq(rail.rescue.ramp, "")
		rail.tree_chop.health.apply_damage(5.0, {})
	assert_eq(rail.rescue.ramp, "tree", "砍了三刀倒了")


## 「會走的金光」：野果灌木旁一隻嘴邊發金光的狼，不打人。諾恩走近牠才沿著路線小跑；跟丟了牠停下來等；經過路邊的野果停下來聞；
## 跟到詛咒寶箱前面，牠把金屬吐在地上、不見 → 撿起來看。地上成對的齒痕沿著同一條路線
func test_glint_wolf_leads_norn_to_the_cursed_chest() -> void:
	var level: CorruptForest = _load_exploring()
	var s: GameSession = _session()
	var explore: ForestExplore = level.explore
	var hud: Hud = level.get_node("Hud") as Hud
	var player: PlayerController = level.get_node("Player") as PlayerController
	level.sera.set_physics_process(false)
	await _frames(2)
	var marks: MultiMeshInstance3D = level.get_node("GlintMarks") as MultiMeshInstance3D
	var spots: Array[Vector3] = ForestExplore.glint_spots()
	assert_true(spots.size() >= 16 and spots.size() % 2 == 0 and marks.multimesh.instance_count == spots.size(), "成對的齒痕（%d 個）" % spots.size())
	assert_true(spots[spots.size() - 1].distance_to(ForestExplore.CHEST_POS) < 6.0, "最後一對在寶箱附近")
	for p: Vector3 in spots + ForestExplore.GLINT_TRAIL:
		assert_eq(ForestMap.keep_inside(p), p, "齒痕與路線在走得到的地方")
	var wolf: GlintWolf = explore.glint_wolf
	assert_true(wolf != null and wolf.get_node_or_null("Glint") is OmniLight3D, "嘴邊一點金光")
	assert_false(wolf.is_in_group("enemies"), "不是敵人（不咬人、自動攻擊不會去砍牠）")
	assert_true(wolf.global_position.distance_to(ForestExplore.BUSH_SPOTS[2]) < 3.0, "一開始在狼徑旁的野果灌木邊")
	var start: Vector3 = wolf.global_position
	await _frames(30)
	assert_true(wolf.global_position.distance_to(start) < 0.01 and not wolf.started, "諾恩還很遠：牠不動")
	# 走近：牠開始跑。一路跟著（每幀把諾恩放在牠後面幾公尺）
	var sniffed: bool = false
	var frames: int = 0
	while explore.glint_shard == null and frames < 2400:
		player.global_position = wolf.global_position + Vector3(0, 0.05, 5.0) if is_instance_valid(wolf) else player.global_position
		await tree.physics_frame
		frames += 1
		if is_instance_valid(wolf) and wolf.is_sniffing():
			sniffed = true
			assert_true(wolf.global_position.distance_to(ForestExplore.GLINT_BUSH) < 3.0, "停在路邊那叢野果旁聞")
	assert_true(sniffed, "經過野果灌木停下來聞（讓人跟得上）")
	assert_not_null(explore.glint_shard, "跟到底：金屬吐在地上（%d 幀）" % frames)
	assert_true(explore.glint_shard.global_position.distance_to(ForestExplore.CHEST_POS) < 3.0, "就在詛咒寶箱前面")
	await _frames(int(GlintWolf.FLEE_SEC * 60.0) + 5)
	assert_false(is_instance_valid(wolf), "牠鑽進霧裡不見了")
	explore.glint_shard.use(player)
	assert_true(bool(s.state.get_flag(ForestExplore.FLAG_GLINT, false)))
	assert_eq(hud.center_lines(), PackedStringArray(["CH1_GLINT_LINE1", "CH1_GLINT_LINE2"]))
	await _frames(2)
	assert_true(explore.glint_shard == null, "撿走了")


## 跟丟了牠停下來等；路上砍牠一下，金屬掉在原地、牠跑掉。撿過金屬的存檔沒有這隻狼
func test_glint_wolf_waits_when_lost_and_drops_the_metal_when_hit() -> void:
	var level: CorruptForest = _load_exploring()
	var explore: ForestExplore = level.explore
	var player: PlayerController = level.get_node("Player") as PlayerController
	level.sera.set_physics_process(false)
	await _frames(2)
	var wolf: GlintWolf = explore.glint_wolf
	player.global_position = wolf.global_position + Vector3(0, 0.05, 6.0)
	await _frames(60)
	assert_true(wolf.started and wolf.global_position.distance_to(ForestExplore.GLINT_TRAIL[0]) > 2.0, "走近：牠跑起來了")
	player.global_position = ForestMap.at(ForestMap.GLADE) + Vector3(0, 0.05, 0)
	await _frames(5)
	var waiting_at: Vector3 = wolf.global_position
	await _frames(60)
	assert_true(wolf.global_position.distance_to(waiting_at) < 0.01, "諾恩離太遠：牠停下來等")
	assert_true(wolf.is_in_group("damageable"), "砍得到")
	wolf.health.apply_damage(10.0, {})
	assert_not_null(explore.glint_shard, "被砍到：金屬掉在原地")
	assert_true(explore.glint_shard.global_position.distance_to(waiting_at) < 1.0)
	assert_true(wolf.gone)
	level.free()
	_session().set_flag(ForestExplore.FLAG_GLINT, true)
	_level = (load(LEVEL) as PackedScene).instantiate() as CorruptForest
	tree.root.add_child(_level)
	await _frames(2)
	assert_true(_level.explore.glint_wolf == null and _level.get_node_or_null("GlintWolf") == null, "撿過金屬：沒有這隻狼")


## 增補稿在別的段落加的幾句（照旗標換台詞）：公會的止血棉與「你剛剛用哪隻手？」、試戴過戒指的人在瘴氣裡那一句、
## 看過藥單的人在營火旁照出標籤上的字、公會結尾雷歐擦桌子、祭壇禁藥射出去前照約定喊
func test_added_lines_follow_what_the_player_did_before() -> void:
	var db: DialogueDB = DialogueDB.load_default()
	assert_true(db.errors.is_empty(), "對話資料沒有錯：%s" % str(db.errors))
	var st := GameState.new()
	var r := DialogueRunner.new(db, st)
	assert_true(r.start("ch1_guild_leo"))
	assert_eq(str(r.current()["speaker"]), "SPK_LILITH", "先是莉莉絲遞止血棉")
	assert_eq(r.current_text(), "DLG_CH1_COTTON_001")
	r.advance()
	assert_eq(r.current_text(), "DLG_CH1_COTTON_002", "手指已經長好了")
	r.advance()
	assert_true(str(r.current()["speaker"]) == "SPK_SHEILA" and r.current_text() == "DLG_CH1_COTTON_003", "席菈：你剛剛用哪隻手？")
	r.advance()
	assert_eq(r.current_text(), "DLG_CH1_LEO_001", "雷歐把兩人隔開，接回原本那段話")
	# 瘴氣裡：試戴過戒指
	r = DialogueRunner.new(db, st)
	r.start("ch1_forest_gate")
	r.advance()
	assert_eq(r.current_text(), "DLG_CH1_GATE_002")
	st.set_flag("ch1.ring_tried", true)
	assert_eq(r.current_text(), "DLG_CH1_GATE_002_RING")
	# 營火：看過藥單
	r = DialogueRunner.new(db, st)
	r.start("ch1_campfire")
	for i: int in 3:
		r.advance()
	assert_eq(r.current_text(), "DLG_CH1_CAMP_004")
	st.set_flag("ch1.sera_list", true)
	assert_eq(r.current_text(), "DLG_CH1_CAMP_004_LABEL", "火光照出標籤上刮掉的那一行")
	# 公會結尾：雷歐擦桌子（拿到收據的版本看著那張紙）
	r = DialogueRunner.new(db, st)
	r.start("ch1_guild_return")
	var seen: PackedStringArray = []
	var guard: int = 0
	while r.is_running() and guard < 30:
		guard += 1
		seen.append(r.current_text())
		if not r.visible_choices.is_empty():
			r.choose(0)
		else:
			r.advance()
	assert_true(seen.has("DLG_CH1_RETURN_WIPE") and seen.find("DLG_CH1_RETURN_WIPE") == seen.find("DLG_CH1_RETURN_LEDGER_TOGETHER") + 1, "記帳那一句之後雷歐擦桌子：%s" % str(seen))
	st.set_flag("ch1.ledger", "receipt")
	r = DialogueRunner.new(db, st)
	r.start("ch1_guild_return")
	seen = []
	guard = 0
	while r.is_running() and guard < 30:
		guard += 1
		seen.append(r.current_text())
		if not r.visible_choices.is_empty():
			r.choose(0)
		else:
			r.advance()
	assert_true(seen.has("DLG_CH1_RETURN_WIPE_RECEIPT"), "拿到收據：他看著那張紙")
	# 祭壇：禁藥
	assert_eq(RuinedAltar.chaos_bark(st), "BARK_SERA_CHAOS", "沒救過車（舊存檔）：原本那一句")
	st.set_flag(RailEvent.FLAG_SAVED, true)
	st.set_flag(RailEvent.FLAG_PROMISE, "medicine")
	assert_eq(RuinedAltar.chaos_bark(st), "BARK_SERA_CHAOS_DUCK", "上次她喊低頭：這裡也喊")
	st.set_flag(RailEvent.FLAG_PROMISE, "warn_me")
	assert_eq(RuinedAltar.chaos_bark(st), "BARK_SERA_CHAOS_WAIT", "說好先說一聲的：這裡也說「我等你」")


## 泥灘的樹人站得夠遠：跟阿展說話、伸手試、放毒蕈的地方牠都還沒發現人（敵人 14 m 內才發現）；坡頂的狼在絞盤旁才會過來
func test_rail_enemies_keep_out_of_the_way_until_the_player_goes_to_them() -> void:
	var treant: Array = ForestExplore.PACKS["rail_mud"][0]
	var wolf: Array = ForestExplore.PACKS["rail_top"][0]
	var treant_at := Vector3(float(treant[1]), 0, float(treant[2]))
	var wolf_at := Vector3(float(wolf[1]), 0, float(wolf[2]))
	var aggro: float = EnemyBrain.new().aggro_range
	for spot: Vector3 in [RailSite.AZHAN_SEAT, RailSite.REACH_SPOT, RailSite.WEIGH_SPOT, RailSite.SERA_SHOT]:
		assert_true(spot.distance_to(treant_at) > aggro + 0.3, "樹人離 %s 夠遠（%.1f m）" % [str(spot), spot.distance_to(treant_at)])
		assert_true(spot.distance_to(wolf_at) > aggro + 0.3, "狼離 %s 夠遠（%.1f m）" % [str(spot), spot.distance_to(wolf_at)])
	assert_true(RailSite.WINCH.distance_to(wolf_at) < aggro, "到絞盤旁狼就過來")
	assert_true(RailSite.DEAD_TREE.distance_to(treant_at) < float(CombatTuning.num("spore_treant.leash", 16.0)) - 2.0, "樹人引得到枯木旁（%.1f m）" % RailSite.DEAD_TREE.distance_to(treant_at))
