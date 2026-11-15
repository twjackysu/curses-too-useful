extends TestCase
## 席菈要做什麼（SeraBrain，純邏輯）：跟在諾恩後面的距離、射藥的節奏。場上的席菈在 tests/flow/test_chapter1.gd。

const DT: float = 1.0 / 60.0


func _n(key: String) -> float:
	return CombatTuning.num("sera." + key)


func test_follows_past_far_and_keeps_walking_until_near() -> void:
	var b := SeraBrain.new()
	var mid: float = (_n("follow_near") + _n("follow_far")) * 0.5
	assert_true(_n("follow_near") >= 4.0 and _n("follow_far") <= 6.0, "跟在後面 4～6 m")
	assert_eq(b.follow_speed(mid), 0.0, "一開始就在範圍裡：站著")
	assert_eq(b.follow_speed(_n("follow_far") + 0.5), _n("walk_speed"), "諾恩走遠了就跟上")
	assert_eq(b.follow_speed(mid), _n("walk_speed"), "走到一半不停（不會一步一停）")
	assert_eq(b.follow_speed(_n("follow_near") - 0.1), 0.0, "夠近了停下")
	assert_eq(b.follow_speed(mid), 0.0, "停下之後，諾恩沒走遠就不動")
	assert_eq(b.follow_speed(_n("follow_far") + _n("run_extra") + 1.0), _n("run_speed"), "落後太多用跑的")


func test_no_enemy_no_vial() -> void:
	var b := SeraBrain.new()
	for i: int in 900:
		assert_false(b.tick(DT, false), "附近沒有敵人不射")
	assert_false(b.is_aiming())


func test_first_vial_comes_quickly_then_one_every_interval() -> void:
	var b := SeraBrain.new()
	var times: Array[float] = []
	var stood_still_while_aiming: bool = false
	var t: float = 0.0
	while t < 30.0 and times.size() < 2:
		t += DT
		if b.tick(DT, true):
			times.append(t)
		if b.is_aiming():
			stood_still_while_aiming = b.follow_speed(100.0) == 0.0
	assert_eq(times.size(), 2)
	assert_true(absf(times[0] - (_n("first_vial_delay") + _n("aim_time"))) < 0.05, "開打後很快來第一瓶（含舉弩瞄準）")
	assert_true(absf(times[1] - times[0] - (_n("vial_interval") + _n("aim_time"))) < 0.05, "之後固定間隔")
	assert_true(stood_still_while_aiming, "瞄準的時候不走路")
	assert_true(_n("vial_interval") < float(StatusRules.load_default().source(Sera.VIAL_SOURCE)["duration"]),
		"下一瓶在上一瓶的效果結束前就到：打架時增益不會斷")


func test_fight_over_resets_to_the_quick_first_vial() -> void:
	var b := SeraBrain.new()
	var t: float = 0.0
	while not b.tick(DT, true) and t < 10.0:
		t += DT
	assert_true(absf(b.shot_left - (_n("vial_interval"))) < 0.001)
	b.tick(DT, false)
	assert_true(absf(b.shot_left - (_n("first_vial_delay"))) < 0.001, "敵人都倒了：下一場的第一瓶一樣很快")


func test_a_requested_vial_comes_without_any_enemy() -> void:
	var b := SeraBrain.new()
	assert_true(b.request(), "她答應了")
	assert_false(b.tick(DT, false))
	assert_true(b.is_aiming(), "要了就馬上舉弩")
	var t: float = 0.0
	while not b.tick(DT, false) and t < 5.0:
		t += DT
	assert_true(absf(t - _n("aim_time")) < 0.05, "瞄完就射")
	for i: int in 300:
		assert_false(b.tick(DT, false), "只射要的那一瓶")


## 向她要過一瓶之後她要裝填：ask_cooldown 秒內再要不會答應（也不會偷偷排一瓶），時間到了才可以。
func test_asking_again_has_to_wait_for_her_to_reload() -> void:
	var b := SeraBrain.new()
	assert_true(b.request())
	assert_false(b.request(), "已經答應一瓶了，還沒射")
	var shots: int = 0
	var t: float = 0.0
	while t < _n("ask_cooldown") - 0.2:
		t += DT
		if b.is_aiming():
			assert_false(b.request(), "正舉著弩")
		if b.tick(DT, false):
			shots += 1
			assert_false(b.request(), "剛射完，還在裝填")
	assert_eq(shots, 1, "被拒絕的那幾次沒有偷偷多射")
	assert_false(b.request(), "還差一點")
	for i: int in 30:
		b.tick(DT, false)
	assert_true(b.request(), "裝好了，可以再要")
	assert_true(_n("ask_cooldown") > float(StatusRules.load_default().source(Sera.ASK_SOURCE)["duration"]),
		"要來的增益會斷一下才能再要：不是按著不放就一直有")


## 還沒結伴：往瘴氣走幾步 → 退回原位，一直重複；最近也到不了戴面具的距離
func test_waiting_alone_she_steps_toward_the_miasma_and_back() -> void:
	assert_eq(SeraBrain.hesitate_goal(0.0), SeraBrain.HESITATE_STEP, "一開始就往前走（玩家進場幾秒內看得到她在動）")
	assert_eq(SeraBrain.hesitate_goal(SeraBrain.HESITATE_IN_SEC + 0.1), 0.0, "然後退回原位")
	assert_eq(SeraBrain.hesitate_goal(SeraBrain.HESITATE_CYCLE_SEC + 0.1), SeraBrain.HESITATE_STEP, "再來一次")
	var walk: float = SeraBrain.HESITATE_STEP / SeraBrain.HESITATE_SPEED
	assert_true(SeraBrain.HESITATE_IN_SEC > walk + 1.0, "走到前面之後停下來看一秒以上")
	assert_true(SeraBrain.HESITATE_CYCLE_SEC - SeraBrain.HESITATE_IN_SEC > walk + 1.5, "走回原位、轉回來之後也停一下")

