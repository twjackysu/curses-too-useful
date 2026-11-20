class_name RailEvent
extends Node
## 森林裡的斷軌事件（docs/story/chapter-1-expanded.md「自由時段 B｜森林裡那台沒煞車的車」；第一章 ⑥）的劇情。
## 看得到的東西在 RailSite、規則在 RailRescue（純邏輯）。CorruptForest 生出它。
## 流程：岔路口聽到有人在數數 → 木軌盡頭的阿展（對話 ch1_rail_azhan）→ 伸手搆拉桿差半步、席菈放一朵毒蕈試車 → 兩條走法：
##   坡頂放繩：夠快地砍開纏住絞盤的三股藤（踩網吃麻痺；帶暖泥塞省一股）→ 搖絞盤
##   坡底接車：樹人在枯木旁砸地把它震倒（樹人倒了自己砍；帶鐵盾可以架在窄軌上）→ 踩上去頂住車頭
## → 最後一下照跟席菈的約定（ch1.after_slimes_answer：warn_me＝她舉弩等玩家給信號、medicine＝她喊「低頭」自己射）打開車扣，
##   被車扣壓著的煞車繩甩下來、阿展用左手把它拉到底 → 車停回主軌、對話 ch1_rail_saved（兩種金光；最後一句設 ch1.cart_saved）。
## 講過話、車還沒救下來的時候可以再問阿展一次（照做到哪一步提醒下一步）。
## 任務 gather 階段要「蕈採滿且車停穩」才聽到慘叫（data/quests/ch1_main.json）。
## 劇情旗標：ch1.rail_heard、ch1.azhan_met（對話設）、ch1.cart_tried、ch1.rail_rope、ch1.rail_ramp（"tree"／"shield"）、
## ch1.cart_route（"top"／"bottom"：最後那一下演完了）、ch1.cart_saved（對話設）。

const FLAG_MET: String = "ch1.azhan_met"
const FLAG_TRIED: String = "ch1.cart_tried"
const FLAG_ROPE: String = "ch1.rail_rope"
const FLAG_RAMP: String = "ch1.rail_ramp"
const FLAG_ROUTE: String = "ch1.cart_route"
const FLAG_SAVED: String = "ch1.cart_saved"
const FLAG_PROMISE: String = "ch1.after_slimes_answer"
const MEET_DIALOGUE: String = "ch1_rail_azhan"
const SAVED_DIALOGUE: String = "ch1_rail_saved"
const AZHAN_KEY: String = "SPK_AZHAN"
const CART_KEY: String = "RAIL_CART"
const PLUG_ITEM: String = "warm_mud_plug"
const SHIELD_ITEM: String = "rusty_shield"
## 走到岔路口（陷阱林）這麼近就聽到數數；走到離阿展這麼近他數出聲
const HEAR_DIST: float = 9.0
const COUNT_DIST: float = 15.0
## 頂住車頭的那一下從哪裡踩上去（枯木的斜坡腳下）
const TREE_FOOT: Vector3 = Vector3(53.3, 0.0, -44.9)
## 最後那一下的時間軸（秒）：畫面暗一下擺好位置（坡底：諾恩弓著身頂住車頭；坡頂：從坡頂的鏡頭看他搖絞盤 CRANK_SHOT_SEC 秒、
## 繩放一段、車往下放 CRANK_LOWER 公尺）→ 從阿展這一邊看：席菈舉弩瞄著車扣（等信號／喊低頭之後 DUCK_SEC 秒）→ 藥瓶飛 VIAL_SEC 秒打上車扣
## → 車扣彈開、車往下滑一小步（LURCH：坡底頂著／坡頂繩拉著），煞車繩 CORD_FLY_SEC 秒甩到阿展手上，他 PULL_AT 秒後用左手往下拉
## （拉到一半 HAUL_AT 拉桿倒到底）→ 一共 BRAKE_SEC 秒 → 畫面再暗一下，車停回主軌
const DIM: Vector3 = Vector3(0.3, 0.2, 0.35)
const CRANK_SHOT_SEC: float = 2.4
const CRANK_LOWER: float = 0.3
const DUCK_SEC: float = 0.8
const VIAL_SEC: float = 0.42
const VIAL_ARC: float = 0.4
const LURCH: Vector2 = Vector2(0.28, 0.12)
const CORD_FLY_SEC: float = 0.5
const PULL_AT: float = 0.1
const HAUL_AT: float = 0.75
const BRAKE_SEC: float = 2.3
## 席菈舉著弩等的時候停在 shoot 動作的第幾秒（舉到定位之後、擊發之前）
const AIM_HOLD: float = 0.5
## 等信號最多等這麼久（玩家沒按也會繼續：不卡住）
const SIGNAL_MAX: float = 12.0
## 藤長回來的時候席菈提醒去踩網：隔這麼久才再喊一次
const VINE_BARK_EVERY: float = 9.0
## 砍斷的藤飛出來的碎葉、車扣彈開的火星
const VINE_BITS: Color = Color(0.32, 0.66, 0.28)
const BUCKLE_GOLD: Color = Color(1.0, 0.8, 0.3)

