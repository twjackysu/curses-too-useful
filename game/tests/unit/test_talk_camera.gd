extends TestCase
## 對話的鏡頭（TalkCamera）的鏡位：看著講話的人、留在玩家鏡頭的那一側、換人講不跨線。


func test_shot_looks_at_the_speaker_from_the_listeners_side() -> void:
	var speaker := Vector3(2, 0, -3)
	var listener := Vector3(2, 0, 1)
	var home := Vector3(4, 2, 5)
	var s: Transform3D = TalkCamera.shot(speaker, listener, home)
	var aim: Vector3 = TalkCamera.aim_point(speaker)
	assert_true((-s.basis.z).dot((aim - s.origin).normalized()) > 0.999, "鏡頭對著講話的人的胸口")
	assert_true(absf(s.origin.y - TalkCamera.EYE_HEIGHT) < 0.001, "在眼睛的高度")
	assert_true(absf((s.origin - speaker).dot(Vector3.BACK) - TalkCamera.DIST) < 0.001, "在聽的人那一邊、固定的距離")
	assert_true(s.origin.x > speaker.x + 0.5, "偏到玩家鏡頭的那一側（%s）" % s.origin)
	assert_true(absf(s.basis.x.y) < 0.001, "鏡頭不歪")
	# 臉（比對準的地方高）落在畫面中線上面
	var face: Vector3 = speaker + Vector3.UP * 1.45
	assert_true((face - s.origin).dot(s.basis.y) > 0.1, "臉在畫面的上半")


func test_reverse_shot_stays_on_the_same_side_of_the_line() -> void:
	var a := Vector3(0, 0, 0)
	var b := Vector3(0, 0, 4)
	for home: Vector3 in [Vector3(3, 2, 6), Vector3(-3, 2, 6)]:
		var on_a: Transform3D = TalkCamera.shot(a, b, home)
		var on_b: Transform3D = TalkCamera.shot(b, a, home)
		assert_true(signf(on_a.origin.x) == signf(home.x) and signf(on_b.origin.x) == signf(home.x),
			"兩個鏡位都在玩家鏡頭那一側（%s／%s）" % [on_a.origin, on_b.origin])
		# 所以 a 在兩個畫面裡都朝同一邊看：a 的鏡位裡 b 在畫面的一側，b 的鏡位裡 a 在另一側
		var b_in_a: float = (b - on_a.origin).dot(on_a.basis.x)
		var a_in_b: float = (a - on_b.origin).dot(on_b.basis.x)
		assert_true(b_in_a * a_in_b < 0.0, "切過去左右不顛倒")


