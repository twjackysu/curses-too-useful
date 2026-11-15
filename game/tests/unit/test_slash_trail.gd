extends TestCase
## 揮劍的劍光（SlashTrail）：帶子的形狀、劍尖在哪裡、諾恩出手時有沒有畫出來、顏色與大小跟不跟著狀態與連段。


func test_ribbon_stays_round_between_two_samples() -> void:
	# 劍從朝上轉到朝前（90 度），中間沒有別的取樣：外緣每一點離手都是劍長，不是切過去的一條弦（弦的中點只有 0.71）
	var hands := PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	var tips := PackedVector3Array([Vector3.UP, Vector3.FORWARD])
	var built: Array = SlashTrail.ribbon(hands, tips, Vector2(0.5, 1.0))
	var pts: PackedVector3Array = built[0]
	var along: PackedFloat32Array = built[1]
	assert_true(pts.size() >= 2 * (int(90.0 / SlashTrail.STEP_DEG) + 1), "90 度補了很多段（%d 點）" % pts.size())
	assert_eq(pts.size(), along.size() * 2, "一對一對，每一對有一個位置")
	for i: int in along.size():
		assert_true(absf(pts[i * 2].length() - 0.5) < 0.001, "內緣離手 0.5（第 %d 對：%.3f）" % [i, pts[i * 2].length()])
		assert_true(absf(pts[i * 2 + 1].length() - 1.0) < 0.001, "外緣離手 1.0（第 %d 對：%.3f）" % [i, pts[i * 2 + 1].length()])
		assert_true(i == 0 or along[i] > along[i - 1], "位置一路往後")
	assert_true(pts[1].is_equal_approx(Vector3.UP), "從第一個取樣開始")
	assert_true(pts[pts.size() - 1].is_equal_approx(Vector3.FORWARD), "到最後一個取樣結束")
	assert_eq(along[0], 0.0)
	assert_eq(along[along.size() - 1], 1.0, "最後一對落在第二個取樣")
	var one: Array = SlashTrail.ribbon(PackedVector3Array([Vector3.ZERO]), PackedVector3Array([Vector3.UP]), Vector2(0, 1))
	assert_eq((one[0] as PackedVector3Array).size(), 2, "只有一個取樣＝一對點，畫不出面")


func test_ribbon_has_no_corner_at_a_sample() -> void:
	# 手不動、劍每個取樣轉 40 度，轉的軸中途換了（先往前倒、再往旁邊掃）：外緣在那個取樣點要彎過去，不是折過去
	var hands := PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	var tips := PackedVector3Array([
		Vector3.UP,
		Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-40.0)),
		Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-80.0)),
		Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-80.0)).rotated(Vector3.UP, deg_to_rad(-40.0)),
	])
	var built: Array = SlashTrail.ribbon(hands, tips, Vector2(0.0, 1.0))
	var pts: PackedVector3Array = built[0]
	var along: PackedFloat32Array = built[1]
	var worst: float = 0.0
	for i: int in range(1, along.size() - 1):
		var a: Vector3 = pts[i * 2 + 1] - pts[i * 2 - 1]
		var b: Vector3 = pts[i * 2 + 3] - pts[i * 2 + 1]
		worst = maxf(worst, rad_to_deg(a.angle_to(b)))
		assert_true(absf(pts[i * 2 + 1].length() - 1.0) < 0.001, "補出來的劍還是原本的長度")
	assert_true(worst < 45.0, "外緣是彎過去的（相鄰兩小段最多差 %.1f 度；一段一段各自補的話，換軸的那一點是 90 度的折角）" % worst)


func test_blade_tip_is_the_far_end_of_the_longest_axis() -> void:
	var weapon := Node3D.new()
	var model := Node3D.new()
	model.rotation_degrees = Vector3(0, 0, 180)
	model.scale = Vector3.ONE * 0.5
	var blade := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 2.0, 0.02)
	blade.mesh = box
	blade.position = Vector3(0, 0.8, 0)  # 模型自己的座標：握把在下、劍身往上到 1.8
	model.add_child(blade)
	weapon.add_child(model)
	var tip: Vector3 = PlayerController.blade_tip(weapon)
	assert_true(tip.is_equal_approx(Vector3(0, -0.9, 0)), "轉了半圈、縮成一半：劍尖在 −Y 0.9（%s）" % tip)
	var empty := Node3D.new()
	assert_eq(PlayerController.blade_tip(empty), Vector3.ZERO, "沒有網格")
	empty.free()
	weapon.free()