var level: StoryLevel
var player: PlayerController
var hud: Hud
var sera: Sera
var explore: ForestExplore
var site: RailSite
var rescue := RailRescue.new()
var azhan: Npc
var azhan_use: Interactable
var reach_use: Interactable
var vine_knot: Choppable
var winch_use: Interactable
var tree_chop: Choppable
var shield_use: Interactable
var hold_use: Interactable
var weigh_use: Interactable
## 最後那一下的鏡頭（等信號、藥瓶飛、阿展拉煞車都從阿展這一邊看；畫面暗下去停車的時候收掉）
var final_camera: FinisherCamera
## 最後那一下演到哪：0＝沒在演、1＝暗下去擺位置、2＝席菈舉弩（等信號或等低頭）、3＝藥瓶在飛、4＝阿展拉煞車、5＝暗下去停車
var final_step: int = 0
var final_route: String = ""
var _final_t: float = 0.0
## 這一次最後一下：阿展開始拉了嗎、拉到底了嗎
var _pulling: bool = false
var _hauled: bool = false
## 模型不在的時候搖把照時間轉（有模型就照 crank 動作播到哪）
var _crank_t: float = 0.0
## 等信號最多等多久（平常 SIGNAL_MAX；連拍用的開發旗標縮短）
var _signal_max: float = SIGNAL_MAX
var _tree_hinted: bool = false
var _vine_bark_in: float = 0.0
## 最後那一下演的時候先停住的敵人（演完放開）
var _paused_foes: Array[Node] = []


static func create(p_level: StoryLevel, p_player: PlayerController, p_hud: Hud, p_sera: Sera, p_explore: ForestExplore) -> RailEvent:
	var e := RailEvent.new()
	e.name = "RailEvent"
	e.level = p_level
	e.player = p_player
	e.hud = p_hud
	e.sera = p_sera
	e.explore = p_explore
	return e


