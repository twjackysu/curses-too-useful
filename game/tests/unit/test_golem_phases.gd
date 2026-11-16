extends TestCase
## 魔像這一場戰鬥的階段（GolemPhases）：一半生命狂暴 → 吼 → 狂暴出招 → 凝視 → 擋住了力竭、沒擋住再來一次。


func _phases() -> GolemPhases:
	var p := GolemPhases.new()
	p.enrage_at = 0.5
	p.roar_sec = 2.0
	p.rage_sec = 6.0
	p.gaze_sec = 3.0
	p.spent_sec = 8.0
	p.hp_floor = 0.15
	return p


## 走 seconds 秒（一幀 0.1 秒），回傳這段時間發生的事
func _run(p: GolemPhases, seconds: float, hp: float) -> PackedStringArray:
	var events: PackedStringArray = []
	for i: int in int(round(seconds / 0.1)):
		var e: String = p.tick(0.1, hp)
		if e != "":
			events.append(e)
			if e == "fire":
				break
	return events


func test_tuning_has_the_golem_numbers() -> void:
	CombatTuning.load_tuning()
	var p: GolemPhases = GolemPhases.new().configure()
	assert_true(p.enrage_at > 0.0 and p.enrage_at < 1.0)
	assert_true(p.hp_floor > 0.0 and p.hp_floor < p.enrage_at, "核心粉碎之前的底線比狂暴的門檻低")
	assert_true(p.gaze_sec >= 2.5, "凝視的前兆夠長，來得及跑到席菈前面（%.1f 秒）" % p.gaze_sec)
	assert_true(p.block_width >= 1.0)


func test_enrages_at_half_health_then_roars_rages_and_gazes() -> void:
	var p: GolemPhases = _phases()
	assert_eq(_run(p, 5.0, 0.8), PackedStringArray(), "生命還多：一直是平常的樣子")
	assert_false(p.is_enraged())
	assert_eq(p.floor_ratio(), 0.15, "核心還在：生命打不到底線以下")
	assert_eq(_run(p, 0.1, 0.5), PackedStringArray(["enrage"]), "掉到一半：狂暴")
	assert_true(p.is_enraged() and p.phase == GolemPhases.Phase.ROAR)
	assert_eq(_run(p, 2.0, 0.5), PackedStringArray(["rage"]), "吼完開始狂暴地出招")
	assert_eq(_run(p, 5.0, 0.45), PackedStringArray(), "狂暴中先打一陣子")
	assert_eq(_run(p, 1.1, 0.45), PackedStringArray(["gaze"]), "然後擺石化凝視的前兆")
	assert_eq(p.gaze_progress(), 0.0)
	_run(p, 1.5, 0.45)
	assert_true(absf(p.gaze_progress() - 0.5) < 0.05, "前兆擺到一半")
	assert_eq(_run(p, 2.0, 0.45), PackedStringArray(["fire"]), "時間到：凝視打出去")


func test_unblocked_gaze_comes_again_and_a_blocked_one_spends_the_golem() -> void:
	var p: GolemPhases = _phases()
	_run(p, 0.1, 0.4)
	_run(p, 2.0, 0.4)
	_run(p, 6.1, 0.4)
	assert_eq(_run(p, 3.1, 0.4), PackedStringArray(["fire"]))
	p.resolve_gaze(false)
	assert_eq(p.phase, GolemPhases.Phase.RAGE, "沒擋住：回去狂暴")
	assert_true(p.gazes == 1 and not p.blocked)
	assert_eq(_run(p, 6.1, 0.4), PackedStringArray(["gaze"]), "過一陣子再凝視一次")
	assert_eq(_run(p, 3.1, 0.4), PackedStringArray(["fire"]))
	p.resolve_gaze(true)
	assert_eq(p.phase, GolemPhases.Phase.SPENT, "擋住了：力竭")
	assert_true(p.gazes == 2 and p.blocked)
	p.resolve_gaze(false)
	assert_true(p.blocked and p.gazes == 2, "同一次凝視只算一次")
	assert_eq(_run(p, 8.1, 0.4), PackedStringArray(["recover"]), "跪完站起來")
	assert_eq(_run(p, 20.0, 0.4), PackedStringArray(), "擋住過了就不再凝視")
	p.core_open = true
	assert_eq(p.floor_ratio(), 0.0, "禁藥上身之後核心可以粉碎")


func test_blocking_means_standing_between_the_golem_and_sera() -> void:
	var golem := Vector3(0, 0, 0)
	var sera := Vector3(0, 0, 10)
	assert_true(GolemPhases.blocks(golem, sera, Vector3(0, 0, 5), 1.4), "站在兩人正中間")
	assert_true(GolemPhases.blocks(golem, sera, Vector3(1.2, 0.05, 8.5), 1.4), "偏一點、靠近席菈也算")
	assert_false(GolemPhases.blocks(golem, sera, Vector3(2.0, 0, 5), 1.4), "離那條線太遠")
	assert_false(GolemPhases.blocks(golem, sera, Vector3(0, 0, -2), 1.4), "站在魔像背後不算")
	assert_false(GolemPhases.blocks(golem, sera, Vector3(0, 0, 11), 1.4), "站在席菈後面不算")
	assert_false(GolemPhases.blocks(golem, golem, Vector3(0, 0, 0), 1.4), "兩人疊在一起沒有線")
