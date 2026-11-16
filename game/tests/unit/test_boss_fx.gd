extends TestCase
## Boss 演出用的小東西（不用載關卡的部分）：收尾那一刀的側面鏡位、飛出去的碎塊、拿得走的魔像核心。
## 魔像身上的（被砍的反應、核心的光、凝視的那道光、核心滾出來）在 flow/test_altar.gd。


func test_finisher_shot_stands_beside_the_pair_on_the_players_side() -> void:
	var attacker := Vector3(0, 0, 2)
	var victim := Vector3(0, 0, 0)
	# 出手的人朝 −Z 砍：他的右手邊是 +X。玩家的鏡頭在右邊 → 鏡位也在右邊
	var right: Transform3D = FinisherCamera.shot(attacker, victim, Vector3(1.0, 2.0, 5.0), 6.0, 1.3, 2.0)
	assert_true(right.origin.x > 5.0, "在兩人連線的右邊 6 m（x=%.1f）" % right.origin.x)
	assert_true(right.origin.z > 2.0, "往出手的人後面退一點：看得到他的背與對方的正面")
	assert_true(absf(right.origin.y - 1.3) < 0.001)
	var aim := Vector3(0, 2.0, 1.0)
	assert_true((-right.basis.z).dot((aim - right.origin).normalized()) > 0.999, "看著兩人之間 2 m 高的地方")
	var left: Transform3D = FinisherCamera.shot(attacker, victim, Vector3(-1.0, 2.0, 5.0), 6.0, 1.3, 2.0)
	assert_true(left.origin.x < -5.0, "玩家的鏡頭在左邊就站左邊（切過去不會左右顛倒）")


func test_finisher_camera_takes_over_then_hands_the_view_back() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var home := Camera3D.new()
	home.position = Vector3(0.8, 2.0, 5.0)
	root.add_child(home)
	home.current = true
	await tree.process_frame
	var cam: FinisherCamera = FinisherCamera.play(root, Vector3(0, 0, 2), Vector3.ZERO, 0.1, 6.0, 1.3, 2.0)
	assert_not_null(cam)
	assert_true(cam.current and not home.current, "切到側面的鏡頭")
	assert_true(cam.is_holding())
	await tree.create_timer(0.3, true, false, true).timeout
	assert_true(cam.is_inside_tree() and not cam.is_holding(), "停完了，正在滑回去")
	await tree.create_timer(FinisherCamera.BACK_SEC + 0.2, true, false, true).timeout
	await tree.process_frame
	assert_false(is_instance_valid(cam), "演完自己收掉")
	assert_true(home.current, "還給玩家的鏡頭")
	root.queue_free()
	await tree.process_frame


func test_rock_debris_bursts_once_at_the_given_spot_and_cleans_up() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var ps: CPUParticles3D = RockDebris.burst(root, Vector3(3, 1, -2), Vector3.UP, 12, 0.2, Color(0.4, 0.4, 0.4), Vector2(2, 5))
	assert_eq(ps.global_position, Vector3(3, 1, -2), "噴在指定的地方（先擺好位置才開始噴）")
	assert_true(ps.one_shot and ps.emitting and ps.amount == 12)
	assert_true(ps.mesh is SphereMesh and (ps.mesh as SphereMesh).radial_segments <= 6, "是有稜角的石塊，不是面向鏡頭的圓點、也不是方塊")
	var glowing: CPUParticles3D = RockDebris.burst(root, Vector3.ZERO, Vector3.UP, 4, 0.2, Color(0.7, 0.4, 1.0), Vector2(2, 5), 3.0)
	assert_true(glowing.mesh is PrismMesh and ((glowing.mesh as PrismMesh).material as StandardMaterial3D).emission_enabled, "核心的晶片：細長的三角碎片，自己會亮")
	root.queue_free()
	await tree.process_frame


func test_golem_core_can_be_carried_on_norns_shoulder() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var body := Node3D.new()
	body.position = Vector3(4, 0, 4)
	root.add_child(body)
	var core: GolemCore = GolemCore.create()
	core.position = Vector3(1, 0.24, 1)
	root.add_child(core)
	core.carry_on(body, 0.1)
	assert_eq(core.get_parent(), body, "掛到他身上")
	assert_true(core.global_position.distance_to(Vector3(1, 0.24, 1)) < 0.01, "從地上原本的位置飛過去")
	await tree.create_timer(0.25).timeout
	assert_true(core.position.distance_to(GolemCore.CARRY_POS) < 0.01, "停在左肩旁邊")
	# 結尾的公會大廳：直接掛上去
	var carried: GolemCore = GolemCore.create()
	carried.carry_on(body)
	assert_eq(carried.position, GolemCore.CARRY_POS)
	root.queue_free()
	await tree.process_frame