func _ready() -> void:
	add_to_group(Interactable.GROUP)
	site = RailSite.new()
	level.add_child(site)
	var st: GameState = Game.session.state
	# 面向西邊（玩家走過來的方向；車在他背後——他在數身邊木箱裡的杯子）
	azhan = Npc.create("Azhan", "azhan", RailSite.AZHAN_SEAT, 90.0)
	azhan.doll_colors(Color(0.5, 0.42, 0.3), Color(0.3, 0.42, 0.36))
	azhan.pose = "sit"
	level.add_child(azhan)
	azhan_use = _use("AzhanTalk", RailSite.AZHAN_SEAT, "HINT_TALK_AZHAN", 2.6, _on_azhan_used)
	reach_use = _use("CartReach", RailSite.REACH_SPOT, "HINT_RAIL_REACH", 2.0, _on_reach_used)
	winch_use = _use("WinchCrank", RailSite.WINCH + Vector3(0, 0, 1.0), "HINT_RAIL_WINCH", 2.4, func(_by: PlayerController) -> void: start_final("top"))
	shield_use = _use("ShieldPlace", RailSite.REACH_SPOT + Vector3(0, 0, 0.9), "HINT_RAIL_SHIELD", 2.2, _on_shield_used)
	hold_use = _use("CartHold", TREE_FOOT, "HINT_RAIL_HOLD", 2.4, func(_by: PlayerController) -> void: start_final("bottom"))
	weigh_use = _use("CartWeigh", RailSite.WEIGH_SPOT, "HINT_RAIL_WEIGH", 1.8, _on_weigh_used)
	vine_knot = Choppable.create("VineKnot", RailSite.WINCH)
	vine_knot.chopped.connect(_on_vine_chopped)
	level.add_child(vine_knot)
	tree_chop = Choppable.create("DeadTreeChop", RailSite.DEAD_TREE)
	tree_chop.chopped.connect(_on_tree_chopped)
	level.add_child(tree_chop)
	# 讀檔：照旗標擺回去
	rescue.rope_free = bool(st.get_flag(FLAG_ROPE, false))
	rescue.ramp = str(st.get_flag(FLAG_RAMP, ""))
	if rescue.ramp == "tree":
		site.topple(false)
	elif rescue.ramp == "shield":
		site.place_shield()
	site.show_vines(RailRescue.VINES if rescue.rope_free else 0)
	site.show_rope_free(rescue.rope_free)
	if str(st.get_flag(FLAG_ROUTE, "")) != "":
		_settle()
	for v: Variant in (explore.packs.get("rail_mud", []) as Array):
		if v is SporeTreant:
			(v as SporeTreant).slammed.connect(_on_treant_slam)
	if level is CorruptForest:
		var cam: TalkCamera = (level as CorruptForest).talk_camera
		cam.cast[AZHAN_KEY] = azhan
		cam.cast[CART_KEY] = site.cart
	Game.dialogue_ended.connect(_on_dialogue_ended)
	# 截圖／連拍用（配 `--explore --at=…`）：`--rail=met` 跟阿展講過了、`--rail=tried` 兩條走法開放了、`--rail=rope`／`--rail=tree`／
	# `--rail=shield` 那一條準備好了、`--rail=final-top`／`--rail=final-bottom` 進場 1.5 秒後演最後那一下、`--rail=saved` 車停穩了；
	# `--rail=cut` 進場 1.5 秒後連砍三股藤（繩落下來）、`--rail=fell` 枯木被震倒——都從那一刻開始連拍；
	# `--rail=final-top-signal`／`final-bottom-signal` 是等信號的版本
	var demo: String = str(Game.level_args().get("rail", ""))
	if demo != "":
		_demo(demo)


func _demo(demo: String) -> void:
	if demo == "talk":
		# `--rail=talk`：進場就開始阿展那段話（配 `--talk-skip=N`）
		get_tree().create_timer(0.3).timeout.connect(func() -> void: Game.start_dialogue(MEET_DIALOGUE))
		return
	Game.session.set_flag(FLAG_MET, true)
	if demo == "met":
		return
	Game.session.set_flag(FLAG_TRIED, true)
	if demo in ["rope", "final-top", "final-top-signal"]:
		rescue.rope_free = true
		Game.session.set_flag(FLAG_ROPE, true)
		site.show_vines(RailRescue.VINES)
		site.show_rope_free(true)
	if demo in ["tree", "final-bottom", "final-bottom-signal"]:
		rescue.ramp = "tree"
		Game.session.set_flag(FLAG_RAMP, "tree")
		site.topple(false)
	if demo == "shield":
		rescue.ramp = "shield"
		Game.session.set_flag(FLAG_RAMP, "shield")
		site.place_shield()
	if demo.begins_with("final-"):
		var route: String = demo.trim_prefix("final-")
		if route.ends_with("-signal"):
			# `--rail=final-bottom-signal`：說好「先說一聲」的版本（她舉著弩等信號）；沒有人按，等 2.5 秒就當作給了
			route = route.trim_suffix("-signal")
			Game.session.set_flag(FLAG_PROMISE, "warn_me")
			_signal_max = 2.5
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			App.burst_start_in(1)
			start_final(route))
	if demo == "cut":
		for i: int in RailRescue.VINES:
			get_tree().create_timer(1.5 + 0.25 * float(i)).timeout.connect(func() -> void:
				if i == 0:
					App.burst_start_in(1)
				_on_vine_chopped({}))
	if demo == "fell":
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			App.burst_start_in(1)
			_tree_down(true))
	if demo == "saved":
		Game.session.set_flag(FLAG_ROUTE, "top")
		Game.session.set_flag(FLAG_SAVED, true)
		_settle()