func test_shot_is_finite_when_both_stand_on_the_same_spot() -> void:
	var s: Transform3D = TalkCamera.shot(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
	assert_true(s.origin.is_finite() and s.basis.x.is_finite() and absf(s.basis.determinant() - 1.0) < 0.001)



## 滑過去的路：直線會擦過誰的頭就往外繞一個弧，兩端不動
func test_glide_bulges_away_from_a_head_in_the_way() -> void:
	# 相遇那一段的位置：玩家的鏡頭在諾恩右後方，席菈的鏡位在他左前方，直線從他頭邊 0.7 m 擦過去
	var noen := Vector3(-0.3, 0, 12.2)
	var from := Vector3(0.2, 2.1, 15.6)
	var to := Vector3(-1.22, 1.5, 11.8)
	var heads: Array[Vector3] = [noen, Vector3(-1.4, 0, 9.5)]
	var d: Vector3 = TalkCamera.detour(from, to, heads)
	assert_true(d.length() > 0.3 and d.length() <= TalkCamera.MAX_DETOUR + 0.001, "要繞（%.2f m）" % d.length())
	assert_true(absf(d.y) < 0.001, "只往旁邊繞，不改高度")
	var straight: float = 99.0
	var at_closest: float = 0.0
	var curved: float = 99.0
	for i: int in 41:
		var t: float = i / 40.0
		var p: Vector3 = from.lerp(to, t)
		var q: Vector3 = p + d * sin(PI * t)
		var gap: float = Vector2(p.x - noen.x, p.z - noen.z).length()
		if gap < straight:
			straight = gap
			at_closest = Vector2(q.x - noen.x, q.z - noen.z).length()
		curved = minf(curved, Vector2(q.x - noen.x, q.z - noen.z).length())
	assert_true(straight < 0.8, "直線離他的頭 %.2f m" % straight)
	assert_true(at_closest > TalkCamera.HEAD_CLEAR - 0.05, "原本擦過去的那一點繞開了（%.2f m）" % at_closest)
	# 整條路上最近的地方變成終點（鏡位本來就在他前面一公尺，那時候已經背對他了）
	var end: float = Vector2(to.x - noen.x, to.z - noen.z).length()
	assert_true(curved > end - 0.01, "路上沒有比終點更靠近他的地方（最近 %.2f m、終點 %.2f m）" % [curved, end])
	# 路上沒有人：不繞
	var nobody: Array[Vector3] = [Vector3(6, 0, 6)]
	assert_eq(TalkCamera.detour(from, to, nobody), Vector3.ZERO)
	# 有人站在起點旁邊（瘴氣裡那一段：席菈跟在後面，就在玩家的鏡頭旁邊）：兩端不能動，不用繞
	var beside_start: Array[Vector3] = [Vector3(from.x + 0.4, 0, from.z + 0.3)]
	assert_eq(TalkCamera.detour(from, to, beside_start), Vector3.ZERO)
	var beside_end: Array[Vector3] = [Vector3(to.x - 0.5, 0, to.z - 0.6)]
	assert_eq(TalkCamera.detour(from, to, beside_end), Vector3.ZERO)
	# 兩端疊在一起、剛好穿過頭：算得出來
	var through: Array[Vector3] = [Vector3(0, 0, 2)]
	assert_true(TalkCamera.detour(Vector3(0, 2, 0), Vector3(0, 2, 4), through).is_finite())
	assert_eq(TalkCamera.detour(from, from, heads), Vector3.ZERO)



## 過肩鏡位（二樓的巡察官往下看諾恩）：鏡頭在講話的人背後、比他的頭高，看著對方的胸口
func test_over_shoulder_shot_looks_past_the_speaker_at_the_target() -> void:
	var speaker := Vector3(0.9, 3.5, -8.0)
	var target := Vector3(0.2, 0.0, -2.5)
	var t: Transform3D = TalkCamera.over_shoulder(speaker, target)
	assert_true(t.origin.z < speaker.z - 0.5, "在他背後（%s）" % str(t.origin))
	assert_true(t.origin.y > speaker.y + 1.6, "比他的頭高")
	var aim: Vector3 = target + Vector3.UP * TalkCamera.OVER_AIM
	var fwd: Vector3 = -t.basis.z
	assert_true(fwd.dot((aim - t.origin).normalized()) > 0.999, "看著對方的胸口")
	# 講話的人在畫面裡（偏一邊、在前景），不是在鏡頭後面
	assert_true(fwd.dot((speaker + Vector3.UP * 1.5 - t.origin).normalized()) > 0.5, "他在畫面前景")


## 兩人同框：兩個人都在畫面裡、鏡頭在玩家那一側、往聽的人那邊偏（看得到講話的人的臉）
func test_two_shot_frames_both_from_the_players_side() -> void:
	var speaker := Vector3(0, 0, 0)
	var listener := Vector3(2.2, 0, 0)
	for home: Vector3 in [Vector3(1, 2, 5), Vector3(1, 2, -5)]:
		var t: Transform3D = TalkCamera.two_shot(speaker, listener, home)
		assert_true(signf(t.origin.z) == signf(home.z), "在玩家鏡頭那一側（%s）" % str(t.origin))
		assert_true(t.origin.x > 1.1, "往聽的人那邊偏（%s）" % str(t.origin))
		var cam := Camera3D.new()
		cam.fov = TalkCamera.TALK_FOV
		var fwd: Vector3 = -t.basis.z
		var half_w: float = tan(deg_to_rad(TalkCamera.TALK_FOV) * 0.5) * 16.0 / 9.0
		var half_h: float = tan(deg_to_rad(TalkCamera.TALK_FOV) * 0.5)
		for who: Vector3 in [speaker, listener]:
			for h: float in [0.3, 1.6]:
				var v: Vector3 = who + Vector3.UP * h - t.origin
				var depth: float = v.dot(fwd)
				assert_true(depth > 0.5, "在鏡頭前面")
				assert_true(absf(v.dot(t.basis.x)) / depth < half_w * 0.95, "左右在畫面裡（%s 高 %.1f）" % [str(who), h])
				assert_true(absf(v.dot(t.basis.y)) / depth < half_h * 1.02, "上下在畫面裡（%s 高 %.1f）" % [str(who), h])
		cam.free()
		# 講話的人面向聽的人（+X）：鏡頭在他臉的那一邊（他前面的半邊）
		assert_true((t.origin - speaker).dot(Vector3.RIGHT) > 0.0, "看得到講話的人的臉")
	var same: Transform3D = TalkCamera.two_shot(Vector3.ZERO, Vector3.ZERO, Vector3(0, 2, 4))
	assert_true(same.origin.is_finite() and absf(same.basis.determinant() - 1.0) < 0.001)
