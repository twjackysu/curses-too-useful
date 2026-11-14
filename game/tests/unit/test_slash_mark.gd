extends TestCase
## 刀痕（SlashMark）：朝向照劍掃的方向、劍砍的才有、顏色與大小跟著狀態與連段、自己會收掉。


func test_facing_lies_along_the_cut_as_seen_from_the_eye() -> void:
	# 鏡頭在 +Z，劍往下劈、同時往鏡頭的反方向帶：畫面上是一條直的
	var b: Basis = SlashMark.facing(Vector3(0, -1, -1), Vector3(0, 0, 5))
	assert_true(b.x.is_equal_approx(Vector3.DOWN), "沿著刀痕的軸是劍掃的方向壓到畫面上（%s）" % b.x)
	assert_true(b.z.is_equal_approx(Vector3.BACK), "面朝鏡頭")
	assert_true(absf(b.determinant() - 1.0) < 0.001, "三個軸互相垂直、沒有翻面")
	# 橫掃：一條橫的
	assert_true(absf(SlashMark.facing(Vector3.LEFT, Vector3(0, 1, 5)).x.dot(Vector3.LEFT)) > 0.99, "橫掃是橫的")


func test_facing_falls_back_to_a_diagonal_when_the_cut_points_at_the_eye() -> void:
	for cut: Vector3 in [Vector3(0, 0, -1), Vector3.ZERO]:
		var b: Basis = SlashMark.facing(cut, Vector3(0, 0, 3))
		assert_true(b.x.is_finite() and absf(b.x.length() - 1.0) < 0.001, "有方向（%s）" % b.x)
		assert_true(absf(b.x.x) > 0.5 and absf(b.x.y) > 0.5, "是斜的（%s）" % b.x)
		assert_true(absf(b.x.dot(b.z)) < 0.001, "還是貼在畫面上")
	# 鏡頭從正上方看：也不會算出壞掉的軸
	assert_true(SlashMark.facing(Vector3.DOWN, Vector3.UP).x.is_finite(), "從正上方看")


func test_mark_shoots_out_thins_and_frees_itself() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var mark: SlashMark = SlashMark.spawn(root, Vector3(1, 2, 3), Vector3.DOWN, Vector3.BACK, false, false)
	var big: SlashMark = SlashMark.spawn(root, Vector3.ZERO, Vector3.DOWN, Vector3.BACK, true, true)
	assert_true(mark.global_position.is_equal_approx(Vector3(1, 2, 3)), "在命中點")
	var start: Vector2 = mark.size()
	assert_true(absf(start.x - SlashMark.LENGTH * SlashMark.START_LEN) < 0.001, "一出現就有六成長（打擊停頓時停在這個樣子）")
	assert_true(absf(mark.basis.x.length() - start.x) < 0.001 and absf(mark.basis.y.length() - start.y) < 0.001, "網格拉成那個大小")
	assert_true(big.size().x > start.x * 1.3 and big.size().y > start.y * 1.3, "收尾的那一刀比較長、比較粗")
	var rust: ShaderMaterial = mark.material_override as ShaderMaterial
	var golden: ShaderMaterial = big.material_override as ShaderMaterial
	assert_eq(golden.get_shader_parameter("tint") as Color, SlashTrail.GOLD_TINT, "反轉中是金的（跟劍光同一個顏色）")
	assert_ne(rust.get_shader_parameter("tint") as Color, SlashTrail.GOLD_TINT, "平常不是金的")
	mark._process(SlashMark.SHOOT_SEC)
	assert_true(absf(mark.size().x - SlashMark.LENGTH) < 0.001, "衝到全長")
	assert_true(mark.size().y < start.y, "變細")
	assert_true(float(rust.get_shader_parameter("fade")) < 1.0, "開始淡")
	mark._process(SlashMark.LIFE)
	assert_true(mark.is_queued_for_deletion(), "時間到自己收掉")
	assert_false(big.is_queued_for_deletion(), "收尾的那一刀留得比較久")
	root.queue_free()
	await tree.process_frame


## 史萊姆挨打：帶著劍掃的方向才有刀痕；炸開的毒、藥瓶（沒有方向）只有原本的碎屑與閃光。
func test_only_sword_hits_leave_a_mark() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var slime := Slime.new()
	root.add_child(slime)
	await tree.physics_frame
	slime.health.apply_damage(1.0, {"kind": "burst"})
	assert_not_null(slime.last_hit_fx, "挨打有碎屑與閃光")
	assert_true(slime.last_hit_fx.get_node_or_null("SlashMark") == null, "不是劍砍的：沒有刀痕")
	slime.health.apply_damage(1.0, {"kind": "blunt", "cut": Vector3(-1, -1, 0), "gold": true, "heavy": true})
	var mark: SlashMark = slime.last_hit_fx.get_node_or_null("SlashMark") as SlashMark
	assert_not_null(mark, "劍砍的：有刀痕")
	assert_true(mark.gold and mark.big, "金的、收尾的大小")
	assert_true(mark.global_position.distance_to(slime.last_hit_fx.global_position) < 0.001, "在命中點上")
	root.queue_free()
	await tree.process_frame


## 諾恩真的砍下去：史萊姆身上的刀痕照劍掃的方向（往下劈的那一下主要是往下），第一刀鏽色、反轉之後金色。
func test_norn_strike_marks_the_slime_along_the_blade() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var slime := Slime.new()
	slime.position = Vector3(0, 0, -1.2)
	root.add_child(slime)
	await tree.physics_frame
	assert_true(absf(player.blade_sweep().length() - 1.0) < 0.001, "還沒揮也有一個方向（%s）" % player.blade_sweep())
	var golds: Array[bool] = []
	var alongs: Array[Vector3] = []
	for swing: int in 2:
		var before: int = slime.hit_fx_count
		player.start_attack()
		for i: int in 90:
			await tree.process_frame
			if slime.hit_fx_count > before:
				break
		assert_true(slime.hit_fx_count > before, "第 %d 刀砍中" % (swing + 1))
		var mark: SlashMark = slime.last_hit_fx.get_node_or_null("SlashMark") as SlashMark
		assert_not_null(mark, "第 %d 刀：史萊姆身上有刀痕" % (swing + 1))
		if mark == null:
			break
		golds.append(mark.gold)
		alongs.append(mark.basis.x.normalized())
		for i: int in 60:
			if player.puppet().action != "attack":
				break
			await tree.physics_frame
	assert_eq(golds, [false, true] as Array[bool], "第一刀鏽色（砍中才反轉），第二刀金色")
	if alongs.size() == 2:
		assert_true(absf(alongs[0].y) > 0.8, "往下劈的那一下：刀痕是直的（%s）" % alongs[0])
		assert_true(absf(alongs[1].x) > absf(alongs[0].x) + 0.4, "橫掃的那一下：刀痕斜到橫的那一邊（%s）" % alongs[1])
	root.queue_free()
	await tree.process_frame