func _use(node_name: String, at: Vector3, hint: String, reach: float, on_used: Callable) -> Interactable:
	var it: Interactable = Interactable.create(node_name, at, hint, reach)
	it.enabled = false
	it.used.connect(on_used)
	level.add_child(it)
	return it


func _flag(key: String) -> bool:
	return bool(Game.session.state.get_flag(key, false))


func is_saved() -> bool:
	return _flag(FLAG_SAVED)


## 最後那一下演完了（車停回主軌；對話可能還沒講）
func is_settled() -> bool:
	return str(Game.session.state.get_flag(FLAG_ROUTE, "")) != ""


func _physics_process(delta: float) -> void:
	if not Game.session.in_story():
		return
	var st: GameState = Game.session.state
	var open: bool = ForestExplore.unlocked(st)
	var met: bool = _flag(FLAG_MET)
	var tried: bool = _flag(FLAG_TRIED)
	var settled: bool = is_settled()
	var busy: bool = final_step != 0
	var working: bool = open and tried and not settled and not busy
	azhan_use.enabled = open and not busy and (not settled or is_saved())
	reach_use.enabled = open and met and not tried
	vine_knot.active = working and not rescue.rope_free
	winch_use.enabled = working and rescue.rope_free
	tree_chop.active = working and rescue.ramp == ""
	shield_use.enabled = working and rescue.ramp == "" and int(st.items.get(SHIELD_ITEM, 0)) > 0
	hold_use.enabled = working and rescue.ramp != ""
	weigh_use.enabled = working and int(st.get_flag(ForestExplore.FLAG_MUSHROOMS, 0)) > 0
	hold_use.position = TREE_FOOT if rescue.ramp == "tree" else RailSite.REACH_SPOT
	rescue.has_plug = int(st.items.get(PLUG_ITEM, 0)) > 0
	if open and not met:
		var here: Vector2 = ForestMap.flat(player.global_position)
		if here.distance_to(Vector2(ForestMap.TRAPS.x, ForestMap.TRAPS.y)) < HEAR_DIST and st.grant_once("ch1.rail_heard"):
			hud.show_center_lines("CH1_RAIL_HEARD_LINE1", "CH1_RAIL_HEARD_LINE2", 6.0)
		if player.global_position.distance_to(azhan.global_position) < COUNT_DIST and st.grant_once("ch1.azhan_count_bark"):
			hud.show_bark(azhan, "BARK_AZHAN_COUNT", 3.6, AZHAN_KEY)
	_vine_bark_in = maxf(_vine_bark_in - delta, 0.0)
	if working and rescue.tick(delta):
		site.show_vines(0)
		# 自動攻擊會一直砍、一直長回來：這一句隔一陣子才再喊
		if _vine_bark_in <= 0.0 and sera.joined:
			_vine_bark_in = VINE_BARK_EVERY
			hud.show_bark(sera, "BARK_SERA_VINES_BACK", 3.4, Sera.NAME_KEY)
	if busy:
		_tick_final(delta)


# ---------------------------------------------------------------- 阿展與「先動手」

