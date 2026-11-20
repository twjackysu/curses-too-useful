class_name RailEvent
extends Node
## 森林裡的斷軌事件（docs/story/chapter-1-expanded.md「自由時段 B｜森林裡那台沒煞車的車」；第一章 ⑥）的劇情。
## 看得到的東西在 RailSite、規則在 RailRescue（純邏輯）。CorruptForest 生出它。
## 流程：岔路口聽到有人在數數 → 木軌盡頭的阿展（對話 ch1_rail_azhan）→ 伸手搆拉桿差半步、席菈放一朵毒蕈試車 → 兩條走法：
##   坡頂放繩：夠快地砍開纏住絞盤的三股藤（踩網吃麻痺；帶暖泥塞省一股）→ 搖絞盤
##   坡底接車：樹人在枯木旁砸地把它震倒（樹人倒了自己砍；帶鐵盾可以架在窄軌上）→ 踩上去頂住車頭
## → 最後一下照跟席菈的約定（ch1.after_slimes_answer：warn_me＝她舉弩等玩家給信號、medicine＝她喊「低頭」自己射）打開車扣，
##   阿展用左手拉回煞車 → 車停回主軌、對話 ch1_rail_saved（兩種金光；最後一句設 ch1.cart_saved）。
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
## 最後那一下的時間軸（秒）：畫面暗一下擺好位置 → 席菈舉弩（等信號／喊低頭之後 DUCK_SEC 秒）→ 藥瓶飛 VIAL_SEC 秒打上車扣
## → 阿展拉煞車 BRAKE_SEC 秒 → 畫面再暗一下，車停回主軌
const DIM: Vector3 = Vector3(0.3, 0.2, 0.35)
const DUCK_SEC: float = 0.8
const VIAL_SEC: float = 0.42
const BRAKE_SEC: float = 1.3
## 等信號最多等這麼久（玩家沒按也會繼續：不卡住）
const SIGNAL_MAX: float = 12.0
## 藤長回來的時候席菈提醒去踩網：隔這麼久才再喊一次
const VINE_BARK_EVERY: float = 9.0

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
var _vial: MeshInstance3D
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
	# `--rail=shield` 那一條準備好了、`--rail=final-top`／`--rail=final-bottom` 進場 1.5 秒後演最後那一下、`--rail=saved` 車停穩了
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
	if demo in ["rope", "final-top"]:
		rescue.rope_free = true
		Game.session.set_flag(FLAG_ROPE, true)
		site.show_vines(RailRescue.VINES)
		site.show_rope_free(true)
	if demo in ["tree", "final-bottom"]:
		rescue.ramp = "tree"
		Game.session.set_flag(FLAG_RAMP, "tree")
		site.topple(false)
	if demo == "shield":
		rescue.ramp = "shield"
		Game.session.set_flag(FLAG_RAMP, "shield")
		site.place_shield()
	if demo.begins_with("final-"):
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			App.burst_start_in(1)
			start_final(demo.trim_prefix("final-")))
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
	azhan_use.enabled = open and not busy and (not met or is_saved())
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
		return
	Game.start_dialogue(MEET_DIALOGUE)


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
	var y: float = RailSite.cart_spot(false).y
	var t: Tween = site.cart.create_tween()
	t.tween_property(site.cart, "position:y", y - 0.06, 0.35)
	t.tween_interval(1.1)
	t.tween_property(site.cart, "position:y", y, 0.3)


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
	if not free:
		hud.show_banner(tr("CH1_RAIL_VINE_CUT").format({"have": rescue.vines_cut, "need": rescue.vines_needed()}), 1.2)
		return
	site.show_vines(RailRescue.VINES)
	site.show_rope_free(true)
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
	Game.session.set_flag(FLAG_RAMP, "tree")
	Sfx.play_at(level, "blunt_weak", RailSite.DEAD_TREE + Vector3.UP, 0.0, 0.05)
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


## 畫面黑的那一刻：諾恩站到位（坡底：橋面上、車頭旁邊；坡頂：絞盤旁、看著車）、席菈到阿展這一邊舉弩、阿展站起來
func _pose_for_final() -> void:
	var cart_at: Vector3 = site.cart.global_position
	if final_route == "bottom":
		player.stand_at(RailSite.stand_spot(), -PI * 0.5)
	else:
		var from: Vector3 = RailSite.WINCH + Vector3(-0.9, player.global_position.y, 0.3)
		player.stand_at(from, atan2(-(cart_at.x - from.x), -(cart_at.z - from.z)))
	sera.global_position = RailSite.SERA_SHOT + Vector3(0, sera.global_position.y, 0)
	sera.hold_at = RailSite.SERA_SHOT
	azhan.pose = ""
	azhan.global_position = RailSite.AZHAN_BRAKE
	azhan.face(cart_at)