## 諾恩砍一刀：揮的那一段有劍光、貼著劍、揮完淡掉；第一刀是鏽色，身上有反轉中的狀態之後是金的；收尾那一刀比較大。
func test_swing_draws_a_trail_rust_then_gold_and_bigger_on_the_finisher() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	await tree.physics_frame
	var first: SlashTrail = player.slash_trail()
	assert_not_null(first, "手上有劍就有劍光")
	assert_false(first.visible, "沒出手的時候看不到")
	var tints: Array[Color] = []
	var widths: Array[float] = []
	for swing: int in 3:
		player.start_attack()
		var trail: SlashTrail = null
		var seen: bool = false
		var widest: float = 0.0
		for i: int in 90:
			await tree.process_frame
			trail = player.slash_trail()
			if trail.visible and trail.sample_count() >= 3:
				seen = true
				widest = maxf(widest, trail.mesh.get_aabb().get_longest_axis_size())
			if seen and not trail.recording:
				break
		assert_true(seen, "第 %d 刀：揮的那一段看得到劍光" % (swing + 1))
		var mat: ShaderMaterial = trail.material_override as ShaderMaterial
		tints.append(mat.get_shader_parameter("tint") as Color)
		widths.append(widest)
		assert_true(widest > 0.5, "第 %d 刀：弧有大小（%.2f m）" % [swing + 1, widest])
		if swing == 0:
			var swish: AudioStream = Sfx.stream("slash")
			var heard: int = 0
			for c: Node in player.get_children():
				if c is AudioStreamPlayer3D and (c as AudioStreamPlayer3D).stream == swish:
					heard += 1
			assert_eq(heard, 1, "揮出去有一聲（沒砍到東西也有）")
			# 揮完之後淡掉
			for i: int in 40:
				await tree.process_frame
			assert_false(trail.visible, "揮完就消失")
			assert_eq(trail.sample_count(), 0, "每一段都過了壽命")
			player.status_effects.apply_source("rusty_sword_cut")
		# 等這一刀收招，在連段的時間內接下一刀
		for i: int in 60:
			if player.puppet().action != "attack":
				break
			await tree.physics_frame
	assert_eq(tints[0], SlashTrail.RUST_TINT, "身上沒有狀態：鏽色")
	assert_eq(tints[1], SlashTrail.GOLD_TINT, "身上有反轉中的狀態：金色")
	assert_true(player.is_finisher(), "第三刀是收尾")
	assert_true(widths[2] > widths[1] * 1.15, "收尾那一刀的弧最大（%.2f 對 %.2f）" % [widths[2], widths[1]])
	# 金色的收尾面積最大，所以不能也最亮（整片白掉、蓋住後面的人）；鏽色本來就暗，收尾可以亮一點
	assert_true(SlashTrail.strength_for(true, true) < SlashTrail.strength_for(true, false), "金色的收尾比平常的金色暗")
	assert_true(SlashTrail.strength_for(false, true) > SlashTrail.strength_for(false, false), "鏽色的收尾比平常的亮")
	assert_true(absf(float((player.slash_trail().material_override as ShaderMaterial).get_shader_parameter("strength")) - SlashTrail.strength_for(true, true)) < 0.001, "第三刀用的是金色收尾的亮度")
	root.queue_free()
	await tree.process_frame


## 三下連段從背後（玩家的鏡頭）看：第一、三下是劈在身體右邊的直劈；第二下拉開時劍收在左肩那一邊（以前直直豎在胸前，像敬禮），
## 再從左到右橫掃一整道。量的是劍尖在身體座標裡的位置（x＝右、y＝上）。只有模型在的時候量——程式人偶三下是同一個姿勢。
func test_second_swing_sweeps_from_the_left_shoulder_across_to_the_right() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	await tree.physics_frame
	var hand: Node3D = player.puppet().hand("R")
	var weapon: Node3D = hand.get_node_or_null("Weapon") as Node3D if hand != null else null
	if not player.puppet().uses_model() or weapon == null:
		root.queue_free()
		await tree.process_frame
		return
	var body: Node3D = player.get_node("Body") as Node3D
	var tip_at: Vector3 = PlayerController.blade_tip(weapon)
	var left: Array[float] = []      # 每一下揮的那一段，劍尖最左到哪裡
	var right: Array[float] = []
	var tall: Array[float] = []      # 劍尖上下走了多少
	var wind_blade := Vector3.ZERO   # 第二下拉開到底（開始揮的那一刻）劍身的方向：手 → 劍尖
	for swing: int in 3:
		player.start_attack()
		var lo := Vector3.INF
		var hi := -Vector3.INF
		for i: int in 120:
			await tree.process_frame
			if player.puppet().action != "attack":
				break
			var t: float = player.puppet().action_time / float(Puppet.ACTION_TIME["attack"])
			if t < PlayerController.TRAIL_WINDOW.x or t >= PlayerController.TRAIL_WINDOW.y:
				continue
			var inv: Transform3D = body.global_transform.affine_inverse()
			var xf: Transform3D = player.puppet().joint_now("hand_R") * weapon.transform
			var tip: Vector3 = inv * (xf * tip_at)
			if swing == 1 and lo == Vector3.INF:
				wind_blade = (tip - inv * xf.origin).normalized()
			lo = lo.min(tip)
			hi = hi.max(tip)
		left.append(lo.x)
		right.append(hi.x)
		tall.append(hi.y - lo.y)
		for i: int in 10:
			await tree.physics_frame
	assert_true(wind_blade.x < -0.5 and wind_blade.z > -0.5, "第二下拉開：劍朝左（左肩那一邊），不是豎在胸前也不是指著前面（%s）" % wind_blade)
	assert_true(left[1] < -0.4 and right[1] > 1.0, "第二下：劍尖從身體左邊掃到右邊（%.2f → %.2f m）" % [left[1], right[1]])
	assert_true(right[1] - left[1] > tall[1] * 1.5, "第二下是橫的（寬 %.2f、高 %.2f m）" % [right[1] - left[1], tall[1]])
	for i: int in [0, 2]:
		assert_true(left[i] > 0.0, "第 %d 下整道劈在身體右邊：劈到正前方會被諾恩自己的背擋住（最左 %.2f m）" % [i + 1, left[i]])
		assert_true(tall[i] > (right[i] - left[i]) * 1.4, "第 %d 下是直的（高 %.2f、寬 %.2f m）" % [i + 1, tall[i], right[i] - left[i]])
	root.queue_free()
	await tree.process_frame