func _on_azhan_used(_by: PlayerController) -> void:
	if is_saved():
		hud.show_bark(azhan, "BARK_AZHAN_AFTER", 3.6, AZHAN_KEY)
	elif _flag(FLAG_MET):
		hud.show_bark(azhan, azhan_hint(), 5.0, AZHAN_KEY)
	else:
		Game.start_dialogue(MEET_DIALOGUE)


## 講過話、車還沒救下來：再問他一次，他照現在做到哪一步提醒下一步
func azhan_hint() -> String:
	if not _flag(FLAG_TRIED):
		return "BARK_AZHAN_HINT_REACH"
	if rescue.rope_free:
		return "BARK_AZHAN_HINT_WINCH"
	if rescue.ramp != "":
		return "BARK_AZHAN_HINT_HOLD"
	return "BARK_AZHAN_HINT_WAYS"


## 伸手去搆煞車的拉桿：差半步。席菈把一朵夜光毒蕈放進車架——車往下沉一寸；拿回來又浮上來。兩條走法從這裡開放
func _on_reach_used(by: PlayerController) -> void:
	Game.session.set_flag(FLAG_TRIED, true)
	by.gesture("reach", site.cart.global_position)
	hud.show_banner("CH1_RAIL_SHORT", 2.4)
	get_tree().create_timer(1.3, false, true).timeout.connect(func() -> void:
		if sera.joined:
			hud.show_bark(sera, "BARK_SERA_RAIL_MUSHROOM", 4.2, Sera.NAME_KEY)
		_dip_cart())
	get_tree().create_timer(4.6, false, true).timeout.connect(func() -> void:
		hud.show_center_lines("CH1_RAIL_WAYS_LINE1", "CH1_RAIL_WAYS_LINE2", 8.0, Hud.CENTER_LINE2_COLOR))
	Game.session.autosave()


## 車往下沉一點、再浮回來（放一朵毒蕈上去的重量）
func _dip_cart() -> void:
	var t: Tween = site.create_tween()
	t.tween_property(site, "cart_dip", 0.06, 0.35)
	t.tween_interval(1.1)
	t.tween_property(site, "cart_dip", 0.0, 0.3)


## 自己放一朵採到的毒蕈上去試（劇本：玩家可以自己放一次，看上坡的繩與下坡的泥）：只是看，毒蕈拿得回來
func _on_weigh_used(by: PlayerController) -> void:
	by.gesture("reach", site.cart.global_position)
	_dip_cart()
	hud.show_banner("CH1_RAIL_WEIGH", 3.6)


# ---------------------------------------------------------------- 坡頂放繩

func _on_vine_chopped(_info: Dictionary) -> void:
	if rescue.rope_free:
		return
	var free: bool = rescue.chop_vine()
	site.show_vines(rescue.vines_cut)
	Sfx.play_at(level, "web_stick", RailSite.WINCH + Vector3.UP, -6.0, 0.08)
	# 砍斷的那一股：碎葉往砍的人那一邊飛
	RockDebris.burst(level, RailSite.WINCH + Vector3(0, 0.9, 0), (player.global_position - RailSite.WINCH).normalized() + Vector3.UP, 10, 0.12, VINE_BITS, Vector2(1.5, 4.0), 0.5)
	if not free:
		hud.show_banner(tr("CH1_RAIL_VINE_CUT").format({"have": rescue.vines_cut, "need": rescue.vines_needed()}), 1.2)
		return
	site.show_vines(RailRescue.VINES)
	site.show_rope_free(true, true)
	Game.session.set_flag(FLAG_ROPE, true)
	if rescue.plug_used:
		Game.session.state.items[PLUG_ITEM] = int(Game.session.state.items.get(PLUG_ITEM, 0)) - 1
		hud.show_banner("CH1_RAIL_PLUG_USED", 4.0)
	else:
		hud.show_banner("CH1_RAIL_ROPE_FREE", 3.2)
	Game.session.autosave()


# ---------------------------------------------------------------- 坡底接車