func promise_is_signal() -> bool:
	return str(Game.session.state.get_flag(FLAG_PROMISE, "")) == "warn_me"


## 等信號的時候畫面下方的提示（InteractPrompt 問的）
func interact_hint() -> Dictionary:
	if final_step == 2 and promise_is_signal():
		return {"fmt": tr("HINT_RAIL_SIGNAL"), "action": Interactable.ACTION, "progress": -1.0}
	return {}


## 玩家給信號（按鍵，或測試直接叫）
func give_signal() -> void:
	if final_step == 2 and promise_is_signal():
		_fire()


func _tick_final(delta: float) -> void:
	_final_t += delta
	match final_step:
		1:
			if _final_t >= DIM.x + DIM.y + DIM.z:
				final_step = 2
				_final_t = 0.0
				final_camera = FinisherCamera.play_shot(level, RailSite.FINAL_EYE, RailSite.FINAL_AIM, 600.0)
				sera.puppet().play_action("shoot")
				if promise_is_signal():
					hud.show_bark(sera, "BARK_SERA_WAIT", 4.0, Sera.NAME_KEY)
				else:
					hud.show_bark(sera, "BARK_SERA_DUCK", 2.4, Sera.NAME_KEY)
					player.gesture("bow", site.cart.global_position)
		2:
			if promise_is_signal():
				if Input.is_action_just_pressed(Interactable.ACTION) or _final_t >= SIGNAL_MAX:
					_fire()
			elif _final_t >= DUCK_SEC:
				_fire()
		3:
			var k: float = clampf(_final_t / VIAL_SEC, 0.0, 1.0)
			var from: Vector3 = _vial.get_meta("from")
			var to: Vector3 = site.buckle.global_position
			_vial.global_position = from.lerp(to, k) + Vector3.UP * sin(k * PI) * 0.9
			if k >= 1.0:
				_vial.queue_free()
				_vial = null
				Sfx.play_at(level, "vial_shatter", to, -2.0, 0.04)
				site.buckle.visible = false
				# 煞車鬆開：車往下滑一小步就被頂住（坡底）／被繩拉住（坡頂），不再晃
				site.cart_stuck = false
				site.cart.create_tween().tween_property(site.cart, "position:x", RailSite.CART_X - 0.28, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				final_step = 4
				_final_t = 0.0
				azhan.gesture("reach")
				hud.show_bark(azhan, "BARK_AZHAN_BRAKE", 2.4, AZHAN_KEY)
				site.lever.create_tween().tween_property(site.lever, "rotation:z", -0.35, 0.5).set_delay(0.4)
		4:
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


## 席菈擊發：一瓶從弩口飛向車扣（不是射諾恩的那種藥瓶——只是看得到的一顆）
func _fire() -> void:
	final_step = 3
	_final_t = 0.0
	sera.puppet().play_action("shoot")
	var from: Vector3 = sera.crossbow().global_position if sera.crossbow() != null else sera.global_position + Vector3.UP * 1.2
	_vial = MeshInstance3D.new()
	_vial.name = "BuckleVial"
	var ball := SphereMesh.new()
	ball.radius = 0.09
	ball.height = 0.18
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.75, 0.5, 1.0)
	glass.emission_enabled = true
	glass.emission = Color(0.75, 0.5, 1.0)
	glass.emission_energy_multiplier = 2.5
	ball.material = glass
	_vial.mesh = ball
	_vial.set_meta("from", from)
	level.add_child(_vial)
	_vial.global_position = from
	Sfx.play_at(level, "vial_shot", from, -5.0)


## 畫面黑的那一刻：車停回主軌、三個人站到車旁邊；記下走的是哪一條
func _park() -> void:
	if final_camera != null and is_instance_valid(final_camera):
		final_camera.hold_sec = 0.0
	final_camera = null
	Game.session.set_flag(FLAG_ROUTE, final_route)
	_settle()
	player.stand_up()
	player.global_position = Vector3(RailSite.CART_HOME_X + 1.6, 0.05, RailSite.TRACK_Z + 1.5)
	sera.hold_at = Vector3.INF
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
