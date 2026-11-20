extends TestCase
## 斷軌事件的規則（RailRescue）：三股藤要在時間內砍完、暖泥塞省一股；枯木被樹人震倒、樹人不在了自己砍、盾牌代替。


## 照平常的出手速度（一刀 0.55 秒）砍不完三股：第三刀之前藤長回來了
func test_three_vines_need_haste() -> void:
	var r := RailRescue.new()
	assert_eq(r.vines_needed(), 3)
	assert_false(r.chop_vine())
	assert_false(r.tick(0.55), "第二刀還來得及")
	assert_false(r.chop_vine())
	assert_true(r.tick(0.55), "第三刀之前藤長回來了")
	assert_eq(r.vines_cut, 0, "從頭來")
	assert_false(r.rope_free)
	# 出手快 150%（一刀 0.22 秒）：三刀都在時間內
	assert_false(r.chop_vine())
	assert_false(r.tick(0.22))
	assert_false(r.chop_vine())
	assert_false(r.tick(0.22))
	assert_true(r.chop_vine(), "第三股砍斷：繩子放下來")
	assert_true(r.rope_free and r.top_ready())
	assert_false(r.plug_used)
	assert_false(r.tick(5.0), "放下來之後藤不會再長")


## 帶著暖泥塞只要砍兩股：平常的出手速度就夠
func test_warm_mud_plug_skips_the_last_vine() -> void:
	var r := RailRescue.new()
	r.has_plug = true
	assert_eq(r.vines_needed(), 2)
	assert_false(r.chop_vine())
	assert_false(r.tick(0.55))
	assert_true(r.chop_vine())
	assert_true(r.plug_used, "用掉一瓶")


## 枯木：樹人在旁邊砸地才震得倒；樹人還在時自己砍不倒，不在了砍三刀；架了盾就不用枯木
func test_dead_tree_falls_to_a_slam_or_three_chops_and_shield_also_works() -> void:
	var tree_at := Vector3(10, 0, 10)
	var r := RailRescue.new()
	assert_false(r.slam(Vector3(20, 0, 10), tree_at), "砸得太遠")
	assert_false(r.bottom_ready())
	assert_true(r.slam(Vector3(12, 0, 11), tree_at))
	assert_eq(r.ramp, "tree")
	assert_false(r.place_shield(), "已經有斜坡了")
	r = RailRescue.new()
	for i: int in 5:
		assert_false(r.chop_tree(false), "樹人還在：砍不倒")
	assert_eq(r.tree_chops, 0)
	assert_false(r.chop_tree(true))
	assert_false(r.chop_tree(true))
	assert_true(r.chop_tree(true), "第三刀倒")
	r = RailRescue.new()
	assert_true(r.place_shield())
	assert_eq(r.ramp, "shield")
	assert_true(r.bottom_ready())
	assert_false(r.slam(tree_at, tree_at), "架了盾之後枯木不用倒")