func _tree_down(by_treant: bool) -> void:
	site.topple()
	# 根部裂開的木屑；倒到棧橋上的那一下（RailSite.topple 的 0.9 秒裡第一次碰到約在一半）再揚一次
	RockDebris.burst(level, RailSite.DEAD_TREE + Vector3(0, 0.3, 0), Vector3.UP, 14, 0.15, RailSite.DEAD_BARK * 0.8, Vector2(2.0, 5.0))
	get_tree().create_timer(0.4, false, true).timeout.connect(func() -> void:
		RockDebris.burst(level, Vector3(RailSite.DEAD_TREE.x, RailSite.deck_y(RailSite.DEAD_TREE.x), RailSite.TRACK_Z - 0.5), Vector3.UP, 12, 0.13, RailSite.DEAD_BARK * 0.6, Vector2(1.5, 4.0))
		Sfx.play_at(level, "blunt_weak", RailSite.DEAD_TREE + Vector3(0, 1.5, 3.0), -3.0, 0.05))
	Game.session.set_flag(FLAG_RAMP, "tree")
	Sfx.play_at(level, "treant_fall", RailSite.DEAD_TREE + Vector3.UP, -2.0, 0.05)
	hud.show_banner("CH1_RAIL_TREE_DOWN", 3.2)
	if by_treant and sera.joined:
		hud.show_bark(sera, "BARK_SERA_TREE", 3.4, Sera.NAME_KEY)
	Game.session.autosave()


func _on_treant_slam(at: Vector3) -> void:
	if _flag(FLAG_TRIED) and not is_settled() and rescue.slam(at, RailSite.DEAD_TREE):
		_tree_down(true)


func _on_tree_chopped(_info: Dictionary) -> void:
	var can_fell: bool = explore.pack_alive("rail_mud") == 0
	if rescue.chop_tree(can_fell):
		_tree_down(false)
	elif not can_fell and not _tree_hinted:
		_tree_hinted = true
		hud.show_banner("CH1_RAIL_TREE_HINT", 3.6)


func _on_shield_used(_by: PlayerController) -> void:
	if not rescue.place_shield():
		return
	site.place_shield()
	Game.session.set_flag(FLAG_RAMP, "shield")
	hud.show_banner("CH1_RAIL_SHIELD_SET", 3.2)
	Game.session.autosave()


# ---------------------------------------------------------------- 最後一把煞車

## 最後那一下開始（route＝"top" 搖絞盤放繩／"bottom" 踩上去頂住車頭）。準備還沒好就不演
func start_final(route: String) -> void:
	if final_step != 0 or is_settled():
		return
	if (route == "top" and not rescue.top_ready()) or (route == "bottom" and not rescue.bottom_ready()):
		return
	final_route = route
	final_step = 1
	_final_t = 0.0
	level.lock_for_cutscene(true)
	# 演的這幾秒敵人不動（坡頂的狼、泥灘的樹人不會趁他定在原地的時候咬他）
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e.is_physics_processing():
			e.set_physics_process(false)
			_paused_foes.append(e)
	hud.dim_blink(DIM.x, DIM.y, DIM.z, _pose_for_final)


## 畫面黑的那一刻：諾恩收劍、站到位（坡底：橋面上弓著身頂住車頭；坡頂：握著絞盤的搖把）、席菈到阿展這一邊瞄著車扣、
## 阿展站到斷口邊上；鏡頭切過去（坡頂先看諾恩搖絞盤，再換到阿展這一邊）
func _pose_for_final() -> void:
	player.sheathe(true)
	if final_route == "bottom":
		player.stand_at(RailSite.stand_spot(), -PI * 0.5)
		player.puppet().set_pose("brace", 0.0)
		_cut_to(RailSite.FINAL_EYE, RailSite.FINAL_AIM)
	else:
		player.stand_at(RailSite.crank_spot() + Vector3(0, player.global_position.y, 0), PI * 0.5)
		player.puppet().set_pose("crank", 0.0)
		player.puppet().pose_speed = 1.0
		_crank_t = 0.0
		site.slide_cart(CRANK_LOWER, CRANK_SHOT_SEC, Tween.TRANS_SINE)
		_cut_to(RailSite.CRANK_EYE, RailSite.CRANK_AIM)
	var mark: Vector3 = site.buckle.global_position
	sera.global_position = RailSite.SERA_SHOT + Vector3(0, sera.global_position.y, 0)
	sera.hold_at = RailSite.SERA_SHOT
	sera.hold_look = mark
	sera.rotation.y = atan2(-(mark.x - RailSite.SERA_SHOT.x), -(mark.z - RailSite.SERA_SHOT.z))
	azhan.pose = ""
	azhan.global_position = RailSite.AZHAN_PULL
	azhan.rotation.y = -PI * 0.5
	azhan.face(site.cart.global_position)


