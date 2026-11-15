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