## 換鏡位（直接切，不滑回玩家的鏡頭）
func _cut_to(eye: Vector3, aim: Vector3) -> void:
	var old: FinisherCamera = final_camera
	final_camera = FinisherCamera.play_shot(level, eye, aim, 600.0, player.camera())
	if old != null and is_instance_valid(old):
		old.queue_free()


func promise_is_signal() -> bool:
	return str(Game.session.state.get_flag(FLAG_PROMISE, "")) == "warn_me"


## 等信號的時候畫面下方的提示（InteractPrompt 問的；這時候是過場、玩家不能動，所以要 in_cutscene 才顯示得出來）
func interact_hint() -> Dictionary:
	if final_step == 2 and promise_is_signal():
		return {"fmt": tr("HINT_RAIL_SIGNAL"), "action": Interactable.ACTION, "progress": -1.0, "in_cutscene": true}
	return {}


## 玩家給信號（按鍵，或測試直接叫）
func give_signal() -> void:
	if final_step == 2 and promise_is_signal():
		_fire()


## 坡頂：搖把跟著諾恩的手轉（有模型照 crank 動作播到哪；沒有就照時間）
func _turn_crank(delta: float) -> void:
	var phase: float = player.puppet().pose_phase()
	if phase < 0.0:
		_crank_t += delta * player.puppet().pose_speed
		phase = _crank_t / RailSite.CRANK_SEC
	site.set_crank(phase * TAU)


func _tick_final(delta: float) -> void:
	_final_t += delta
	var top: bool = final_route == "top"
	if top and (final_step > 1 or _final_t > DIM.x):
		_turn_crank(delta)
	match final_step:
		1:
			if _final_t >= DIM.x + DIM.y + DIM.z + (CRANK_SHOT_SEC if top else 0.0):
				final_step = 2
				_final_t = 0.0
				if top:
					# 繩放夠了：握著搖把不動，鏡頭換到阿展這一邊
					player.puppet().pose_speed = 0.0
					_cut_to(RailSite.FINAL_EYE, RailSite.FINAL_AIM)
				sera.puppet().play_action("shoot")
				sera.puppet().pause_at(AIM_HOLD)
				if promise_is_signal():
					hud.show_bark(sera, "BARK_SERA_WAIT", 4.0, Sera.NAME_KEY)
				else:
					hud.show_bark(sera, "BARK_SERA_DUCK", 2.4, Sera.NAME_KEY)
					player.puppet().head = "down"
		2:
			if promise_is_signal():
				if Input.is_action_just_pressed(Interactable.ACTION) or _final_t >= _signal_max:
					_fire()
			elif _final_t >= DUCK_SEC:
				_fire()
		3:
			# 藥瓶自己飛（SeraVial），打中發 shattered；沒發（瓶子不見了）也照時間往下走
			if _final_t >= VIAL_SEC + 0.3:
				_on_buckle_hit()
		4:
			if not top:
				player.move_seat(RailSite.stand_spot(site.cart_slide))
			if not _pulling and _final_t >= PULL_AT:
				_pulling = true
				azhan.gesture("pull")
			if not _hauled and _final_t >= HAUL_AT:
				_hauled = true
				site.set_brake(0.45)
				Sfx.play_at(level, "door_creak", site.cart.global_position, -6.0, 0.05)
				hud.show_bark(azhan, "BARK_AZHAN_BRAKE", 2.4, AZHAN_KEY)
			if _final_t >= CORD_FLY_SEC:
				# 繩頭落到他手上了：跟著那隻手（往下拉）
				var hand: Node3D = azhan.puppet.hand("L")
				var grip: Vector3 = hand.global_position if hand != null else RailSite.CORD_CATCH
				site.cord_end = site.cord_end.lerp(grip, minf(delta * 14.0, 1.0))
			if _final_t >= BRAKE_SEC:
				final_step = 5
				_final_t = 0.0
				hud.dim_blink(DIM.x, DIM.y, DIM.z, _park)
		5:
			if _final_t >= DIM.x + DIM.y + DIM.z:
				final_step = 0
				level.lock_for_cutscene(false)
				for e: Node in _paused_foes:
					if is_instance_valid(e):
						e.set_physics_process(true)
				_paused_foes.clear()
				hud.show_banner("CH1_RAIL_SAVED", 3.0)
				Game.start_dialogue(SAVED_DIALOGUE)


## 席菈擊發：一瓶從弩口飛向車扣（跟射諾恩的是同一種瓶子，只是不上狀態；坡底那一條剛好從他耳邊擦過去）
func _fire() -> void:
	final_step = 3
	_final_t = 0.0
	_pulling = false
	_hauled = false
	sera.puppet().release_hold()
	var from: Vector3 = sera.crossbow().global_position if sera.crossbow() != null else sera.global_position + Vector3.UP * 1.2
	SeraVial.launch_at(level, from, site.buckle.global_position, VIAL_SEC, VIAL_ARC).shattered.connect(_on_buckle_hit)
	Sfx.play_at(level, "vial_shot", from, -5.0)


## 藥瓶打上車扣：扣子彈開、車往下滑一小步就被頂住（坡底）／被繩拉住（坡頂），煞車繩甩向阿展
func _on_buckle_hit() -> void:
	if final_step != 3:
		return
	final_step = 4
	_final_t = 0.0
	player.puppet().head = ""
	site.cart_stuck = false
	site.pop_buckle(RailSite.CORD_CATCH, CORD_FLY_SEC)
	site.slide_cart(LURCH.y if final_route == "top" else LURCH.x, 0.3)
	Sfx.play_at(level, "iron_clang", site.cart.global_position, -9.0, 0.05)
	RockDebris.burst(level, site.buckle.global_position, Vector3.UP, 8, 0.07, BUCKLE_GOLD, Vector2(2.0, 5.0), 2.5)


## 畫面黑的那一刻：車停回主軌、三個人站到車旁邊；記下走的是哪一條
func _park() -> void:
	if final_camera != null and is_instance_valid(final_camera):
		final_camera.hold_sec = 0.0
	final_camera = null
	Game.session.set_flag(FLAG_ROUTE, final_route)
	_settle()
	player.puppet().pose_speed = 1.0
	player.puppet().head = ""
	player.stand_up()
	player.sheathe(false)
	player.global_position = Vector3(RailSite.CART_HOME_X + 1.6, 0.05, RailSite.TRACK_Z + 1.5)
	sera.hold_at = Vector3.INF
	sera.hold_look = Vector3.INF
	sera.global_position = Vector3(RailSite.CART_HOME_X + 2.6, sera.global_position.y, RailSite.TRACK_Z + 2.4)
	player.snap_camera()
	Game.session.autosave()


## 車救下來之後的樣子（讀檔也叫）：車在主軌上、阿展站在車旁邊
func _settle() -> void:
	site.park_cart()
	site.show_vines(RailRescue.VINES if rescue.rope_free else 0)
	azhan.pose = ""
	azhan.global_position = RailSite.AZHAN_BRAKE
	azhan.face(site.cart.global_position)


func _on_dialogue_ended(dialogue_id: String) -> void:
	if dialogue_id == SAVED_DIALOGUE:
		Game.session.autosave()
